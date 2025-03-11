@new
@module
external createParser: unit => 'parser = "tree-sitter"

@send
external setLanguage: ('parser, 'language) => unit = "setLanguage"

@new
@module("tree-sitter")
external createQuery: ('language, string) => 'query = "Query"

type position = {
  row: int,
  column: int,
}
type nodetype
type rec node = {
  @as("type") type_: nodetype,
  startPosition: position,
  endPosition: position,
  childCount: int,
  children: array<node>,
  text: string,
}
type tree = {
  rootNode: node,
}
@send external parse: ('parser, string) => tree = "parse"

type capture = {
  name: string,
  node: node,
}
@send external captures: ('query, node) => array<capture> = "captures"


