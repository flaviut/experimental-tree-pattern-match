import sequtils, strutils, nre, tables, algorithm
type
  NodeType* = object
    name: string
  NodeKind* = enum
    nkA = "a", nkB = "b", nkC = "c", nkD = "d", nkWildcard = "*"
  Node* = object
    kind: NodeKind
    typ: NodeType
    children: seq[Node]

proc nNode(kind: NodeKind, children: varargs[Node]): Node =
  result = Node( kind: kind, children: @[] )
  for c in children:
    result.children.add(c)

proc matches(haystack, needle: Node): bool =
  if needle.kind == nkWildcard and needle.children.len == 0:
    return needle.typ == haystack.typ

  if haystack.kind != needle.kind and
     needle.kind != nkWildcard:
    return false

  if haystack.children.len != needle.children.len:
    return false

  for i, v in needle.children:
    if not haystack.children[i].matches(needle.children[i]):
      return false

  return true

proc `$`(self: Node): string =
  if self.children.len != 0:
    result = "(" & $self.kind & (if self.typ.name != "": ":" & self.typ.name else: "")
    for i, c in self.children:
      result.add(" ")
      result.add($c)
    result.add(")")
  else:
    result = $self.kind & (if self.typ.name != "": ":" & self.typ.name else: "")

let identTable = {
  "a": nkA,
  "b": nkB,
  "c": nkC,
  "d": nkD,
  "*": nkWildcard,
  }.toTable()

proc tokenize(str: string): seq[string] =
  result = str.replace(re"\(", " ( ").replace(re"\)", " ) ").replace(re":", " : ").strip().split(re"\s+")
  reverse(result)

proc parse(tokens: var seq[string]): Node =
  if tokens.len == 0:
    raise newException(Exception, "Unexpected EOF")
  let tok = tokens.pop()
  if tok == "(":
    result = parse(tokens)
    while tokens[tokens.len - 1] != ")":
      result.children.add(parse(tokens))
    discard tokens.pop()
  elif identTable.hasKey(tok):
    result = Node( kind: identTable[tok], children: @[], typ: NodeType(name : "") )
    if tokens[tokens.len - 1] == ":":
      result.typ = NodeType(name : tokens[tokens.len - 2])
      discard tokens.pop()
      discard tokens.pop()
  else:
    raise newException(Exception, "Unexpected token $1" % [tok])

proc parse(str: string): Node =
  var toks = tokenize(str)
  return parse(toks)

proc find(haystack: Node, needle: Node): seq[Node] =
  result = @[]

  for c in haystack.children:
    result.add(c.find(needle))

  if haystack.matches(needle):
    result.add(haystack)

let haystack = parse("""
(a
  (b:int a b a b)
  (d d a b
    (d d a b c)
  )
)
""")
let needle = parse("""
(*:int * * * *)
""")

for m in haystack.find(needle):
  echo m

