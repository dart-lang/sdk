## 0.1.2-main.4

- Fix bug where augmenting classes with type parameters didn't work.

## 0.1.2-main.3

- Re-export 'package:_macros/src/executor/response_impls.dart'.

## 0.1.2-main.2

- Re-publish of `0.1.2-main.1` which was retracted due to a corrupted tar file.

## 0.1.2-main.1

- Make it an error for macros to complete with pending async work scheduled.

## 0.1.2-main.0

- Remove type parameter on internal `StaticType` implementation.

## 0.1.1-main.0

- Add identifiers to `NamedStaticType`.
- Add `StaticType.asInstanceOf`.

## 0.1.0-main.7

- Fix for generating code after extendsType

## 0.1.0-main.6

- Add extendsType API for adding an extends clause.
- Refactor builder implementations, fixes some bugs around nested builders.

## 0.1.0-main.5

- Handle ParallelWaitError with DiagnosticException errors nicely.
- Fix a bug where we weren't reporting diagnostics for nested builders.

## 0.1.0-main.4

- Improve formatting of constructor initializer augmentations.

## 0.1.0-main.3

- Validate parts in `Code.fromParts()`.

## 0.1.0-main.2

- Add caching for `typeDeclarationOf` results.

## 0.1.0-main.1

- Add caching for `TypeDeclaration` related introspection results.

## 0.1.0-main.0

Initial release, highly experimental at this time.
