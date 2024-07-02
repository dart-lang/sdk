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

- [ ] Call Hierarchy (an IDE feature where you can get a call hierarchy if you
      click on a method)
- [ ] Closing Labels (an LSP feature allowing the IDE to show lightly grayed out
      comments at the end of the last line of a multi-line invocation, to aid
      the user in understanding what invocation is closed by a `)`)
- [ ] Code Completion
- [ ] Code Folding
- [ ] Document Colors (an LSP feature whereby a reference to a color in code can
      be associated with a colored swatch and a color picker)
- [ ] Hovers
- Implemented/override markers (a legacy protocol feature, only available to
  IntelliJ and Android Studio)
  - [ ] Implemented Markers (allows navigation from a base class method to
        methods that override it, or from a base class to classes that
        extend/implement it)
  - [ ] Override Markers (allows navigation from a method to the base class
        method it overrides, or from a class to the class that it
        extends/implements)
- [ ] Inlay Hints (an LSP feature allowing extra information to be displayed
      using inline hints)
- Navigation
  - [ ] Go to Definition (LSP feature)
  - [ ] Go to Type Definition (LSP feature)
  - [ ] Go to Super (LSP feature)
  - [ ] Legacy protocol (for IntelliJ and Android Studio)
- Occurrences
  - [ ] Legacy protocol (for IntelliJ and Android Studio)
  - [ ] Document Highlights (LSP feature)
- [ ] Organize Imports
- Outline
  - [ ] Flutter Outline
  - [ ] Legacy protocol, a.k.a. Document Symbols (for IntelliJ and Android
        Studio)
  - [ ] LSP feature
- Refactorings and quick assists/fixes (note that in addition to potentially
  creating new refactorings and/or quick assists/fixes, part of the work
  required to implement a new language feature includes evaluating each existing
  refactoring and quick fix/assist to see whether it needs to be improved or
  have test cases added to reflect the new feature).
  - [ ] Legacy refactorings (for IntelliJ and Android Studio)
  - [ ] LSP rename refactoring (note that LSP has a special protocol for
        renames)
  - [ ] LSP self-describing refactorings
  - [ ] Quick Assists
  - [ ] Quick Fixes
- Search
  - [ ] Find References
  - [ ] Implementations - LSP
  - [ ] Member Declarations
  - [ ] Member References
  - [ ] Top-level Declarations
- [ ] Selection Range (an LSP feature allowing a selection to be expanded to
      cover the range of an ancestor AST node)
- Syntax Highlighting
  - [ ] Legacy protocol, a.k.a. Semantic Highlights (for IntelliJ and Android
        Studio)
  - [ ] Semantic Tokens (LSP feature)
- [ ] Signature Help (an LSP feature that tells the parameters and types needed
      for an invocation)
- [ ] Snippets
- [ ] Sort Members
- Type Hierarchy
  - [ ] Legacy protocol (for IntelliJ and Android Studio)
  - [ ] LSP feature
- [ ] Workspace Symbols (LSP feature)
