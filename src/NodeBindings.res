@module("fs")
external readFileSync: (string, string) => string = "readFileSync"

@scope("process")
external cwd: unit => string = "cwd"

@module("path")
external join3: (string, string, string) => string = "join"

@module("path")
external dirname: string => string = "dirname"
