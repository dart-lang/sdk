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
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  alwaysDeclareReturnTypesOfFunctions = LinterLintTemplate(
    name: LintNames.always_declare_return_types,
    problemMessage: "The function '{0}' should have a return type but doesn't.",
    correctionMessage: "Try adding a return type to the function.",
    hasPublishedDocs: true,
    uniqueName: 'always_declare_return_types_of_functions',
    withArguments: _withArgumentsAlwaysDeclareReturnTypesOfFunctions,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  alwaysDeclareReturnTypesOfMethods = LinterLintTemplate(
    name: LintNames.always_declare_return_types,
    problemMessage: "The method '{0}' should have a return type but doesn't.",
    correctionMessage: "Try adding a return type to the method.",
    hasPublishedDocs: true,
    uniqueName: 'always_declare_return_types_of_methods',
    withArguments: _withArgumentsAlwaysDeclareReturnTypesOfMethods,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments alwaysPutControlBodyOnNewLine =
      LinterLintWithoutArguments(
        name: LintNames.always_put_control_body_on_new_line,
        problemMessage: "Statement should be on a separate line.",
        correctionMessage: "Try moving the statement to a new line.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  alwaysPutRequiredNamedParametersFirst = LinterLintWithoutArguments(
    name: LintNames.always_put_required_named_parameters_first,
    problemMessage:
        "Required named parameters should be before optional named parameters.",
    correctionMessage:
        "Try moving the required named parameter to be before any optional "
        "named parameters.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments alwaysSpecifyTypesAddType =
      LinterLintWithoutArguments(
        name: LintNames.always_specify_types,
        problemMessage: "Missing type annotation.",
        correctionMessage: "Try adding a type annotation.",
        uniqueName: 'always_specify_types_add_type',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  alwaysSpecifyTypesReplaceKeyword = LinterLintTemplate(
    name: LintNames.always_specify_types,
    problemMessage: "Missing type annotation.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
    uniqueName: 'always_specify_types_replace_keyword',
    withArguments: _withArgumentsAlwaysSpecifyTypesReplaceKeyword,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  alwaysSpecifyTypesSpecifyType = LinterLintTemplate(
    name: LintNames.always_specify_types,
    problemMessage: "Missing type annotation.",
    correctionMessage: "Try specifying the type '{0}'.",
    uniqueName: 'always_specify_types_specify_type',
    withArguments: _withArgumentsAlwaysSpecifyTypesSpecifyType,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments alwaysSpecifyTypesSplitToTypes =
      LinterLintWithoutArguments(
        name: LintNames.always_specify_types,
        problemMessage: "Missing type annotation.",
        correctionMessage:
            "Try splitting the declaration and specify the different type "
            "annotations.",
        uniqueName: 'always_specify_types_split_to_types',
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments alwaysUsePackageImports =
      LinterLintWithoutArguments(
        name: LintNames.always_use_package_imports,
        problemMessage:
            "Use 'package:' imports for files in the 'lib' directory.",
        correctionMessage: "Try converting the URI to a 'package:' URI.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments analyzerElementModelTrackingBad =
      LinterLintWithoutArguments(
        name: LintNames.analyzer_element_model_tracking_bad,
        problemMessage: "Bad tracking annotation for this member.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  analyzerElementModelTrackingMoreThanOne = LinterLintWithoutArguments(
    name: LintNames.analyzer_element_model_tracking_more_than_one,
    problemMessage: "There can be only one tracking annotation.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments analyzerElementModelTrackingZero =
      LinterLintWithoutArguments(
        name: LintNames.analyzer_element_model_tracking_zero,
        problemMessage: "No required tracking annotation.",
        expectedTypes: [],
      );

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
  static const LinterLintWithoutArguments
  analyzerPublicApiBadPartDirective = LinterLintWithoutArguments(
    name: LintNames.analyzer_public_api_bad_part_directive,
    problemMessage:
        "Part directives in the analyzer public API should point to files in the "
        "analyzer public API.",
    expectedTypes: [],
  );

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
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required String types})
  >
  analyzerPublicApiBadType = LinterLintTemplate(
    name: LintNames.analyzer_public_api_bad_type,
    problemMessage:
        "Element makes use of type(s) which is not part of the analyzer public "
        "API: {0}.",
    withArguments: _withArgumentsAnalyzerPublicApiBadType,
    expectedTypes: [ExpectedType.string],
  );

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
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required String types})
  >
  analyzerPublicApiExperimentalInconsistency = LinterLintTemplate(
    name: LintNames.analyzer_public_api_experimental_inconsistency,
    problemMessage:
        "Element makes use of experimental type(s), but is not itself marked with "
        "`@experimental`: {0}.",
    withArguments: _withArgumentsAnalyzerPublicApiExperimentalInconsistency,
    expectedTypes: [ExpectedType.string],
  );

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
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required String elements})
  >
  analyzerPublicApiExportsNonPublicName = LinterLintTemplate(
    name: LintNames.analyzer_public_api_exports_non_public_name,
    problemMessage:
        "Export directive exports element(s) that are not part of the analyzer "
        "public API: {0}.",
    withArguments: _withArgumentsAnalyzerPublicApiExportsNonPublicName,
    expectedTypes: [ExpectedType.string],
  );

  /// Lint issued if a top level declaration in the analyzer public API has a
  /// name ending in `Impl`.
  ///
  /// Such declarations are not meant to be members of the analyzer public API,
  /// so if they are either declared outside of `package:analyzer/src`, or
  /// marked with `@AnalyzerPublicApi(...)`, that is almost certainly a mistake.
  ///
  /// No parameters.
  static const LinterLintWithoutArguments
  analyzerPublicApiImplInPublicApi = LinterLintWithoutArguments(
    name: LintNames.analyzer_public_api_impl_in_public_api,
    problemMessage:
        "Declarations in the analyzer public API should not end in \"Impl\".",
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  annotateOverrides = LinterLintTemplate(
    name: LintNames.annotate_overrides,
    problemMessage:
        "The member '{0}' overrides an inherited member but isn't annotated with "
        "'@override'.",
    correctionMessage: "Try adding the '@override' annotation.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsAnnotateOverrides,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  annotateRedeclares = LinterLintTemplate(
    name: LintNames.annotate_redeclares,
    problemMessage:
        "The member '{0}' is redeclaring but isn't annotated with '@redeclare'.",
    correctionMessage: "Try adding the '@redeclare' annotation.",
    withArguments: _withArgumentsAnnotateRedeclares,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments avoidAnnotatingWithDynamic =
      LinterLintWithoutArguments(
        name: LintNames.avoid_annotating_with_dynamic,
        problemMessage: "Unnecessary 'dynamic' type annotation.",
        correctionMessage: "Try removing the type 'dynamic'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  avoidBoolLiteralsInConditionalExpressions = LinterLintWithoutArguments(
    name: LintNames.avoid_bool_literals_in_conditional_expressions,
    problemMessage:
        "Conditional expressions with a 'bool' literal can be simplified.",
    correctionMessage:
        "Try rewriting the expression to use either '&&' or '||'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  avoidCatchesWithoutOnClauses = LinterLintWithoutArguments(
    name: LintNames.avoid_catches_without_on_clauses,
    problemMessage:
        "Catch clause should use 'on' to specify the type of exception being "
        "caught.",
    correctionMessage: "Try adding an 'on' clause before the 'catch'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments avoidCatchingErrorsClass =
      LinterLintWithoutArguments(
        name: LintNames.avoid_catching_errors,
        problemMessage: "The type 'Error' should not be caught.",
        correctionMessage:
            "Try removing the catch or catching an 'Exception' instead.",
        uniqueName: 'avoid_catching_errors_class',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidCatchingErrorsSubclass = LinterLintTemplate(
    name: LintNames.avoid_catching_errors,
    problemMessage:
        "The type '{0}' should not be caught because it is a subclass of 'Error'.",
    correctionMessage:
        "Try removing the catch or catching an 'Exception' instead.",
    uniqueName: 'avoid_catching_errors_subclass',
    withArguments: _withArgumentsAvoidCatchingErrorsSubclass,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  avoidClassesWithOnlyStaticMembers = LinterLintWithoutArguments(
    name: LintNames.avoid_classes_with_only_static_members,
    problemMessage: "Classes should define instance members.",
    correctionMessage:
        "Try adding instance behavior or moving the members out of the class.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments avoidDoubleAndIntChecks =
      LinterLintWithoutArguments(
        name: LintNames.avoid_double_and_int_checks,
        problemMessage: "Explicit check for double or int.",
        correctionMessage: "Try removing the check.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidDynamicCalls =
      LinterLintWithoutArguments(
        name: LintNames.avoid_dynamic_calls,
        problemMessage:
            "Method invocation or property access on a 'dynamic' target.",
        correctionMessage: "Try giving the target a type.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidEmptyElse =
      LinterLintWithoutArguments(
        name: LintNames.avoid_empty_else,
        problemMessage: "Empty statements are not allowed in an 'else' clause.",
        correctionMessage:
            "Try removing the empty statement or removing the else clause.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidEqualsAndHashCodeOnMutableClasses = LinterLintTemplate(
    name: LintNames.avoid_equals_and_hash_code_on_mutable_classes,
    problemMessage:
        "The method '{0}' should not be overridden in classes not annotated with "
        "'@immutable'.",
    correctionMessage:
        "Try removing the override or annotating the class with '@immutable'.",
    withArguments: _withArgumentsAvoidEqualsAndHashCodeOnMutableClasses,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  avoidEscapingInnerQuotes = LinterLintTemplate(
    name: LintNames.avoid_escaping_inner_quotes,
    problemMessage: "Unnecessary escape of '{0}'.",
    correctionMessage: "Try changing the outer quotes to '{1}'.",
    withArguments: _withArgumentsAvoidEscapingInnerQuotes,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  avoidFieldInitializersInConstClasses = LinterLintWithoutArguments(
    name: LintNames.avoid_field_initializers_in_const_classes,
    problemMessage: "Fields in 'const' classes should not have initializers.",
    correctionMessage:
        "Try converting the field to a getter or initialize the field in the "
        "constructors.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments avoidFinalParameters =
      LinterLintWithoutArguments(
        name: LintNames.avoid_final_parameters,
        problemMessage: "Parameters should not be marked as 'final'.",
        correctionMessage: "Try removing the keyword 'final'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidFunctionLiteralsInForeachCalls =
      LinterLintWithoutArguments(
        name: LintNames.avoid_function_literals_in_foreach_calls,
        problemMessage: "Function literals shouldn't be passed to 'forEach'.",
        correctionMessage: "Try using a 'for' loop.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidFutureorVoid =
      LinterLintWithoutArguments(
        name: LintNames.avoid_futureor_void,
        problemMessage: "Don't use the type 'FutureOr<void>'.",
        correctionMessage: "Try using 'Future<void>?' or 'void'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidImplementingValueTypes =
      LinterLintWithoutArguments(
        name: LintNames.avoid_implementing_value_types,
        problemMessage: "Classes that override '==' should not be implemented.",
        correctionMessage:
            "Try removing the class from the 'implements' clause.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidInitToNull =
      LinterLintWithoutArguments(
        name: LintNames.avoid_init_to_null,
        problemMessage: "Redundant initialization to 'null'.",
        correctionMessage: "Try removing the initializer.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  avoidJsRoundedInts = LinterLintWithoutArguments(
    name: LintNames.avoid_js_rounded_ints,
    problemMessage:
        "Integer literal can't be represented exactly when compiled to JavaScript.",
    correctionMessage: "Try using a 'BigInt' to represent the value.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments avoidMultipleDeclarationsPerLine =
      LinterLintWithoutArguments(
        name: LintNames.avoid_multiple_declarations_per_line,
        problemMessage: "Multiple variables declared on a single line.",
        correctionMessage:
            "Try splitting the variable declarations into multiple lines.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidNullChecksInEqualityOperators =
      LinterLintWithoutArguments(
        name: LintNames.avoid_null_checks_in_equality_operators,
        problemMessage:
            "Unnecessary null comparison in implementation of '=='.",
        correctionMessage: "Try removing the comparison.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidPositionalBooleanParameters =
      LinterLintWithoutArguments(
        name: LintNames.avoid_positional_boolean_parameters,
        problemMessage: "'bool' parameters should be named parameters.",
        correctionMessage: "Try converting the parameter to a named parameter.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidPrint =
      LinterLintWithoutArguments(
        name: LintNames.avoid_print,
        problemMessage: "Don't invoke 'print' in production code.",
        correctionMessage: "Try using a logging framework.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidPrivateTypedefFunctions =
      LinterLintWithoutArguments(
        name: LintNames.avoid_private_typedef_functions,
        problemMessage:
            "The typedef is unnecessary because it is only used in one place.",
        correctionMessage: "Try inlining the type or using it in other places.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  avoidRedundantArgumentValues = LinterLintWithoutArguments(
    name: LintNames.avoid_redundant_argument_values,
    problemMessage:
        "The value of the argument is redundant because it matches the default "
        "value.",
    correctionMessage: "Try removing the argument.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  avoidRelativeLibImports = LinterLintWithoutArguments(
    name: LintNames.avoid_relative_lib_imports,
    problemMessage: "Can't use a relative path to import a library in 'lib'.",
    correctionMessage:
        "Try fixing the relative path or changing the import to a 'package:' "
        "import.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  avoidRenamingMethodParameters = LinterLintTemplate(
    name: LintNames.avoid_renaming_method_parameters,
    problemMessage:
        "The parameter name '{0}' doesn't match the name '{1}' in the overridden "
        "method.",
    correctionMessage: "Try changing the name to '{1}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsAvoidRenamingMethodParameters,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  avoidReturningNullForVoidFromFunction = LinterLintWithoutArguments(
    name: LintNames.avoid_returning_null_for_void,
    problemMessage:
        "Don't return 'null' from a function with a return type of 'void'.",
    correctionMessage: "Try removing the 'null'.",
    hasPublishedDocs: true,
    uniqueName: 'avoid_returning_null_for_void_from_function',
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments avoidReturningNullForVoidFromMethod =
      LinterLintWithoutArguments(
        name: LintNames.avoid_returning_null_for_void,
        problemMessage:
            "Don't return 'null' from a method with a return type of 'void'.",
        correctionMessage: "Try removing the 'null'.",
        hasPublishedDocs: true,
        uniqueName: 'avoid_returning_null_for_void_from_method',
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidReturningThis =
      LinterLintWithoutArguments(
        name: LintNames.avoid_returning_this,
        problemMessage: "Don't return 'this' from a method.",
        correctionMessage:
            "Try changing the return type to 'void' and removing the return.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidReturnTypesOnSetters =
      LinterLintWithoutArguments(
        name: LintNames.avoid_return_types_on_setters,
        problemMessage: "Unnecessary return type on a setter.",
        correctionMessage: "Try removing the return type.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidSettersWithoutGetters =
      LinterLintWithoutArguments(
        name: LintNames.avoid_setters_without_getters,
        problemMessage: "Setter has no corresponding getter.",
        correctionMessage:
            "Try adding a corresponding getter or removing the setter.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  avoidShadowingTypeParameters = LinterLintTemplate(
    name: LintNames.avoid_shadowing_type_parameters,
    problemMessage:
        "The type parameter '{0}' shadows a type parameter from the enclosing {1}.",
    correctionMessage: "Try renaming one of the type parameters.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsAvoidShadowingTypeParameters,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidSingleCascadeInExpressionStatements = LinterLintTemplate(
    name: LintNames.avoid_single_cascade_in_expression_statements,
    problemMessage: "Unnecessary cascade expression.",
    correctionMessage: "Try using the operator '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsAvoidSingleCascadeInExpressionStatements,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments avoidSlowAsyncIo =
      LinterLintWithoutArguments(
        name: LintNames.avoid_slow_async_io,
        problemMessage: "Use of an async 'dart:io' method.",
        correctionMessage: "Try using the synchronous version of the method.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidTypesAsParameterNamesFormalParameter = LinterLintTemplate(
    name: LintNames.avoid_types_as_parameter_names,
    problemMessage: "The parameter name '{0}' matches a visible type name.",
    correctionMessage:
        "Try adding a name for the parameter or changing the parameter name to "
        "not match an existing type.",
    hasPublishedDocs: true,
    uniqueName: 'avoid_types_as_parameter_names_formal_parameter',
    withArguments: _withArgumentsAvoidTypesAsParameterNamesFormalParameter,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidTypesAsParameterNamesTypeParameter = LinterLintTemplate(
    name: LintNames.avoid_types_as_parameter_names,
    problemMessage:
        "The type parameter name '{0}' matches a visible type name.",
    correctionMessage:
        "Try changing the type parameter name to not match an existing type.",
    hasPublishedDocs: true,
    uniqueName: 'avoid_types_as_parameter_names_type_parameter',
    withArguments: _withArgumentsAvoidTypesAsParameterNamesTypeParameter,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments avoidTypesOnClosureParameters =
      LinterLintWithoutArguments(
        name: LintNames.avoid_types_on_closure_parameters,
        problemMessage:
            "Unnecessary type annotation on a function expression parameter.",
        correctionMessage: "Try removing the type annotation.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments avoidTypeToString =
      LinterLintWithoutArguments(
        name: LintNames.avoid_type_to_string,
        problemMessage:
            "Using 'toString' on a 'Type' is not safe in production code.",
        correctionMessage:
            "Try a normal type check or compare the 'runtimeType' directly.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  avoidUnnecessaryContainers = LinterLintWithoutArguments(
    name: LintNames.avoid_unnecessary_containers,
    problemMessage: "Unnecessary instance of 'Container'.",
    correctionMessage:
        "Try removing the 'Container' (but not its children) from the widget "
        "tree.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidUnusedConstructorParameters = LinterLintTemplate(
    name: LintNames.avoid_unused_constructor_parameters,
    problemMessage: "The parameter '{0}' is not used in the constructor.",
    correctionMessage: "Try using the parameter or removing it.",
    withArguments: _withArgumentsAvoidUnusedConstructorParameters,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  avoidVoidAsync = LinterLintWithoutArguments(
    name: LintNames.avoid_void_async,
    problemMessage:
        "An 'async' function should have a 'Future' return type when it doesn't "
        "return a value.",
    correctionMessage: "Try changing the return type.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments avoidWebLibrariesInFlutter =
      LinterLintWithoutArguments(
        name: LintNames.avoid_web_libraries_in_flutter,
        problemMessage:
            "Don't use web-only libraries outside Flutter web plugins.",
        correctionMessage: "Try finding a different library for your needs.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  awaitOnlyFutures = LinterLintTemplate(
    name: LintNames.await_only_futures,
    problemMessage:
        "Uses 'await' on an instance of '{0}', which is not a subtype of 'Future'.",
    correctionMessage: "Try removing the 'await' or changing the expression.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsAwaitOnlyFutures,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  camelCaseExtensions = LinterLintTemplate(
    name: LintNames.camel_case_extensions,
    problemMessage:
        "The extension name '{0}' isn't an UpperCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the UpperCamelCase style.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsCamelCaseExtensions,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  camelCaseTypes = LinterLintTemplate(
    name: LintNames.camel_case_types,
    problemMessage: "The type name '{0}' isn't an UpperCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the UpperCamelCase style.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsCamelCaseTypes,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments cancelSubscriptions =
      LinterLintWithoutArguments(
        name: LintNames.cancel_subscriptions,
        problemMessage: "Uncancelled instance of 'StreamSubscription'.",
        correctionMessage:
            "Try invoking 'cancel' in the function in which the "
            "'StreamSubscription' was created.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments cascadeInvocations =
      LinterLintWithoutArguments(
        name: LintNames.cascade_invocations,
        problemMessage: "Unnecessary duplication of receiver.",
        correctionMessage: "Try using a cascade to avoid the duplication.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  castNullableToNonNullable = LinterLintWithoutArguments(
    name: LintNames.cast_nullable_to_non_nullable,
    problemMessage: "Don't cast a nullable value to a non-nullable type.",
    correctionMessage:
        "Try adding a not-null assertion ('!') to make the type non-nullable.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  closeSinks = LinterLintWithoutArguments(
    name: LintNames.close_sinks,
    problemMessage: "Unclosed instance of 'Sink'.",
    correctionMessage:
        "Try invoking 'close' in the function in which the 'Sink' was created.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  collectionMethodsUnrelatedType = LinterLintTemplate(
    name: LintNames.collection_methods_unrelated_type,
    problemMessage: "The argument type '{0}' isn't related to '{1}'.",
    correctionMessage: "Try changing the argument or element type to match.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsCollectionMethodsUnrelatedType,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments combinatorsOrdering =
      LinterLintWithoutArguments(
        name: LintNames.combinators_ordering,
        problemMessage: "Sort combinator names alphabetically.",
        correctionMessage: "Try sorting the combinator names alphabetically.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments commentReferences =
      LinterLintWithoutArguments(
        name: LintNames.comment_references,
        problemMessage: "The referenced name isn't visible in scope.",
        correctionMessage: "Try adding an import for the referenced name.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  conditionalUriDoesNotExist = LinterLintTemplate(
    name: LintNames.conditional_uri_does_not_exist,
    problemMessage: "The target of the conditional URI '{0}' doesn't exist.",
    correctionMessage:
        "Try creating the file referenced by the URI, or try using a URI for a "
        "file that does exist.",
    withArguments: _withArgumentsConditionalUriDoesNotExist,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  constantIdentifierNames = LinterLintTemplate(
    name: LintNames.constant_identifier_names,
    problemMessage:
        "The constant name '{0}' isn't a lowerCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the lowerCamelCase style.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsConstantIdentifierNames,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  controlFlowInFinally = LinterLintTemplate(
    name: LintNames.control_flow_in_finally,
    problemMessage: "Use of '{0}' in a 'finally' clause.",
    correctionMessage: "Try restructuring the code.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsControlFlowInFinally,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  curlyBracesInFlowControlStructures = LinterLintTemplate(
    name: LintNames.curly_braces_in_flow_control_structures,
    problemMessage: "Statements in {0} should be enclosed in a block.",
    correctionMessage: "Try wrapping the statement in a block.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsCurlyBracesInFlowControlStructures,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments danglingLibraryDocComments =
      LinterLintWithoutArguments(
        name: LintNames.dangling_library_doc_comments,
        problemMessage: "Dangling library doc comment.",
        correctionMessage:
            "Add a 'library' directive after the library comment.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  dependOnReferencedPackages = LinterLintTemplate(
    name: LintNames.depend_on_referenced_packages,
    problemMessage:
        "The imported package '{0}' isn't a dependency of the importing package.",
    correctionMessage:
        "Try adding a dependency for '{0}' in the 'pubspec.yaml' file.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDependOnReferencedPackages,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments deprecatedConsistencyConstructor =
      LinterLintWithoutArguments(
        name: LintNames.deprecated_consistency,
        problemMessage:
            "Constructors in a deprecated class should be deprecated.",
        correctionMessage: "Try marking the constructor as deprecated.",
        uniqueName: 'deprecated_consistency_constructor',
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments deprecatedConsistencyField =
      LinterLintWithoutArguments(
        name: LintNames.deprecated_consistency,
        problemMessage:
            "Fields that are initialized by a deprecated parameter should be "
            "deprecated.",
        correctionMessage: "Try marking the field as deprecated.",
        uniqueName: 'deprecated_consistency_field',
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  deprecatedConsistencyParameter = LinterLintWithoutArguments(
    name: LintNames.deprecated_consistency,
    problemMessage:
        "Parameters that initialize a deprecated field should be deprecated.",
    correctionMessage: "Try marking the parameter as deprecated.",
    uniqueName: 'deprecated_consistency_parameter',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  deprecatedMemberUseFromSamePackageWithMessage = LinterLintTemplate(
    name: LintNames.deprecated_member_use_from_same_package,
    problemMessage: "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement, "
        "if a replacement is specified.",
    uniqueName: 'deprecated_member_use_from_same_package_with_message',
    withArguments: _withArgumentsDeprecatedMemberUseFromSamePackageWithMessage,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  deprecatedMemberUseFromSamePackageWithoutMessage = LinterLintTemplate(
    name: LintNames.deprecated_member_use_from_same_package,
    problemMessage: "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement, "
        "if a replacement is specified.",
    uniqueName: 'deprecated_member_use_from_same_package_without_message',
    withArguments:
        _withArgumentsDeprecatedMemberUseFromSamePackageWithoutMessage,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  diagnosticDescribeAllProperties = LinterLintWithoutArguments(
    name: LintNames.diagnostic_describe_all_properties,
    problemMessage:
        "The public property isn't described by either 'debugFillProperties' or "
        "'debugDescribeChildren'.",
    correctionMessage: "Try describing the property.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments directivesOrderingAlphabetical =
      LinterLintWithoutArguments(
        name: LintNames.directives_ordering,
        problemMessage: "Sort directive sections alphabetically.",
        correctionMessage: "Try sorting the directives.",
        uniqueName: 'directives_ordering_alphabetical',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  directivesOrderingDart = LinterLintTemplate(
    name: LintNames.directives_ordering,
    problemMessage: "Place 'dart:' {0} before other {0}.",
    correctionMessage: "Try sorting the directives.",
    uniqueName: 'directives_ordering_dart',
    withArguments: _withArgumentsDirectivesOrderingDart,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments directivesOrderingExports =
      LinterLintWithoutArguments(
        name: LintNames.directives_ordering,
        problemMessage:
            "Specify exports in a separate section after all imports.",
        correctionMessage: "Try sorting the directives.",
        uniqueName: 'directives_ordering_exports',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  directivesOrderingPackageBeforeRelative = LinterLintTemplate(
    name: LintNames.directives_ordering,
    problemMessage: "Place 'package:' {0} before relative {0}.",
    correctionMessage: "Try sorting the directives.",
    uniqueName: 'directives_ordering_package_before_relative',
    withArguments: _withArgumentsDirectivesOrderingPackageBeforeRelative,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  discardedFutures = LinterLintWithoutArguments(
    name: LintNames.discarded_futures,
    problemMessage: "'Future'-returning calls in a non-'async' function.",
    correctionMessage:
        "Try converting the enclosing function to be 'async' and then 'await' "
        "the future, or wrap the expression in 'unawaited'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments documentIgnores =
      LinterLintWithoutArguments(
        name: LintNames.document_ignores,
        problemMessage:
            "Missing documentation explaining why the diagnostic is ignored.",
        correctionMessage:
            "Try adding a comment immediately above the ignore comment.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments doNotUseEnvironment =
      LinterLintWithoutArguments(
        name: LintNames.do_not_use_environment,
        problemMessage: "Invalid use of an environment declaration.",
        correctionMessage: "Try removing the environment declaration usage.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  emptyCatches = LinterLintWithoutArguments(
    name: LintNames.empty_catches,
    problemMessage: "Empty catch block.",
    correctionMessage:
        "Try adding statements to the block, adding a comment to the block, or "
        "removing the 'catch' clause.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  emptyConstructorBodies = LinterLintWithoutArguments(
    name: LintNames.empty_constructor_bodies,
    problemMessage:
        "Empty constructor bodies should be written using a ';' rather than '{}'.",
    correctionMessage: "Try replacing the constructor body with ';'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments emptyStatements =
      LinterLintWithoutArguments(
        name: LintNames.empty_statements,
        problemMessage: "Unnecessary empty statement.",
        correctionMessage:
            "Try removing the empty statement or restructuring the code.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments eolAtEndOfFile =
      LinterLintWithoutArguments(
        name: LintNames.eol_at_end_of_file,
        problemMessage: "Missing a newline at the end of the file.",
        correctionMessage: "Try adding a newline at the end of the file.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  eraseDartTypeExtensionTypes = LinterLintWithoutArguments(
    name: LintNames.erase_dart_type_extension_types,
    problemMessage: "Unsafe use of 'DartType' in an 'is' check.",
    correctionMessage:
        "Ensure DartType extension types are erased by using a helper method.",
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  exhaustiveCases = LinterLintTemplate(
    name: LintNames.exhaustive_cases,
    problemMessage: "Missing case clauses for some constants in '{0}'.",
    correctionMessage: "Try adding case clauses for the missing constants.",
    withArguments: _withArgumentsExhaustiveCases,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  fileNames = LinterLintTemplate(
    name: LintNames.file_names,
    problemMessage:
        "The file name '{0}' isn't a lower_case_with_underscores identifier.",
    correctionMessage:
        "Try changing the name to follow the lower_case_with_underscores "
        "style.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsFileNames,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments flutterStyleTodos =
      LinterLintWithoutArguments(
        name: LintNames.flutter_style_todos,
        problemMessage: "To-do comment doesn't follow the Flutter style.",
        correctionMessage:
            "Try following the Flutter style for to-do comments.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  hashAndEquals = LinterLintTemplate(
    name: LintNames.hash_and_equals,
    problemMessage: "Missing a corresponding override of '{0}'.",
    correctionMessage: "Try overriding '{0}' or removing '{1}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsHashAndEquals,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  implementationImports = LinterLintWithoutArguments(
    name: LintNames.implementation_imports,
    problemMessage:
        "Import of a library in the 'lib/src' directory of another package.",
    correctionMessage:
        "Try importing a public library that exports this library, or removing "
        "the import.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments implicitCallTearoffs =
      LinterLintWithoutArguments(
        name: LintNames.implicit_call_tearoffs,
        problemMessage: "Implicit tear-off of the 'call' method.",
        correctionMessage: "Try explicitly tearing off the 'call' method.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  /// Object p2: undocumented
  /// Object p3: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
    })
  >
  implicitReopen = LinterLintTemplate(
    name: LintNames.implicit_reopen,
    problemMessage:
        "The {0} '{1}' reopens '{2}' because it is not marked '{3}'.",
    correctionMessage:
        "Try marking '{1}' '{3}' or annotating it with '@reopen'.",
    withArguments: _withArgumentsImplicitReopen,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// No parameters.
  static const LinterLintWithoutArguments invalidCasePatterns =
      LinterLintWithoutArguments(
        name: LintNames.invalid_case_patterns,
        problemMessage:
            "This expression is not valid in a 'case' clause in Dart 3.0.",
        correctionMessage: "Try refactoring the expression to be valid in 3.0.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesDartAsJs = LinterLintTemplate(
    name: LintNames.invalid_runtime_check_with_js_interop_types,
    problemMessage:
        "Cast from '{0}' to '{1}' casts a Dart value to a JS interop type, which "
        "might not be platform-consistent.",
    correctionMessage:
        "Try using conversion methods from 'dart:js_interop' to convert "
        "between Dart types and JS interop types.",
    hasPublishedDocs: true,
    uniqueName: 'invalid_runtime_check_with_js_interop_types_dart_as_js',
    withArguments: _withArgumentsInvalidRuntimeCheckWithJsInteropTypesDartAsJs,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesDartIsJs = LinterLintTemplate(
    name: LintNames.invalid_runtime_check_with_js_interop_types,
    problemMessage:
        "Runtime check between '{0}' and '{1}' checks whether a Dart value is a JS "
        "interop type, which might not be platform-consistent.",
    uniqueName: 'invalid_runtime_check_with_js_interop_types_dart_is_js',
    withArguments: _withArgumentsInvalidRuntimeCheckWithJsInteropTypesDartIsJs,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesJsAsDart = LinterLintTemplate(
    name: LintNames.invalid_runtime_check_with_js_interop_types,
    problemMessage:
        "Cast from '{0}' to '{1}' casts a JS interop value to a Dart type, which "
        "might not be platform-consistent.",
    correctionMessage:
        "Try using conversion methods from 'dart:js_interop' to convert "
        "between JS interop types and Dart types.",
    uniqueName: 'invalid_runtime_check_with_js_interop_types_js_as_dart',
    withArguments: _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsAsDart,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs = LinterLintTemplate(
    name: LintNames.invalid_runtime_check_with_js_interop_types,
    problemMessage:
        "Cast from '{0}' to '{1}' casts a JS interop value to an incompatible JS "
        "interop type, which might not be platform-consistent.",
    uniqueName:
        'invalid_runtime_check_with_js_interop_types_js_as_incompatible_js',
    withArguments:
        _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesJsIsDart = LinterLintTemplate(
    name: LintNames.invalid_runtime_check_with_js_interop_types,
    problemMessage:
        "Runtime check between '{0}' and '{1}' checks whether a JS interop value "
        "is a Dart type, which might not be platform-consistent.",
    uniqueName: 'invalid_runtime_check_with_js_interop_types_js_is_dart',
    withArguments: _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsDart,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs = LinterLintTemplate(
    name: LintNames.invalid_runtime_check_with_js_interop_types,
    problemMessage:
        "Runtime check between '{0}' and '{1}' involves a non-trivial runtime "
        "check between two JS interop types that might not be "
        "platform-consistent.",
    correctionMessage:
        "Try using a JS interop member like 'isA' from 'dart:js_interop' to "
        "check the underlying type of JS interop values.",
    uniqueName:
        'invalid_runtime_check_with_js_interop_types_js_is_inconsistent_js',
    withArguments:
        _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs = LinterLintTemplate(
    name: LintNames.invalid_runtime_check_with_js_interop_types,
    problemMessage:
        "Runtime check between '{0}' and '{1}' involves a runtime check between a "
        "JS interop value and an unrelated JS interop type that will always be "
        "true and won't check the underlying type.",
    correctionMessage:
        "Try using a JS interop member like 'isA' from 'dart:js_interop' to "
        "check the underlying type of JS interop values, or make the JS "
        "interop type a supertype using 'implements'.",
    uniqueName:
        'invalid_runtime_check_with_js_interop_types_js_is_unrelated_js',
    withArguments:
        _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments joinReturnWithAssignment =
      LinterLintWithoutArguments(
        name: LintNames.join_return_with_assignment,
        problemMessage: "Assignment could be inlined in 'return' statement.",
        correctionMessage:
            "Try inlining the assigned value in the 'return' statement.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  leadingNewlinesInMultilineStrings = LinterLintWithoutArguments(
    name: LintNames.leading_newlines_in_multiline_strings,
    problemMessage: "Missing a newline at the beginning of a multiline string.",
    correctionMessage: "Try adding a newline at the beginning of the string.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments libraryAnnotations =
      LinterLintWithoutArguments(
        name: LintNames.library_annotations,
        problemMessage:
            "This annotation should be attached to a library directive.",
        correctionMessage:
            "Try attaching the annotation to a library directive.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  libraryNames = LinterLintTemplate(
    name: LintNames.library_names,
    problemMessage:
        "The library name '{0}' isn't a lower_case_with_underscores identifier.",
    correctionMessage:
        "Try changing the name to follow the lower_case_with_underscores "
        "style.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsLibraryNames,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  libraryPrefixes = LinterLintTemplate(
    name: LintNames.library_prefixes,
    problemMessage:
        "The prefix '{0}' isn't a lower_case_with_underscores identifier.",
    correctionMessage:
        "Try changing the prefix to follow the lower_case_with_underscores "
        "style.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsLibraryPrefixes,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  libraryPrivateTypesInPublicApi = LinterLintWithoutArguments(
    name: LintNames.library_private_types_in_public_api,
    problemMessage: "Invalid use of a private type in a public API.",
    correctionMessage:
        "Try making the private type public, or making the API that uses the "
        "private type also be private.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments linesLongerThan80Chars =
      LinterLintWithoutArguments(
        name: LintNames.lines_longer_than_80_chars,
        problemMessage: "The line length exceeds the 80-character limit.",
        correctionMessage: "Try breaking the line across multiple lines.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments literalOnlyBooleanExpressions =
      LinterLintWithoutArguments(
        name: LintNames.literal_only_boolean_expressions,
        problemMessage: "The Boolean expression has a constant value.",
        correctionMessage: "Try changing the expression.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  matchingSuperParameters = LinterLintTemplate(
    name: LintNames.matching_super_parameters,
    problemMessage:
        "The super parameter named '{0}'' does not share the same name as the "
        "corresponding parameter in the super constructor, '{1}'.",
    correctionMessage:
        "Try using the name of the corresponding parameter in the super "
        "constructor.",
    withArguments: _withArgumentsMatchingSuperParameters,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments missingCodeBlockLanguageInDocComment =
      LinterLintWithoutArguments(
        name: LintNames.missing_code_block_language_in_doc_comment,
        problemMessage: "The code block is missing a specified language.",
        correctionMessage: "Try adding a language to the code block.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  missingWhitespaceBetweenAdjacentStrings = LinterLintWithoutArguments(
    name: LintNames.missing_whitespace_between_adjacent_strings,
    problemMessage: "Missing whitespace between adjacent strings.",
    correctionMessage: "Try adding whitespace between the strings.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments noAdjacentStringsInList =
      LinterLintWithoutArguments(
        name: LintNames.no_adjacent_strings_in_list,
        problemMessage: "Don't use adjacent strings in a list literal.",
        correctionMessage: "Try adding a comma between the strings.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments noDefaultCases =
      LinterLintWithoutArguments(
        name: LintNames.no_default_cases,
        problemMessage: "Invalid use of 'default' member in a switch.",
        correctionMessage:
            "Try enumerating all the possible values of the switch expression.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  noDuplicateCaseValues = LinterLintTemplate(
    name: LintNames.no_duplicate_case_values,
    problemMessage:
        "The value of the case clause ('{0}') is equal to the value of an earlier "
        "case clause ('{1}').",
    correctionMessage: "Try removing or changing the value.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNoDuplicateCaseValues,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  noLeadingUnderscoresForLibraryPrefixes = LinterLintTemplate(
    name: LintNames.no_leading_underscores_for_library_prefixes,
    problemMessage: "The library prefix '{0}' starts with an underscore.",
    correctionMessage:
        "Try renaming the prefix to not start with an underscore.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNoLeadingUnderscoresForLibraryPrefixes,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  noLeadingUnderscoresForLocalIdentifiers = LinterLintTemplate(
    name: LintNames.no_leading_underscores_for_local_identifiers,
    problemMessage: "The local variable '{0}' starts with an underscore.",
    correctionMessage:
        "Try renaming the variable to not start with an underscore.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNoLeadingUnderscoresForLocalIdentifiers,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  noLiteralBoolComparisons = LinterLintWithoutArguments(
    name: LintNames.no_literal_bool_comparisons,
    problemMessage: "Unnecessary comparison to a boolean literal.",
    correctionMessage:
        "Remove the comparison and use the negate `!` operator if necessary.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments noLogicInCreateState =
      LinterLintWithoutArguments(
        name: LintNames.no_logic_in_create_state,
        problemMessage: "Don't put any logic in 'createState'.",
        correctionMessage: "Try moving the logic out of 'createState'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  nonConstantIdentifierNames = LinterLintTemplate(
    name: LintNames.non_constant_identifier_names,
    problemMessage:
        "The variable name '{0}' isn't a lowerCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the lowerCamelCase style.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNonConstantIdentifierNames,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments noopPrimitiveOperations =
      LinterLintWithoutArguments(
        name: LintNames.noop_primitive_operations,
        problemMessage: "The expression has no effect and can be removed.",
        correctionMessage: "Try removing the expression.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments noRuntimetypeTostring =
      LinterLintWithoutArguments(
        name: LintNames.no_runtimeType_toString,
        problemMessage:
            "Using 'toString' on a 'Type' is not safe in production code.",
        correctionMessage:
            "Try removing the usage of 'toString' or restructuring the code.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments noSelfAssignments =
      LinterLintWithoutArguments(
        name: LintNames.no_self_assignments,
        problemMessage: "The variable or property is being assigned to itself.",
        correctionMessage:
            "Try removing the assignment that has no direct effect.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments noSoloTests =
      LinterLintWithoutArguments(
        name: LintNames.no_solo_tests,
        problemMessage: "Don't commit soloed tests.",
        correctionMessage:
            "Try removing the 'soloTest' annotation or 'solo_' prefix.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments noTrailingSpaces =
      LinterLintWithoutArguments(
        name: LintNames.no_trailing_spaces,
        problemMessage:
            "Don't create string literals with trailing spaces in tests.",
        correctionMessage: "Try removing the trailing spaces.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments noWildcardVariableUses =
      LinterLintWithoutArguments(
        name: LintNames.no_wildcard_variable_uses,
        problemMessage: "The referenced identifier is a wildcard.",
        correctionMessage: "Use an identifier name that is not a wildcard.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  nullCheckOnNullableTypeParameter = LinterLintWithoutArguments(
    name: LintNames.null_check_on_nullable_type_parameter,
    problemMessage:
        "The null check operator shouldn't be used on a variable whose type is a "
        "potentially nullable type parameter.",
    correctionMessage: "Try explicitly testing for 'null'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments nullClosures =
      LinterLintWithoutArguments(
        name: LintNames.null_closures,
        problemMessage: "Closure can't be 'null' because it might be invoked.",
        correctionMessage: "Try providing a non-null closure.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments omitLocalVariableTypes =
      LinterLintWithoutArguments(
        name: LintNames.omit_local_variable_types,
        problemMessage: "Unnecessary type annotation on a local variable.",
        correctionMessage: "Try removing the type annotation.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  omitObviousLocalVariableTypes = LinterLintWithoutArguments(
    name: LintNames.omit_obvious_local_variable_types,
    problemMessage:
        "Omit the type annotation on a local variable when the type is obvious.",
    correctionMessage: "Try removing the type annotation.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments omitObviousPropertyTypes =
      LinterLintWithoutArguments(
        name: LintNames.omit_obvious_property_types,
        problemMessage:
            "The type annotation isn't needed because it is obvious.",
        correctionMessage: "Try removing the type annotation.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  oneMemberAbstracts = LinterLintTemplate(
    name: LintNames.one_member_abstracts,
    problemMessage: "Unnecessary use of an abstract class.",
    correctionMessage:
        "Try making '{0}' a top-level function and removing the class.",
    withArguments: _withArgumentsOneMemberAbstracts,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  onlyThrowErrors = LinterLintWithoutArguments(
    name: LintNames.only_throw_errors,
    problemMessage:
        "Don't throw instances of classes that don't extend either 'Exception' or "
        "'Error'.",
    correctionMessage: "Try throwing a different class of object.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  overriddenFields = LinterLintTemplate(
    name: LintNames.overridden_fields,
    problemMessage: "Field overrides a field inherited from '{0}'.",
    correctionMessage:
        "Try removing the field, overriding the getter and setter if "
        "necessary.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsOverriddenFields,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  packageNames = LinterLintTemplate(
    name: LintNames.package_names,
    problemMessage:
        "The package name '{0}' isn't a lower_case_with_underscores identifier.",
    correctionMessage:
        "Try changing the name to follow the lower_case_with_underscores "
        "style.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPackageNames,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  packagePrefixedLibraryNames = LinterLintTemplate(
    name: LintNames.package_prefixed_library_names,
    problemMessage:
        "The library name is not a dot-separated path prefixed by the package "
        "name.",
    correctionMessage: "Try changing the name to '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPackagePrefixedLibraryNames,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  parameterAssignments = LinterLintTemplate(
    name: LintNames.parameter_assignments,
    problemMessage: "Invalid assignment to the parameter '{0}'.",
    correctionMessage: "Try using a local variable in place of the parameter.",
    withArguments: _withArgumentsParameterAssignments,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments preferAdjacentStringConcatenation =
      LinterLintWithoutArguments(
        name: LintNames.prefer_adjacent_string_concatenation,
        problemMessage:
            "String literals shouldn't be concatenated by the '+' operator.",
        correctionMessage: "Try removing the operator to use adjacent strings.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferAssertsInInitializerLists =
      LinterLintWithoutArguments(
        name: LintNames.prefer_asserts_in_initializer_lists,
        problemMessage: "Assert should be in the initializer list.",
        correctionMessage: "Try moving the assert to the initializer list.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferAssertsWithMessage =
      LinterLintWithoutArguments(
        name: LintNames.prefer_asserts_with_message,
        problemMessage: "Missing a message in an assert.",
        correctionMessage: "Try adding a message to the assert.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferCollectionLiterals =
      LinterLintWithoutArguments(
        name: LintNames.prefer_collection_literals,
        problemMessage: "Unnecessary constructor invocation.",
        correctionMessage: "Try using a collection literal.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferConditionalAssignment =
      LinterLintWithoutArguments(
        name: LintNames.prefer_conditional_assignment,
        problemMessage:
            "The 'if' statement could be replaced by a null-aware assignment.",
        correctionMessage:
            "Try using the '??=' operator to conditionally assign a value.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferConstConstructors =
      LinterLintWithoutArguments(
        name: LintNames.prefer_const_constructors,
        problemMessage:
            "Use 'const' with the constructor to improve performance.",
        correctionMessage:
            "Try adding the 'const' keyword to the constructor invocation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferConstConstructorsInImmutables = LinterLintWithoutArguments(
    name: LintNames.prefer_const_constructors_in_immutables,
    problemMessage:
        "Constructors in '@immutable' classes should be declared as 'const'.",
    correctionMessage: "Try adding 'const' to the constructor declaration.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments preferConstDeclarations =
      LinterLintWithoutArguments(
        name: LintNames.prefer_const_declarations,
        problemMessage:
            "Use 'const' for final variables initialized to a constant value.",
        correctionMessage: "Try replacing 'final' with 'const'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferConstLiteralsToCreateImmutables = LinterLintWithoutArguments(
    name: LintNames.prefer_const_literals_to_create_immutables,
    problemMessage:
        "Use 'const' literals as arguments to constructors of '@immutable' "
        "classes.",
    correctionMessage: "Try adding 'const' before the literal.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments preferConstructorsOverStaticMethods =
      LinterLintWithoutArguments(
        name: LintNames.prefer_constructors_over_static_methods,
        problemMessage: "Static method should be a constructor.",
        correctionMessage: "Try converting the method into a constructor.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferContainsAlwaysFalse = LinterLintWithoutArguments(
    name: LintNames.prefer_contains,
    problemMessage:
        "Always 'false' because 'indexOf' is always greater than or equal to -1.",
    uniqueName: 'prefer_contains_always_false',
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferContainsAlwaysTrue = LinterLintWithoutArguments(
    name: LintNames.prefer_contains,
    problemMessage:
        "Always 'true' because 'indexOf' is always greater than or equal to -1.",
    uniqueName: 'prefer_contains_always_true',
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments preferContainsUseContains =
      LinterLintWithoutArguments(
        name: LintNames.prefer_contains,
        problemMessage: "Unnecessary use of 'indexOf' to test for containment.",
        correctionMessage: "Try using 'contains'.",
        hasPublishedDocs: true,
        uniqueName: 'prefer_contains_use_contains',
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferDoubleQuotes =
      LinterLintWithoutArguments(
        name: LintNames.prefer_double_quotes,
        problemMessage: "Unnecessary use of single quotes.",
        correctionMessage:
            "Try using double quotes unless the string contains double quotes.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferExpressionFunctionBodies =
      LinterLintWithoutArguments(
        name: LintNames.prefer_expression_function_bodies,
        problemMessage: "Unnecessary use of a block function body.",
        correctionMessage: "Try using an expression function body.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  preferFinalFields = LinterLintTemplate(
    name: LintNames.prefer_final_fields,
    problemMessage: "The private field {0} could be 'final'.",
    correctionMessage: "Try making the field 'final'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPreferFinalFields,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments preferFinalInForEachPattern =
      LinterLintWithoutArguments(
        name: LintNames.prefer_final_in_for_each,
        problemMessage: "The pattern should be final.",
        correctionMessage: "Try making the pattern final.",
        hasPublishedDocs: true,
        uniqueName: 'prefer_final_in_for_each_pattern',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  preferFinalInForEachVariable = LinterLintTemplate(
    name: LintNames.prefer_final_in_for_each,
    problemMessage: "The variable '{0}' should be final.",
    correctionMessage: "Try making the variable final.",
    uniqueName: 'prefer_final_in_for_each_variable',
    withArguments: _withArgumentsPreferFinalInForEachVariable,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments preferFinalLocals =
      LinterLintWithoutArguments(
        name: LintNames.prefer_final_locals,
        problemMessage: "Local variables should be final.",
        correctionMessage: "Try making the variable final.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  preferFinalParameters = LinterLintTemplate(
    name: LintNames.prefer_final_parameters,
    problemMessage: "The parameter '{0}' should be final.",
    correctionMessage: "Try making the parameter final.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPreferFinalParameters,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferForeach = LinterLintWithoutArguments(
    name: LintNames.prefer_foreach,
    problemMessage:
        "Use 'forEach' and a tear-off rather than a 'for' loop to apply a function "
        "to every element.",
    correctionMessage:
        "Try using 'forEach' and a tear-off rather than a 'for' loop.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments preferForElementsToMapFromiterable =
      LinterLintWithoutArguments(
        name: LintNames.prefer_for_elements_to_map_fromIterable,
        problemMessage: "Use 'for' elements when building maps from iterables.",
        correctionMessage:
            "Try using a collection literal with a 'for' element.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferFunctionDeclarationsOverVariables = LinterLintWithoutArguments(
    name: LintNames.prefer_function_declarations_over_variables,
    problemMessage:
        "Use a function declaration rather than a variable assignment to bind a "
        "function to a name.",
    correctionMessage:
        "Try rewriting the closure assignment as a function declaration.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  preferGenericFunctionTypeAliases = LinterLintTemplate(
    name: LintNames.prefer_generic_function_type_aliases,
    problemMessage: "Use the generic function type syntax in 'typedef's.",
    correctionMessage: "Try using the generic function type syntax ('{0}').",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPreferGenericFunctionTypeAliases,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferIfElementsToConditionalExpressions = LinterLintWithoutArguments(
    name: LintNames.prefer_if_elements_to_conditional_expressions,
    problemMessage: "Use an 'if' element to conditionally add elements.",
    correctionMessage:
        "Try using an 'if' element rather than a conditional expression.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments preferIfNullOperators =
      LinterLintWithoutArguments(
        name: LintNames.prefer_if_null_operators,
        problemMessage:
            "Use the '??' operator rather than '?:' when testing for 'null'.",
        correctionMessage: "Try rewriting the code to use '??'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  preferInitializingFormals = LinterLintTemplate(
    name: LintNames.prefer_initializing_formals,
    problemMessage:
        "Use an initializing formal to assign a parameter to a field.",
    correctionMessage:
        "Try using an initialing formal ('this.{0}') to initialize the field.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPreferInitializingFormals,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments preferInlinedAddsMultiple =
      LinterLintWithoutArguments(
        name: LintNames.prefer_inlined_adds,
        problemMessage: "The addition of multiple list items could be inlined.",
        correctionMessage: "Try adding the items to the list literal directly.",
        hasPublishedDocs: true,
        uniqueName: 'prefer_inlined_adds_multiple',
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferInlinedAddsSingle =
      LinterLintWithoutArguments(
        name: LintNames.prefer_inlined_adds,
        problemMessage: "The addition of a list item could be inlined.",
        correctionMessage: "Try adding the item to the list literal directly.",
        hasPublishedDocs: true,
        uniqueName: 'prefer_inlined_adds_single',
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferInterpolationToComposeStrings =
      LinterLintWithoutArguments(
        name: LintNames.prefer_interpolation_to_compose_strings,
        problemMessage: "Use interpolation to compose strings and values.",
        correctionMessage:
            "Try using string interpolation to build the composite string.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferIntLiterals =
      LinterLintWithoutArguments(
        name: LintNames.prefer_int_literals,
        problemMessage: "Unnecessary use of a 'double' literal.",
        correctionMessage: "Try using an 'int' literal.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferIsEmptyAlwaysFalse = LinterLintWithoutArguments(
    name: LintNames.prefer_is_empty,
    problemMessage:
        "The comparison is always 'false' because the length is always greater "
        "than or equal to 0.",
    uniqueName: 'prefer_is_empty_always_false',
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferIsEmptyAlwaysTrue = LinterLintWithoutArguments(
    name: LintNames.prefer_is_empty,
    problemMessage:
        "The comparison is always 'true' because the length is always greater than "
        "or equal to 0.",
    uniqueName: 'prefer_is_empty_always_true',
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferIsEmptyUseIsEmpty = LinterLintWithoutArguments(
    name: LintNames.prefer_is_empty,
    problemMessage:
        "Use 'isEmpty' instead of 'length' to test whether the collection is "
        "empty.",
    correctionMessage: "Try rewriting the expression to use 'isEmpty'.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_is_empty_use_is_empty',
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferIsEmptyUseIsNotEmpty = LinterLintWithoutArguments(
    name: LintNames.prefer_is_empty,
    problemMessage:
        "Use 'isNotEmpty' instead of 'length' to test whether the collection is "
        "empty.",
    correctionMessage: "Try rewriting the expression to use 'isNotEmpty'.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_is_empty_use_is_not_empty',
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments preferIsNotEmpty =
      LinterLintWithoutArguments(
        name: LintNames.prefer_is_not_empty,
        problemMessage:
            "Use 'isNotEmpty' rather than negating the result of 'isEmpty'.",
        correctionMessage: "Try rewriting the expression to use 'isNotEmpty'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferIsNotOperator =
      LinterLintWithoutArguments(
        name: LintNames.prefer_is_not_operator,
        problemMessage:
            "Use the 'is!' operator rather than negating the value of the 'is' "
            "operator.",
        correctionMessage:
            "Try rewriting the condition to use the 'is!' operator.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferIterableWheretype =
      LinterLintWithoutArguments(
        name: LintNames.prefer_iterable_whereType,
        problemMessage: "Use 'whereType' to select elements of a given type.",
        correctionMessage: "Try rewriting the expression to use 'whereType'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  preferMixin = LinterLintTemplate(
    name: LintNames.prefer_mixin,
    problemMessage: "Only mixins should be mixed in.",
    correctionMessage: "Try converting '{0}' to a mixin.",
    withArguments: _withArgumentsPreferMixin,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferNullAwareMethodCalls = LinterLintWithoutArguments(
    name: LintNames.prefer_null_aware_method_calls,
    problemMessage:
        "Use a null-aware invocation of the 'call' method rather than explicitly "
        "testing for 'null'.",
    correctionMessage: "Try using '?.call()' to invoke the function.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments preferNullAwareOperators =
      LinterLintWithoutArguments(
        name: LintNames.prefer_null_aware_operators,
        problemMessage:
            "Use the null-aware operator '?.' rather than an explicit 'null' "
            "comparison.",
        correctionMessage: "Try using '?.'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferRelativeImports =
      LinterLintWithoutArguments(
        name: LintNames.prefer_relative_imports,
        problemMessage:
            "Use relative imports for files in the 'lib' directory.",
        correctionMessage: "Try converting the URI to a relative URI.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferSingleQuotes =
      LinterLintWithoutArguments(
        name: LintNames.prefer_single_quotes,
        problemMessage: "Unnecessary use of double quotes.",
        correctionMessage:
            "Try using single quotes unless the string contains single quotes.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferSpreadCollections =
      LinterLintWithoutArguments(
        name: LintNames.prefer_spread_collections,
        problemMessage: "The addition of multiple elements could be inlined.",
        correctionMessage:
            "Try using the spread operator ('...') to inline the addition.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferTypingUninitializedVariablesForField = LinterLintWithoutArguments(
    name: LintNames.prefer_typing_uninitialized_variables,
    problemMessage:
        "An uninitialized field should have an explicit type annotation.",
    correctionMessage: "Try adding a type annotation.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_typing_uninitialized_variables_for_field',
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  preferTypingUninitializedVariablesForLocalVariable =
      LinterLintWithoutArguments(
        name: LintNames.prefer_typing_uninitialized_variables,
        problemMessage:
            "An uninitialized variable should have an explicit type annotation.",
        correctionMessage: "Try adding a type annotation.",
        hasPublishedDocs: true,
        uniqueName: 'prefer_typing_uninitialized_variables_for_local_variable',
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments preferVoidToNull =
      LinterLintWithoutArguments(
        name: LintNames.prefer_void_to_null,
        problemMessage: "Unnecessary use of the type 'Null'.",
        correctionMessage: "Try using 'void' instead.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments provideDeprecationMessage =
      LinterLintWithoutArguments(
        name: LintNames.provide_deprecation_message,
        problemMessage: "Missing a deprecation message.",
        correctionMessage:
            "Try using the constructor to provide a message "
            "('@Deprecated(\"message\")').",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments publicMemberApiDocs =
      LinterLintWithoutArguments(
        name: LintNames.public_member_api_docs,
        problemMessage: "Missing documentation for a public member.",
        correctionMessage: "Try adding documentation for the member.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  recursiveGetters = LinterLintTemplate(
    name: LintNames.recursive_getters,
    problemMessage: "The getter '{0}' recursively returns itself.",
    correctionMessage: "Try changing the value being returned.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsRecursiveGetters,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments removeDeprecationsInBreakingVersions =
      LinterLintWithoutArguments(
        name: LintNames.remove_deprecations_in_breaking_versions,
        problemMessage: "Remove deprecated elements in breaking versions.",
        correctionMessage: "Try removing the deprecated element.",
        expectedTypes: [],
      );

  /// A lint code that removed lints can specify as their `lintCode`.
  ///
  /// Avoid other usages as it should be made unnecessary and removed.
  static const LintCode removedLint = LinterLintCode.internal(
    name: 'removed_lint',
    problemMessage: 'Removed lint.',
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments requireTrailingCommas =
      LinterLintWithoutArguments(
        name: LintNames.require_trailing_commas,
        problemMessage: "Missing a required trailing comma.",
        correctionMessage: "Try adding a trailing comma.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  securePubspecUrls = LinterLintTemplate(
    name: LintNames.secure_pubspec_urls,
    problemMessage:
        "The '{0}' protocol shouldn't be used because it isn't secure.",
    correctionMessage: "Try using a secure protocol, such as 'https'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsSecurePubspecUrls,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments sizedBoxForWhitespace =
      LinterLintWithoutArguments(
        name: LintNames.sized_box_for_whitespace,
        problemMessage: "Use a 'SizedBox' to add whitespace to a layout.",
        correctionMessage: "Try using a 'SizedBox' rather than a 'Container'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  sizedBoxShrinkExpand = LinterLintTemplate(
    name: LintNames.sized_box_shrink_expand,
    problemMessage:
        "Use 'SizedBox.{0}' to avoid needing to specify the 'height' and 'width'.",
    correctionMessage:
        "Try using 'SizedBox.{0}' and removing the 'height' and 'width' "
        "arguments.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsSizedBoxShrinkExpand,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments slashForDocComments =
      LinterLintWithoutArguments(
        name: LintNames.slash_for_doc_comments,
        problemMessage: "Use the end-of-line form ('///') for doc comments.",
        correctionMessage: "Try rewriting the comment to use '///'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  sortChildPropertiesLast = LinterLintTemplate(
    name: LintNames.sort_child_properties_last,
    problemMessage:
        "The '{0}' argument should be last in widget constructor invocations.",
    correctionMessage:
        "Try moving the argument to the end of the argument list.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsSortChildPropertiesLast,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  sortConstructorsFirst = LinterLintWithoutArguments(
    name: LintNames.sort_constructors_first,
    problemMessage:
        "Constructor declarations should be before non-constructor declarations.",
    correctionMessage:
        "Try moving the constructor declaration before all other members.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments sortPubDependencies =
      LinterLintWithoutArguments(
        name: LintNames.sort_pub_dependencies,
        problemMessage: "Dependencies not sorted alphabetically.",
        correctionMessage:
            "Try sorting the dependencies alphabetically (A to Z).",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments sortUnnamedConstructorsFirst =
      LinterLintWithoutArguments(
        name: LintNames.sort_unnamed_constructors_first,
        problemMessage: "Invalid location for the unnamed constructor.",
        correctionMessage:
            "Try moving the unnamed constructor before all other constructors.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  specifyNonobviousLocalVariableTypes = LinterLintWithoutArguments(
    name: LintNames.specify_nonobvious_local_variable_types,
    problemMessage:
        "Specify the type of a local variable when the type is non-obvious.",
    correctionMessage: "Try adding a type annotation.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments specifyNonobviousPropertyTypes =
      LinterLintWithoutArguments(
        name: LintNames.specify_nonobvious_property_types,
        problemMessage: "A type annotation is needed because it isn't obvious.",
        correctionMessage: "Try adding a type annotation.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments strictTopLevelInferenceAddType =
      LinterLintWithoutArguments(
        name: LintNames.strict_top_level_inference,
        problemMessage: "Missing type annotation.",
        correctionMessage: "Try adding a type annotation.",
        uniqueName: 'strict_top_level_inference_add_type',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  strictTopLevelInferenceReplaceKeyword = LinterLintTemplate(
    name: LintNames.strict_top_level_inference,
    problemMessage: "Missing type annotation.",
    correctionMessage: "Try replacing '{0}' with a type annotation.",
    uniqueName: 'strict_top_level_inference_replace_keyword',
    withArguments: _withArgumentsStrictTopLevelInferenceReplaceKeyword,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments strictTopLevelInferenceSplitToTypes =
      LinterLintWithoutArguments(
        name: LintNames.strict_top_level_inference,
        problemMessage: "Missing type annotation.",
        correctionMessage:
            "Try splitting the declaration and specify the different type "
            "annotations.",
        uniqueName: 'strict_top_level_inference_split_to_types',
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments switchOnType =
      LinterLintWithoutArguments(
        name: LintNames.switch_on_type,
        problemMessage: "Avoid switch statements on a 'Type'.",
        correctionMessage: "Try using pattern matching on a variable instead.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  testTypesInEquals = LinterLintTemplate(
    name: LintNames.test_types_in_equals,
    problemMessage: "Missing type test for '{0}' in '=='.",
    correctionMessage: "Try testing the type of '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsTestTypesInEquals,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  throwInFinally = LinterLintTemplate(
    name: LintNames.throw_in_finally,
    problemMessage: "Use of '{0}' in 'finally' block.",
    correctionMessage: "Try moving the '{0}' outside the 'finally' block.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsThrowInFinally,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  tightenTypeOfInitializingFormals = LinterLintWithoutArguments(
    name: LintNames.tighten_type_of_initializing_formals,
    problemMessage:
        "Use a type annotation rather than 'assert' to enforce non-nullability.",
    correctionMessage:
        "Try adding a type annotation and removing the 'assert'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments typeAnnotatePublicApis =
      LinterLintWithoutArguments(
        name: LintNames.type_annotate_public_apis,
        problemMessage: "Missing type annotation on a public API.",
        correctionMessage: "Try adding a type annotation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments typeInitFormals =
      LinterLintWithoutArguments(
        name: LintNames.type_init_formals,
        problemMessage: "Don't needlessly type annotate initializing formals.",
        correctionMessage: "Try removing the type.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments typeLiteralInConstantPattern =
      LinterLintWithoutArguments(
        name: LintNames.type_literal_in_constant_pattern,
        problemMessage: "Use 'TypeName _' instead of a type literal.",
        correctionMessage: "Replace with 'TypeName _'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  unawaitedFutures = LinterLintWithoutArguments(
    name: LintNames.unawaited_futures,
    problemMessage:
        "Missing an 'await' for the 'Future' computed by this expression.",
    correctionMessage:
        "Try adding an 'await' or wrapping the expression with 'unawaited'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  unintendedHtmlInDocComment = LinterLintWithoutArguments(
    name: LintNames.unintended_html_in_doc_comment,
    problemMessage: "Angle brackets will be interpreted as HTML.",
    correctionMessage:
        "Try using backticks around the content with angle brackets, or try "
        "replacing `<` with `&lt;` and `>` with `&gt;`.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryAsync =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_async,
        problemMessage:
            "Don't make a function 'async' if it doesn't use 'await'.",
        correctionMessage: "Try removing the 'async' modifier.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryAwaitInReturn =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_await_in_return,
        problemMessage: "Unnecessary 'await'.",
        correctionMessage: "Try removing the 'await'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryBraceInStringInterps =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_brace_in_string_interps,
        problemMessage: "Unnecessary braces in a string interpolation.",
        correctionMessage: "Try removing the braces.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryBreaks =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_breaks,
        problemMessage: "Unnecessary 'break' statement.",
        correctionMessage: "Try removing the 'break'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryConst =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_const,
        problemMessage: "Unnecessary 'const' keyword.",
        correctionMessage: "Try removing the keyword.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryConstructorName =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_constructor_name,
        problemMessage: "Unnecessary '.new' constructor name.",
        correctionMessage: "Try removing the '.new'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryFinalWithoutType =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_final,
        problemMessage: "Local variables should not be marked as 'final'.",
        correctionMessage: "Replace 'final' with 'var'.",
        uniqueName: 'unnecessary_final_without_type',
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryFinalWithType =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_final,
        problemMessage: "Local variables should not be marked as 'final'.",
        correctionMessage: "Remove the 'final'.",
        hasPublishedDocs: true,
        uniqueName: 'unnecessary_final_with_type',
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryGettersSetters =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_getters_setters,
        problemMessage: "Unnecessary use of getter and setter to wrap a field.",
        correctionMessage:
            "Try removing the getter and setter and renaming the field.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unnecessaryIgnore = LinterLintTemplate(
    name: LintNames.unnecessary_ignore,
    problemMessage:
        "The diagnostic '{0}' isn't produced at this location so it doesn't need "
        "to be ignored.",
    correctionMessage: "Try removing the ignore comment.",
    hasPublishedDocs: true,
    uniqueName: 'unnecessary_ignore',
    withArguments: _withArgumentsUnnecessaryIgnore,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unnecessaryIgnoreFile = LinterLintTemplate(
    name: LintNames.unnecessary_ignore,
    problemMessage:
        "The diagnostic '{0}' isn't produced in this file so it doesn't need to be "
        "ignored.",
    correctionMessage: "Try removing the ignore comment.",
    uniqueName: 'unnecessary_ignore_file',
    withArguments: _withArgumentsUnnecessaryIgnoreFile,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unnecessaryIgnoreName = LinterLintTemplate(
    name: LintNames.unnecessary_ignore,
    problemMessage:
        "The diagnostic '{0}' isn't produced at this location so it doesn't need "
        "to be ignored.",
    correctionMessage: "Try removing the name from the list.",
    uniqueName: 'unnecessary_ignore_name',
    withArguments: _withArgumentsUnnecessaryIgnoreName,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unnecessaryIgnoreNameFile = LinterLintTemplate(
    name: LintNames.unnecessary_ignore,
    problemMessage:
        "The diagnostic '{0}' isn't produced in this file so it doesn't need to be "
        "ignored.",
    correctionMessage: "Try removing the name from the list.",
    uniqueName: 'unnecessary_ignore_name_file',
    withArguments: _withArgumentsUnnecessaryIgnoreNameFile,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryLambdas =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_lambdas,
        problemMessage: "Closure should be a tearoff.",
        correctionMessage: "Try using a tearoff rather than a closure.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryLate =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_late,
        problemMessage: "Unnecessary 'late' modifier.",
        correctionMessage: "Try removing the 'late'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  unnecessaryLibraryDirective = LinterLintWithoutArguments(
    name: LintNames.unnecessary_library_directive,
    problemMessage:
        "Library directives without comments or annotations should be avoided.",
    correctionMessage: "Try deleting the library directive.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryLibraryName =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_library_name,
        problemMessage: "Library names are not necessary.",
        correctionMessage: "Remove the library name.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryNew =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_new,
        problemMessage: "Unnecessary 'new' keyword.",
        correctionMessage: "Try removing the 'new' keyword.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  unnecessaryNullableForFinalVariableDeclarations = LinterLintWithoutArguments(
    name: LintNames.unnecessary_nullable_for_final_variable_declarations,
    problemMessage: "Type could be non-nullable.",
    correctionMessage: "Try changing the type to be non-nullable.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryNullAwareAssignments =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_null_aware_assignments,
        problemMessage: "Unnecessary assignment of 'null'.",
        correctionMessage: "Try removing the assignment.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  unnecessaryNullAwareOperatorOnExtensionOnNullable = LinterLintWithoutArguments(
    name: LintNames.unnecessary_null_aware_operator_on_extension_on_nullable,
    problemMessage:
        "Unnecessary use of a null-aware operator to invoke an extension method on "
        "a nullable type.",
    correctionMessage: "Try removing the '?'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryNullChecks =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_null_checks,
        problemMessage: "Unnecessary use of a null check ('!').",
        correctionMessage: "Try removing the null check.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryNullInIfNullOperators =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_null_in_if_null_operators,
        problemMessage: "Unnecessary use of '??' with 'null'.",
        correctionMessage:
            "Try removing the '??' operator and the 'null' operand.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryOverrides =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_overrides,
        problemMessage: "Unnecessary override.",
        correctionMessage:
            "Try adding behavior in the overriding member or removing the "
            "override.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryParenthesis =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_parenthesis,
        problemMessage: "Unnecessary use of parentheses.",
        correctionMessage: "Try removing the parentheses.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryRawStrings =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_raw_strings,
        problemMessage: "Unnecessary use of a raw string.",
        correctionMessage: "Try using a normal string.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryStatements =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_statements,
        problemMessage: "Unnecessary statement.",
        correctionMessage: "Try completing the statement or breaking it up.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryStringEscapes =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_string_escapes,
        problemMessage: "Unnecessary escape in string literal.",
        correctionMessage: "Remove the '\\' escape.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryStringInterpolations =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_string_interpolations,
        problemMessage: "Unnecessary use of string interpolation.",
        correctionMessage:
            "Try replacing the string literal with the variable name.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryThis =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_this,
        problemMessage: "Unnecessary 'this.' qualifier.",
        correctionMessage: "Try removing 'this.'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryToListInSpreads =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_to_list_in_spreads,
        problemMessage: "Unnecessary use of 'toList' in a spread.",
        correctionMessage: "Try removing the invocation of 'toList'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryUnawaited =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_unawaited,
        problemMessage: "Unnecessary use of 'unawaited'.",
        correctionMessage:
            "Try removing the use of 'unawaited', as the unawaited element is "
            "annotated with '@awaitNotRequired'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments unnecessaryUnderscores =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_underscores,
        problemMessage: "Unnecessary use of multiple underscores.",
        correctionMessage: "Try using '_'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unreachableFromMain = LinterLintTemplate(
    name: LintNames.unreachable_from_main,
    problemMessage: "Unreachable member '{0}' in an executable library.",
    correctionMessage: "Try referencing the member or removing it.",
    withArguments: _withArgumentsUnreachableFromMain,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  unrelatedTypeEqualityChecksInExpression = LinterLintTemplate(
    name: LintNames.unrelated_type_equality_checks,
    problemMessage:
        "The type of the right operand ('{0}') isn't a subtype or a supertype of "
        "the left operand ('{1}').",
    correctionMessage: "Try changing one or both of the operands.",
    hasPublishedDocs: true,
    uniqueName: 'unrelated_type_equality_checks_in_expression',
    withArguments: _withArgumentsUnrelatedTypeEqualityChecksInExpression,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  unrelatedTypeEqualityChecksInPattern = LinterLintTemplate(
    name: LintNames.unrelated_type_equality_checks,
    problemMessage:
        "The type of the operand ('{0}') isn't a subtype or a supertype of the "
        "value being matched ('{1}').",
    correctionMessage: "Try changing one or both of the operands.",
    hasPublishedDocs: true,
    uniqueName: 'unrelated_type_equality_checks_in_pattern',
    withArguments: _withArgumentsUnrelatedTypeEqualityChecksInPattern,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  unsafeVariance = LinterLintWithoutArguments(
    name: LintNames.unsafe_variance,
    problemMessage:
        "This type is unsafe: a type parameter occurs in a non-covariant position.",
    correctionMessage:
        "Try using a more general type that doesn't contain any type "
        "parameters in such a position.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  useBuildContextSynchronouslyAsyncUse = LinterLintWithoutArguments(
    name: LintNames.use_build_context_synchronously,
    problemMessage: "Don't use 'BuildContext's across async gaps.",
    correctionMessage:
        "Try rewriting the code to not use the 'BuildContext', or guard the "
        "use with a 'mounted' check.",
    hasPublishedDocs: true,
    uniqueName: 'use_build_context_synchronously_async_use',
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  useBuildContextSynchronouslyWrongMounted = LinterLintWithoutArguments(
    name: LintNames.use_build_context_synchronously,
    problemMessage:
        "Don't use 'BuildContext's across async gaps, guarded by an unrelated "
        "'mounted' check.",
    correctionMessage:
        "Guard a 'State.context' use with a 'mounted' check on the State, and "
        "other BuildContext use with a 'mounted' check on the BuildContext.",
    hasPublishedDocs: true,
    uniqueName: 'use_build_context_synchronously_wrong_mounted',
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments useColoredBox =
      LinterLintWithoutArguments(
        name: LintNames.use_colored_box,
        problemMessage:
            "Use a 'ColoredBox' rather than a 'Container' with only a 'Color'.",
        correctionMessage: "Try replacing the 'Container' with a 'ColoredBox'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  useDecoratedBox = LinterLintWithoutArguments(
    name: LintNames.use_decorated_box,
    problemMessage:
        "Use 'DecoratedBox' rather than a 'Container' with only a 'Decoration'.",
    correctionMessage: "Try replacing the 'Container' with a 'DecoratedBox'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments useEnums = LinterLintWithoutArguments(
    name: LintNames.use_enums,
    problemMessage: "Class should be an enum.",
    correctionMessage: "Try using an enum rather than a class.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  useFullHexValuesForFlutterColors = LinterLintWithoutArguments(
    name: LintNames.use_full_hex_values_for_flutter_colors,
    problemMessage:
        "Instances of 'Color' should be created using an 8-digit hexadecimal "
        "integer (such as '0xFFFFFFFF').",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  useFunctionTypeSyntaxForParameters = LinterLintTemplate(
    name: LintNames.use_function_type_syntax_for_parameters,
    problemMessage:
        "Use the generic function type syntax to declare the parameter '{0}'.",
    correctionMessage: "Try using the generic function type syntax.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUseFunctionTypeSyntaxForParameters,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments useIfNullToConvertNullsToBools =
      LinterLintWithoutArguments(
        name: LintNames.use_if_null_to_convert_nulls_to_bools,
        problemMessage:
            "Use an if-null operator to convert a 'null' to a 'bool'.",
        correctionMessage: "Try using an if-null operator.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  useIsEvenRatherThanModulo = LinterLintTemplate(
    name: LintNames.use_is_even_rather_than_modulo,
    problemMessage: "Use '{0}' rather than '% 2'.",
    correctionMessage: "Try using '{0}'.",
    withArguments: _withArgumentsUseIsEvenRatherThanModulo,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  useKeyInWidgetConstructors = LinterLintWithoutArguments(
    name: LintNames.use_key_in_widget_constructors,
    problemMessage:
        "Constructors for public widgets should have a named 'key' parameter.",
    correctionMessage: "Try adding a named parameter to the constructor.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments useLateForPrivateFieldsAndVariables =
      LinterLintWithoutArguments(
        name: LintNames.use_late_for_private_fields_and_variables,
        problemMessage:
            "Use 'late' for private members with a non-nullable type.",
        correctionMessage: "Try making adding the modifier 'late'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  useNamedConstants = LinterLintTemplate(
    name: LintNames.use_named_constants,
    problemMessage:
        "Use the constant '{0}' rather than a constructor returning the same "
        "object.",
    correctionMessage: "Try using '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUseNamedConstants,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  useNullAwareElements = LinterLintWithoutArguments(
    name: LintNames.use_null_aware_elements,
    problemMessage:
        "Use the null-aware marker '?' rather than a null check via an 'if'.",
    correctionMessage: "Try using '?'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments useRawStrings =
      LinterLintWithoutArguments(
        name: LintNames.use_raw_strings,
        problemMessage: "Use a raw string to avoid using escapes.",
        correctionMessage:
            "Try making the string a raw string and removing the escapes.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments useRethrowWhenPossible =
      LinterLintWithoutArguments(
        name: LintNames.use_rethrow_when_possible,
        problemMessage: "Use 'rethrow' to rethrow a caught exception.",
        correctionMessage: "Try replacing the 'throw' with a 'rethrow'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments useSettersToChangeProperties =
      LinterLintWithoutArguments(
        name: LintNames.use_setters_to_change_properties,
        problemMessage: "The method is used to change a property.",
        correctionMessage: "Try converting the method to a setter.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments
  useStringBuffers = LinterLintWithoutArguments(
    name: LintNames.use_string_buffers,
    problemMessage: "Use a string buffer rather than '+' to compose strings.",
    correctionMessage: "Try writing the parts of a string to a string buffer.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments useStringInPartOfDirectives =
      LinterLintWithoutArguments(
        name: LintNames.use_string_in_part_of_directives,
        problemMessage: "The part-of directive uses a library name.",
        correctionMessage:
            "Try converting the directive to use the URI of the library.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  useSuperParametersMultiple = LinterLintTemplate(
    name: LintNames.use_super_parameters,
    problemMessage: "Parameters '{0}' could be super parameters.",
    correctionMessage: "Trying converting '{0}' to super parameters.",
    hasPublishedDocs: true,
    uniqueName: 'use_super_parameters_multiple',
    withArguments: _withArgumentsUseSuperParametersMultiple,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LinterLintTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  useSuperParametersSingle = LinterLintTemplate(
    name: LintNames.use_super_parameters,
    problemMessage: "Parameter '{0}' could be a super parameter.",
    correctionMessage: "Trying converting '{0}' to a super parameter.",
    hasPublishedDocs: true,
    uniqueName: 'use_super_parameters_single',
    withArguments: _withArgumentsUseSuperParametersSingle,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const LinterLintWithoutArguments
  useTestThrowsMatchers = LinterLintWithoutArguments(
    name: LintNames.use_test_throws_matchers,
    problemMessage:
        "Use the 'throwsA' matcher instead of using 'fail' when there is no "
        "exception thrown.",
    correctionMessage:
        "Try removing the try-catch and using 'throwsA' to expect an "
        "exception.",
    expectedTypes: [],
  );

  /// No parameters.
  static const LinterLintWithoutArguments useToAndAsIfApplicable =
      LinterLintWithoutArguments(
        name: LintNames.use_to_and_as_if_applicable,
        problemMessage: "Start the name of the method with 'to' or 'as'.",
        correctionMessage:
            "Try renaming the method to use either 'to' or 'as'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments useTruncatingDivision =
      LinterLintWithoutArguments(
        name: LintNames.use_truncating_division,
        problemMessage: "Use truncating division.",
        correctionMessage:
            "Try using truncating division, '~/', instead of regular division "
            "('/') followed by 'toInt()'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments validRegexps =
      LinterLintWithoutArguments(
        name: LintNames.valid_regexps,
        problemMessage: "Invalid regular expression syntax.",
        correctionMessage: "Try correcting the regular expression.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments visitRegisteredNodes =
      LinterLintWithoutArguments(
        name: LintNames.visit_registered_nodes,
        problemMessage:
            "Declare 'visit' methods for all registered node types.",
        correctionMessage:
            "Try declaring a 'visit' method for all registered node types.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const LinterLintWithoutArguments voidChecks =
      LinterLintWithoutArguments(
        name: LintNames.void_checks,
        problemMessage: "Assignment to a variable of type 'void'.",
        correctionMessage:
            "Try removing the assignment or changing the type of the variable.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  @Deprecated('Please use LintCode instead')
  const LinterLintCode(
    String name,
    String problemMessage, {
    super.expectedTypes,
    super.correctionMessage,
    super.hasPublishedDocs,
    String? uniqueName,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         uniqueName: 'LintCode.${uniqueName ?? name}',
       );

  const LinterLintCode.internal({
    required super.name,
    required super.problemMessage,
    super.expectedTypes,
    super.correctionMessage,
    super.hasPublishedDocs,
    String? uniqueName,
  }) : super(uniqueName: 'LintCode.${uniqueName ?? name}');

  @override
  String get url {
    if (hasPublishedDocs) {
      return 'https://dart.dev/diagnostics/$name';
    }
    return 'https://dart.dev/lints/$name';
  }

  static LocatableDiagnostic _withArgumentsAlwaysDeclareReturnTypesOfFunctions({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.alwaysDeclareReturnTypesOfFunctions,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsAlwaysDeclareReturnTypesOfMethods({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.alwaysDeclareReturnTypesOfMethods,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsAlwaysSpecifyTypesReplaceKeyword({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.alwaysSpecifyTypesReplaceKeyword,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsAlwaysSpecifyTypesSpecifyType({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.alwaysSpecifyTypesSpecifyType,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsAnalyzerPublicApiBadType({
    required String types,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.analyzerPublicApiBadType, [
      types,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsAnalyzerPublicApiExperimentalInconsistency({
    required String types,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.analyzerPublicApiExperimentalInconsistency,
      [types],
    );
  }

  static LocatableDiagnostic
  _withArgumentsAnalyzerPublicApiExportsNonPublicName({
    required String elements,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.analyzerPublicApiExportsNonPublicName,
      [elements],
    );
  }

  static LocatableDiagnostic _withArgumentsAnnotateOverrides({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.annotateOverrides, [p0]);
  }

  static LocatableDiagnostic _withArgumentsAnnotateRedeclares({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.annotateRedeclares, [p0]);
  }

  static LocatableDiagnostic _withArgumentsAvoidCatchingErrorsSubclass({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.avoidCatchingErrorsSubclass, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsAvoidEqualsAndHashCodeOnMutableClasses({required Object p0}) {
    return LocatableDiagnosticImpl(
      LinterLintCode.avoidEqualsAndHashCodeOnMutableClasses,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsAvoidEscapingInnerQuotes({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.avoidEscapingInnerQuotes, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsAvoidRenamingMethodParameters({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.avoidRenamingMethodParameters,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsAvoidShadowingTypeParameters({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.avoidShadowingTypeParameters,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsAvoidSingleCascadeInExpressionStatements({required Object p0}) {
    return LocatableDiagnosticImpl(
      LinterLintCode.avoidSingleCascadeInExpressionStatements,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsAvoidTypesAsParameterNamesFormalParameter({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.avoidTypesAsParameterNamesFormalParameter,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsAvoidTypesAsParameterNamesTypeParameter({required Object p0}) {
    return LocatableDiagnosticImpl(
      LinterLintCode.avoidTypesAsParameterNamesTypeParameter,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsAvoidUnusedConstructorParameters({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.avoidUnusedConstructorParameters,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsAwaitOnlyFutures({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.awaitOnlyFutures, [p0]);
  }

  static LocatableDiagnostic _withArgumentsCamelCaseExtensions({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.camelCaseExtensions, [p0]);
  }

  static LocatableDiagnostic _withArgumentsCamelCaseTypes({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.camelCaseTypes, [p0]);
  }

  static LocatableDiagnostic _withArgumentsCollectionMethodsUnrelatedType({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.collectionMethodsUnrelatedType,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsConditionalUriDoesNotExist({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.conditionalUriDoesNotExist, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsConstantIdentifierNames({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.constantIdentifierNames, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsControlFlowInFinally({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.controlFlowInFinally, [p0]);
  }

  static LocatableDiagnostic _withArgumentsCurlyBracesInFlowControlStructures({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.curlyBracesInFlowControlStructures,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsDependOnReferencedPackages({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.dependOnReferencedPackages, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsDeprecatedMemberUseFromSamePackageWithMessage({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.deprecatedMemberUseFromSamePackageWithMessage,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsDeprecatedMemberUseFromSamePackageWithoutMessage({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.deprecatedMemberUseFromSamePackageWithoutMessage,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsDirectivesOrderingDart({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.directivesOrderingDart, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsDirectivesOrderingPackageBeforeRelative({required Object p0}) {
    return LocatableDiagnosticImpl(
      LinterLintCode.directivesOrderingPackageBeforeRelative,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsExhaustiveCases({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.exhaustiveCases, [p0]);
  }

  static LocatableDiagnostic _withArgumentsFileNames({required Object p0}) {
    return LocatableDiagnosticImpl(LinterLintCode.fileNames, [p0]);
  }

  static LocatableDiagnostic _withArgumentsHashAndEquals({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.hashAndEquals, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsImplicitReopen({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.implicitReopen, [
      p0,
      p1,
      p2,
      p3,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsInvalidRuntimeCheckWithJsInteropTypesDartAsJs({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.invalidRuntimeCheckWithJsInteropTypesDartAsJs,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInvalidRuntimeCheckWithJsInteropTypesDartIsJs({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.invalidRuntimeCheckWithJsInteropTypesDartIsJs,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsAsDart({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.invalidRuntimeCheckWithJsInteropTypesJsAsDart,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.invalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsDart({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.invalidRuntimeCheckWithJsInteropTypesJsIsDart,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.invalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.invalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsLibraryNames({required Object p0}) {
    return LocatableDiagnosticImpl(LinterLintCode.libraryNames, [p0]);
  }

  static LocatableDiagnostic _withArgumentsLibraryPrefixes({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.libraryPrefixes, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMatchingSuperParameters({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.matchingSuperParameters, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsNoDuplicateCaseValues({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.noDuplicateCaseValues, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsNoLeadingUnderscoresForLibraryPrefixes({required Object p0}) {
    return LocatableDiagnosticImpl(
      LinterLintCode.noLeadingUnderscoresForLibraryPrefixes,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsNoLeadingUnderscoresForLocalIdentifiers({required Object p0}) {
    return LocatableDiagnosticImpl(
      LinterLintCode.noLeadingUnderscoresForLocalIdentifiers,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsNonConstantIdentifierNames({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.nonConstantIdentifierNames, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsOneMemberAbstracts({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.oneMemberAbstracts, [p0]);
  }

  static LocatableDiagnostic _withArgumentsOverriddenFields({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.overriddenFields, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPackageNames({required Object p0}) {
    return LocatableDiagnosticImpl(LinterLintCode.packageNames, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPackagePrefixedLibraryNames({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.packagePrefixedLibraryNames, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsParameterAssignments({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.parameterAssignments, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPreferFinalFields({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.preferFinalFields, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPreferFinalInForEachVariable({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.preferFinalInForEachVariable,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsPreferFinalParameters({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.preferFinalParameters, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPreferGenericFunctionTypeAliases({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.preferGenericFunctionTypeAliases,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsPreferInitializingFormals({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.preferInitializingFormals, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsPreferMixin({required Object p0}) {
    return LocatableDiagnosticImpl(LinterLintCode.preferMixin, [p0]);
  }

  static LocatableDiagnostic _withArgumentsRecursiveGetters({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.recursiveGetters, [p0]);
  }

  static LocatableDiagnostic _withArgumentsSecurePubspecUrls({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.securePubspecUrls, [p0]);
  }

  static LocatableDiagnostic _withArgumentsSizedBoxShrinkExpand({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.sizedBoxShrinkExpand, [p0]);
  }

  static LocatableDiagnostic _withArgumentsSortChildPropertiesLast({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.sortChildPropertiesLast, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsStrictTopLevelInferenceReplaceKeyword({required Object p0}) {
    return LocatableDiagnosticImpl(
      LinterLintCode.strictTopLevelInferenceReplaceKeyword,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsTestTypesInEquals({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.testTypesInEquals, [p0]);
  }

  static LocatableDiagnostic _withArgumentsThrowInFinally({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.throwInFinally, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnnecessaryIgnore({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.unnecessaryIgnore, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnnecessaryIgnoreFile({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.unnecessaryIgnoreFile, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnnecessaryIgnoreName({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.unnecessaryIgnoreName, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnnecessaryIgnoreNameFile({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.unnecessaryIgnoreNameFile, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUnreachableFromMain({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.unreachableFromMain, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsUnrelatedTypeEqualityChecksInExpression({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.unrelatedTypeEqualityChecksInExpression,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsUnrelatedTypeEqualityChecksInPattern({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.unrelatedTypeEqualityChecksInPattern,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsUseFunctionTypeSyntaxForParameters({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      LinterLintCode.useFunctionTypeSyntaxForParameters,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsUseIsEvenRatherThanModulo({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.useIsEvenRatherThanModulo, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUseNamedConstants({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.useNamedConstants, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUseSuperParametersMultiple({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.useSuperParametersMultiple, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUseSuperParametersSingle({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(LinterLintCode.useSuperParametersSingle, [
      p0,
    ]);
  }
}

final class LinterLintTemplate<T extends Function> extends LinterLintCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const LinterLintTemplate({
    required super.name,
    required super.problemMessage,
    required this.withArguments,
    required super.expectedTypes,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.uniqueName,
  }) : super.internal();
}

final class LinterLintWithoutArguments extends LinterLintCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const LinterLintWithoutArguments({
    required super.name,
    required super.problemMessage,
    required super.expectedTypes,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.uniqueName,
  }) : super.internal();
}
