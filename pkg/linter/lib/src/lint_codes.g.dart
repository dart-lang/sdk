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
  alwaysDeclareReturnTypesOfFunctions = LinterLintTemplate(
    name: LintNames.always_declare_return_types,
    problemMessage: "The function '{0}' should have a return type but doesn't.",
    correctionMessage: "Try adding a return type to the function.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.always_declare_return_types_of_functions',
    withArguments: _withArgumentsAlwaysDeclareReturnTypesOfFunctions,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  alwaysDeclareReturnTypesOfMethods = LinterLintTemplate(
    name: LintNames.always_declare_return_types,
    problemMessage: "The method '{0}' should have a return type but doesn't.",
    correctionMessage: "Try adding a return type to the method.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.always_declare_return_types_of_methods',
    withArguments: _withArgumentsAlwaysDeclareReturnTypesOfMethods,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments alwaysPutControlBodyOnNewLine =
      LinterLintWithoutArguments(
        name: LintNames.always_put_control_body_on_new_line,
        problemMessage: "Statement should be on a separate line.",
        correctionMessage: "Try moving the statement to a new line.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.always_put_control_body_on_new_line',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  alwaysPutRequiredNamedParametersFirst = LinterLintWithoutArguments(
    name: LintNames.always_put_required_named_parameters_first,
    problemMessage:
        "Required named parameters should be before optional named parameters.",
    correctionMessage:
        "Try moving the required named parameter to be before any optional "
        "named parameters.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.always_put_required_named_parameters_first',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments alwaysSpecifyTypesAddType =
      LinterLintWithoutArguments(
        name: LintNames.always_specify_types,
        problemMessage: "Missing type annotation.",
        correctionMessage: "Try adding a type annotation.",
        uniqueName: 'LintCode.always_specify_types_add_type',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  alwaysSpecifyTypesReplaceKeyword = LinterLintTemplate(
    name: LintNames.always_specify_types,
    problemMessage: "Missing type annotation.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
    uniqueName: 'LintCode.always_specify_types_replace_keyword',
    withArguments: _withArgumentsAlwaysSpecifyTypesReplaceKeyword,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  alwaysSpecifyTypesSpecifyType = LinterLintTemplate(
    name: LintNames.always_specify_types,
    problemMessage: "Missing type annotation.",
    correctionMessage: "Try specifying the type '{0}'.",
    uniqueName: 'LintCode.always_specify_types_specify_type',
    withArguments: _withArgumentsAlwaysSpecifyTypesSpecifyType,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments alwaysSpecifyTypesSplitToTypes =
      LinterLintWithoutArguments(
        name: LintNames.always_specify_types,
        problemMessage: "Missing type annotation.",
        correctionMessage:
            "Try splitting the declaration and specify the different type "
            "annotations.",
        uniqueName: 'LintCode.always_specify_types_split_to_types',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments alwaysUsePackageImports =
      LinterLintWithoutArguments(
        name: LintNames.always_use_package_imports,
        problemMessage:
            "Use 'package:' imports for files in the 'lib' directory.",
        correctionMessage: "Try converting the URI to a 'package:' URI.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.always_use_package_imports',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments analyzerElementModelTrackingBad =
      LinterLintWithoutArguments(
        name: LintNames.analyzer_element_model_tracking_bad,
        problemMessage: "Bad tracking annotation for this member.",
        uniqueName: 'LintCode.analyzer_element_model_tracking_bad',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  analyzerElementModelTrackingMoreThanOne = LinterLintWithoutArguments(
    name: LintNames.analyzer_element_model_tracking_more_than_one,
    problemMessage: "There can be only one tracking annotation.",
    uniqueName: 'LintCode.analyzer_element_model_tracking_more_than_one',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments analyzerElementModelTrackingZero =
      LinterLintWithoutArguments(
        name: LintNames.analyzer_element_model_tracking_zero,
        problemMessage: "No required tracking annotation.",
        uniqueName: 'LintCode.analyzer_element_model_tracking_zero',
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
  static const DiagnosticWithoutArguments
  analyzerPublicApiBadPartDirective = LinterLintWithoutArguments(
    name: LintNames.analyzer_public_api_bad_part_directive,
    problemMessage:
        "Part directives in the analyzer public API should point to files in the "
        "analyzer public API.",
    uniqueName: 'LintCode.analyzer_public_api_bad_part_directive',
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
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String types})
  >
  analyzerPublicApiBadType = LinterLintTemplate(
    name: LintNames.analyzer_public_api_bad_type,
    problemMessage:
        "Element makes use of type(s) which is not part of the analyzer public "
        "API: {0}.",
    uniqueName: 'LintCode.analyzer_public_api_bad_type',
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
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String types})
  >
  analyzerPublicApiExperimentalInconsistency = LinterLintTemplate(
    name: LintNames.analyzer_public_api_experimental_inconsistency,
    problemMessage:
        "Element makes use of experimental type(s), but is not itself marked with "
        "`@experimental`: {0}.",
    uniqueName: 'LintCode.analyzer_public_api_experimental_inconsistency',
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
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String elements})
  >
  analyzerPublicApiExportsNonPublicName = LinterLintTemplate(
    name: LintNames.analyzer_public_api_exports_non_public_name,
    problemMessage:
        "Export directive exports element(s) that are not part of the analyzer "
        "public API: {0}.",
    uniqueName: 'LintCode.analyzer_public_api_exports_non_public_name',
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
  static const DiagnosticWithoutArguments
  analyzerPublicApiImplInPublicApi = LinterLintWithoutArguments(
    name: LintNames.analyzer_public_api_impl_in_public_api,
    problemMessage:
        "Declarations in the analyzer public API should not end in \"Impl\".",
    uniqueName: 'LintCode.analyzer_public_api_impl_in_public_api',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  annotateOverrides = LinterLintTemplate(
    name: LintNames.annotate_overrides,
    problemMessage:
        "The member '{0}' overrides an inherited member but isn't annotated with "
        "'@override'.",
    correctionMessage: "Try adding the '@override' annotation.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.annotate_overrides',
    withArguments: _withArgumentsAnnotateOverrides,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  annotateRedeclares = LinterLintTemplate(
    name: LintNames.annotate_redeclares,
    problemMessage:
        "The member '{0}' is redeclaring but isn't annotated with '@redeclare'.",
    correctionMessage: "Try adding the '@redeclare' annotation.",
    uniqueName: 'LintCode.annotate_redeclares',
    withArguments: _withArgumentsAnnotateRedeclares,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidAnnotatingWithDynamic =
      LinterLintWithoutArguments(
        name: LintNames.avoid_annotating_with_dynamic,
        problemMessage: "Unnecessary 'dynamic' type annotation.",
        correctionMessage: "Try removing the type 'dynamic'.",
        uniqueName: 'LintCode.avoid_annotating_with_dynamic',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  avoidBoolLiteralsInConditionalExpressions = LinterLintWithoutArguments(
    name: LintNames.avoid_bool_literals_in_conditional_expressions,
    problemMessage:
        "Conditional expressions with a 'bool' literal can be simplified.",
    correctionMessage:
        "Try rewriting the expression to use either '&&' or '||'.",
    uniqueName: 'LintCode.avoid_bool_literals_in_conditional_expressions',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  avoidCatchesWithoutOnClauses = LinterLintWithoutArguments(
    name: LintNames.avoid_catches_without_on_clauses,
    problemMessage:
        "Catch clause should use 'on' to specify the type of exception being "
        "caught.",
    correctionMessage: "Try adding an 'on' clause before the 'catch'.",
    uniqueName: 'LintCode.avoid_catches_without_on_clauses',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidCatchingErrorsClass =
      LinterLintWithoutArguments(
        name: LintNames.avoid_catching_errors,
        problemMessage: "The type 'Error' should not be caught.",
        correctionMessage:
            "Try removing the catch or catching an 'Exception' instead.",
        uniqueName: 'LintCode.avoid_catching_errors_class',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidCatchingErrorsSubclass = LinterLintTemplate(
    name: LintNames.avoid_catching_errors,
    problemMessage:
        "The type '{0}' should not be caught because it is a subclass of 'Error'.",
    correctionMessage:
        "Try removing the catch or catching an 'Exception' instead.",
    uniqueName: 'LintCode.avoid_catching_errors_subclass',
    withArguments: _withArgumentsAvoidCatchingErrorsSubclass,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  avoidClassesWithOnlyStaticMembers = LinterLintWithoutArguments(
    name: LintNames.avoid_classes_with_only_static_members,
    problemMessage: "Classes should define instance members.",
    correctionMessage:
        "Try adding instance behavior or moving the members out of the class.",
    uniqueName: 'LintCode.avoid_classes_with_only_static_members',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidDoubleAndIntChecks =
      LinterLintWithoutArguments(
        name: LintNames.avoid_double_and_int_checks,
        problemMessage: "Explicit check for double or int.",
        correctionMessage: "Try removing the check.",
        uniqueName: 'LintCode.avoid_double_and_int_checks',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidDynamicCalls =
      LinterLintWithoutArguments(
        name: LintNames.avoid_dynamic_calls,
        problemMessage:
            "Method invocation or property access on a 'dynamic' target.",
        correctionMessage: "Try giving the target a type.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.avoid_dynamic_calls',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidEmptyElse =
      LinterLintWithoutArguments(
        name: LintNames.avoid_empty_else,
        problemMessage: "Empty statements are not allowed in an 'else' clause.",
        correctionMessage:
            "Try removing the empty statement or removing the else clause.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.avoid_empty_else',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidEqualsAndHashCodeOnMutableClasses = LinterLintTemplate(
    name: LintNames.avoid_equals_and_hash_code_on_mutable_classes,
    problemMessage:
        "The method '{0}' should not be overridden in classes not annotated with "
        "'@immutable'.",
    correctionMessage:
        "Try removing the override or annotating the class with '@immutable'.",
    uniqueName: 'LintCode.avoid_equals_and_hash_code_on_mutable_classes',
    withArguments: _withArgumentsAvoidEqualsAndHashCodeOnMutableClasses,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  avoidEscapingInnerQuotes = LinterLintTemplate(
    name: LintNames.avoid_escaping_inner_quotes,
    problemMessage: "Unnecessary escape of '{0}'.",
    correctionMessage: "Try changing the outer quotes to '{1}'.",
    uniqueName: 'LintCode.avoid_escaping_inner_quotes',
    withArguments: _withArgumentsAvoidEscapingInnerQuotes,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  avoidFieldInitializersInConstClasses = LinterLintWithoutArguments(
    name: LintNames.avoid_field_initializers_in_const_classes,
    problemMessage: "Fields in 'const' classes should not have initializers.",
    correctionMessage:
        "Try converting the field to a getter or initialize the field in the "
        "constructors.",
    uniqueName: 'LintCode.avoid_field_initializers_in_const_classes',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidFinalParameters =
      LinterLintWithoutArguments(
        name: LintNames.avoid_final_parameters,
        problemMessage: "Parameters should not be marked as 'final'.",
        correctionMessage: "Try removing the keyword 'final'.",
        uniqueName: 'LintCode.avoid_final_parameters',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidFunctionLiteralsInForeachCalls =
      LinterLintWithoutArguments(
        name: LintNames.avoid_function_literals_in_foreach_calls,
        problemMessage: "Function literals shouldn't be passed to 'forEach'.",
        correctionMessage: "Try using a 'for' loop.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.avoid_function_literals_in_foreach_calls',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidFutureorVoid =
      LinterLintWithoutArguments(
        name: LintNames.avoid_futureor_void,
        problemMessage: "Don't use the type 'FutureOr<void>'.",
        correctionMessage: "Try using 'Future<void>?' or 'void'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.avoid_futureor_void',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidImplementingValueTypes =
      LinterLintWithoutArguments(
        name: LintNames.avoid_implementing_value_types,
        problemMessage: "Classes that override '==' should not be implemented.",
        correctionMessage:
            "Try removing the class from the 'implements' clause.",
        uniqueName: 'LintCode.avoid_implementing_value_types',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidInitToNull =
      LinterLintWithoutArguments(
        name: LintNames.avoid_init_to_null,
        problemMessage: "Redundant initialization to 'null'.",
        correctionMessage: "Try removing the initializer.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.avoid_init_to_null',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  avoidJsRoundedInts = LinterLintWithoutArguments(
    name: LintNames.avoid_js_rounded_ints,
    problemMessage:
        "Integer literal can't be represented exactly when compiled to JavaScript.",
    correctionMessage: "Try using a 'BigInt' to represent the value.",
    uniqueName: 'LintCode.avoid_js_rounded_ints',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidMultipleDeclarationsPerLine =
      LinterLintWithoutArguments(
        name: LintNames.avoid_multiple_declarations_per_line,
        problemMessage: "Multiple variables declared on a single line.",
        correctionMessage:
            "Try splitting the variable declarations into multiple lines.",
        uniqueName: 'LintCode.avoid_multiple_declarations_per_line',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidNullChecksInEqualityOperators =
      LinterLintWithoutArguments(
        name: LintNames.avoid_null_checks_in_equality_operators,
        problemMessage:
            "Unnecessary null comparison in implementation of '=='.",
        correctionMessage: "Try removing the comparison.",
        uniqueName: 'LintCode.avoid_null_checks_in_equality_operators',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidPositionalBooleanParameters =
      LinterLintWithoutArguments(
        name: LintNames.avoid_positional_boolean_parameters,
        problemMessage: "'bool' parameters should be named parameters.",
        correctionMessage: "Try converting the parameter to a named parameter.",
        uniqueName: 'LintCode.avoid_positional_boolean_parameters',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidPrint =
      LinterLintWithoutArguments(
        name: LintNames.avoid_print,
        problemMessage: "Don't invoke 'print' in production code.",
        correctionMessage: "Try using a logging framework.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.avoid_print',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidPrivateTypedefFunctions =
      LinterLintWithoutArguments(
        name: LintNames.avoid_private_typedef_functions,
        problemMessage:
            "The typedef is unnecessary because it is only used in one place.",
        correctionMessage: "Try inlining the type or using it in other places.",
        uniqueName: 'LintCode.avoid_private_typedef_functions',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  avoidRedundantArgumentValues = LinterLintWithoutArguments(
    name: LintNames.avoid_redundant_argument_values,
    problemMessage:
        "The value of the argument is redundant because it matches the default "
        "value.",
    correctionMessage: "Try removing the argument.",
    uniqueName: 'LintCode.avoid_redundant_argument_values',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  avoidRelativeLibImports = LinterLintWithoutArguments(
    name: LintNames.avoid_relative_lib_imports,
    problemMessage: "Can't use a relative path to import a library in 'lib'.",
    correctionMessage:
        "Try fixing the relative path or changing the import to a 'package:' "
        "import.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.avoid_relative_lib_imports',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  avoidRenamingMethodParameters = LinterLintTemplate(
    name: LintNames.avoid_renaming_method_parameters,
    problemMessage:
        "The parameter name '{0}' doesn't match the name '{1}' in the overridden "
        "method.",
    correctionMessage: "Try changing the name to '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.avoid_renaming_method_parameters',
    withArguments: _withArgumentsAvoidRenamingMethodParameters,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  avoidReturningNullForVoidFromFunction = LinterLintWithoutArguments(
    name: LintNames.avoid_returning_null_for_void,
    problemMessage:
        "Don't return 'null' from a function with a return type of 'void'.",
    correctionMessage: "Try removing the 'null'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.avoid_returning_null_for_void_from_function',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidReturningNullForVoidFromMethod =
      LinterLintWithoutArguments(
        name: LintNames.avoid_returning_null_for_void,
        problemMessage:
            "Don't return 'null' from a method with a return type of 'void'.",
        correctionMessage: "Try removing the 'null'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.avoid_returning_null_for_void_from_method',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidReturningThis =
      LinterLintWithoutArguments(
        name: LintNames.avoid_returning_this,
        problemMessage: "Don't return 'this' from a method.",
        correctionMessage:
            "Try changing the return type to 'void' and removing the return.",
        uniqueName: 'LintCode.avoid_returning_this',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidReturnTypesOnSetters =
      LinterLintWithoutArguments(
        name: LintNames.avoid_return_types_on_setters,
        problemMessage: "Unnecessary return type on a setter.",
        correctionMessage: "Try removing the return type.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.avoid_return_types_on_setters',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidSettersWithoutGetters =
      LinterLintWithoutArguments(
        name: LintNames.avoid_setters_without_getters,
        problemMessage: "Setter has no corresponding getter.",
        correctionMessage:
            "Try adding a corresponding getter or removing the setter.",
        uniqueName: 'LintCode.avoid_setters_without_getters',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  avoidShadowingTypeParameters = LinterLintTemplate(
    name: LintNames.avoid_shadowing_type_parameters,
    problemMessage:
        "The type parameter '{0}' shadows a type parameter from the enclosing {1}.",
    correctionMessage: "Try renaming one of the type parameters.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.avoid_shadowing_type_parameters',
    withArguments: _withArgumentsAvoidShadowingTypeParameters,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidSingleCascadeInExpressionStatements = LinterLintTemplate(
    name: LintNames.avoid_single_cascade_in_expression_statements,
    problemMessage: "Unnecessary cascade expression.",
    correctionMessage: "Try using the operator '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.avoid_single_cascade_in_expression_statements',
    withArguments: _withArgumentsAvoidSingleCascadeInExpressionStatements,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidSlowAsyncIo =
      LinterLintWithoutArguments(
        name: LintNames.avoid_slow_async_io,
        problemMessage: "Use of an async 'dart:io' method.",
        correctionMessage: "Try using the synchronous version of the method.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.avoid_slow_async_io',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidTypesAsParameterNamesFormalParameter = LinterLintTemplate(
    name: LintNames.avoid_types_as_parameter_names,
    problemMessage: "The parameter name '{0}' matches a visible type name.",
    correctionMessage:
        "Try adding a name for the parameter or changing the parameter name to "
        "not match an existing type.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.avoid_types_as_parameter_names_formal_parameter',
    withArguments: _withArgumentsAvoidTypesAsParameterNamesFormalParameter,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidTypesAsParameterNamesTypeParameter = LinterLintTemplate(
    name: LintNames.avoid_types_as_parameter_names,
    problemMessage:
        "The type parameter name '{0}' matches a visible type name.",
    correctionMessage:
        "Try changing the type parameter name to not match an existing type.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.avoid_types_as_parameter_names_type_parameter',
    withArguments: _withArgumentsAvoidTypesAsParameterNamesTypeParameter,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidTypesOnClosureParameters =
      LinterLintWithoutArguments(
        name: LintNames.avoid_types_on_closure_parameters,
        problemMessage:
            "Unnecessary type annotation on a function expression parameter.",
        correctionMessage: "Try removing the type annotation.",
        uniqueName: 'LintCode.avoid_types_on_closure_parameters',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidTypeToString =
      LinterLintWithoutArguments(
        name: LintNames.avoid_type_to_string,
        problemMessage:
            "Using 'toString' on a 'Type' is not safe in production code.",
        correctionMessage:
            "Try a normal type check or compare the 'runtimeType' directly.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.avoid_type_to_string',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  avoidUnnecessaryContainers = LinterLintWithoutArguments(
    name: LintNames.avoid_unnecessary_containers,
    problemMessage: "Unnecessary instance of 'Container'.",
    correctionMessage:
        "Try removing the 'Container' (but not its children) from the widget "
        "tree.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.avoid_unnecessary_containers',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  avoidUnusedConstructorParameters = LinterLintTemplate(
    name: LintNames.avoid_unused_constructor_parameters,
    problemMessage: "The parameter '{0}' is not used in the constructor.",
    correctionMessage: "Try using the parameter or removing it.",
    uniqueName: 'LintCode.avoid_unused_constructor_parameters',
    withArguments: _withArgumentsAvoidUnusedConstructorParameters,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  avoidVoidAsync = LinterLintWithoutArguments(
    name: LintNames.avoid_void_async,
    problemMessage:
        "An 'async' function should have a 'Future' return type when it doesn't "
        "return a value.",
    correctionMessage: "Try changing the return type.",
    uniqueName: 'LintCode.avoid_void_async',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments avoidWebLibrariesInFlutter =
      LinterLintWithoutArguments(
        name: LintNames.avoid_web_libraries_in_flutter,
        problemMessage:
            "Don't use web-only libraries outside Flutter web plugins.",
        correctionMessage: "Try finding a different library for your needs.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.avoid_web_libraries_in_flutter',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  awaitOnlyFutures = LinterLintTemplate(
    name: LintNames.await_only_futures,
    problemMessage:
        "Uses 'await' on an instance of '{0}', which is not a subtype of 'Future'.",
    correctionMessage: "Try removing the 'await' or changing the expression.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.await_only_futures',
    withArguments: _withArgumentsAwaitOnlyFutures,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  camelCaseExtensions = LinterLintTemplate(
    name: LintNames.camel_case_extensions,
    problemMessage:
        "The extension name '{0}' isn't an UpperCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the UpperCamelCase style.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.camel_case_extensions',
    withArguments: _withArgumentsCamelCaseExtensions,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  camelCaseTypes = LinterLintTemplate(
    name: LintNames.camel_case_types,
    problemMessage: "The type name '{0}' isn't an UpperCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the UpperCamelCase style.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.camel_case_types',
    withArguments: _withArgumentsCamelCaseTypes,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments cancelSubscriptions =
      LinterLintWithoutArguments(
        name: LintNames.cancel_subscriptions,
        problemMessage: "Uncancelled instance of 'StreamSubscription'.",
        correctionMessage:
            "Try invoking 'cancel' in the function in which the "
            "'StreamSubscription' was created.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.cancel_subscriptions',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments cascadeInvocations =
      LinterLintWithoutArguments(
        name: LintNames.cascade_invocations,
        problemMessage: "Unnecessary duplication of receiver.",
        correctionMessage: "Try using a cascade to avoid the duplication.",
        uniqueName: 'LintCode.cascade_invocations',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  castNullableToNonNullable = LinterLintWithoutArguments(
    name: LintNames.cast_nullable_to_non_nullable,
    problemMessage: "Don't cast a nullable value to a non-nullable type.",
    correctionMessage:
        "Try adding a not-null assertion ('!') to make the type non-nullable.",
    uniqueName: 'LintCode.cast_nullable_to_non_nullable',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  closeSinks = LinterLintWithoutArguments(
    name: LintNames.close_sinks,
    problemMessage: "Unclosed instance of 'Sink'.",
    correctionMessage:
        "Try invoking 'close' in the function in which the 'Sink' was created.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.close_sinks',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  collectionMethodsUnrelatedType = LinterLintTemplate(
    name: LintNames.collection_methods_unrelated_type,
    problemMessage: "The argument type '{0}' isn't related to '{1}'.",
    correctionMessage: "Try changing the argument or element type to match.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.collection_methods_unrelated_type',
    withArguments: _withArgumentsCollectionMethodsUnrelatedType,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments combinatorsOrdering =
      LinterLintWithoutArguments(
        name: LintNames.combinators_ordering,
        problemMessage: "Sort combinator names alphabetically.",
        correctionMessage: "Try sorting the combinator names alphabetically.",
        uniqueName: 'LintCode.combinators_ordering',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments commentReferences =
      LinterLintWithoutArguments(
        name: LintNames.comment_references,
        problemMessage: "The referenced name isn't visible in scope.",
        correctionMessage: "Try adding an import for the referenced name.",
        uniqueName: 'LintCode.comment_references',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  conditionalUriDoesNotExist = LinterLintTemplate(
    name: LintNames.conditional_uri_does_not_exist,
    problemMessage: "The target of the conditional URI '{0}' doesn't exist.",
    correctionMessage:
        "Try creating the file referenced by the URI, or try using a URI for a "
        "file that does exist.",
    uniqueName: 'LintCode.conditional_uri_does_not_exist',
    withArguments: _withArgumentsConditionalUriDoesNotExist,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  constantIdentifierNames = LinterLintTemplate(
    name: LintNames.constant_identifier_names,
    problemMessage:
        "The constant name '{0}' isn't a lowerCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the lowerCamelCase style.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.constant_identifier_names',
    withArguments: _withArgumentsConstantIdentifierNames,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  controlFlowInFinally = LinterLintTemplate(
    name: LintNames.control_flow_in_finally,
    problemMessage: "Use of '{0}' in a 'finally' clause.",
    correctionMessage: "Try restructuring the code.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.control_flow_in_finally',
    withArguments: _withArgumentsControlFlowInFinally,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  curlyBracesInFlowControlStructures = LinterLintTemplate(
    name: LintNames.curly_braces_in_flow_control_structures,
    problemMessage: "Statements in {0} should be enclosed in a block.",
    correctionMessage: "Try wrapping the statement in a block.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.curly_braces_in_flow_control_structures',
    withArguments: _withArgumentsCurlyBracesInFlowControlStructures,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments danglingLibraryDocComments =
      LinterLintWithoutArguments(
        name: LintNames.dangling_library_doc_comments,
        problemMessage: "Dangling library doc comment.",
        correctionMessage:
            "Add a 'library' directive after the library comment.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.dangling_library_doc_comments',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  dependOnReferencedPackages = LinterLintTemplate(
    name: LintNames.depend_on_referenced_packages,
    problemMessage:
        "The imported package '{0}' isn't a dependency of the importing package.",
    correctionMessage:
        "Try adding a dependency for '{0}' in the 'pubspec.yaml' file.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.depend_on_referenced_packages',
    withArguments: _withArgumentsDependOnReferencedPackages,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments deprecatedConsistencyConstructor =
      LinterLintWithoutArguments(
        name: LintNames.deprecated_consistency,
        problemMessage:
            "Constructors in a deprecated class should be deprecated.",
        correctionMessage: "Try marking the constructor as deprecated.",
        uniqueName: 'LintCode.deprecated_consistency_constructor',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments deprecatedConsistencyField =
      LinterLintWithoutArguments(
        name: LintNames.deprecated_consistency,
        problemMessage:
            "Fields that are initialized by a deprecated parameter should be "
            "deprecated.",
        correctionMessage: "Try marking the field as deprecated.",
        uniqueName: 'LintCode.deprecated_consistency_field',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  deprecatedConsistencyParameter = LinterLintWithoutArguments(
    name: LintNames.deprecated_consistency,
    problemMessage:
        "Parameters that initialize a deprecated field should be deprecated.",
    correctionMessage: "Try marking the parameter as deprecated.",
    uniqueName: 'LintCode.deprecated_consistency_parameter',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  deprecatedMemberUseFromSamePackageWithMessage = LinterLintTemplate(
    name: LintNames.deprecated_member_use_from_same_package,
    problemMessage: "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement, "
        "if a replacement is specified.",
    uniqueName: 'LintCode.deprecated_member_use_from_same_package_with_message',
    withArguments: _withArgumentsDeprecatedMemberUseFromSamePackageWithMessage,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  deprecatedMemberUseFromSamePackageWithoutMessage = LinterLintTemplate(
    name: LintNames.deprecated_member_use_from_same_package,
    problemMessage: "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement, "
        "if a replacement is specified.",
    uniqueName:
        'LintCode.deprecated_member_use_from_same_package_without_message',
    withArguments:
        _withArgumentsDeprecatedMemberUseFromSamePackageWithoutMessage,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  diagnosticDescribeAllProperties = LinterLintWithoutArguments(
    name: LintNames.diagnostic_describe_all_properties,
    problemMessage:
        "The public property isn't described by either 'debugFillProperties' or "
        "'debugDescribeChildren'.",
    correctionMessage: "Try describing the property.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.diagnostic_describe_all_properties',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments directivesOrderingAlphabetical =
      LinterLintWithoutArguments(
        name: LintNames.directives_ordering,
        problemMessage: "Sort directive sections alphabetically.",
        correctionMessage: "Try sorting the directives.",
        uniqueName: 'LintCode.directives_ordering_alphabetical',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  directivesOrderingDart = LinterLintTemplate(
    name: LintNames.directives_ordering,
    problemMessage: "Place 'dart:' {0} before other {0}.",
    correctionMessage: "Try sorting the directives.",
    uniqueName: 'LintCode.directives_ordering_dart',
    withArguments: _withArgumentsDirectivesOrderingDart,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments directivesOrderingExports =
      LinterLintWithoutArguments(
        name: LintNames.directives_ordering,
        problemMessage:
            "Specify exports in a separate section after all imports.",
        correctionMessage: "Try sorting the directives.",
        uniqueName: 'LintCode.directives_ordering_exports',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  directivesOrderingPackageBeforeRelative = LinterLintTemplate(
    name: LintNames.directives_ordering,
    problemMessage: "Place 'package:' {0} before relative {0}.",
    correctionMessage: "Try sorting the directives.",
    uniqueName: 'LintCode.directives_ordering_package_before_relative',
    withArguments: _withArgumentsDirectivesOrderingPackageBeforeRelative,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  discardedFutures = LinterLintWithoutArguments(
    name: LintNames.discarded_futures,
    problemMessage: "'Future'-returning calls in a non-'async' function.",
    correctionMessage:
        "Try converting the enclosing function to be 'async' and then 'await' "
        "the future, or wrap the expression in 'unawaited'.",
    uniqueName: 'LintCode.discarded_futures',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments documentIgnores =
      LinterLintWithoutArguments(
        name: LintNames.document_ignores,
        problemMessage:
            "Missing documentation explaining why the diagnostic is ignored.",
        correctionMessage:
            "Try adding a comment immediately above the ignore comment.",
        uniqueName: 'LintCode.document_ignores',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments doNotUseEnvironment =
      LinterLintWithoutArguments(
        name: LintNames.do_not_use_environment,
        problemMessage: "Invalid use of an environment declaration.",
        correctionMessage: "Try removing the environment declaration usage.",
        uniqueName: 'LintCode.do_not_use_environment',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  emptyCatches = LinterLintWithoutArguments(
    name: LintNames.empty_catches,
    problemMessage: "Empty catch block.",
    correctionMessage:
        "Try adding statements to the block, adding a comment to the block, or "
        "removing the 'catch' clause.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.empty_catches',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  emptyConstructorBodies = LinterLintWithoutArguments(
    name: LintNames.empty_constructor_bodies,
    problemMessage:
        "Empty constructor bodies should be written using a ';' rather than '{}'.",
    correctionMessage: "Try replacing the constructor body with ';'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.empty_constructor_bodies',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments emptyStatements =
      LinterLintWithoutArguments(
        name: LintNames.empty_statements,
        problemMessage: "Unnecessary empty statement.",
        correctionMessage:
            "Try removing the empty statement or restructuring the code.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.empty_statements',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments eolAtEndOfFile =
      LinterLintWithoutArguments(
        name: LintNames.eol_at_end_of_file,
        problemMessage: "Missing a newline at the end of the file.",
        correctionMessage: "Try adding a newline at the end of the file.",
        uniqueName: 'LintCode.eol_at_end_of_file',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  eraseDartTypeExtensionTypes = LinterLintWithoutArguments(
    name: LintNames.erase_dart_type_extension_types,
    problemMessage: "Unsafe use of 'DartType' in an 'is' check.",
    correctionMessage:
        "Ensure DartType extension types are erased by using a helper method.",
    uniqueName: 'LintCode.erase_dart_type_extension_types',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  exhaustiveCases = LinterLintTemplate(
    name: LintNames.exhaustive_cases,
    problemMessage: "Missing case clauses for some constants in '{0}'.",
    correctionMessage: "Try adding case clauses for the missing constants.",
    uniqueName: 'LintCode.exhaustive_cases',
    withArguments: _withArgumentsExhaustiveCases,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
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
    uniqueName: 'LintCode.file_names',
    withArguments: _withArgumentsFileNames,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments flutterStyleTodos =
      LinterLintWithoutArguments(
        name: LintNames.flutter_style_todos,
        problemMessage: "To-do comment doesn't follow the Flutter style.",
        correctionMessage:
            "Try following the Flutter style for to-do comments.",
        uniqueName: 'LintCode.flutter_style_todos',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  hashAndEquals = LinterLintTemplate(
    name: LintNames.hash_and_equals,
    problemMessage: "Missing a corresponding override of '{0}'.",
    correctionMessage: "Try overriding '{0}' or removing '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.hash_and_equals',
    withArguments: _withArgumentsHashAndEquals,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  implementationImports = LinterLintWithoutArguments(
    name: LintNames.implementation_imports,
    problemMessage:
        "Import of a library in the 'lib/src' directory of another package.",
    correctionMessage:
        "Try importing a public library that exports this library, or removing "
        "the import.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.implementation_imports',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments implicitCallTearoffs =
      LinterLintWithoutArguments(
        name: LintNames.implicit_call_tearoffs,
        problemMessage: "Implicit tear-off of the 'call' method.",
        correctionMessage: "Try explicitly tearing off the 'call' method.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.implicit_call_tearoffs',
        expectedTypes: [],
      );

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
  implicitReopen = LinterLintTemplate(
    name: LintNames.implicit_reopen,
    problemMessage:
        "The {0} '{1}' reopens '{2}' because it is not marked '{3}'.",
    correctionMessage:
        "Try marking '{1}' '{3}' or annotating it with '@reopen'.",
    uniqueName: 'LintCode.implicit_reopen',
    withArguments: _withArgumentsImplicitReopen,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments invalidCasePatterns =
      LinterLintWithoutArguments(
        name: LintNames.invalid_case_patterns,
        problemMessage:
            "This expression is not valid in a 'case' clause in Dart 3.0.",
        correctionMessage: "Try refactoring the expression to be valid in 3.0.",
        uniqueName: 'LintCode.invalid_case_patterns',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
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
    uniqueName:
        'LintCode.invalid_runtime_check_with_js_interop_types_dart_as_js',
    withArguments: _withArgumentsInvalidRuntimeCheckWithJsInteropTypesDartAsJs,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesDartIsJs = LinterLintTemplate(
    name: LintNames.invalid_runtime_check_with_js_interop_types,
    problemMessage:
        "Runtime check between '{0}' and '{1}' checks whether a Dart value is a JS "
        "interop type, which might not be platform-consistent.",
    uniqueName:
        'LintCode.invalid_runtime_check_with_js_interop_types_dart_is_js',
    withArguments: _withArgumentsInvalidRuntimeCheckWithJsInteropTypesDartIsJs,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
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
    uniqueName:
        'LintCode.invalid_runtime_check_with_js_interop_types_js_as_dart',
    withArguments: _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsAsDart,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs = LinterLintTemplate(
    name: LintNames.invalid_runtime_check_with_js_interop_types,
    problemMessage:
        "Cast from '{0}' to '{1}' casts a JS interop value to an incompatible JS "
        "interop type, which might not be platform-consistent.",
    uniqueName:
        'LintCode.invalid_runtime_check_with_js_interop_types_js_as_incompatible_js',
    withArguments:
        _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidRuntimeCheckWithJsInteropTypesJsIsDart = LinterLintTemplate(
    name: LintNames.invalid_runtime_check_with_js_interop_types,
    problemMessage:
        "Runtime check between '{0}' and '{1}' checks whether a JS interop value "
        "is a Dart type, which might not be platform-consistent.",
    uniqueName:
        'LintCode.invalid_runtime_check_with_js_interop_types_js_is_dart',
    withArguments: _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsDart,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
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
        'LintCode.invalid_runtime_check_with_js_interop_types_js_is_inconsistent_js',
    withArguments:
        _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
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
        'LintCode.invalid_runtime_check_with_js_interop_types_js_is_unrelated_js',
    withArguments:
        _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments joinReturnWithAssignment =
      LinterLintWithoutArguments(
        name: LintNames.join_return_with_assignment,
        problemMessage: "Assignment could be inlined in 'return' statement.",
        correctionMessage:
            "Try inlining the assigned value in the 'return' statement.",
        uniqueName: 'LintCode.join_return_with_assignment',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  leadingNewlinesInMultilineStrings = LinterLintWithoutArguments(
    name: LintNames.leading_newlines_in_multiline_strings,
    problemMessage: "Missing a newline at the beginning of a multiline string.",
    correctionMessage: "Try adding a newline at the beginning of the string.",
    uniqueName: 'LintCode.leading_newlines_in_multiline_strings',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments libraryAnnotations =
      LinterLintWithoutArguments(
        name: LintNames.library_annotations,
        problemMessage:
            "This annotation should be attached to a library directive.",
        correctionMessage:
            "Try attaching the annotation to a library directive.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.library_annotations',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
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
    uniqueName: 'LintCode.library_names',
    withArguments: _withArgumentsLibraryNames,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
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
    uniqueName: 'LintCode.library_prefixes',
    withArguments: _withArgumentsLibraryPrefixes,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  libraryPrivateTypesInPublicApi = LinterLintWithoutArguments(
    name: LintNames.library_private_types_in_public_api,
    problemMessage: "Invalid use of a private type in a public API.",
    correctionMessage:
        "Try making the private type public, or making the API that uses the "
        "private type also be private.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.library_private_types_in_public_api',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments linesLongerThan80Chars =
      LinterLintWithoutArguments(
        name: LintNames.lines_longer_than_80_chars,
        problemMessage: "The line length exceeds the 80-character limit.",
        correctionMessage: "Try breaking the line across multiple lines.",
        uniqueName: 'LintCode.lines_longer_than_80_chars',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments literalOnlyBooleanExpressions =
      LinterLintWithoutArguments(
        name: LintNames.literal_only_boolean_expressions,
        problemMessage: "The Boolean expression has a constant value.",
        correctionMessage: "Try changing the expression.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.literal_only_boolean_expressions',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
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
    uniqueName: 'LintCode.matching_super_parameters',
    withArguments: _withArgumentsMatchingSuperParameters,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments missingCodeBlockLanguageInDocComment =
      LinterLintWithoutArguments(
        name: LintNames.missing_code_block_language_in_doc_comment,
        problemMessage: "The code block is missing a specified language.",
        correctionMessage: "Try adding a language to the code block.",
        uniqueName: 'LintCode.missing_code_block_language_in_doc_comment',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  missingWhitespaceBetweenAdjacentStrings = LinterLintWithoutArguments(
    name: LintNames.missing_whitespace_between_adjacent_strings,
    problemMessage: "Missing whitespace between adjacent strings.",
    correctionMessage: "Try adding whitespace between the strings.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.missing_whitespace_between_adjacent_strings',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments noAdjacentStringsInList =
      LinterLintWithoutArguments(
        name: LintNames.no_adjacent_strings_in_list,
        problemMessage: "Don't use adjacent strings in a list literal.",
        correctionMessage: "Try adding a comma between the strings.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.no_adjacent_strings_in_list',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments noDefaultCases =
      LinterLintWithoutArguments(
        name: LintNames.no_default_cases,
        problemMessage: "Invalid use of 'default' member in a switch.",
        correctionMessage:
            "Try enumerating all the possible values of the switch expression.",
        uniqueName: 'LintCode.no_default_cases',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  noDuplicateCaseValues = LinterLintTemplate(
    name: LintNames.no_duplicate_case_values,
    problemMessage:
        "The value of the case clause ('{0}') is equal to the value of an earlier "
        "case clause ('{1}').",
    correctionMessage: "Try removing or changing the value.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.no_duplicate_case_values',
    withArguments: _withArgumentsNoDuplicateCaseValues,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  noLeadingUnderscoresForLibraryPrefixes = LinterLintTemplate(
    name: LintNames.no_leading_underscores_for_library_prefixes,
    problemMessage: "The library prefix '{0}' starts with an underscore.",
    correctionMessage:
        "Try renaming the prefix to not start with an underscore.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.no_leading_underscores_for_library_prefixes',
    withArguments: _withArgumentsNoLeadingUnderscoresForLibraryPrefixes,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  noLeadingUnderscoresForLocalIdentifiers = LinterLintTemplate(
    name: LintNames.no_leading_underscores_for_local_identifiers,
    problemMessage: "The local variable '{0}' starts with an underscore.",
    correctionMessage:
        "Try renaming the variable to not start with an underscore.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.no_leading_underscores_for_local_identifiers',
    withArguments: _withArgumentsNoLeadingUnderscoresForLocalIdentifiers,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  noLiteralBoolComparisons = LinterLintWithoutArguments(
    name: LintNames.no_literal_bool_comparisons,
    problemMessage: "Unnecessary comparison to a boolean literal.",
    correctionMessage:
        "Remove the comparison and use the negate `!` operator if necessary.",
    uniqueName: 'LintCode.no_literal_bool_comparisons',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments noLogicInCreateState =
      LinterLintWithoutArguments(
        name: LintNames.no_logic_in_create_state,
        problemMessage: "Don't put any logic in 'createState'.",
        correctionMessage: "Try moving the logic out of 'createState'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.no_logic_in_create_state',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  nonConstantIdentifierNames = LinterLintTemplate(
    name: LintNames.non_constant_identifier_names,
    problemMessage:
        "The variable name '{0}' isn't a lowerCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the lowerCamelCase style.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.non_constant_identifier_names',
    withArguments: _withArgumentsNonConstantIdentifierNames,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments noopPrimitiveOperations =
      LinterLintWithoutArguments(
        name: LintNames.noop_primitive_operations,
        problemMessage: "The expression has no effect and can be removed.",
        correctionMessage: "Try removing the expression.",
        uniqueName: 'LintCode.noop_primitive_operations',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments noRuntimetypeTostring =
      LinterLintWithoutArguments(
        name: LintNames.no_runtimeType_toString,
        problemMessage:
            "Using 'toString' on a 'Type' is not safe in production code.",
        correctionMessage:
            "Try removing the usage of 'toString' or restructuring the code.",
        uniqueName: 'LintCode.no_runtimeType_toString',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments noSelfAssignments =
      LinterLintWithoutArguments(
        name: LintNames.no_self_assignments,
        problemMessage: "The variable or property is being assigned to itself.",
        correctionMessage:
            "Try removing the assignment that has no direct effect.",
        uniqueName: 'LintCode.no_self_assignments',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments noSoloTests =
      LinterLintWithoutArguments(
        name: LintNames.no_solo_tests,
        problemMessage: "Don't commit soloed tests.",
        correctionMessage:
            "Try removing the 'soloTest' annotation or 'solo_' prefix.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.no_solo_tests',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments noTrailingSpaces =
      LinterLintWithoutArguments(
        name: LintNames.no_trailing_spaces,
        problemMessage:
            "Don't create string literals with trailing spaces in tests.",
        correctionMessage: "Try removing the trailing spaces.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.no_trailing_spaces',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments noWildcardVariableUses =
      LinterLintWithoutArguments(
        name: LintNames.no_wildcard_variable_uses,
        problemMessage: "The referenced identifier is a wildcard.",
        correctionMessage: "Use an identifier name that is not a wildcard.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.no_wildcard_variable_uses',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  nullCheckOnNullableTypeParameter = LinterLintWithoutArguments(
    name: LintNames.null_check_on_nullable_type_parameter,
    problemMessage:
        "The null check operator shouldn't be used on a variable whose type is a "
        "potentially nullable type parameter.",
    correctionMessage: "Try explicitly testing for 'null'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.null_check_on_nullable_type_parameter',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments nullClosures =
      LinterLintWithoutArguments(
        name: LintNames.null_closures,
        problemMessage: "Closure can't be 'null' because it might be invoked.",
        correctionMessage: "Try providing a non-null closure.",
        uniqueName: 'LintCode.null_closures',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments omitLocalVariableTypes =
      LinterLintWithoutArguments(
        name: LintNames.omit_local_variable_types,
        problemMessage: "Unnecessary type annotation on a local variable.",
        correctionMessage: "Try removing the type annotation.",
        uniqueName: 'LintCode.omit_local_variable_types',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  omitObviousLocalVariableTypes = LinterLintWithoutArguments(
    name: LintNames.omit_obvious_local_variable_types,
    problemMessage:
        "Omit the type annotation on a local variable when the type is obvious.",
    correctionMessage: "Try removing the type annotation.",
    uniqueName: 'LintCode.omit_obvious_local_variable_types',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments omitObviousPropertyTypes =
      LinterLintWithoutArguments(
        name: LintNames.omit_obvious_property_types,
        problemMessage:
            "The type annotation isn't needed because it is obvious.",
        correctionMessage: "Try removing the type annotation.",
        uniqueName: 'LintCode.omit_obvious_property_types',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  oneMemberAbstracts = LinterLintTemplate(
    name: LintNames.one_member_abstracts,
    problemMessage: "Unnecessary use of an abstract class.",
    correctionMessage:
        "Try making '{0}' a top-level function and removing the class.",
    uniqueName: 'LintCode.one_member_abstracts',
    withArguments: _withArgumentsOneMemberAbstracts,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  onlyThrowErrors = LinterLintWithoutArguments(
    name: LintNames.only_throw_errors,
    problemMessage:
        "Don't throw instances of classes that don't extend either 'Exception' or "
        "'Error'.",
    correctionMessage: "Try throwing a different class of object.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.only_throw_errors',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  overriddenFields = LinterLintTemplate(
    name: LintNames.overridden_fields,
    problemMessage: "Field overrides a field inherited from '{0}'.",
    correctionMessage:
        "Try removing the field, overriding the getter and setter if "
        "necessary.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.overridden_fields',
    withArguments: _withArgumentsOverriddenFields,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
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
    uniqueName: 'LintCode.package_names',
    withArguments: _withArgumentsPackageNames,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  packagePrefixedLibraryNames = LinterLintTemplate(
    name: LintNames.package_prefixed_library_names,
    problemMessage:
        "The library name is not a dot-separated path prefixed by the package "
        "name.",
    correctionMessage: "Try changing the name to '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.package_prefixed_library_names',
    withArguments: _withArgumentsPackagePrefixedLibraryNames,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  parameterAssignments = LinterLintTemplate(
    name: LintNames.parameter_assignments,
    problemMessage: "Invalid assignment to the parameter '{0}'.",
    correctionMessage: "Try using a local variable in place of the parameter.",
    uniqueName: 'LintCode.parameter_assignments',
    withArguments: _withArgumentsParameterAssignments,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments preferAdjacentStringConcatenation =
      LinterLintWithoutArguments(
        name: LintNames.prefer_adjacent_string_concatenation,
        problemMessage:
            "String literals shouldn't be concatenated by the '+' operator.",
        correctionMessage: "Try removing the operator to use adjacent strings.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_adjacent_string_concatenation',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferAssertsInInitializerLists =
      LinterLintWithoutArguments(
        name: LintNames.prefer_asserts_in_initializer_lists,
        problemMessage: "Assert should be in the initializer list.",
        correctionMessage: "Try moving the assert to the initializer list.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_asserts_in_initializer_lists',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferAssertsWithMessage =
      LinterLintWithoutArguments(
        name: LintNames.prefer_asserts_with_message,
        problemMessage: "Missing a message in an assert.",
        correctionMessage: "Try adding a message to the assert.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_asserts_with_message',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferCollectionLiterals =
      LinterLintWithoutArguments(
        name: LintNames.prefer_collection_literals,
        problemMessage: "Unnecessary constructor invocation.",
        correctionMessage: "Try using a collection literal.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_collection_literals',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferConditionalAssignment =
      LinterLintWithoutArguments(
        name: LintNames.prefer_conditional_assignment,
        problemMessage:
            "The 'if' statement could be replaced by a null-aware assignment.",
        correctionMessage:
            "Try using the '??=' operator to conditionally assign a value.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_conditional_assignment',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferConstConstructors =
      LinterLintWithoutArguments(
        name: LintNames.prefer_const_constructors,
        problemMessage:
            "Use 'const' with the constructor to improve performance.",
        correctionMessage:
            "Try adding the 'const' keyword to the constructor invocation.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_const_constructors',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferConstConstructorsInImmutables = LinterLintWithoutArguments(
    name: LintNames.prefer_const_constructors_in_immutables,
    problemMessage:
        "Constructors in '@immutable' classes should be declared as 'const'.",
    correctionMessage: "Try adding 'const' to the constructor declaration.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.prefer_const_constructors_in_immutables',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments preferConstDeclarations =
      LinterLintWithoutArguments(
        name: LintNames.prefer_const_declarations,
        problemMessage:
            "Use 'const' for final variables initialized to a constant value.",
        correctionMessage: "Try replacing 'final' with 'const'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_const_declarations',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferConstLiteralsToCreateImmutables = LinterLintWithoutArguments(
    name: LintNames.prefer_const_literals_to_create_immutables,
    problemMessage:
        "Use 'const' literals as arguments to constructors of '@immutable' "
        "classes.",
    correctionMessage: "Try adding 'const' before the literal.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.prefer_const_literals_to_create_immutables',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments preferConstructorsOverStaticMethods =
      LinterLintWithoutArguments(
        name: LintNames.prefer_constructors_over_static_methods,
        problemMessage: "Static method should be a constructor.",
        correctionMessage: "Try converting the method into a constructor.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_constructors_over_static_methods',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferContainsAlwaysFalse = LinterLintWithoutArguments(
    name: LintNames.prefer_contains,
    problemMessage:
        "Always 'false' because 'indexOf' is always greater than or equal to -1.",
    uniqueName: 'LintCode.prefer_contains_always_false',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferContainsAlwaysTrue = LinterLintWithoutArguments(
    name: LintNames.prefer_contains,
    problemMessage:
        "Always 'true' because 'indexOf' is always greater than or equal to -1.",
    uniqueName: 'LintCode.prefer_contains_always_true',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments preferContainsUseContains =
      LinterLintWithoutArguments(
        name: LintNames.prefer_contains,
        problemMessage: "Unnecessary use of 'indexOf' to test for containment.",
        correctionMessage: "Try using 'contains'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_contains_use_contains',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferDoubleQuotes =
      LinterLintWithoutArguments(
        name: LintNames.prefer_double_quotes,
        problemMessage: "Unnecessary use of single quotes.",
        correctionMessage:
            "Try using double quotes unless the string contains double quotes.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_double_quotes',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferExpressionFunctionBodies =
      LinterLintWithoutArguments(
        name: LintNames.prefer_expression_function_bodies,
        problemMessage: "Unnecessary use of a block function body.",
        correctionMessage: "Try using an expression function body.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_expression_function_bodies',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  preferFinalFields = LinterLintTemplate(
    name: LintNames.prefer_final_fields,
    problemMessage: "The private field {0} could be 'final'.",
    correctionMessage: "Try making the field 'final'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.prefer_final_fields',
    withArguments: _withArgumentsPreferFinalFields,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments preferFinalInForEachPattern =
      LinterLintWithoutArguments(
        name: LintNames.prefer_final_in_for_each,
        problemMessage: "The pattern should be final.",
        correctionMessage: "Try making the pattern final.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_final_in_for_each_pattern',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  preferFinalInForEachVariable = LinterLintTemplate(
    name: LintNames.prefer_final_in_for_each,
    problemMessage: "The variable '{0}' should be final.",
    correctionMessage: "Try making the variable final.",
    uniqueName: 'LintCode.prefer_final_in_for_each_variable',
    withArguments: _withArgumentsPreferFinalInForEachVariable,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments preferFinalLocals =
      LinterLintWithoutArguments(
        name: LintNames.prefer_final_locals,
        problemMessage: "Local variables should be final.",
        correctionMessage: "Try making the variable final.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_final_locals',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  preferFinalParameters = LinterLintTemplate(
    name: LintNames.prefer_final_parameters,
    problemMessage: "The parameter '{0}' should be final.",
    correctionMessage: "Try making the parameter final.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.prefer_final_parameters',
    withArguments: _withArgumentsPreferFinalParameters,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferForeach = LinterLintWithoutArguments(
    name: LintNames.prefer_foreach,
    problemMessage:
        "Use 'forEach' and a tear-off rather than a 'for' loop to apply a function "
        "to every element.",
    correctionMessage:
        "Try using 'forEach' and a tear-off rather than a 'for' loop.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.prefer_foreach',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments preferForElementsToMapFromiterable =
      LinterLintWithoutArguments(
        name: LintNames.prefer_for_elements_to_map_fromIterable,
        problemMessage: "Use 'for' elements when building maps from iterables.",
        correctionMessage:
            "Try using a collection literal with a 'for' element.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_for_elements_to_map_fromIterable',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferFunctionDeclarationsOverVariables = LinterLintWithoutArguments(
    name: LintNames.prefer_function_declarations_over_variables,
    problemMessage:
        "Use a function declaration rather than a variable assignment to bind a "
        "function to a name.",
    correctionMessage:
        "Try rewriting the closure assignment as a function declaration.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.prefer_function_declarations_over_variables',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  preferGenericFunctionTypeAliases = LinterLintTemplate(
    name: LintNames.prefer_generic_function_type_aliases,
    problemMessage: "Use the generic function type syntax in 'typedef's.",
    correctionMessage: "Try using the generic function type syntax ('{0}').",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.prefer_generic_function_type_aliases',
    withArguments: _withArgumentsPreferGenericFunctionTypeAliases,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferIfElementsToConditionalExpressions = LinterLintWithoutArguments(
    name: LintNames.prefer_if_elements_to_conditional_expressions,
    problemMessage: "Use an 'if' element to conditionally add elements.",
    correctionMessage:
        "Try using an 'if' element rather than a conditional expression.",
    uniqueName: 'LintCode.prefer_if_elements_to_conditional_expressions',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments preferIfNullOperators =
      LinterLintWithoutArguments(
        name: LintNames.prefer_if_null_operators,
        problemMessage:
            "Use the '??' operator rather than '?:' when testing for 'null'.",
        correctionMessage: "Try rewriting the code to use '??'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_if_null_operators',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  preferInitializingFormals = LinterLintTemplate(
    name: LintNames.prefer_initializing_formals,
    problemMessage:
        "Use an initializing formal to assign a parameter to a field.",
    correctionMessage:
        "Try using an initialing formal ('this.{0}') to initialize the field.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.prefer_initializing_formals',
    withArguments: _withArgumentsPreferInitializingFormals,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments preferInlinedAddsMultiple =
      LinterLintWithoutArguments(
        name: LintNames.prefer_inlined_adds,
        problemMessage: "The addition of multiple list items could be inlined.",
        correctionMessage: "Try adding the items to the list literal directly.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_inlined_adds_multiple',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferInlinedAddsSingle =
      LinterLintWithoutArguments(
        name: LintNames.prefer_inlined_adds,
        problemMessage: "The addition of a list item could be inlined.",
        correctionMessage: "Try adding the item to the list literal directly.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_inlined_adds_single',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferInterpolationToComposeStrings =
      LinterLintWithoutArguments(
        name: LintNames.prefer_interpolation_to_compose_strings,
        problemMessage: "Use interpolation to compose strings and values.",
        correctionMessage:
            "Try using string interpolation to build the composite string.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_interpolation_to_compose_strings',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferIntLiterals =
      LinterLintWithoutArguments(
        name: LintNames.prefer_int_literals,
        problemMessage: "Unnecessary use of a 'double' literal.",
        correctionMessage: "Try using an 'int' literal.",
        uniqueName: 'LintCode.prefer_int_literals',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferIsEmptyAlwaysFalse = LinterLintWithoutArguments(
    name: LintNames.prefer_is_empty,
    problemMessage:
        "The comparison is always 'false' because the length is always greater "
        "than or equal to 0.",
    uniqueName: 'LintCode.prefer_is_empty_always_false',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferIsEmptyAlwaysTrue = LinterLintWithoutArguments(
    name: LintNames.prefer_is_empty,
    problemMessage:
        "The comparison is always 'true' because the length is always greater than "
        "or equal to 0.",
    uniqueName: 'LintCode.prefer_is_empty_always_true',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferIsEmptyUseIsEmpty = LinterLintWithoutArguments(
    name: LintNames.prefer_is_empty,
    problemMessage:
        "Use 'isEmpty' instead of 'length' to test whether the collection is "
        "empty.",
    correctionMessage: "Try rewriting the expression to use 'isEmpty'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.prefer_is_empty_use_is_empty',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferIsEmptyUseIsNotEmpty = LinterLintWithoutArguments(
    name: LintNames.prefer_is_empty,
    problemMessage:
        "Use 'isNotEmpty' instead of 'length' to test whether the collection is "
        "empty.",
    correctionMessage: "Try rewriting the expression to use 'isNotEmpty'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.prefer_is_empty_use_is_not_empty',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments preferIsNotEmpty =
      LinterLintWithoutArguments(
        name: LintNames.prefer_is_not_empty,
        problemMessage:
            "Use 'isNotEmpty' rather than negating the result of 'isEmpty'.",
        correctionMessage: "Try rewriting the expression to use 'isNotEmpty'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_is_not_empty',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferIsNotOperator =
      LinterLintWithoutArguments(
        name: LintNames.prefer_is_not_operator,
        problemMessage:
            "Use the 'is!' operator rather than negating the value of the 'is' "
            "operator.",
        correctionMessage:
            "Try rewriting the condition to use the 'is!' operator.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_is_not_operator',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferIterableWheretype =
      LinterLintWithoutArguments(
        name: LintNames.prefer_iterable_whereType,
        problemMessage: "Use 'whereType' to select elements of a given type.",
        correctionMessage: "Try rewriting the expression to use 'whereType'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_iterable_whereType',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  preferMixin = LinterLintTemplate(
    name: LintNames.prefer_mixin,
    problemMessage: "Only mixins should be mixed in.",
    correctionMessage: "Try converting '{0}' to a mixin.",
    uniqueName: 'LintCode.prefer_mixin',
    withArguments: _withArgumentsPreferMixin,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferNullAwareMethodCalls = LinterLintWithoutArguments(
    name: LintNames.prefer_null_aware_method_calls,
    problemMessage:
        "Use a null-aware invocation of the 'call' method rather than explicitly "
        "testing for 'null'.",
    correctionMessage: "Try using '?.call()' to invoke the function.",
    uniqueName: 'LintCode.prefer_null_aware_method_calls',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments preferNullAwareOperators =
      LinterLintWithoutArguments(
        name: LintNames.prefer_null_aware_operators,
        problemMessage:
            "Use the null-aware operator '?.' rather than an explicit 'null' "
            "comparison.",
        correctionMessage: "Try using '?.'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_null_aware_operators',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferRelativeImports =
      LinterLintWithoutArguments(
        name: LintNames.prefer_relative_imports,
        problemMessage:
            "Use relative imports for files in the 'lib' directory.",
        correctionMessage: "Try converting the URI to a relative URI.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_relative_imports',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferSingleQuotes =
      LinterLintWithoutArguments(
        name: LintNames.prefer_single_quotes,
        problemMessage: "Unnecessary use of double quotes.",
        correctionMessage:
            "Try using single quotes unless the string contains single quotes.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_single_quotes',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferSpreadCollections =
      LinterLintWithoutArguments(
        name: LintNames.prefer_spread_collections,
        problemMessage: "The addition of multiple elements could be inlined.",
        correctionMessage:
            "Try using the spread operator ('...') to inline the addition.",
        uniqueName: 'LintCode.prefer_spread_collections',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferTypingUninitializedVariablesForField = LinterLintWithoutArguments(
    name: LintNames.prefer_typing_uninitialized_variables,
    problemMessage:
        "An uninitialized field should have an explicit type annotation.",
    correctionMessage: "Try adding a type annotation.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.prefer_typing_uninitialized_variables_for_field',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  preferTypingUninitializedVariablesForLocalVariable =
      LinterLintWithoutArguments(
        name: LintNames.prefer_typing_uninitialized_variables,
        problemMessage:
            "An uninitialized variable should have an explicit type annotation.",
        correctionMessage: "Try adding a type annotation.",
        hasPublishedDocs: true,
        uniqueName:
            'LintCode.prefer_typing_uninitialized_variables_for_local_variable',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments preferVoidToNull =
      LinterLintWithoutArguments(
        name: LintNames.prefer_void_to_null,
        problemMessage: "Unnecessary use of the type 'Null'.",
        correctionMessage: "Try using 'void' instead.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.prefer_void_to_null',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments provideDeprecationMessage =
      LinterLintWithoutArguments(
        name: LintNames.provide_deprecation_message,
        problemMessage: "Missing a deprecation message.",
        correctionMessage:
            "Try using the constructor to provide a message "
            "('@Deprecated(\"message\")').",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.provide_deprecation_message',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments publicMemberApiDocs =
      LinterLintWithoutArguments(
        name: LintNames.public_member_api_docs,
        problemMessage: "Missing documentation for a public member.",
        correctionMessage: "Try adding documentation for the member.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.public_member_api_docs',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  recursiveGetters = LinterLintTemplate(
    name: LintNames.recursive_getters,
    problemMessage: "The getter '{0}' recursively returns itself.",
    correctionMessage: "Try changing the value being returned.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.recursive_getters',
    withArguments: _withArgumentsRecursiveGetters,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments removeDeprecationsInBreakingVersions =
      LinterLintWithoutArguments(
        name: LintNames.remove_deprecations_in_breaking_versions,
        problemMessage: "Remove deprecated elements in breaking versions.",
        correctionMessage: "Try removing the deprecated element.",
        uniqueName: 'LintCode.remove_deprecations_in_breaking_versions',
        expectedTypes: [],
      );

  /// A lint code that removed lints can specify as their `lintCode`.
  ///
  /// Avoid other usages as it should be made unnecessary and removed.
  static const LintCode removedLint = LinterLintCode.internal(
    name: 'removed_lint',
    problemMessage: 'Removed lint.',
    expectedTypes: [],
    uniqueName: 'LintCode.removed_lint',
  );

  /// No parameters.
  static const DiagnosticWithoutArguments requireTrailingCommas =
      LinterLintWithoutArguments(
        name: LintNames.require_trailing_commas,
        problemMessage: "Missing a required trailing comma.",
        correctionMessage: "Try adding a trailing comma.",
        uniqueName: 'LintCode.require_trailing_commas',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  securePubspecUrls = LinterLintTemplate(
    name: LintNames.secure_pubspec_urls,
    problemMessage:
        "The '{0}' protocol shouldn't be used because it isn't secure.",
    correctionMessage: "Try using a secure protocol, such as 'https'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.secure_pubspec_urls',
    withArguments: _withArgumentsSecurePubspecUrls,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments sizedBoxForWhitespace =
      LinterLintWithoutArguments(
        name: LintNames.sized_box_for_whitespace,
        problemMessage: "Use a 'SizedBox' to add whitespace to a layout.",
        correctionMessage: "Try using a 'SizedBox' rather than a 'Container'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.sized_box_for_whitespace',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
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
    uniqueName: 'LintCode.sized_box_shrink_expand',
    withArguments: _withArgumentsSizedBoxShrinkExpand,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments slashForDocComments =
      LinterLintWithoutArguments(
        name: LintNames.slash_for_doc_comments,
        problemMessage: "Use the end-of-line form ('///') for doc comments.",
        correctionMessage: "Try rewriting the comment to use '///'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.slash_for_doc_comments',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  sortChildPropertiesLast = LinterLintTemplate(
    name: LintNames.sort_child_properties_last,
    problemMessage:
        "The '{0}' argument should be last in widget constructor invocations.",
    correctionMessage:
        "Try moving the argument to the end of the argument list.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.sort_child_properties_last',
    withArguments: _withArgumentsSortChildPropertiesLast,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  sortConstructorsFirst = LinterLintWithoutArguments(
    name: LintNames.sort_constructors_first,
    problemMessage:
        "Constructor declarations should be before non-constructor declarations.",
    correctionMessage:
        "Try moving the constructor declaration before all other members.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.sort_constructors_first',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments sortPubDependencies =
      LinterLintWithoutArguments(
        name: LintNames.sort_pub_dependencies,
        problemMessage: "Dependencies not sorted alphabetically.",
        correctionMessage:
            "Try sorting the dependencies alphabetically (A to Z).",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.sort_pub_dependencies',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments sortUnnamedConstructorsFirst =
      LinterLintWithoutArguments(
        name: LintNames.sort_unnamed_constructors_first,
        problemMessage: "Invalid location for the unnamed constructor.",
        correctionMessage:
            "Try moving the unnamed constructor before all other constructors.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.sort_unnamed_constructors_first',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  specifyNonobviousLocalVariableTypes = LinterLintWithoutArguments(
    name: LintNames.specify_nonobvious_local_variable_types,
    problemMessage:
        "Specify the type of a local variable when the type is non-obvious.",
    correctionMessage: "Try adding a type annotation.",
    uniqueName: 'LintCode.specify_nonobvious_local_variable_types',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments specifyNonobviousPropertyTypes =
      LinterLintWithoutArguments(
        name: LintNames.specify_nonobvious_property_types,
        problemMessage: "A type annotation is needed because it isn't obvious.",
        correctionMessage: "Try adding a type annotation.",
        uniqueName: 'LintCode.specify_nonobvious_property_types',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments strictTopLevelInferenceAddType =
      LinterLintWithoutArguments(
        name: LintNames.strict_top_level_inference,
        problemMessage: "Missing type annotation.",
        correctionMessage: "Try adding a type annotation.",
        uniqueName: 'LintCode.strict_top_level_inference_add_type',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  strictTopLevelInferenceReplaceKeyword = LinterLintTemplate(
    name: LintNames.strict_top_level_inference,
    problemMessage: "Missing type annotation.",
    correctionMessage: "Try replacing '{0}' with a type annotation.",
    uniqueName: 'LintCode.strict_top_level_inference_replace_keyword',
    withArguments: _withArgumentsStrictTopLevelInferenceReplaceKeyword,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments strictTopLevelInferenceSplitToTypes =
      LinterLintWithoutArguments(
        name: LintNames.strict_top_level_inference,
        problemMessage: "Missing type annotation.",
        correctionMessage:
            "Try splitting the declaration and specify the different type "
            "annotations.",
        uniqueName: 'LintCode.strict_top_level_inference_split_to_types',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments switchOnType =
      LinterLintWithoutArguments(
        name: LintNames.switch_on_type,
        problemMessage: "Avoid switch statements on a 'Type'.",
        correctionMessage: "Try using pattern matching on a variable instead.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.switch_on_type',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  testTypesInEquals = LinterLintTemplate(
    name: LintNames.test_types_in_equals,
    problemMessage: "Missing type test for '{0}' in '=='.",
    correctionMessage: "Try testing the type of '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.test_types_in_equals',
    withArguments: _withArgumentsTestTypesInEquals,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  throwInFinally = LinterLintTemplate(
    name: LintNames.throw_in_finally,
    problemMessage: "Use of '{0}' in 'finally' block.",
    correctionMessage: "Try moving the '{0}' outside the 'finally' block.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.throw_in_finally',
    withArguments: _withArgumentsThrowInFinally,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  tightenTypeOfInitializingFormals = LinterLintWithoutArguments(
    name: LintNames.tighten_type_of_initializing_formals,
    problemMessage:
        "Use a type annotation rather than 'assert' to enforce non-nullability.",
    correctionMessage:
        "Try adding a type annotation and removing the 'assert'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.tighten_type_of_initializing_formals',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments typeAnnotatePublicApis =
      LinterLintWithoutArguments(
        name: LintNames.type_annotate_public_apis,
        problemMessage: "Missing type annotation on a public API.",
        correctionMessage: "Try adding a type annotation.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.type_annotate_public_apis',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments typeInitFormals =
      LinterLintWithoutArguments(
        name: LintNames.type_init_formals,
        problemMessage: "Don't needlessly type annotate initializing formals.",
        correctionMessage: "Try removing the type.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.type_init_formals',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments typeLiteralInConstantPattern =
      LinterLintWithoutArguments(
        name: LintNames.type_literal_in_constant_pattern,
        problemMessage: "Use 'TypeName _' instead of a type literal.",
        correctionMessage: "Replace with 'TypeName _'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.type_literal_in_constant_pattern',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  unawaitedFutures = LinterLintWithoutArguments(
    name: LintNames.unawaited_futures,
    problemMessage:
        "Missing an 'await' for the 'Future' computed by this expression.",
    correctionMessage:
        "Try adding an 'await' or wrapping the expression with 'unawaited'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.unawaited_futures',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  unintendedHtmlInDocComment = LinterLintWithoutArguments(
    name: LintNames.unintended_html_in_doc_comment,
    problemMessage: "Angle brackets will be interpreted as HTML.",
    correctionMessage:
        "Try using backticks around the content with angle brackets, or try "
        "replacing `<` with `&lt;` and `>` with `&gt;`.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.unintended_html_in_doc_comment',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryAsync =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_async,
        problemMessage:
            "Don't make a function 'async' if it doesn't use 'await'.",
        correctionMessage: "Try removing the 'async' modifier.",
        uniqueName: 'LintCode.unnecessary_async',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryAwaitInReturn =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_await_in_return,
        problemMessage: "Unnecessary 'await'.",
        correctionMessage: "Try removing the 'await'.",
        uniqueName: 'LintCode.unnecessary_await_in_return',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryBraceInStringInterps =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_brace_in_string_interps,
        problemMessage: "Unnecessary braces in a string interpolation.",
        correctionMessage: "Try removing the braces.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_brace_in_string_interps',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryBreaks =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_breaks,
        problemMessage: "Unnecessary 'break' statement.",
        correctionMessage: "Try removing the 'break'.",
        uniqueName: 'LintCode.unnecessary_breaks',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryConst =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_const,
        problemMessage: "Unnecessary 'const' keyword.",
        correctionMessage: "Try removing the keyword.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_const',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryConstructorName =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_constructor_name,
        problemMessage: "Unnecessary '.new' constructor name.",
        correctionMessage: "Try removing the '.new'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_constructor_name',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryFinalWithoutType =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_final,
        problemMessage: "Local variables should not be marked as 'final'.",
        correctionMessage: "Replace 'final' with 'var'.",
        uniqueName: 'LintCode.unnecessary_final_without_type',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryFinalWithType =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_final,
        problemMessage: "Local variables should not be marked as 'final'.",
        correctionMessage: "Remove the 'final'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_final_with_type',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryGettersSetters =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_getters_setters,
        problemMessage: "Unnecessary use of getter and setter to wrap a field.",
        correctionMessage:
            "Try removing the getter and setter and renaming the field.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_getters_setters',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unnecessaryIgnore = LinterLintTemplate(
    name: LintNames.unnecessary_ignore,
    problemMessage:
        "The diagnostic '{0}' isn't produced at this location so it doesn't need "
        "to be ignored.",
    correctionMessage: "Try removing the ignore comment.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.unnecessary_ignore',
    withArguments: _withArgumentsUnnecessaryIgnore,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unnecessaryIgnoreFile = LinterLintTemplate(
    name: LintNames.unnecessary_ignore,
    problemMessage:
        "The diagnostic '{0}' isn't produced in this file so it doesn't need to be "
        "ignored.",
    correctionMessage: "Try removing the ignore comment.",
    uniqueName: 'LintCode.unnecessary_ignore_file',
    withArguments: _withArgumentsUnnecessaryIgnoreFile,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unnecessaryIgnoreName = LinterLintTemplate(
    name: LintNames.unnecessary_ignore,
    problemMessage:
        "The diagnostic '{0}' isn't produced at this location so it doesn't need "
        "to be ignored.",
    correctionMessage: "Try removing the name from the list.",
    uniqueName: 'LintCode.unnecessary_ignore_name',
    withArguments: _withArgumentsUnnecessaryIgnoreName,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unnecessaryIgnoreNameFile = LinterLintTemplate(
    name: LintNames.unnecessary_ignore,
    problemMessage:
        "The diagnostic '{0}' isn't produced in this file so it doesn't need to be "
        "ignored.",
    correctionMessage: "Try removing the name from the list.",
    uniqueName: 'LintCode.unnecessary_ignore_name_file',
    withArguments: _withArgumentsUnnecessaryIgnoreNameFile,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryLambdas =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_lambdas,
        problemMessage: "Closure should be a tearoff.",
        correctionMessage: "Try using a tearoff rather than a closure.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_lambdas',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryLate =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_late,
        problemMessage: "Unnecessary 'late' modifier.",
        correctionMessage: "Try removing the 'late'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_late',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  unnecessaryLibraryDirective = LinterLintWithoutArguments(
    name: LintNames.unnecessary_library_directive,
    problemMessage:
        "Library directives without comments or annotations should be avoided.",
    correctionMessage: "Try deleting the library directive.",
    uniqueName: 'LintCode.unnecessary_library_directive',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryLibraryName =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_library_name,
        problemMessage: "Library names are not necessary.",
        correctionMessage: "Remove the library name.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_library_name',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryNew =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_new,
        problemMessage: "Unnecessary 'new' keyword.",
        correctionMessage: "Try removing the 'new' keyword.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_new',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  unnecessaryNullableForFinalVariableDeclarations = LinterLintWithoutArguments(
    name: LintNames.unnecessary_nullable_for_final_variable_declarations,
    problemMessage: "Type could be non-nullable.",
    correctionMessage: "Try changing the type to be non-nullable.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.unnecessary_nullable_for_final_variable_declarations',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryNullAwareAssignments =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_null_aware_assignments,
        problemMessage: "Unnecessary assignment of 'null'.",
        correctionMessage: "Try removing the assignment.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_null_aware_assignments',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  unnecessaryNullAwareOperatorOnExtensionOnNullable = LinterLintWithoutArguments(
    name: LintNames.unnecessary_null_aware_operator_on_extension_on_nullable,
    problemMessage:
        "Unnecessary use of a null-aware operator to invoke an extension method on "
        "a nullable type.",
    correctionMessage: "Try removing the '?'.",
    hasPublishedDocs: true,
    uniqueName:
        'LintCode.unnecessary_null_aware_operator_on_extension_on_nullable',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryNullChecks =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_null_checks,
        problemMessage: "Unnecessary use of a null check ('!').",
        correctionMessage: "Try removing the null check.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_null_checks',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryNullInIfNullOperators =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_null_in_if_null_operators,
        problemMessage: "Unnecessary use of '??' with 'null'.",
        correctionMessage:
            "Try removing the '??' operator and the 'null' operand.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_null_in_if_null_operators',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryOverrides =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_overrides,
        problemMessage: "Unnecessary override.",
        correctionMessage:
            "Try adding behavior in the overriding member or removing the "
            "override.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_overrides',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryParenthesis =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_parenthesis,
        problemMessage: "Unnecessary use of parentheses.",
        correctionMessage: "Try removing the parentheses.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_parenthesis',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryRawStrings =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_raw_strings,
        problemMessage: "Unnecessary use of a raw string.",
        correctionMessage: "Try using a normal string.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_raw_strings',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryStatements =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_statements,
        problemMessage: "Unnecessary statement.",
        correctionMessage: "Try completing the statement or breaking it up.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_statements',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryStringEscapes =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_string_escapes,
        problemMessage: "Unnecessary escape in string literal.",
        correctionMessage: "Remove the '\\' escape.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_string_escapes',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryStringInterpolations =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_string_interpolations,
        problemMessage: "Unnecessary use of string interpolation.",
        correctionMessage:
            "Try replacing the string literal with the variable name.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_string_interpolations',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryThis =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_this,
        problemMessage: "Unnecessary 'this.' qualifier.",
        correctionMessage: "Try removing 'this.'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_this',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryToListInSpreads =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_to_list_in_spreads,
        problemMessage: "Unnecessary use of 'toList' in a spread.",
        correctionMessage: "Try removing the invocation of 'toList'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_to_list_in_spreads',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryUnawaited =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_unawaited,
        problemMessage: "Unnecessary use of 'unawaited'.",
        correctionMessage:
            "Try removing the use of 'unawaited', as the unawaited element is "
            "annotated with '@awaitNotRequired'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_unawaited',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments unnecessaryUnderscores =
      LinterLintWithoutArguments(
        name: LintNames.unnecessary_underscores,
        problemMessage: "Unnecessary use of multiple underscores.",
        correctionMessage: "Try using '_'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.unnecessary_underscores',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unreachableFromMain = LinterLintTemplate(
    name: LintNames.unreachable_from_main,
    problemMessage: "Unreachable member '{0}' in an executable library.",
    correctionMessage: "Try referencing the member or removing it.",
    uniqueName: 'LintCode.unreachable_from_main',
    withArguments: _withArgumentsUnreachableFromMain,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  unrelatedTypeEqualityChecksInExpression = LinterLintTemplate(
    name: LintNames.unrelated_type_equality_checks,
    problemMessage:
        "The type of the right operand ('{0}') isn't a subtype or a supertype of "
        "the left operand ('{1}').",
    correctionMessage: "Try changing one or both of the operands.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.unrelated_type_equality_checks_in_expression',
    withArguments: _withArgumentsUnrelatedTypeEqualityChecksInExpression,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  unrelatedTypeEqualityChecksInPattern = LinterLintTemplate(
    name: LintNames.unrelated_type_equality_checks,
    problemMessage:
        "The type of the operand ('{0}') isn't a subtype or a supertype of the "
        "value being matched ('{1}').",
    correctionMessage: "Try changing one or both of the operands.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.unrelated_type_equality_checks_in_pattern',
    withArguments: _withArgumentsUnrelatedTypeEqualityChecksInPattern,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  unsafeVariance = LinterLintWithoutArguments(
    name: LintNames.unsafe_variance,
    problemMessage:
        "This type is unsafe: a type parameter occurs in a non-covariant position.",
    correctionMessage:
        "Try using a more general type that doesn't contain any type "
        "parameters in such a position.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.unsafe_variance',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  useBuildContextSynchronouslyAsyncUse = LinterLintWithoutArguments(
    name: LintNames.use_build_context_synchronously,
    problemMessage: "Don't use 'BuildContext's across async gaps.",
    correctionMessage:
        "Try rewriting the code to not use the 'BuildContext', or guard the "
        "use with a 'mounted' check.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.use_build_context_synchronously_async_use',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  useBuildContextSynchronouslyWrongMounted = LinterLintWithoutArguments(
    name: LintNames.use_build_context_synchronously,
    problemMessage:
        "Don't use 'BuildContext's across async gaps, guarded by an unrelated "
        "'mounted' check.",
    correctionMessage:
        "Guard a 'State.context' use with a 'mounted' check on the State, and "
        "other BuildContext use with a 'mounted' check on the BuildContext.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.use_build_context_synchronously_wrong_mounted',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments useColoredBox =
      LinterLintWithoutArguments(
        name: LintNames.use_colored_box,
        problemMessage:
            "Use a 'ColoredBox' rather than a 'Container' with only a 'Color'.",
        correctionMessage: "Try replacing the 'Container' with a 'ColoredBox'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.use_colored_box',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  useDecoratedBox = LinterLintWithoutArguments(
    name: LintNames.use_decorated_box,
    problemMessage:
        "Use 'DecoratedBox' rather than a 'Container' with only a 'Decoration'.",
    correctionMessage: "Try replacing the 'Container' with a 'DecoratedBox'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.use_decorated_box',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments useEnums = LinterLintWithoutArguments(
    name: LintNames.use_enums,
    problemMessage: "Class should be an enum.",
    correctionMessage: "Try using an enum rather than a class.",
    uniqueName: 'LintCode.use_enums',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  useFullHexValuesForFlutterColors = LinterLintWithoutArguments(
    name: LintNames.use_full_hex_values_for_flutter_colors,
    problemMessage:
        "Instances of 'Color' should be created using an 8-digit hexadecimal "
        "integer (such as '0xFFFFFFFF').",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.use_full_hex_values_for_flutter_colors',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  useFunctionTypeSyntaxForParameters = LinterLintTemplate(
    name: LintNames.use_function_type_syntax_for_parameters,
    problemMessage:
        "Use the generic function type syntax to declare the parameter '{0}'.",
    correctionMessage: "Try using the generic function type syntax.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.use_function_type_syntax_for_parameters',
    withArguments: _withArgumentsUseFunctionTypeSyntaxForParameters,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments useIfNullToConvertNullsToBools =
      LinterLintWithoutArguments(
        name: LintNames.use_if_null_to_convert_nulls_to_bools,
        problemMessage:
            "Use an if-null operator to convert a 'null' to a 'bool'.",
        correctionMessage: "Try using an if-null operator.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.use_if_null_to_convert_nulls_to_bools',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  useIsEvenRatherThanModulo = LinterLintTemplate(
    name: LintNames.use_is_even_rather_than_modulo,
    problemMessage: "Use '{0}' rather than '% 2'.",
    correctionMessage: "Try using '{0}'.",
    uniqueName: 'LintCode.use_is_even_rather_than_modulo',
    withArguments: _withArgumentsUseIsEvenRatherThanModulo,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  useKeyInWidgetConstructors = LinterLintWithoutArguments(
    name: LintNames.use_key_in_widget_constructors,
    problemMessage:
        "Constructors for public widgets should have a named 'key' parameter.",
    correctionMessage: "Try adding a named parameter to the constructor.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.use_key_in_widget_constructors',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments useLateForPrivateFieldsAndVariables =
      LinterLintWithoutArguments(
        name: LintNames.use_late_for_private_fields_and_variables,
        problemMessage:
            "Use 'late' for private members with a non-nullable type.",
        correctionMessage: "Try making adding the modifier 'late'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.use_late_for_private_fields_and_variables',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  useNamedConstants = LinterLintTemplate(
    name: LintNames.use_named_constants,
    problemMessage:
        "Use the constant '{0}' rather than a constructor returning the same "
        "object.",
    correctionMessage: "Try using '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.use_named_constants',
    withArguments: _withArgumentsUseNamedConstants,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  useNullAwareElements = LinterLintWithoutArguments(
    name: LintNames.use_null_aware_elements,
    problemMessage:
        "Use the null-aware marker '?' rather than a null check via an 'if'.",
    correctionMessage: "Try using '?'.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.use_null_aware_elements',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments useRawStrings =
      LinterLintWithoutArguments(
        name: LintNames.use_raw_strings,
        problemMessage: "Use a raw string to avoid using escapes.",
        correctionMessage:
            "Try making the string a raw string and removing the escapes.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.use_raw_strings',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments useRethrowWhenPossible =
      LinterLintWithoutArguments(
        name: LintNames.use_rethrow_when_possible,
        problemMessage: "Use 'rethrow' to rethrow a caught exception.",
        correctionMessage: "Try replacing the 'throw' with a 'rethrow'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.use_rethrow_when_possible',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments useSettersToChangeProperties =
      LinterLintWithoutArguments(
        name: LintNames.use_setters_to_change_properties,
        problemMessage: "The method is used to change a property.",
        correctionMessage: "Try converting the method to a setter.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.use_setters_to_change_properties',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments
  useStringBuffers = LinterLintWithoutArguments(
    name: LintNames.use_string_buffers,
    problemMessage: "Use a string buffer rather than '+' to compose strings.",
    correctionMessage: "Try writing the parts of a string to a string buffer.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.use_string_buffers',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments useStringInPartOfDirectives =
      LinterLintWithoutArguments(
        name: LintNames.use_string_in_part_of_directives,
        problemMessage: "The part-of directive uses a library name.",
        correctionMessage:
            "Try converting the directive to use the URI of the library.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.use_string_in_part_of_directives',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  useSuperParametersMultiple = LinterLintTemplate(
    name: LintNames.use_super_parameters,
    problemMessage: "Parameters '{0}' could be super parameters.",
    correctionMessage: "Trying converting '{0}' to super parameters.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.use_super_parameters_multiple',
    withArguments: _withArgumentsUseSuperParametersMultiple,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: undocumented
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  useSuperParametersSingle = LinterLintTemplate(
    name: LintNames.use_super_parameters,
    problemMessage: "Parameter '{0}' could be a super parameter.",
    correctionMessage: "Trying converting '{0}' to a super parameter.",
    hasPublishedDocs: true,
    uniqueName: 'LintCode.use_super_parameters_single',
    withArguments: _withArgumentsUseSuperParametersSingle,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  useTestThrowsMatchers = LinterLintWithoutArguments(
    name: LintNames.use_test_throws_matchers,
    problemMessage:
        "Use the 'throwsA' matcher instead of using 'fail' when there is no "
        "exception thrown.",
    correctionMessage:
        "Try removing the try-catch and using 'throwsA' to expect an "
        "exception.",
    uniqueName: 'LintCode.use_test_throws_matchers',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments useToAndAsIfApplicable =
      LinterLintWithoutArguments(
        name: LintNames.use_to_and_as_if_applicable,
        problemMessage: "Start the name of the method with 'to' or 'as'.",
        correctionMessage:
            "Try renaming the method to use either 'to' or 'as'.",
        uniqueName: 'LintCode.use_to_and_as_if_applicable',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments useTruncatingDivision =
      LinterLintWithoutArguments(
        name: LintNames.use_truncating_division,
        problemMessage: "Use truncating division.",
        correctionMessage:
            "Try using truncating division, '~/', instead of regular division "
            "('/') followed by 'toInt()'.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.use_truncating_division',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments validRegexps =
      LinterLintWithoutArguments(
        name: LintNames.valid_regexps,
        problemMessage: "Invalid regular expression syntax.",
        correctionMessage: "Try correcting the regular expression.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.valid_regexps',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments visitRegisteredNodes =
      LinterLintWithoutArguments(
        name: LintNames.visit_registered_nodes,
        problemMessage:
            "Declare 'visit' methods for all registered node types.",
        correctionMessage:
            "Try declaring a 'visit' method for all registered node types.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.visit_registered_nodes',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments voidChecks =
      LinterLintWithoutArguments(
        name: LintNames.void_checks,
        problemMessage: "Assignment to a variable of type 'void'.",
        correctionMessage:
            "Try removing the assignment or changing the type of the variable.",
        hasPublishedDocs: true,
        uniqueName: 'LintCode.void_checks',
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
  }) : super.internal();
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
  }) : super.internal();
}
