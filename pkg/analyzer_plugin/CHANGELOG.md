## 0.4.0
- Deprecated the class `DartChangeBuilder` and enhanced `ChangeBuilder` to be
  the replacement for it.
- Deprecated the method `ChangeBuilder.addFileEdit` and introduced
  `ChangeBuilder.addDartFileEdit` and `ChangeBuilder.addGenericFileEdit` to be
  the replacements for it.
- Changed the support version range of the analyzer to `>=0.41.0 <0.42.0`.

## 0.3.0
- Removed deprecated `Plugin.getResolveResult`. Use `getResolvedUnitResult`.

## 0.2.5
- Change supported analyzer version to `^0.39.12`

## 0.2.4
- Exposed method `AnalyzerConverter.locationFromElement` (was previously
  private).

## 0.2.3
- Added class `Relevance`.
- Removed `FixKind.name`, replaced with `FixKind.id`.  Technically this is a
  breaking change but we believe that in practice it is benign, since
  `FixKind.name` was only used for debugging.
- Added function `computeDartNavigation`.
- Note: never published (had problematic imports of package:analysis_server).

## 0.2.2
- Change supported analyzer version to `^0.39.0`

## 0.2.1
- Bump maximum supported version of the analyzer to `<0.39.0`.
- Bug fixes: #37916, #38326.

## 0.2.0
- Change `DartEditBuilder.writeOverride()` to accept `ExecutableElement`
  instead of `FunctionType`.

## 0.1.0

- Support the latest `pkg:analyzer`.
- remove the declared type of generated setters

## 0.0.1-alpha.8

- Support the latest `pkg:analyzer`.

## 0.0.1-alpha.7

- Remove CompletionSuggestion.elementUri, replaced with AvailableSuggestionSet.
- Remove 'importUri' from CompletionSuggestion.
- Include type parameters into suggested code completions.

## 0.0.1-alpha.4

- Upgrade the Dart SDK version constraint

## 0.0.1

- Initial version
