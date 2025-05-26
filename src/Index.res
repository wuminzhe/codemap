open NodeBindings
let require = createRequire(url)

await TreeSitter.init(TreeSitter.defaultModule, ())

let getLanguageName: string => option<string> = filename => {
  filename
  ->String.split(".")
  ->Array.pop
  ->Option.flatMap(ext => {
    switch ext {
    | "js" => Some("javascript")
    | "ts" => Some("typescript")
    | "rs" => Some("rust")
    | "py" => Some("python")
    | _ => None
    }
  })
}

let getLanguage = async languageName => {
  let path = resolve(require, `tree-sitter-wasms/out/tree-sitter-${languageName}.wasm`)
  try {
    // Console.log(path)
    // await access(path)
    let language = await TreeSitter.load(TreeSitter.languageModule, path)
    Ok(language)
  } catch {
  | Exn.Error(obj) => {
      switch Exn.message(obj) {
      | Some(msg) => Error(`Language not found: ${languageName}, ${msg}`)
      | None => Error(`Failed to load language: ${languageName}`)
      }
    }
  }
}

let getScmQuery: string => string = languageName => {
  let scmFilename = switch languageName {
  | "javascript" => "javascript.scm"
  | "python" => "python.scm"
  | _ => raise(Failure(`Unsupported scm query for language ${languageName}`))
  }

  readFileSync(join3("src", "queries", scmFilename), "utf-8")
}


let orElse: (option<'a>, unit => option<'b>) => option<'b> = (o, f) => {
  switch o {
  | Some(x) => Some(x)
  | None => f()
  }
}

let buildParser: 'language => 'parser = language => {
  let parser = TreeSitter.createParser()
  TreeSitter.setLanguage(parser, language)
  parser
}

type chunk = {
  content: string,
  startRow: int,
  endRow: int,
}

let mergeChunks: array<chunk> => array<chunk> = chunks => {
  let result = [chunks->Array.getUnsafe(0)]

  for i in 1 to Array.length(chunks) - 1 {
    let prevIndex = Array.length(result) - 1
    let curr = chunks->Array.getUnsafe(i)
    let prev = result->Array.getUnsafe(prevIndex)

    if prev.endRow + 1 == curr.startRow {
      result->Array.setUnsafe(
        prevIndex,
        {
          content: prev.content ++ "\n" ++ curr.content,
          startRow: prev.startRow,
          endRow: curr.endRow,
        },
      )
    } else {
      Array.push(result, curr)
    }
  }

  result
}

// Async function to get the outline of a file using TreeSitter
let getOutlineAsync: string => Promise.t<result<string, string>> = filename => {
  // Check if the file extension is supported
  switch getLanguageName(filename) {
  | None => Promise.resolve(Error(`Unsupported file extension: ${filename}`))
  | Some(languageName) => {
      // Try to get the SCM query for the language
      let scmResult = try {
        Ok(getScmQuery(languageName))
      } catch {
      | Exn.Error(obj) => {
          switch Exn.message(obj) {
          | Some(msg) => Error(`Failed to get SCM query: ${msg}`)
          | None => Error(`Failed to get SCM query for ${languageName}`)
          }
        }
      }
      
      switch scmResult {
      | Error(err) => Promise.resolve(Error(err))
      | Ok(scm) => {
          // Load the language
          getLanguage(languageName)
          ->Promise.then(languageResult => {
            switch languageResult {
            | Error(err) => Promise.resolve(Error(err))
            | Ok(language) => {
                // Try to read and parse the file
                try {
                  // Read the file
                  let source = readFileSync(filename, "utf-8")->String.trim
                  
                  if source == "" {
                    Promise.resolve(Error(`Empty file: ${filename}`))
                  } else {
                    // Parse the file with TreeSitter
                    let parser = buildParser(language)
                    let tree = TreeSitter.parse(parser, source)
                    let rootNode = TreeSitter.rootNode(tree)
                    
                    // Create the query and get captures
                    let query = TreeSitter.query(language, scm)
                    let captures = TreeSitter.captures(query, rootNode)
                      ->Array.toSorted((a, b) => {
                        float(a.node.startPosition.row - b.node.startPosition.row)
                      })
                      ->Array.filter(capture => {
                        let {name} = capture
                        String.startsWith(name, "name.definition.") || 
                        String.startsWith(name, "name.reference.")
                      })
                    
                    // Process captures into chunks
                    let lines = String.split(source, "\n")
                    let chunks = captures->Array.map(capture => {
                      let content = lines
                        ->Array.slice(
                          ~start=capture.node.startPosition.row, 
                          ~end=capture.node.endPosition.row + 1
                        )
                        ->Array.join("\n")
                      
                      {
                        content,
                        startRow: capture.node.startPosition.row,
                        endRow: capture.node.endPosition.row,
                      }
                    })
                    
                    // Generate the outline
                    if Array.length(chunks) > 0 {
                      let merged = mergeChunks(chunks)
                      let result = merged
                        ->Array.map(chunk => chunk.content)
                        ->Array.join("\n…\n")
                      
                      Promise.resolve(Ok(result))
                    } else {
                      Promise.resolve(Error(`No outline elements found in file: ${filename}`))
                    }
                  }
                } catch {
                | Exn.Error(obj) => {
                    let errorMsg = switch Exn.message(obj) {
                    | Some(msg) => `Failed to process file: ${msg}`
                    | None => `Failed to process file: ${filename}`
                    }
                    Promise.resolve(Error(errorMsg))
                  }
                }
              }
            }
          })
          ->Promise.catch(err => {
            Promise.resolve(Error(`Error processing outline for ${filename}`))
          })
        }
      }
    }
  }
}

// Test function for getOutlineAsync
let testOutlineAsync = (filename: string) => {
  Console.log(`Testing outline generation for ${filename}...`)
  
  getOutlineAsync(filename)
  ->Promise.then(result => {
    switch result {
    | Ok(outline) => {
        Console.log("✅ Successfully generated outline:")
        Console.log(outline)
      }
    | Error(err) => {
        Console.log("❌ Failed to generate outline:")
        Console.log(err)
      }
    }
    Promise.resolve()
  })
  ->Promise.catch(_ => {
    Console.log("❌ Error during outline generation")
    Promise.resolve()
  })
}

// Execute the test with test.py
let _ = testOutlineAsync("./test.py")

// You can test with other files as well
// For example, uncomment the line below to test with a JavaScript file
// let _ = testOutlineAsync("./src/Demo.res.js")