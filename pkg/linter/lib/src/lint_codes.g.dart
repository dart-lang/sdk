// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/linter/messages.yaml' and run
// 'dart run pkg/linter/tool/generate_lints.dart' to update.

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

// Generator currently outputs double quotes for simplicity.
// ignore_for_file: prefer_single_quotes

// Generated `withArguments` methods always use block bodies for simplicity.
// ignore_for_file: prefer_expression_function_bodies

part of 'lint_codes.dart';

class LinterLintCode extends LintCodeWithExpectedTypes {
  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  alwaysDeclareReturnTypesOfFunctions =
      diag.alwaysDeclareReturnTypesOfFunctions;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  alwaysDeclareReturnTypesOfMethods = diag.alwaysDeclareReturnTypesOfMethods;

  /// No parameters.
  static const LinterLintWithoutArguments alwaysPutControlBodyOnNewLine =
      diag.alwaysPutControlBodyOnNewLine;

  /// No parameters.
  static const LinterLintWithoutArguments
  alwaysPutRequiredNamedParametersFirst =
      diag.alwaysPutRequiredNamedParametersFirst;

  /// No parameters.
  static const LinterLintWithoutArguments alwaysSpecifyTypesAddType =
      diag.alwaysSpecifyTypesAddType;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  alwaysSpecifyTypesReplaceKeyword = diag.alwaysSpecifyTypesReplaceKeyword;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  alwaysSpecifyTypesSpecifyType = diag.alwaysSpecifyTypesSpecifyType;

  /// No parameters.
  static const LinterLintWithoutArguments alwaysSpecifyTypesSplitToTypes =
      diag.alwaysSpecifyTypesSplitToTypes;

  /// No parameters.
  static const LinterLintWithoutArguments alwaysUsePackageImports =
      diag.alwaysUsePackageImports;

  /// No parameters.
  static const LinterLintWithoutArguments analyzerElementModelTrackingBad =
      diag.analyzerElementModelTrackingBad;

  /// No parameters.
  static const LinterLintWithoutArguments
  analyzerElementModelTrackingMoreThanOne =
      diag.analyzerElementModelTrackingMoreThanOne;

  /// No parameters.
  static const LinterLintWithoutArguments analyzerElementModelTrackingZero =
      diag.analyzerElementModelTrackingZero;

  /// Lint issued if a file in the analyzer public API contains a `part`
  /// directive that points to a file that's not in the analyzer public API.
  ///
  /// The rationale for this lint is that if such a `part` directive were to
  /// exist, it would cause all the members of the part file to become part of
  /// the analyzer's public API, even though they don't appear to be public API.
  ///
  /// Note that the analyzer doesn't make very much use of `part` directives,
  /// but it may do so in the future once augmentations and enhanced parts are
  /// supported.
  ///
  /// No parameters.
  static const LinterLintWithoutArguments analyzerPublicApiBadPartDirective =
      diag.analyzerPublicApiBadPartDirective;

