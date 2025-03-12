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
  filename: string,
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

let getTags: string => option<array<tag>> = filename => {
  getLanguageName(filename)
  ->orElse(() => {
    Console.log("Unsupported file extension")
    None
  })
  ->Option.map(languageName => {
    let language = getLanguage(languageName)
    let scmQuery = getScmQuery(languageName)
    (language, scmQuery)
  })
  ->Option.map(((language, scmQuery)) => {
    let parser = createParser()
    parser->setLanguage(language)
    let query = createQuery(language, scmQuery)
    (parser, query)
  })
  ->Option.map(((parser, query)) => {
    let source = readFileSync(filename, "utf-8")
    let tree = parser->parse(source)
    captures(query, tree.rootNode)
  })
  ->Option.map(captures => {
    captures->Array.filterMap(capture => {
      let {name, node} = capture
      let kind = if String.startsWith(name, "name.definition.") {
        Some("def")
      } else if String.startsWith(name, "name.reference.") {
        Some("ref")
      } else {
        None
      }
      kind->Option.map(
        kind => {
          {
            filename,
            name: node.text,
            kind,
            line: node.startPosition.row,
            col: node.startPosition.column,
          }
        },
      )
    })
  })
}

let tags = getTags("test.py")
Console.log(tags)
