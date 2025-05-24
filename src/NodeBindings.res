@module("fs")
external readFileSync: (string, string) => string = "readFileSync"

@scope("process")
external cwd: unit => string = "cwd"

@module("path")
external join3: (string, string, string) => string = "join"

@module("path")
external dirname: string => string = "dirname"

@module("node:fs/promises")
external readFile: (string, string) => Promise.t<string> = "readFile"
external access: string => Promise.t<unit> = "access"

@module("node:module")
external createRequire: string => 'a = "createRequire"

// Binding for import.meta.url
@val @scope("import.meta") external url: string = "url"

@send external resolve: ('a, string) => string = "resolve"
