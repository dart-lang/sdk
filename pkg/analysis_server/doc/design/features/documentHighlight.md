# Document highlight

   LSP:    [textDocument/documentHighlight][] requests
   Legacy: `analysis.occurrences` notification

Document highlight is used to highlight both local declarations of and
references to the element declared or referenced at the location of the
insertion cursor.

## Symmetry

In most cases the operation should be symmetric. That is, the same set of
locations should be highlighted no matter which of those locations contains the
insertion cursor. For example, if the user clicks on the declaration of a local
variable, then all references to that variable should be highlighted, and if the
user clicks on any of the highlighted references the set of highlights should
stay the same.

There are a few cases where symmetry is violated. In particular, symmetry is
violated at declaration sites where a single declaration introduces multiple
elements. In those cases, the set of references to all of the introduced
elements are highlighted, clicking on one of the highlighted references will
remove the highlights related to other elements.

Declarations are the only place where this can occur. Any other references are,
by the semantics of the language, a reference to a single element, so only
references to that element should be highlighted. This is in keeping with the
[principle of language fidelity][languageFidelity].

Below is a list of the places where symmetry is intentionally broken.

- The declaration of a field introduces both the field (a storage location in an
  object), a getter, and optionally a setter (unless the field is either `final'
  or `const`). Selecting the field should highlight references to all three
  elements; selecting a reference to one of those three elements should only
  highlight references to the same element.

- The declaration of a top-level variable similarly introduces both the variable
  (a storage location), a getter, and optionally a setter (unless the variable
  is either `final` or `const`).

- The declaration of a declaring parameter introduces both the parameter and a
  field, which in turn introduces a getter and a possible setter.

- In an object or record pattern, the names of a getter can be omitted if the
  matching pattern is a variable declaration pattern whose name matches the name
  of the getter. If the getter isn't specified, then the variable declaration
  introduces both a local variable declaration and a reference to the getter.

There are a couple of other places where one declaration introduces other
elements where we don't break symmetry. There isn't a principled reason for
this, but it seems like breaking symmetry in these cases would be more
surprising to users than the inconsistency is.

- The declaration of a class or enum, when that declaration doesn't have an
explicit declaration of a constructor, introduces the declaration of a default
constructor (an unnamed constructor with no parameters).

- The declaration of an enum introduces the static getter `values` and the
instance getters `index` and `name`.

[languageFidelity]: ../principles/language_fidelity.md
[textDocument/documentHighlight]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_documentHighlight
