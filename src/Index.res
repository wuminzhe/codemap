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

  readFileSync(scmFilename, "utf-8")
}

type tag = {
  name: string,
  kind: string,
  line: int,
  col: int,
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

// let getTags: string => option<array<tag>> = languageName => {
//   let language = getLanguage(languageName)
//   let scm = getScmQuery(languageName)
//
//   let parser = createParser()
//   parser->setLanguage(language)
//   let query =
//     createQuery(language, scm)
//     ->Option.map(((parser, query)) => {
//       let source = readFileSync(filename, "utf-8")
//       let tree = parser->parse(source)
//       captures(query, tree.rootNode)
//     })
//     ->Option.map(captures => {
//       captures->Array.filterMap(capture => {
//         let {name, node} = capture
//         let kind = if String.startsWith(name, "name.definition.") {
//           Some("def")
//         } else if String.startsWith(name, "name.reference.") {
//           Some("ref")
//         } else {
//           None
//         }
//         kind->Option.map(
//           kind => {
//             {
//               filename,
//               name: node.text,
//               kind,
//               line: node.startPosition.row,
//               col: node.startPosition.column,
//             }
//           },
//         )
//       })
//     })
// }

let getTags: array<'capture> => array<tag> = captures => {
  captures->Array.filterMap(capture => {
    let {name, node} = capture
    let kind = if String.startsWith(name, "name.definition.") {
      Some("def")
    } else if String.startsWith(name, "name.reference.") {
      Some("ref")
    } else {
      None
    }
    kind->Option.map(k => {
      {
        name: node.text,
        kind: k,
        line: node.startPosition.row,
        col: node.startPosition.column,
      }
    })
  })
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
  ->Option.map(((parser, query)) => {
    let source = readFileSync(filename, "utf-8")
    let tree = parser->parse(source)
    (source, tree, query)
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

let outline = getOutline("test.py")
Console.log(outline)

// monad bera sui chains
