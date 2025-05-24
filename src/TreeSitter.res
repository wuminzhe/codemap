// import WebTreeSitter from "web-tree-sitter";
// var a = new WebTreeSitter();
@new
@module("web-tree-sitter")
external createParser: unit => 'parser = "default"

// The init function is a method on the default export
@val
@module("web-tree-sitter")
external defaultModule: 'a = "default"

@send
external init: ('a, unit) => Promise.t<unit> = "init"


@val
@scope("WebTreeSitter")
external languageModule: 'languageModule = "Language"

@send
external load: ('languageModule, string) => Promise.t<'language> = "load"

@send
external setLanguage: ('parser, 'language) => unit = "setLanguage"

@send
external query: ('language, string) => 'query = "query"

@send
external parse: ('parser, string) => 'tree = "parse"

@get
external rootNode: 'tree => 'treeRootNode = "rootNode"

type position = {
  row: int,
  column: int,
}

type node = {
  startPosition: position,
  endPosition: position,
  text: string,
}

type capture = {
  name: string,
  node: node,
}

@send
external captures: ('query, 'treeRootNode) => array<capture> = "captures"

// type position = {
//   row: int,
//   column: int,
// }
// type nodetype
// type rec node = {
//   @as("type") type_: nodetype,
//   startPosition: position,
//   endPosition: position,
//   childCount: int,
//   children: array<node>,
//   text: string,
// }
// type tree = {
//   rootNode: node,
// }
// @send external parse: ('parser, string) => tree = "parse"
//
// type capture = {
//   name: string,
//   node: node,
// }
// @send external captures: ('query, node) => array<capture> = "captures"
//
//
