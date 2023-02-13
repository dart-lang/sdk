# Implementing a new language feature

When a new language feature is approved, a tracking issue will be created in
order to track the work required in the `analysis_server` package. Separate
issues are created to track the work in the `analyzer`, `dartdoc`, and `linter`
packages.

Below is a template for the list of server features that need to be reviewed to
see whether they need to be enhanced in order to work correctly with the new
feature. In almost all cases new tests will need to be written to ensure that
the feature isn't broken when run over code that uses the new language feature.
In some cases, new support will need to be added.

Separate issues should be created for each of the items in the list.

## Template

The following is a list of the individual features that need to be considered.
The features are listed in alphabetical order.

- [ ] Call Hierarchy
- [ ] Closing Labels
- [ ] Code Completion
- [ ] Code Folding
- [ ] documentSymbol
- [ ] Flutter Outline
- [ ] Hovers
- [ ] Implemented Markers
- [ ] Navigation
- [ ] Occurrences
- [ ] Organize Imports
- [ ] Outline
- [ ] Overrides Markers
- [ ] Quick Assists
- [ ] Quick Fixes
- [ ] Refactorings - legacy
- [ ] Refactorings - self describing
- [ ] Search - Find References
- [ ] Search - Member Declarations
- [ ] Search - Member References
- [ ] Search - Top-level Declarations
- [ ] selectionRange
- [ ] Semantic Highlights
- [ ] Semantic Tokens
- [ ] signatureHelp
- [ ] Snippets
- [ ] Sort Members
- [ ] Type Hierarchy
