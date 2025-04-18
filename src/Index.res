open NodeBindings
open TreeSitterLanguages
open TreeSitter

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

let getLanguage: string => 'language = languageName => {
  switch languageName {
  | "javascript" => javascript
  | "python" => python
  | _ => raise(Failure("Unsupported language"))
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
  let parser = createParser()
  parser->setLanguage(language)
  parser
}

let buildQuery: ('language, string) => 'query = (language, scm) => {
  createQuery(language, scm)
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

let getOutline: string => option<string> = filename => {
  getLanguageName(filename)
  ->orElse(() => {
    Console.log("Unsupported file extension")
    None
  })
  ->Option.map(languageName => {
    let language = getLanguage(languageName)
    let scm = getScmQuery(languageName)
    (language, scm)
  })
  ->Option.map(((language, scm)) => {
    let parser = buildParser(language)
    let query = buildQuery(language, scm)
    (parser, query)
  })
  ->Option.flatMap(((parser, query)) => {
    try {
      let source = readFileSync(filename, "utf-8")->String.trim
      switch source {
      | "" => {
          Console.log(`Empty file: ${filename}`)
          None
        }
      | _ => {
          let tree = parser->parse(source)
          Some((source, tree, query))
        }
      }
    } catch {
    | _ => {
        Console.log(`Failed to read file: ${filename}`)
        None
      }
    }
  })
  ->Option.map(((source, tree, query)) => {
    let captures =
      captures(query, tree.rootNode)
      ->Array.toSorted((a, b) => {
        float(a.node.startPosition.row - b.node.startPosition.row)
      })
      ->Array.filter(capture => {
        let {name} = capture
        String.startsWith(name, "name.definition.") || String.startsWith(name, "name.reference.")
      })
    (source, captures)
  })
  ->Option.map(((source, captures)) => {
    let lines = String.split(source, "\n")
    captures->Array.map(capture => {
      let content =
        lines
        ->Array.slice(~start=capture.node.startPosition.row, ~end=capture.node.endPosition.row + 1)
        ->Array.join("\n")
      {
        content,
        startRow: capture.node.startPosition.row,
        endRow: capture.node.endPosition.row,
      }
    })
  })
  ->Option.map(chunks => {
    let merged = mergeChunks(chunks)
    merged
    ->Array.map(chunk => {
      chunk.content
    })
    ->Array.join("\n…\n")
  })
}

let outline = getOutline("/home/akiwu/Projects/wuminzhe/subnames-tools/nameToAddr.js")
Console.log(outline)

// let outline = getOutline("test.py")
// Console.log(outline)

// monad bera sui chains
