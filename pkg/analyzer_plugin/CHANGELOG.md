## 0.14.5-dev

- Require version `10.3.0-dev` of the `analyzer` package.

## 0.14.4

- Require version `10.2.0` of the `analyzer` package.

## 0.14.3

- Require version `10.1.0` of the `analyzer` package.

## 0.14.2

- Require version `10.0.2` of the `analyzer` package.

## 0.14.1

- Require version `10.0.1` of the `analyzer` package.

## 0.14.0

- Require version `10.0.0` of the `analyzer` package.
- `AssistContributorMixin` is now a mixin.
- Remove deprecated `methodBeingCopied` parameters on various methods.
- Remove `ChangeBuilder.new`'s deprecated `eol` parameter.
- Remove `ChangeBuilder.addDartFileEdit`'s deprecated `importPrefixGenerator` parameter.
- Remove the deprecated `ChangeBuilder.copy` method.
- Remove the deprecated `RangeFactory.error` method.

## 0.13.11

- Require version `9.0.0` of the `analyzer` package.

## 0.13.10

- Require version `8.4.0` of the `analyzer` package.

## 0.13.9

- Require version `8.3.0` of the `analyzer` package.

## 0.13.8

- Require version `8.2.0` of the `analyzer` package.
- Require Dart SDK `^3.9.0`.

## 0.13.7

- Require version `8.1.1` of the `analyzer` package.

## 0.13.6

- Require version `^8.1.0` of the `analyzer` package.

## 0.13.5

- Require version `^8.0.0` of the `analyzer` package.

## 0.13.4

- Require version `^7.5.1` of the `analyzer` package.

## 0.13.2

- Deprecated: `RangeFactory.error` is replaced by `RangeFactory.diagnostic`.
- Require version `^7.4.6` of the `analyzer` package.

## 0.13.1

- Updated SDK constraint to `^3.5.0`.
- Require version `7.4.x` of the `analyzer` package.

## 0.13.0

- Remove `elementName()` from `RangeFactory`. Use `fragmentName()` instead.
- Breaking changes to `DartFileEditBuilder` and `DartEditBuilder`.
- Breaking changes to `AnalyzerConverter`.
- Support for a plugin to send an `AnalysisStatus` notification, featuring an
  `isAnalyzing` `bool` field.

## 0.12.0

- Breaking changes to `DartFileEditBuilder`: `convertFunctionFromSyncToAsync`
  and `replaceTypeWithFuture`.
- Breaking changes to all classes in `lib/protocol/protocol_common.dart` and
  `lib/protocol/protocol_generated.dart` that implement `Enum`: These classes
  are all now proper Dart enums. Each such enum no longer has a static `VALUES`
  field, no a public constructor. Each enum value also no longer has an
  instance getter, `name` (though the `EnumName` extension in `dart:core`
  provides a `name` instance getter). The instances of each enum are also now
  considered exhaustive (which may trigger new diagnostics on existing switch
  statements and switch expressions).
- Support version `7.x` of the `analyzer` package.
- Support change descriptions on SourceEdit.
- New API in `DartFileEditBuilder`: `getIndent`, `insertCaseClauseAtEnd`,
  `insertConstructor`, `insertField`, `insertGetter`, `insertMethod`,
  `writeIndent`.
- New API in `DartEditBuilder`: `writeFormalParameter` and
  `writeFormalParameters`.
- New experimental API in `DartEditBuilder`: `writeOverride2`,
  `writeReference2`, `writeType2`, `writeTypeParameter2`, and
  `writeTypeParameters2`.

## 0.11.3

- Support version `6.x` of the `analyzer` package.

## 0.11.2

- Support version `5.x` of the `analyzer` package.

## 0.11.1
- Call `analyzeFiles` from `handleAffectedFiles` only for files that are
  analyzed in this analysis context.

## 0.11.0
- Using `AnalysisContextCollection` and `AnalysisContext` for analysis.

## 0.10.0
- Support version `4.x` of the `analyzer` package.

## 0.9.0
- Support version `3.x` of the `analyzer` package.

## 0.8.0
- Require SDK `2.14` to use `Object.hash()`.
- Require `yaml 3.1.0` to use `recover`.

## 0.7.0
- Support version `2.x` of the `analyzer` package.

## 0.6.0
- Bug fixes to the protocol.

## 0.5.0
- Changed the support version range of the analyzer to `^1.3.0`.
- Removed `Plugin.fileContentOverlay`, instead `Plugin.resourceProvider` is
  now `OverlayResourceProvider`, and `analysis.updateContent` updates it.
- Removed deprecated `DartChangeBuilder` and `DartChangeBuilderImpl`.
- Removed deprecated `ChangeBuilder.addFileEdit()`.
- Stable null safety release.
- Updated dependencies to null safe releases.

## 0.4.0
- Deprecated the class `DartChangeBuilder` and enhanced `ChangeBuilder` to be
  the replacement for it.
- Deprecated the method `ChangeBuilder.addFileEdit` and introduced
  `ChangeBuilder.addDartFileEdit` and `ChangeBuilder.addGenericFileEdit` to be
  the replacements for it.
- Changed the supported version range of the analyzer to `>=0.41.0 <0.42.0`.

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