  /// Lint issued if a method, function, getter, or setter in the analyzer
  /// public API makes use of a type that's not part of the analyzer public API,
  /// or if a non-public type appears in an `extends`, `implements`, `with`, or
  /// `on` clause.
  ///
  /// The reason this is a problem is that it makes it possible for analyzer
  /// clients to implicitly reference analyzer internal types. This can happen
  /// in many ways; here are some examples:
  ///
  /// - If `C` is a public API class that implements `B`, and `B` is a private
  ///   class with a getter called `x`, then a client can access `B.x` via `C`.
  ///
  /// - If `f` has return type `T`, and `T` is a private class with a getter
  ///   called `x`, then a client can access `T.x` via `f().x`.
  ///
  /// - If `f` has type `void Function(T)`, and `T` is a private class with a
  ///   getter called `x`, then a client can access `T.x` via
  ///   `var g = f; g = (t) { print(t.x); }`.
  ///
  /// This lint can be suppressed either with an `ignore` comment, or by marking
  /// the referenced type with `@AnalyzerPublicApi(...)`. The advantage of
  /// marking the referenced type with `@AnalyzerPublicApi(...)` is that it
  /// causes the members of referenced type to be checked by this lint.
  ///
  /// Parameters:
  /// String types: list of types, separated by `, `
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String types})
  >
  analyzerPublicApiBadType = diag.analyzerPublicApiBadType;

  /// Lint issued if an element in the analyzer public API makes use
  /// of a type that's annotated `@experimental`, but the element
  /// itself is not annotated `@experimental`.
  ///
  /// The reason this is a problem is that it makes it possible for
  /// analyzer clients to implicitly reference analyzer experimental
  /// types. This can happen in many ways; here are some examples:
  ///
  /// - If `C` is a non-experimental public API class that implements
  ///   `B`, and `B` is an experimental public API class with a getter
  ///   called `x`, then a client can access `B.x` via `C`.
  ///
  /// - If `f` has return type `T`, and `T` is an experimental public
  ///   API class with a getter called `x`, then a client can access
  ///   `T.x` via `f().x`.
  ///
  /// - If `f` has type `void Function(T)`, and `T` is an experimental
  ///   public API class with a getter called `x`, then a client can
  ///   access `T.x` via `var g = f; g = (t) { print(t.x); }`.
  ///
  /// Parameters:
  /// String types: list of types, separated by `, `
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String types})
  >
  analyzerPublicApiExperimentalInconsistency =
      diag.analyzerPublicApiExperimentalInconsistency;

  /// Lint issued if a file in the analyzer public API contains an `export`
  /// directive that exports a name that's not part of the analyzer public API.
  ///
  /// This lint can be suppressed either with an `ignore` comment, or by marking
  /// the exported declaration with `@AnalyzerPublicApi(...)`. The advantage of
  /// marking the exported declaration with `@AnalyzerPublicApi(...)` is that it
  /// causes the members of the exported declaration to be checked by this lint.
  ///
  /// Parameters:
  /// String elements: List of elements, separated by `, `
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String elements})
  >
  analyzerPublicApiExportsNonPublicName =
      diag.analyzerPublicApiExportsNonPublicName;

  /// Lint issued if a top level declaration in the analyzer public API has a
  /// name ending in `Impl`.
  ///
  /// Such declarations are not meant to be members of the analyzer public API,
  /// so if they are either declared outside of `package:analyzer/src`, or
  /// marked with `@AnalyzerPublicApi(...)`, that is almost certainly a mistake.
  ///
  /// No parameters.
  static const LinterLintWithoutArguments analyzerPublicApiImplInPublicApi =
      diag.analyzerPublicApiImplInPublicApi;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  annotateOverrides = diag.annotateOverrides;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  annotateRedeclares = diag.annotateRedeclares;

  /// No parameters.
  static const LinterLintWithoutArguments avoidAnnotatingWithDynamic =
      diag.avoidAnnotatingWithDynamic;

  /// No parameters.
  static const LinterLintWithoutArguments
  avoidBoolLiteralsInConditionalExpressions =
      diag.avoidBoolLiteralsInConditionalExpressions;

  /// No parameters.
  static const LinterLintWithoutArguments avoidCatchesWithoutOnClauses =
      diag.avoidCatchesWithoutOnClauses;

  /// No parameters.
  static const LinterLintWithoutArguments avoidCatchingErrorsClass =
      diag.avoidCatchingErrorsClass;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidCatchingErrorsSubclass = diag.avoidCatchingErrorsSubclass;

  /// No parameters.
  static const LinterLintWithoutArguments avoidClassesWithOnlyStaticMembers =
      diag.avoidClassesWithOnlyStaticMembers;

  /// No parameters.
  static const LinterLintWithoutArguments avoidDoubleAndIntChecks =
      diag.avoidDoubleAndIntChecks;

  /// No parameters.
  static const LinterLintWithoutArguments avoidDynamicCalls =
      diag.avoidDynamicCalls;

  /// No parameters.
  static const LinterLintWithoutArguments avoidEmptyElse = diag.avoidEmptyElse;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidEqualsAndHashCodeOnMutableClasses =
      diag.avoidEqualsAndHashCodeOnMutableClasses;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  avoidEscapingInnerQuotes = diag.avoidEscapingInnerQuotes;

  /// No parameters.
  static const LinterLintWithoutArguments avoidFieldInitializersInConstClasses =
      diag.avoidFieldInitializersInConstClasses;

  /// No parameters.
  static const LinterLintWithoutArguments avoidFinalParameters =
      diag.avoidFinalParameters;

  /// No parameters.
  static const LinterLintWithoutArguments avoidFunctionLiteralsInForeachCalls =
      diag.avoidFunctionLiteralsInForeachCalls;

  /// No parameters.
  static const LinterLintWithoutArguments avoidFutureorVoid =
      diag.avoidFutureorVoid;

  /// No parameters.
  static const LinterLintWithoutArguments avoidImplementingValueTypes =
      diag.avoidImplementingValueTypes;

  /// No parameters.
  static const LinterLintWithoutArguments avoidInitToNull =
      diag.avoidInitToNull;

  /// No parameters.
  static const LinterLintWithoutArguments avoidJsRoundedInts =
      diag.avoidJsRoundedInts;

  /// No parameters.
  static const LinterLintWithoutArguments avoidMultipleDeclarationsPerLine =
      diag.avoidMultipleDeclarationsPerLine;

  /// No parameters.
  static const LinterLintWithoutArguments avoidNullChecksInEqualityOperators =
      diag.avoidNullChecksInEqualityOperators;

  /// No parameters.
  static const LinterLintWithoutArguments avoidPositionalBooleanParameters =
      diag.avoidPositionalBooleanParameters;

  /// No parameters.
  static const LinterLintWithoutArguments avoidPrint = diag.avoidPrint;

  /// No parameters.
  static const LinterLintWithoutArguments avoidPrivateTypedefFunctions =
      diag.avoidPrivateTypedefFunctions;

  /// No parameters.
  static const LinterLintWithoutArguments avoidRedundantArgumentValues =
      diag.avoidRedundantArgumentValues;

  /// No parameters.
  static const LinterLintWithoutArguments avoidRelativeLibImports =
      diag.avoidRelativeLibImports;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  avoidRenamingMethodParameters = diag.avoidRenamingMethodParameters;

  /// No parameters.
  static const LinterLintWithoutArguments
  avoidReturningNullForVoidFromFunction =
      diag.avoidReturningNullForVoidFromFunction;

  /// No parameters.
  static const LinterLintWithoutArguments avoidReturningNullForVoidFromMethod =
      diag.avoidReturningNullForVoidFromMethod;

  /// No parameters.
  static const LinterLintWithoutArguments avoidReturningThis =
      diag.avoidReturningThis;

  /// No parameters.
  static const LinterLintWithoutArguments avoidReturnTypesOnSetters =
      diag.avoidReturnTypesOnSetters;

  /// No parameters.
  static const LinterLintWithoutArguments avoidSettersWithoutGetters =
      diag.avoidSettersWithoutGetters;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  avoidShadowingTypeParameters = diag.avoidShadowingTypeParameters;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidSingleCascadeInExpressionStatements =
      diag.avoidSingleCascadeInExpressionStatements;

  /// No parameters.
  static const LinterLintWithoutArguments avoidSlowAsyncIo =
      diag.avoidSlowAsyncIo;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidTypesAsParameterNamesFormalParameter =
      diag.avoidTypesAsParameterNamesFormalParameter;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidTypesAsParameterNamesTypeParameter =
      diag.avoidTypesAsParameterNamesTypeParameter;

  /// No parameters.
  static const LinterLintWithoutArguments avoidTypesOnClosureParameters =
      diag.avoidTypesOnClosureParameters;

  /// No parameters.
  static const LinterLintWithoutArguments avoidTypeToString =
      diag.avoidTypeToString;

  /// No parameters.
  static const LinterLintWithoutArguments avoidUnnecessaryContainers =
      diag.avoidUnnecessaryContainers;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidUnusedConstructorParameters = diag.avoidUnusedConstructorParameters;

  /// No parameters.
  static const LinterLintWithoutArguments avoidVoidAsync = diag.avoidVoidAsync;

  /// No parameters.
  static const LinterLintWithoutArguments avoidWebLibrariesInFlutter =
      diag.avoidWebLibrariesInFlutter;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  awaitOnlyFutures = diag.awaitOnlyFutures;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  camelCaseExtensions = diag.camelCaseExtensions;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  camelCaseTypes = diag.camelCaseTypes;

  /// No parameters.
  static const LinterLintWithoutArguments cancelSubscriptions =
      diag.cancelSubscriptions;

  /// No parameters.
  static const LinterLintWithoutArguments cascadeInvocations =
      diag.cascadeInvocations;

  /// No parameters.
  static const LinterLintWithoutArguments castNullableToNonNullable =
      diag.castNullableToNonNullable;

  /// No parameters.
  static const LinterLintWithoutArguments closeSinks = diag.closeSinks;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  collectionMethodsUnrelatedType = diag.collectionMethodsUnrelatedType;

  /// No parameters.
  static const LinterLintWithoutArguments combinatorsOrdering =
      diag.combinatorsOrdering;

  /// No parameters.
  static const LinterLintWithoutArguments commentReferences =
      diag.commentReferences;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  conditionalUriDoesNotExist = diag.conditionalUriDoesNotExist;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  constantIdentifierNames = diag.constantIdentifierNames;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  controlFlowInFinally = diag.controlFlowInFinally;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  curlyBracesInFlowControlStructures = diag.curlyBracesInFlowControlStructures;

  /// No parameters.
  static const LinterLintWithoutArguments danglingLibraryDocComments =
      diag.danglingLibraryDocComments;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  dependOnReferencedPackages = diag.dependOnReferencedPackages;

  /// No parameters.
  static const LinterLintWithoutArguments deprecatedConsistencyConstructor =
      diag.deprecatedConsistencyConstructor;

  /// No parameters.
  static const LinterLintWithoutArguments deprecatedConsistencyField =
      diag.deprecatedConsistencyField;

  /// No parameters.
  static const LinterLintWithoutArguments deprecatedConsistencyParameter =
      diag.deprecatedConsistencyParameter;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  deprecatedMemberUseFromSamePackageWithMessage =
      diag.deprecatedMemberUseFromSamePackageWithMessage;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  deprecatedMemberUseFromSamePackageWithoutMessage =
      diag.deprecatedMemberUseFromSamePackageWithoutMessage;

  /// No parameters.
  static const LinterLintWithoutArguments diagnosticDescribeAllProperties =
      diag.diagnosticDescribeAllProperties;

  /// No parameters.
  static const LinterLintWithoutArguments directivesOrderingAlphabetical =
      diag.directivesOrderingAlphabetical;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  directivesOrderingDart = diag.directivesOrderingDart;

  /// No parameters.
  static const LinterLintWithoutArguments directivesOrderingExports =
      diag.directivesOrderingExports;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  directivesOrderingPackageBeforeRelative =
      diag.directivesOrderingPackageBeforeRelative;

  /// No parameters.
  static const LinterLintWithoutArguments discardedFutures =
      diag.discardedFutures;

  /// No parameters.
  static const LinterLintWithoutArguments documentIgnores =
      diag.documentIgnores;

  /// No parameters.
  static const LinterLintWithoutArguments doNotUseEnvironment =
      diag.doNotUseEnvironment;

  /// No parameters.
  static const LinterLintWithoutArguments emptyCatches = diag.emptyCatches;

  /// No parameters.
  static const LinterLintWithoutArguments emptyConstructorBodies =
      diag.emptyConstructorBodies;

  /// No parameters.
  static const LinterLintWithoutArguments emptyStatements =
      diag.emptyStatements;

  /// No parameters.
  static const LinterLintWithoutArguments eolAtEndOfFile = diag.eolAtEndOfFile;

  /// No parameters.
  static const LinterLintWithoutArguments eraseDartTypeExtensionTypes =
      diag.eraseDartTypeExtensionTypes;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  exhaustiveCases = diag.exhaustiveCases;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  fileNames = diag.fileNames;

  /// No parameters.
  static const LinterLintWithoutArguments flutterStyleTodos =
      diag.flutterStyleTodos;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  hashAndEquals = diag.hashAndEquals;

  /// No parameters.
  static const LinterLintWithoutArguments implementationImports =
      diag.implementationImports;

  /// No parameters.
  static const LinterLintWithoutArguments implicitCallTearoffs =
      diag.implicitCallTearoffs;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  /// Object p2: undocumented
  /// Object p3: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
    })
  >
  implicitReopen = diag.implicitReopen;

  /// No parameters.
  static const LinterLintWithoutArguments invalidCasePatterns =
      diag.invalidCasePatterns;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesDartAsJs =
      diag.invalidRuntimeCheckWithJsInteropTypesDartAsJs;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesDartIsJs =
      diag.invalidRuntimeCheckWithJsInteropTypesDartIsJs;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesJsAsDart =
      diag.invalidRuntimeCheckWithJsInteropTypesJsAsDart;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs =
      diag.invalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesJsIsDart =
      diag.invalidRuntimeCheckWithJsInteropTypesJsIsDart;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs =
      diag.invalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs =
      diag.invalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs;

  /// No parameters.
  static const LinterLintWithoutArguments joinReturnWithAssignment =
      diag.joinReturnWithAssignment;

  /// No parameters.
  static const LinterLintWithoutArguments leadingNewlinesInMultilineStrings =
      diag.leadingNewlinesInMultilineStrings;

  /// No parameters.
  static const LinterLintWithoutArguments libraryAnnotations =
      diag.libraryAnnotations;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  libraryNames = diag.libraryNames;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  libraryPrefixes = diag.libraryPrefixes;

  /// No parameters.
  static const LinterLintWithoutArguments libraryPrivateTypesInPublicApi =
      diag.libraryPrivateTypesInPublicApi;

  /// No parameters.
  static const LinterLintWithoutArguments linesLongerThan80Chars =
      diag.linesLongerThan80Chars;

  /// No parameters.
  static const LinterLintWithoutArguments literalOnlyBooleanExpressions =
      diag.literalOnlyBooleanExpressions;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  matchingSuperParameters = diag.matchingSuperParameters;

  /// No parameters.
  static const LinterLintWithoutArguments missingCodeBlockLanguageInDocComment =
      diag.missingCodeBlockLanguageInDocComment;

  /// No parameters.
  static const LinterLintWithoutArguments
  missingWhitespaceBetweenAdjacentStrings =
      diag.missingWhitespaceBetweenAdjacentStrings;

  /// No parameters.
  static const LinterLintWithoutArguments noAdjacentStringsInList =
      diag.noAdjacentStringsInList;

  /// No parameters.
  static const LinterLintWithoutArguments noDefaultCases = diag.noDefaultCases;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  noDuplicateCaseValues = diag.noDuplicateCaseValues;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  noLeadingUnderscoresForLibraryPrefixes =
      diag.noLeadingUnderscoresForLibraryPrefixes;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  noLeadingUnderscoresForLocalIdentifiers =
      diag.noLeadingUnderscoresForLocalIdentifiers;

  /// No parameters.
  static const LinterLintWithoutArguments noLiteralBoolComparisons =
      diag.noLiteralBoolComparisons;

  /// No parameters.
  static const LinterLintWithoutArguments noLogicInCreateState =
      diag.noLogicInCreateState;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  nonConstantIdentifierNames = diag.nonConstantIdentifierNames;

  /// No parameters.
  static const LinterLintWithoutArguments noopPrimitiveOperations =
      diag.noopPrimitiveOperations;

  /// No parameters.
  static const LinterLintWithoutArguments noRuntimetypeTostring =
      diag.noRuntimetypeTostring;

  /// No parameters.
  static const LinterLintWithoutArguments noSelfAssignments =
      diag.noSelfAssignments;

  /// No parameters.
  static const LinterLintWithoutArguments noSoloTests = diag.noSoloTests;

  /// No parameters.
  static const LinterLintWithoutArguments noTrailingSpaces =
      diag.noTrailingSpaces;

  /// No parameters.
  static const LinterLintWithoutArguments noWildcardVariableUses =
      diag.noWildcardVariableUses;

  /// No parameters.
  static const LinterLintWithoutArguments nullCheckOnNullableTypeParameter =
      diag.nullCheckOnNullableTypeParameter;

  /// No parameters.
  static const LinterLintWithoutArguments nullClosures = diag.nullClosures;

  /// No parameters.
  static const LinterLintWithoutArguments omitLocalVariableTypes =
      diag.omitLocalVariableTypes;

  /// No parameters.
  static const LinterLintWithoutArguments omitObviousLocalVariableTypes =
      diag.omitObviousLocalVariableTypes;

  /// No parameters.
  static const LinterLintWithoutArguments omitObviousPropertyTypes =
      diag.omitObviousPropertyTypes;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  oneMemberAbstracts = diag.oneMemberAbstracts;

  /// No parameters.
  static const LinterLintWithoutArguments onlyThrowErrors =
      diag.onlyThrowErrors;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  overriddenFields = diag.overriddenFields;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  packageNames = diag.packageNames;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  packagePrefixedLibraryNames = diag.packagePrefixedLibraryNames;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  parameterAssignments = diag.parameterAssignments;

  /// No parameters.
  static const LinterLintWithoutArguments preferAdjacentStringConcatenation =
      diag.preferAdjacentStringConcatenation;

  /// No parameters.
  static const LinterLintWithoutArguments preferAssertsInInitializerLists =
      diag.preferAssertsInInitializerLists;

  /// No parameters.
  static const LinterLintWithoutArguments preferAssertsWithMessage =
      diag.preferAssertsWithMessage;

  /// No parameters.
  static const LinterLintWithoutArguments preferCollectionLiterals =
      diag.preferCollectionLiterals;

  /// No parameters.
  static const LinterLintWithoutArguments preferConditionalAssignment =
      diag.preferConditionalAssignment;

  /// No parameters.
  static const LinterLintWithoutArguments preferConstConstructors =
      diag.preferConstConstructors;

  /// No parameters.
  static const LinterLintWithoutArguments preferConstConstructorsInImmutables =
      diag.preferConstConstructorsInImmutables;

  /// No parameters.
  static const LinterLintWithoutArguments preferConstDeclarations =
      diag.preferConstDeclarations;

  /// No parameters.
  static const LinterLintWithoutArguments
  preferConstLiteralsToCreateImmutables =
      diag.preferConstLiteralsToCreateImmutables;

  /// No parameters.
  static const LinterLintWithoutArguments preferConstructorsOverStaticMethods =
      diag.preferConstructorsOverStaticMethods;

  /// No parameters.
  static const LinterLintWithoutArguments preferContainsAlwaysFalse =
      diag.preferContainsAlwaysFalse;

  /// No parameters.
  static const LinterLintWithoutArguments preferContainsAlwaysTrue =
      diag.preferContainsAlwaysTrue;

  /// No parameters.
  static const LinterLintWithoutArguments preferContainsUseContains =
      diag.preferContainsUseContains;

  /// No parameters.
  static const LinterLintWithoutArguments preferDoubleQuotes =
      diag.preferDoubleQuotes;

  /// No parameters.
  static const LinterLintWithoutArguments preferExpressionFunctionBodies =
      diag.preferExpressionFunctionBodies;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  preferFinalFields = diag.preferFinalFields;

  /// No parameters.
  static const LinterLintWithoutArguments preferFinalInForEachPattern =
      diag.preferFinalInForEachPattern;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  preferFinalInForEachVariable = diag.preferFinalInForEachVariable;

  /// No parameters.
  static const LinterLintWithoutArguments preferFinalLocals =
      diag.preferFinalLocals;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  preferFinalParameters = diag.preferFinalParameters;

  /// No parameters.
  static const LinterLintWithoutArguments preferForeach = diag.preferForeach;

  /// No parameters.
  static const LinterLintWithoutArguments preferForElementsToMapFromiterable =
      diag.preferForElementsToMapFromiterable;

  /// No parameters.
  static const LinterLintWithoutArguments
  preferFunctionDeclarationsOverVariables =
      diag.preferFunctionDeclarationsOverVariables;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  preferGenericFunctionTypeAliases = diag.preferGenericFunctionTypeAliases;

  /// No parameters.
  static const LinterLintWithoutArguments
  preferIfElementsToConditionalExpressions =
      diag.preferIfElementsToConditionalExpressions;

  /// No parameters.
  static const LinterLintWithoutArguments preferIfNullOperators =
      diag.preferIfNullOperators;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  preferInitializingFormals = diag.preferInitializingFormals;

  /// No parameters.
  static const LinterLintWithoutArguments preferInlinedAddsMultiple =
      diag.preferInlinedAddsMultiple;

  /// No parameters.
  static const LinterLintWithoutArguments preferInlinedAddsSingle =
      diag.preferInlinedAddsSingle;

  /// No parameters.
  static const LinterLintWithoutArguments preferInterpolationToComposeStrings =
      diag.preferInterpolationToComposeStrings;

  /// No parameters.
  static const LinterLintWithoutArguments preferIntLiterals =
      diag.preferIntLiterals;

  /// No parameters.
  static const LinterLintWithoutArguments preferIsEmptyAlwaysFalse =
      diag.preferIsEmptyAlwaysFalse;

  /// No parameters.
  static const LinterLintWithoutArguments preferIsEmptyAlwaysTrue =
      diag.preferIsEmptyAlwaysTrue;

  /// No parameters.
  static const LinterLintWithoutArguments preferIsEmptyUseIsEmpty =
      diag.preferIsEmptyUseIsEmpty;

  /// No parameters.
  static const LinterLintWithoutArguments preferIsEmptyUseIsNotEmpty =
      diag.preferIsEmptyUseIsNotEmpty;

  /// No parameters.
  static const LinterLintWithoutArguments preferIsNotEmpty =
      diag.preferIsNotEmpty;

  /// No parameters.
  static const LinterLintWithoutArguments preferIsNotOperator =
      diag.preferIsNotOperator;

  /// No parameters.
  static const LinterLintWithoutArguments preferIterableWheretype =
      diag.preferIterableWheretype;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  preferMixin = diag.preferMixin;

  /// No parameters.
  static const LinterLintWithoutArguments preferNullAwareMethodCalls =
      diag.preferNullAwareMethodCalls;

  /// No parameters.
  static const LinterLintWithoutArguments preferNullAwareOperators =
      diag.preferNullAwareOperators;

  /// No parameters.
  static const LinterLintWithoutArguments preferRelativeImports =
      diag.preferRelativeImports;

  /// No parameters.
  static const LinterLintWithoutArguments preferSingleQuotes =
      diag.preferSingleQuotes;

  /// No parameters.
  static const LinterLintWithoutArguments preferSpreadCollections =
      diag.preferSpreadCollections;

  /// No parameters.
  static const LinterLintWithoutArguments
  preferTypingUninitializedVariablesForField =
      diag.preferTypingUninitializedVariablesForField;

  /// No parameters.
  static const LinterLintWithoutArguments
  preferTypingUninitializedVariablesForLocalVariable =
      diag.preferTypingUninitializedVariablesForLocalVariable;

  /// No parameters.
  static const LinterLintWithoutArguments preferVoidToNull =
      diag.preferVoidToNull;

  /// No parameters.
  static const LinterLintWithoutArguments provideDeprecationMessage =
      diag.provideDeprecationMessage;

  /// No parameters.
  static const LinterLintWithoutArguments publicMemberApiDocs =
      diag.publicMemberApiDocs;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  recursiveGetters = diag.recursiveGetters;

  /// No parameters.
  static const LinterLintWithoutArguments removeDeprecationsInBreakingVersions =
      diag.removeDeprecationsInBreakingVersions;

  /// No parameters.
  static const LinterLintWithoutArguments requireTrailingCommas =
      diag.requireTrailingCommas;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  securePubspecUrls = diag.securePubspecUrls;

  /// No parameters.
  static const LinterLintWithoutArguments sizedBoxForWhitespace =
      diag.sizedBoxForWhitespace;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  sizedBoxShrinkExpand = diag.sizedBoxShrinkExpand;

  /// No parameters.
  static const LinterLintWithoutArguments slashForDocComments =
      diag.slashForDocComments;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  sortChildPropertiesLast = diag.sortChildPropertiesLast;

  /// No parameters.
  static const LinterLintWithoutArguments sortConstructorsFirst =
      diag.sortConstructorsFirst;

  /// No parameters.
  static const LinterLintWithoutArguments sortPubDependencies =
      diag.sortPubDependencies;

  /// No parameters.
  static const LinterLintWithoutArguments sortUnnamedConstructorsFirst =
      diag.sortUnnamedConstructorsFirst;

  /// No parameters.
  static const LinterLintWithoutArguments specifyNonobviousLocalVariableTypes =
      diag.specifyNonobviousLocalVariableTypes;

  /// No parameters.
  static const LinterLintWithoutArguments specifyNonobviousPropertyTypes =
      diag.specifyNonobviousPropertyTypes;

  /// No parameters.
  static const LinterLintWithoutArguments strictTopLevelInferenceAddType =
      diag.strictTopLevelInferenceAddType;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  strictTopLevelInferenceReplaceKeyword =
      diag.strictTopLevelInferenceReplaceKeyword;

  /// No parameters.
  static const LinterLintWithoutArguments strictTopLevelInferenceSplitToTypes =
      diag.strictTopLevelInferenceSplitToTypes;

  /// No parameters.
  static const LinterLintWithoutArguments switchOnType = diag.switchOnType;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  testTypesInEquals = diag.testTypesInEquals;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  throwInFinally = diag.throwInFinally;

  /// No parameters.
  static const LinterLintWithoutArguments tightenTypeOfInitializingFormals =
      diag.tightenTypeOfInitializingFormals;

  /// No parameters.
  static const LinterLintWithoutArguments typeAnnotatePublicApis =
      diag.typeAnnotatePublicApis;

  /// No parameters.
  static const LinterLintWithoutArguments typeInitFormals =
      diag.typeInitFormals;

  /// No parameters.
  static const LinterLintWithoutArguments typeLiteralInConstantPattern =
      diag.typeLiteralInConstantPattern;

  /// No parameters.
  static const LinterLintWithoutArguments unawaitedFutures =
      diag.unawaitedFutures;

  /// No parameters.
  static const LinterLintWithoutArguments unintendedHtmlInDocComment =
      diag.unintendedHtmlInDocComment;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryAsync =
      diag.unnecessaryAsync;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryAwaitInReturn =
      diag.unnecessaryAwaitInReturn;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryBraceInStringInterps =
      diag.unnecessaryBraceInStringInterps;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryBreaks =
      diag.unnecessaryBreaks;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryConst =
      diag.unnecessaryConst;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryConstructorName =
      diag.unnecessaryConstructorName;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryFinalWithoutType =
      diag.unnecessaryFinalWithoutType;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryFinalWithType =
      diag.unnecessaryFinalWithType;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryGettersSetters =
      diag.unnecessaryGettersSetters;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unnecessaryIgnore = diag.unnecessaryIgnore;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unnecessaryIgnoreFile = diag.unnecessaryIgnoreFile;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unnecessaryIgnoreName = diag.unnecessaryIgnoreName;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unnecessaryIgnoreNameFile = diag.unnecessaryIgnoreNameFile;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryLambdas =
      diag.unnecessaryLambdas;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryLate =
      diag.unnecessaryLate;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryLibraryDirective =
      diag.unnecessaryLibraryDirective;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryLibraryName =
      diag.unnecessaryLibraryName;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryNew = diag.unnecessaryNew;

  /// No parameters.
  static const LinterLintWithoutArguments
  unnecessaryNullableForFinalVariableDeclarations =
      diag.unnecessaryNullableForFinalVariableDeclarations;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryNullAwareAssignments =
      diag.unnecessaryNullAwareAssignments;

  /// No parameters.
  static const LinterLintWithoutArguments
  unnecessaryNullAwareOperatorOnExtensionOnNullable =
      diag.unnecessaryNullAwareOperatorOnExtensionOnNullable;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryNullChecks =
      diag.unnecessaryNullChecks;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryNullInIfNullOperators =
      diag.unnecessaryNullInIfNullOperators;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryOverrides =
      diag.unnecessaryOverrides;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryParenthesis =
      diag.unnecessaryParenthesis;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryRawStrings =
      diag.unnecessaryRawStrings;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryStatements =
      diag.unnecessaryStatements;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryStringEscapes =
      diag.unnecessaryStringEscapes;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryStringInterpolations =
      diag.unnecessaryStringInterpolations;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryThis =
      diag.unnecessaryThis;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryToListInSpreads =
      diag.unnecessaryToListInSpreads;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryUnawaited =
      diag.unnecessaryUnawaited;

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryUnderscores =
      diag.unnecessaryUnderscores;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unreachableFromMain = diag.unreachableFromMain;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  unrelatedTypeEqualityChecksInExpression =
      diag.unrelatedTypeEqualityChecksInExpression;

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  unrelatedTypeEqualityChecksInPattern =
      diag.unrelatedTypeEqualityChecksInPattern;

  /// No parameters.
  static const LinterLintWithoutArguments unsafeVariance = diag.unsafeVariance;

  /// No parameters.
  static const LinterLintWithoutArguments useBuildContextSynchronouslyAsyncUse =
      diag.useBuildContextSynchronouslyAsyncUse;

  /// No parameters.
  static const LinterLintWithoutArguments
  useBuildContextSynchronouslyWrongMounted =
      diag.useBuildContextSynchronouslyWrongMounted;

  /// No parameters.
  static const LinterLintWithoutArguments useColoredBox = diag.useColoredBox;

  /// No parameters.
  static const LinterLintWithoutArguments useDecoratedBox =
      diag.useDecoratedBox;

  /// No parameters.
  static const LinterLintWithoutArguments useEnums = diag.useEnums;

  /// No parameters.
  static const LinterLintWithoutArguments useFullHexValuesForFlutterColors =
      diag.useFullHexValuesForFlutterColors;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  useFunctionTypeSyntaxForParameters = diag.useFunctionTypeSyntaxForParameters;

  /// No parameters.
  static const LinterLintWithoutArguments useIfNullToConvertNullsToBools =
      diag.useIfNullToConvertNullsToBools;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  useIsEvenRatherThanModulo = diag.useIsEvenRatherThanModulo;

  /// No parameters.
  static const LinterLintWithoutArguments useKeyInWidgetConstructors =
      diag.useKeyInWidgetConstructors;

  /// No parameters.
  static const LinterLintWithoutArguments useLateForPrivateFieldsAndVariables =
      diag.useLateForPrivateFieldsAndVariables;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  useNamedConstants = diag.useNamedConstants;

  /// No parameters.
  static const LinterLintWithoutArguments useNullAwareElements =
      diag.useNullAwareElements;

  /// No parameters.
  static const LinterLintWithoutArguments useRawStrings = diag.useRawStrings;

  /// No parameters.
  static const LinterLintWithoutArguments useRethrowWhenPossible =
      diag.useRethrowWhenPossible;

  /// No parameters.
  static const LinterLintWithoutArguments useSettersToChangeProperties =
      diag.useSettersToChangeProperties;

  /// No parameters.
  static const LinterLintWithoutArguments useStringBuffers =
      diag.useStringBuffers;

  /// No parameters.
  static const LinterLintWithoutArguments useStringInPartOfDirectives =
      diag.useStringInPartOfDirectives;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  useSuperParametersMultiple = diag.useSuperParametersMultiple;

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  useSuperParametersSingle = diag.useSuperParametersSingle;

  /// No parameters.
  static const LinterLintWithoutArguments useTestThrowsMatchers =
      diag.useTestThrowsMatchers;

  /// No parameters.
  static const LinterLintWithoutArguments useToAndAsIfApplicable =
      diag.useToAndAsIfApplicable;

  /// No parameters.
  static const LinterLintWithoutArguments useTruncatingDivision =
      diag.useTruncatingDivision;

  /// No parameters.
  static const LinterLintWithoutArguments validRegexps = diag.validRegexps;

  /// No parameters.
  static const LinterLintWithoutArguments visitRegisteredNodes =
      diag.visitRegisteredNodes;

  /// No parameters.
  static const LinterLintWithoutArguments voidChecks = diag.voidChecks;

  const LinterLintCode({
    required super.name,
    required super.problemMessage,
    required super.uniqueName,
    super.expectedTypes,
    super.correctionMessage,
    super.hasPublishedDocs,
  });

  @override
  String get url {
    if (hasPublishedDocs) {
      return 'https://dart.dev/diagnostics/$name';
    }
    return 'https://dart.dev/lints/$name';
  }
}

final class LinterLintTemplate<T extends Function> extends LinterLintCode
    implements DiagnosticWithArguments<T> {
  @override
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const LinterLintTemplate({
    required super.name,
    required super.problemMessage,
    required this.withArguments,
    required super.expectedTypes,
    required super.uniqueName,
    super.correctionMessage,
    super.hasPublishedDocs = false,
  });
}

final class LinterLintWithoutArguments extends LinterLintCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const LinterLintWithoutArguments({
    required super.name,
    required super.problemMessage,
    required super.expectedTypes,
    required super.uniqueName,
    super.correctionMessage,
    super.hasPublishedDocs = false,
  });
}
