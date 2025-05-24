open TreeSitter
// open TreeSitterLanguages

await init(defaultModule, ())

let parser = createParser()
// setLanguage(parser, javascript)
Console.log(parser)

open NodeBindings

let file = await readFile("./test.py", "utf-8")
Console.log(file)

let require = createRequire(url)
let wasmPath = resolve(require, `tree-sitter-wasms/out/tree-sitter-python.wasm`)
let language = await load(languageModule, wasmPath)
parser->setLanguage(language)

let query = query(language, Index.getScmQuery("python"))
// Console.log(query)

let tree = parse(parser, file)
let rootNode = rootNode(tree)
// Console.log(rootNode)

let captures = captures(query, rootNode)
Console.log(captures)


