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

let getLanguage: string => option<'language> = languageName => {
  switch languageName {
  | "javascript" => Some(javascript)
  | "python" => Some(python)
  | _ => None
  }
}

let getScmQuery: string => option<string> = languageName => {
  switch languageName {
  | "javascript" => Some("javascript.scm")
  | "python" => Some("python.scm")
  | _ => None
  }->Option.map(filename => {
    readFileSync(filename, "utf-8")
  })
}

type tag = {
  filename: string,
  name: string,
  kind: string,
  line: int,
  col: int,
}

let getTags: string => option<array<tag>> = filename => {
  getLanguageName(filename)
  ->Option.flatMap(languageName => {
    let language = getLanguage(languageName)
    let scmQuery = getScmQuery(languageName)
    switch (language, scmQuery) {
    | (Some(language), Some(scmQuery)) => Some((language, scmQuery))
    | _ => None
    }
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
