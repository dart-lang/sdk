# Outline

   LSP:    [textDocument/documentSymbol][] request
   Legacy: `analysis.outline` notification

Document symbol is used to get the structure of a file. This information is
used, for example, to populate the Outline view and breadcrumbs.

The structural information forms a tree of 'document symbol' nodes.

## Syntactic or semantic structure?

We take the position that the Outline view is intended to effectively be a table
of contents for a file. This is consistent with the way TypeScript uses the
view.

This implies that the information shown in the view should be a subset of the
information in the file. Another way of saying this is that a document symbol
should represent the syntactic structure of the code, not the semantics of the
code.

As a result, we choose to return a node for
- top-level declarations, including classes, enums, extensions, extension types,
  functions, mixins, and top-level variables
- members of top-level declarations, including fields and methods
- augmentations of any of the above
- invocations of the `group` and `test` functions from `package:test`

We do not return nodes for directives or local variables (though we do include
parameters as part of the signature of functions and methods in the detail
field).

[textDocument/documentSymbol]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_documentSymbol
