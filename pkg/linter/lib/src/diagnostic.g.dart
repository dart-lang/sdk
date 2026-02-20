// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// Code generation is easier if we don't have to decide whether to generate an
// expression function body or a block function body.
// ignore_for_file: prefer_expression_function_bodies

// Code generation is easier using double quotes (since we can use json.convert
// to quote strings).
// ignore_for_file: prefer_single_quotes

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:linter/src/diagnostic.dart";

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
alwaysDeclareReturnTypesOfFunctions = LinterLintTemplate(
  name: 'always_declare_return_types',
  problemMessage: "The function '{0}' should have a return type but doesn't.",
  correctionMessage: "Try adding a return type to the function.",
  hasPublishedDocs: true,
  uniqueName: 'always_declare_return_types_of_functions',
  withArguments: _withArgumentsAlwaysDeclareReturnTypesOfFunctions,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
alwaysDeclareReturnTypesOfMethods = LinterLintTemplate(
  name: 'always_declare_return_types',
  problemMessage: "The method '{0}' should have a return type but doesn't.",
  correctionMessage: "Try adding a return type to the method.",
  hasPublishedDocs: true,
  uniqueName: 'always_declare_return_types_of_methods',
  withArguments: _withArgumentsAlwaysDeclareReturnTypesOfMethods,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments alwaysPutControlBodyOnNewLine =
    LinterLintWithoutArguments(
      name: 'always_put_control_body_on_new_line',
      problemMessage: "Statement should be on a separate line.",
      correctionMessage: "Try moving the statement to a new line.",
      hasPublishedDocs: true,
      uniqueName: 'always_put_control_body_on_new_line',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments
alwaysPutRequiredNamedParametersFirst = LinterLintWithoutArguments(
  name: 'always_put_required_named_parameters_first',
  problemMessage:
      "Required named parameters should be before optional named parameters.",
  correctionMessage:
      "Try moving the required named parameter to be before any optional "
      "named parameters.",
  hasPublishedDocs: true,
  uniqueName: 'always_put_required_named_parameters_first',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments alwaysRequireNonNullNamedParameters =
    LinterLintWithoutArguments(
      name: 'always_require_non_null_named_parameters',
      problemMessage: "",
      uniqueName: 'always_require_non_null_named_parameters',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments alwaysSpecifyTypesAddType =
    LinterLintWithoutArguments(
      name: 'always_specify_types',
      problemMessage: "Missing type annotation.",
      correctionMessage: "Try adding a type annotation.",
      uniqueName: 'always_specify_types_add_type',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
/// Object p1: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
alwaysSpecifyTypesReplaceKeyword = LinterLintTemplate(
  name: 'always_specify_types',
  problemMessage: "Missing type annotation.",
  correctionMessage: "Try replacing '{0}' with '{1}'.",
  uniqueName: 'always_specify_types_replace_keyword',
  withArguments: _withArgumentsAlwaysSpecifyTypesReplaceKeyword,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
alwaysSpecifyTypesSpecifyType = LinterLintTemplate(
  name: 'always_specify_types',
  problemMessage: "Missing type annotation.",
  correctionMessage: "Try specifying the type '{0}'.",
  uniqueName: 'always_specify_types_specify_type',
  withArguments: _withArgumentsAlwaysSpecifyTypesSpecifyType,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments alwaysSpecifyTypesSplitToTypes =
    LinterLintWithoutArguments(
      name: 'always_specify_types',
      problemMessage: "Missing type annotation.",
      correctionMessage:
          "Try splitting the declaration and specify the different type "
          "annotations.",
      uniqueName: 'always_specify_types_split_to_types',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments alwaysUsePackageImports =
    LinterLintWithoutArguments(
      name: 'always_use_package_imports',
      problemMessage:
          "Use 'package:' imports for files in the 'lib' directory.",
      correctionMessage: "Try converting the URI to a 'package:' URI.",
      hasPublishedDocs: true,
      uniqueName: 'always_use_package_imports',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments analyzerElementModelTrackingBad =
    LinterLintWithoutArguments(
      name: 'analyzer_element_model_tracking_bad',
      problemMessage: "Bad tracking annotation for this member.",
      uniqueName: 'analyzer_element_model_tracking_bad',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments analyzerElementModelTrackingMoreThanOne =
    LinterLintWithoutArguments(
      name: 'analyzer_element_model_tracking_more_than_one',
      problemMessage: "There can be only one tracking annotation.",
      uniqueName: 'analyzer_element_model_tracking_more_than_one',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments analyzerElementModelTrackingZero =
    LinterLintWithoutArguments(
      name: 'analyzer_element_model_tracking_zero',
      problemMessage: "No required tracking annotation.",
      uniqueName: 'analyzer_element_model_tracking_zero',
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
const LinterLintWithoutArguments
analyzerPublicApiBadPartDirective = LinterLintWithoutArguments(
  name: 'analyzer_public_api_bad_part_directive',
  problemMessage:
      "Part directives in the analyzer public API should point to files in the "
      "analyzer public API.",
  uniqueName: 'analyzer_public_api_bad_part_directive',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String types})
>
analyzerPublicApiBadType = LinterLintTemplate(
  name: 'analyzer_public_api_bad_type',
  problemMessage:
      "Element makes use of type(s) which is not part of the analyzer public "
      "API: {0}.",
  uniqueName: 'analyzer_public_api_bad_type',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String types})
>
analyzerPublicApiExperimentalInconsistency = LinterLintTemplate(
  name: 'analyzer_public_api_experimental_inconsistency',
  problemMessage:
      "Element makes use of experimental type(s), but is not itself marked with "
      "`@experimental`: {0}.",
  uniqueName: 'analyzer_public_api_experimental_inconsistency',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String elements})
>
analyzerPublicApiExportsNonPublicName = LinterLintTemplate(
  name: 'analyzer_public_api_exports_non_public_name',
  problemMessage:
      "Export directive exports element(s) that are not part of the analyzer "
      "public API: {0}.",
  uniqueName: 'analyzer_public_api_exports_non_public_name',
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
const LinterLintWithoutArguments analyzerPublicApiImplInPublicApi =
    LinterLintWithoutArguments(
      name: 'analyzer_public_api_impl_in_public_api',
      problemMessage:
          "Declarations in the analyzer public API should not end in \"Impl\".",
      uniqueName: 'analyzer_public_api_impl_in_public_api',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
annotateOverrides = LinterLintTemplate(
  name: 'annotate_overrides',
  problemMessage:
      "The member '{0}' overrides an inherited member but isn't annotated with "
      "'@override'.",
  correctionMessage: "Try adding the '@override' annotation.",
  hasPublishedDocs: true,
  uniqueName: 'annotate_overrides',
  withArguments: _withArgumentsAnnotateOverrides,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
annotateRedeclares = LinterLintTemplate(
  name: 'annotate_redeclares',
  problemMessage:
      "The member '{0}' is redeclaring but isn't annotated with '@redeclare'.",
  correctionMessage: "Try adding the '@redeclare' annotation.",
  uniqueName: 'annotate_redeclares',
  withArguments: _withArgumentsAnnotateRedeclares,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments avoidAnnotatingWithDynamic =
    LinterLintWithoutArguments(
      name: 'avoid_annotating_with_dynamic',
      problemMessage: "Unnecessary 'dynamic' type annotation.",
      correctionMessage: "Try removing the type 'dynamic'.",
      uniqueName: 'avoid_annotating_with_dynamic',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidAs = LinterLintWithoutArguments(
  name: 'avoid_as',
  problemMessage: "",
  uniqueName: 'avoid_as',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments avoidBoolLiteralsInConditionalExpressions =
    LinterLintWithoutArguments(
      name: 'avoid_bool_literals_in_conditional_expressions',
      problemMessage:
          "Conditional expressions with a 'bool' literal can be simplified.",
      correctionMessage:
          "Try rewriting the expression to use either '&&' or '||'.",
      uniqueName: 'avoid_bool_literals_in_conditional_expressions',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidCatchesWithoutOnClauses =
    LinterLintWithoutArguments(
      name: 'avoid_catches_without_on_clauses',
      problemMessage:
          "Catch clause should use 'on' to specify the type of exception being "
          "caught.",
      correctionMessage: "Try adding an 'on' clause before the 'catch'.",
      uniqueName: 'avoid_catches_without_on_clauses',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidCatchingErrorsClass =
    LinterLintWithoutArguments(
      name: 'avoid_catching_errors',
      problemMessage: "The type 'Error' should not be caught.",
      correctionMessage:
          "Try removing the catch or catching an 'Exception' instead.",
      uniqueName: 'avoid_catching_errors_class',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
avoidCatchingErrorsSubclass = LinterLintTemplate(
  name: 'avoid_catching_errors',
  problemMessage:
      "The type '{0}' should not be caught because it is a subclass of 'Error'.",
  correctionMessage:
      "Try removing the catch or catching an 'Exception' instead.",
  uniqueName: 'avoid_catching_errors_subclass',
  withArguments: _withArgumentsAvoidCatchingErrorsSubclass,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments
avoidClassesWithOnlyStaticMembers = LinterLintWithoutArguments(
  name: 'avoid_classes_with_only_static_members',
  problemMessage: "Classes should define instance members.",
  correctionMessage:
      "Try adding instance behavior or moving the members out of the class.",
  uniqueName: 'avoid_classes_with_only_static_members',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments avoidDoubleAndIntChecks =
    LinterLintWithoutArguments(
      name: 'avoid_double_and_int_checks',
      problemMessage: "Explicit check for double or int.",
      correctionMessage: "Try removing the check.",
      uniqueName: 'avoid_double_and_int_checks',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidDynamicCalls = LinterLintWithoutArguments(
  name: 'avoid_dynamic_calls',
  problemMessage: "Method invocation or property access on a 'dynamic' target.",
  correctionMessage: "Try giving the target a type.",
  hasPublishedDocs: true,
  uniqueName: 'avoid_dynamic_calls',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments avoidEmptyElse = LinterLintWithoutArguments(
  name: 'avoid_empty_else',
  problemMessage: "Empty statements are not allowed in an 'else' clause.",
  correctionMessage:
      "Try removing the empty statement or removing the else clause.",
  hasPublishedDocs: true,
  uniqueName: 'avoid_empty_else',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
avoidEqualsAndHashCodeOnMutableClasses = LinterLintTemplate(
  name: 'avoid_equals_and_hash_code_on_mutable_classes',
  problemMessage:
      "The method '{0}' should not be overridden in classes not annotated with "
      "'@immutable'.",
  correctionMessage:
      "Try removing the override or annotating the class with '@immutable'.",
  uniqueName: 'avoid_equals_and_hash_code_on_mutable_classes',
  withArguments: _withArgumentsAvoidEqualsAndHashCodeOnMutableClasses,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
/// Object p1: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
avoidEscapingInnerQuotes = LinterLintTemplate(
  name: 'avoid_escaping_inner_quotes',
  problemMessage: "Unnecessary escape of '{0}'.",
  correctionMessage: "Try changing the outer quotes to '{1}'.",
  uniqueName: 'avoid_escaping_inner_quotes',
  withArguments: _withArgumentsAvoidEscapingInnerQuotes,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments avoidFieldInitializersInConstClasses =
    LinterLintWithoutArguments(
      name: 'avoid_field_initializers_in_const_classes',
      problemMessage: "Fields in 'const' classes should not have initializers.",
      correctionMessage:
          "Try converting the field to a getter or initialize the field in the "
          "constructors.",
      uniqueName: 'avoid_field_initializers_in_const_classes',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidFinalParameters =
    LinterLintWithoutArguments(
      name: 'avoid_final_parameters',
      problemMessage: "Parameters should not be marked as 'final'.",
      correctionMessage: "Try removing the keyword 'final'.",
      uniqueName: 'avoid_final_parameters',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidFunctionLiteralsInForeachCalls =
    LinterLintWithoutArguments(
      name: 'avoid_function_literals_in_foreach_calls',
      problemMessage: "Function literals shouldn't be passed to 'forEach'.",
      correctionMessage: "Try using a 'for' loop.",
      hasPublishedDocs: true,
      uniqueName: 'avoid_function_literals_in_foreach_calls',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidFutureorVoid = LinterLintWithoutArguments(
  name: 'avoid_futureor_void',
  problemMessage: "Don't use the type 'FutureOr<void>'.",
  correctionMessage: "Try using 'Future<void>?' or 'void'.",
  hasPublishedDocs: true,
  uniqueName: 'avoid_futureor_void',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments avoidImplementingValueTypes =
    LinterLintWithoutArguments(
      name: 'avoid_implementing_value_types',
      problemMessage: "Classes that override '==' should not be implemented.",
      correctionMessage: "Try removing the class from the 'implements' clause.",
      uniqueName: 'avoid_implementing_value_types',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidInitToNull = LinterLintWithoutArguments(
  name: 'avoid_init_to_null',
  problemMessage: "Redundant initialization to 'null'.",
  correctionMessage: "Try removing the initializer.",
  hasPublishedDocs: true,
  uniqueName: 'avoid_init_to_null',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments
avoidJsRoundedInts = LinterLintWithoutArguments(
  name: 'avoid_js_rounded_ints',
  problemMessage:
      "Integer literal can't be represented exactly when compiled to JavaScript.",
  correctionMessage: "Try using a 'BigInt' to represent the value.",
  uniqueName: 'avoid_js_rounded_ints',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments avoidMultipleDeclarationsPerLine =
    LinterLintWithoutArguments(
      name: 'avoid_multiple_declarations_per_line',
      problemMessage: "Multiple variables declared on a single line.",
      correctionMessage:
          "Try splitting the variable declarations into multiple lines.",
      uniqueName: 'avoid_multiple_declarations_per_line',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidNullChecksInEqualityOperators =
    LinterLintWithoutArguments(
      name: 'avoid_null_checks_in_equality_operators',
      problemMessage: "Unnecessary null comparison in implementation of '=='.",
      correctionMessage: "Try removing the comparison.",
      uniqueName: 'avoid_null_checks_in_equality_operators',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidPositionalBooleanParameters =
    LinterLintWithoutArguments(
      name: 'avoid_positional_boolean_parameters',
      problemMessage: "'bool' parameters should be named parameters.",
      correctionMessage: "Try converting the parameter to a named parameter.",
      uniqueName: 'avoid_positional_boolean_parameters',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidPrint = LinterLintWithoutArguments(
  name: 'avoid_print',
  problemMessage: "Don't invoke 'print' in production code.",
  correctionMessage: "Try using a logging framework.",
  hasPublishedDocs: true,
  uniqueName: 'avoid_print',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments avoidPrivateTypedefFunctions =
    LinterLintWithoutArguments(
      name: 'avoid_private_typedef_functions',
      problemMessage:
          "The typedef is unnecessary because it is only used in one place.",
      correctionMessage: "Try inlining the type or using it in other places.",
      uniqueName: 'avoid_private_typedef_functions',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments
avoidRedundantArgumentValues = LinterLintWithoutArguments(
  name: 'avoid_redundant_argument_values',
  problemMessage:
      "The value of the argument is redundant because it matches the default "
      "value.",
  correctionMessage: "Try removing the argument.",
  uniqueName: 'avoid_redundant_argument_values',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments avoidRelativeLibImports =
    LinterLintWithoutArguments(
      name: 'avoid_relative_lib_imports',
      problemMessage: "Can't use a relative path to import a library in 'lib'.",
      correctionMessage:
          "Try fixing the relative path or changing the import to a 'package:' "
          "import.",
      hasPublishedDocs: true,
      uniqueName: 'avoid_relative_lib_imports',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
/// Object p1: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
avoidRenamingMethodParameters = LinterLintTemplate(
  name: 'avoid_renaming_method_parameters',
  problemMessage:
      "The parameter name '{0}' doesn't match the name '{1}' in the overridden "
      "method.",
  correctionMessage: "Try changing the name to '{1}'.",
  hasPublishedDocs: true,
  uniqueName: 'avoid_renaming_method_parameters',
  withArguments: _withArgumentsAvoidRenamingMethodParameters,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments avoidReturningNull =
    LinterLintWithoutArguments(
      name: 'avoid_returning_null',
      problemMessage: "",
      uniqueName: 'avoid_returning_null',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidReturningNullForFuture =
    LinterLintWithoutArguments(
      name: 'avoid_returning_null_for_future',
      problemMessage: "",
      uniqueName: 'avoid_returning_null_for_future',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidReturningNullForVoidFromFunction =
    LinterLintWithoutArguments(
      name: 'avoid_returning_null_for_void',
      problemMessage:
          "Don't return 'null' from a function with a return type of 'void'.",
      correctionMessage: "Try removing the 'null'.",
      hasPublishedDocs: true,
      uniqueName: 'avoid_returning_null_for_void_from_function',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidReturningNullForVoidFromMethod =
    LinterLintWithoutArguments(
      name: 'avoid_returning_null_for_void',
      problemMessage:
          "Don't return 'null' from a method with a return type of 'void'.",
      correctionMessage: "Try removing the 'null'.",
      hasPublishedDocs: true,
      uniqueName: 'avoid_returning_null_for_void_from_method',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidReturningThis =
    LinterLintWithoutArguments(
      name: 'avoid_returning_this',
      problemMessage: "Don't return 'this' from a method.",
      correctionMessage:
          "Try changing the return type to 'void' and removing the return.",
      uniqueName: 'avoid_returning_this',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidReturnTypesOnSetters =
    LinterLintWithoutArguments(
      name: 'avoid_return_types_on_setters',
      problemMessage: "Unnecessary return type on a setter.",
      correctionMessage: "Try removing the return type.",
      hasPublishedDocs: true,
      uniqueName: 'avoid_return_types_on_setters',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidSettersWithoutGetters =
    LinterLintWithoutArguments(
      name: 'avoid_setters_without_getters',
      problemMessage: "Setter has no corresponding getter.",
      correctionMessage:
          "Try adding a corresponding getter or removing the setter.",
      uniqueName: 'avoid_setters_without_getters',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
/// Object p1: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
avoidShadowingTypeParameters = LinterLintTemplate(
  name: 'avoid_shadowing_type_parameters',
  problemMessage:
      "The type parameter '{0}' shadows a type parameter from the enclosing {1}.",
  correctionMessage: "Try renaming one of the type parameters.",
  hasPublishedDocs: true,
  uniqueName: 'avoid_shadowing_type_parameters',
  withArguments: _withArgumentsAvoidShadowingTypeParameters,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
avoidSingleCascadeInExpressionStatements = LinterLintTemplate(
  name: 'avoid_single_cascade_in_expression_statements',
  problemMessage: "Unnecessary cascade expression.",
  correctionMessage: "Try using the operator '{0}'.",
  hasPublishedDocs: true,
  uniqueName: 'avoid_single_cascade_in_expression_statements',
  withArguments: _withArgumentsAvoidSingleCascadeInExpressionStatements,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments avoidSlowAsyncIo = LinterLintWithoutArguments(
  name: 'avoid_slow_async_io',
  problemMessage: "Use of an async 'dart:io' method.",
  correctionMessage: "Try using the synchronous version of the method.",
  hasPublishedDocs: true,
  uniqueName: 'avoid_slow_async_io',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
avoidTypesAsParameterNamesFormalParameter = LinterLintTemplate(
  name: 'avoid_types_as_parameter_names',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
avoidTypesAsParameterNamesTypeParameter = LinterLintTemplate(
  name: 'avoid_types_as_parameter_names',
  problemMessage: "The type parameter name '{0}' matches a visible type name.",
  correctionMessage:
      "Try changing the type parameter name to not match an existing type.",
  hasPublishedDocs: true,
  uniqueName: 'avoid_types_as_parameter_names_type_parameter',
  withArguments: _withArgumentsAvoidTypesAsParameterNamesTypeParameter,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments avoidTypesOnClosureParameters =
    LinterLintWithoutArguments(
      name: 'avoid_types_on_closure_parameters',
      problemMessage:
          "Unnecessary type annotation on a function expression parameter.",
      correctionMessage: "Try removing the type annotation.",
      uniqueName: 'avoid_types_on_closure_parameters',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidTypeToString = LinterLintWithoutArguments(
  name: 'avoid_type_to_string',
  problemMessage:
      "Using 'toString' on a 'Type' is not safe in production code.",
  correctionMessage:
      "Try a normal type check or compare the 'runtimeType' directly.",
  hasPublishedDocs: true,
  uniqueName: 'avoid_type_to_string',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments avoidUnnecessaryContainers =
    LinterLintWithoutArguments(
      name: 'avoid_unnecessary_containers',
      problemMessage: "Unnecessary instance of 'Container'.",
      correctionMessage:
          "Try removing the 'Container' (but not its children) from the widget "
          "tree.",
      hasPublishedDocs: true,
      uniqueName: 'avoid_unnecessary_containers',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments avoidUnstableFinalFields =
    LinterLintWithoutArguments(
      name: 'avoid_unstable_final_fields',
      problemMessage: "",
      uniqueName: 'avoid_unstable_final_fields',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
avoidUnusedConstructorParameters = LinterLintTemplate(
  name: 'avoid_unused_constructor_parameters',
  problemMessage: "The parameter '{0}' is not used in the constructor.",
  correctionMessage: "Try using the parameter or removing it.",
  uniqueName: 'avoid_unused_constructor_parameters',
  withArguments: _withArgumentsAvoidUnusedConstructorParameters,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments avoidVoidAsync = LinterLintWithoutArguments(
  name: 'avoid_void_async',
  problemMessage:
      "An 'async' function should have a 'Future' return type when it doesn't "
      "return a value.",
  correctionMessage: "Try changing the return type.",
  uniqueName: 'avoid_void_async',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments avoidWebLibrariesInFlutter =
    LinterLintWithoutArguments(
      name: 'avoid_web_libraries_in_flutter',
      problemMessage:
          "Don't use web-only libraries outside Flutter web plugins.",
      correctionMessage: "Try finding a different library for your needs.",
      hasPublishedDocs: true,
      uniqueName: 'avoid_web_libraries_in_flutter',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
awaitOnlyFutures = LinterLintTemplate(
  name: 'await_only_futures',
  problemMessage:
      "Uses 'await' on an instance of '{0}', which is not a subtype of 'Future'.",
  correctionMessage: "Try removing the 'await' or changing the expression.",
  hasPublishedDocs: true,
  uniqueName: 'await_only_futures',
  withArguments: _withArgumentsAwaitOnlyFutures,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
camelCaseExtensions = LinterLintTemplate(
  name: 'camel_case_extensions',
  problemMessage:
      "The extension name '{0}' isn't an UpperCamelCase identifier.",
  correctionMessage:
      "Try changing the name to follow the UpperCamelCase style.",
  hasPublishedDocs: true,
  uniqueName: 'camel_case_extensions',
  withArguments: _withArgumentsCamelCaseExtensions,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
camelCaseTypes = LinterLintTemplate(
  name: 'camel_case_types',
  problemMessage: "The type name '{0}' isn't an UpperCamelCase identifier.",
  correctionMessage:
      "Try changing the name to follow the UpperCamelCase style.",
  hasPublishedDocs: true,
  uniqueName: 'camel_case_types',
  withArguments: _withArgumentsCamelCaseTypes,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments cancelSubscriptions =
    LinterLintWithoutArguments(
      name: 'cancel_subscriptions',
      problemMessage: "Uncancelled instance of 'StreamSubscription'.",
      correctionMessage:
          "Try invoking 'cancel' in the function in which the "
          "'StreamSubscription' was created.",
      hasPublishedDocs: true,
      uniqueName: 'cancel_subscriptions',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments cascadeInvocations =
    LinterLintWithoutArguments(
      name: 'cascade_invocations',
      problemMessage: "Unnecessary duplication of receiver.",
      correctionMessage: "Try using a cascade to avoid the duplication.",
      uniqueName: 'cascade_invocations',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments
castNullableToNonNullable = LinterLintWithoutArguments(
  name: 'cast_nullable_to_non_nullable',
  problemMessage: "Don't cast a nullable value to a non-nullable type.",
  correctionMessage:
      "Try adding a not-null assertion ('!') to make the type non-nullable.",
  uniqueName: 'cast_nullable_to_non_nullable',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments closeSinks = LinterLintWithoutArguments(
  name: 'close_sinks',
  problemMessage: "Unclosed instance of 'Sink'.",
  correctionMessage:
      "Try invoking 'close' in the function in which the 'Sink' was created.",
  hasPublishedDocs: true,
  uniqueName: 'close_sinks',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: undocumented
/// Object p1: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
collectionMethodsUnrelatedType = LinterLintTemplate(
  name: 'collection_methods_unrelated_type',
  problemMessage: "The argument type '{0}' isn't related to '{1}'.",
  correctionMessage: "Try changing the argument or element type to match.",
  hasPublishedDocs: true,
  uniqueName: 'collection_methods_unrelated_type',
  withArguments: _withArgumentsCollectionMethodsUnrelatedType,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments combinatorsOrdering =
    LinterLintWithoutArguments(
      name: 'combinators_ordering',
      problemMessage: "Sort combinator names alphabetically.",
      correctionMessage: "Try sorting the combinator names alphabetically.",
      uniqueName: 'combinators_ordering',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments commentReferences = LinterLintWithoutArguments(
  name: 'comment_references',
  problemMessage: "The referenced name isn't visible in scope.",
  correctionMessage: "Try adding an import for the referenced name.",
  uniqueName: 'comment_references',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
conditionalUriDoesNotExist = LinterLintTemplate(
  name: 'conditional_uri_does_not_exist',
  problemMessage: "The target of the conditional URI '{0}' doesn't exist.",
  correctionMessage:
      "Try creating the file referenced by the URI, or try using a URI for a "
      "file that does exist.",
  uniqueName: 'conditional_uri_does_not_exist',
  withArguments: _withArgumentsConditionalUriDoesNotExist,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
constantIdentifierNames = LinterLintTemplate(
  name: 'constant_identifier_names',
  problemMessage: "The constant name '{0}' isn't a lowerCamelCase identifier.",
  correctionMessage:
      "Try changing the name to follow the lowerCamelCase style.",
  hasPublishedDocs: true,
  uniqueName: 'constant_identifier_names',
  withArguments: _withArgumentsConstantIdentifierNames,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
controlFlowInFinally = LinterLintTemplate(
  name: 'control_flow_in_finally',
  problemMessage: "Use of '{0}' in a 'finally' clause.",
  correctionMessage: "Try restructuring the code.",
  hasPublishedDocs: true,
  uniqueName: 'control_flow_in_finally',
  withArguments: _withArgumentsControlFlowInFinally,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
curlyBracesInFlowControlStructures = LinterLintTemplate(
  name: 'curly_braces_in_flow_control_structures',
  problemMessage: "Statements in {0} should be enclosed in a block.",
  correctionMessage: "Try wrapping the statement in a block.",
  hasPublishedDocs: true,
  uniqueName: 'curly_braces_in_flow_control_structures',
  withArguments: _withArgumentsCurlyBracesInFlowControlStructures,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments danglingLibraryDocComments =
    LinterLintWithoutArguments(
      name: 'dangling_library_doc_comments',
      problemMessage: "Dangling library doc comment.",
      correctionMessage: "Add a 'library' directive after the library comment.",
      hasPublishedDocs: true,
      uniqueName: 'dangling_library_doc_comments',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
dependOnReferencedPackages = LinterLintTemplate(
  name: 'depend_on_referenced_packages',
  problemMessage:
      "The imported package '{0}' isn't a dependency of the importing package.",
  correctionMessage:
      "Try adding a dependency for '{0}' in the 'pubspec.yaml' file.",
  hasPublishedDocs: true,
  uniqueName: 'depend_on_referenced_packages',
  withArguments: _withArgumentsDependOnReferencedPackages,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments deprecatedConsistencyConstructor =
    LinterLintWithoutArguments(
      name: 'deprecated_consistency',
      problemMessage:
          "Constructors in a deprecated class should be deprecated.",
      correctionMessage: "Try marking the constructor as deprecated.",
      uniqueName: 'deprecated_consistency_constructor',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments deprecatedConsistencyField =
    LinterLintWithoutArguments(
      name: 'deprecated_consistency',
      problemMessage:
          "Fields that are initialized by a deprecated parameter should be "
          "deprecated.",
      correctionMessage: "Try marking the field as deprecated.",
      uniqueName: 'deprecated_consistency_field',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments deprecatedConsistencyParameter =
    LinterLintWithoutArguments(
      name: 'deprecated_consistency',
      problemMessage:
          "Parameters that initialize a deprecated field should be deprecated.",
      correctionMessage: "Try marking the parameter as deprecated.",
      uniqueName: 'deprecated_consistency_parameter',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
/// Object p1: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
deprecatedMemberUseFromSamePackageWithMessage = LinterLintTemplate(
  name: 'deprecated_member_use_from_same_package',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
deprecatedMemberUseFromSamePackageWithoutMessage = LinterLintTemplate(
  name: 'deprecated_member_use_from_same_package',
  problemMessage: "'{0}' is deprecated and shouldn't be used.",
  correctionMessage:
      "Try replacing the use of the deprecated member with the replacement, "
      "if a replacement is specified.",
  uniqueName: 'deprecated_member_use_from_same_package_without_message',
  withArguments: _withArgumentsDeprecatedMemberUseFromSamePackageWithoutMessage,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments
diagnosticDescribeAllProperties = LinterLintWithoutArguments(
  name: 'diagnostic_describe_all_properties',
  problemMessage:
      "The public property isn't described by either 'debugFillProperties' or "
      "'debugDescribeChildren'.",
  correctionMessage: "Try describing the property.",
  hasPublishedDocs: true,
  uniqueName: 'diagnostic_describe_all_properties',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments directivesOrderingAlphabetical =
    LinterLintWithoutArguments(
      name: 'directives_ordering',
      problemMessage: "Sort directive sections alphabetically.",
      correctionMessage: "Try sorting the directives.",
      uniqueName: 'directives_ordering_alphabetical',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
directivesOrderingDart = LinterLintTemplate(
  name: 'directives_ordering',
  problemMessage: "Place 'dart:' {0} before other {0}.",
  correctionMessage: "Try sorting the directives.",
  uniqueName: 'directives_ordering_dart',
  withArguments: _withArgumentsDirectivesOrderingDart,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments directivesOrderingExports =
    LinterLintWithoutArguments(
      name: 'directives_ordering',
      problemMessage:
          "Specify exports in a separate section after all imports.",
      correctionMessage: "Try sorting the directives.",
      uniqueName: 'directives_ordering_exports',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
directivesOrderingPackageBeforeRelative = LinterLintTemplate(
  name: 'directives_ordering',
  problemMessage: "Place 'package:' {0} before relative {0}.",
  correctionMessage: "Try sorting the directives.",
  uniqueName: 'directives_ordering_package_before_relative',
  withArguments: _withArgumentsDirectivesOrderingPackageBeforeRelative,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments discardedFutures = LinterLintWithoutArguments(
  name: 'discarded_futures',
  problemMessage: "'Future'-returning calls in a non-'async' function.",
  correctionMessage:
      "Try converting the enclosing function to be 'async' and then 'await' "
      "the future, or wrap the expression in 'unawaited'.",
  uniqueName: 'discarded_futures',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments documentIgnores = LinterLintWithoutArguments(
  name: 'document_ignores',
  problemMessage:
      "Missing documentation explaining why the diagnostic is ignored.",
  correctionMessage:
      "Try adding a comment immediately above the ignore comment.",
  uniqueName: 'document_ignores',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments doNotUseEnvironment =
    LinterLintWithoutArguments(
      name: 'do_not_use_environment',
      problemMessage: "Invalid use of an environment declaration.",
      correctionMessage: "Try removing the environment declaration usage.",
      uniqueName: 'do_not_use_environment',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments emptyCatches = LinterLintWithoutArguments(
  name: 'empty_catches',
  problemMessage: "Empty catch block.",
  correctionMessage:
      "Try adding statements to the block, adding a comment to the block, or "
      "removing the 'catch' clause.",
  hasPublishedDocs: true,
  uniqueName: 'empty_catches',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments
emptyConstructorBodies = LinterLintWithoutArguments(
  name: 'empty_constructor_bodies',
  problemMessage:
      "Empty constructor bodies should be written using a ';' rather than '{}'.",
  correctionMessage: "Try replacing the constructor body with ';'.",
  hasPublishedDocs: true,
  uniqueName: 'empty_constructor_bodies',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments emptyStatements = LinterLintWithoutArguments(
  name: 'empty_statements',
  problemMessage: "Unnecessary empty statement.",
  correctionMessage:
      "Try removing the empty statement or restructuring the code.",
  hasPublishedDocs: true,
  uniqueName: 'empty_statements',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments enableNullSafety = LinterLintWithoutArguments(
  name: 'enable_null_safety',
  problemMessage: "",
  uniqueName: 'enable_null_safety',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments eolAtEndOfFile = LinterLintWithoutArguments(
  name: 'eol_at_end_of_file',
  problemMessage: "Missing a newline at the end of the file.",
  correctionMessage: "Try adding a newline at the end of the file.",
  uniqueName: 'eol_at_end_of_file',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments
eraseDartTypeExtensionTypes = LinterLintWithoutArguments(
  name: 'erase_dart_type_extension_types',
  problemMessage: "Unsafe use of 'DartType' in an 'is' check.",
  correctionMessage:
      "Ensure DartType extension types are erased by using a helper method.",
  uniqueName: 'erase_dart_type_extension_types',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
exhaustiveCases = LinterLintTemplate(
  name: 'exhaustive_cases',
  problemMessage: "Missing case clauses for some constants in '{0}'.",
  correctionMessage: "Try adding case clauses for the missing constants.",
  uniqueName: 'exhaustive_cases',
  withArguments: _withArgumentsExhaustiveCases,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
fileNames = LinterLintTemplate(
  name: 'file_names',
  problemMessage:
      "The file name '{0}' isn't a lower_case_with_underscores identifier.",
  correctionMessage:
      "Try changing the name to follow the lower_case_with_underscores "
      "style.",
  hasPublishedDocs: true,
  uniqueName: 'file_names',
  withArguments: _withArgumentsFileNames,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments flutterStyleTodos = LinterLintWithoutArguments(
  name: 'flutter_style_todos',
  problemMessage: "To-do comment doesn't follow the Flutter style.",
  correctionMessage: "Try following the Flutter style for to-do comments.",
  uniqueName: 'flutter_style_todos',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: undocumented
/// Object p1: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
hashAndEquals = LinterLintTemplate(
  name: 'hash_and_equals',
  problemMessage: "Missing a corresponding override of '{0}'.",
  correctionMessage: "Try overriding '{0}' or removing '{1}'.",
  hasPublishedDocs: true,
  uniqueName: 'hash_and_equals',
  withArguments: _withArgumentsHashAndEquals,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments
implementationImports = LinterLintWithoutArguments(
  name: 'implementation_imports',
  problemMessage:
      "Import of a library in the 'lib/src' directory of another package.",
  correctionMessage:
      "Try importing a public library that exports this library, or removing "
      "the import.",
  hasPublishedDocs: true,
  uniqueName: 'implementation_imports',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments implicitCallTearoffs =
    LinterLintWithoutArguments(
      name: 'implicit_call_tearoffs',
      problemMessage: "Implicit tear-off of the 'call' method.",
      correctionMessage: "Try explicitly tearing off the 'call' method.",
      hasPublishedDocs: true,
      uniqueName: 'implicit_call_tearoffs',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
/// Object p1: undocumented
/// Object p2: undocumented
/// Object p3: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  })
>
implicitReopen = LinterLintTemplate(
  name: 'implicit_reopen',
  problemMessage: "The {0} '{1}' reopens '{2}' because it is not marked '{3}'.",
  correctionMessage: "Try marking '{1}' '{3}' or annotating it with '@reopen'.",
  uniqueName: 'implicit_reopen',
  withArguments: _withArgumentsImplicitReopen,
  expectedTypes: [
    ExpectedType.object,
    ExpectedType.object,
    ExpectedType.object,
    ExpectedType.object,
  ],
);

/// No parameters.
const LinterLintWithoutArguments invalidCasePatterns =
    LinterLintWithoutArguments(
      name: 'invalid_case_patterns',
      problemMessage:
          "This expression is not valid in a 'case' clause in Dart 3.0.",
      correctionMessage: "Try refactoring the expression to be valid in 3.0.",
      uniqueName: 'invalid_case_patterns',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
/// Object p1: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidRuntimeCheckWithJsInteropTypesDartAsJs = LinterLintTemplate(
  name: 'invalid_runtime_check_with_js_interop_types',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidRuntimeCheckWithJsInteropTypesDartIsJs = LinterLintTemplate(
  name: 'invalid_runtime_check_with_js_interop_types',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidRuntimeCheckWithJsInteropTypesJsAsDart = LinterLintTemplate(
  name: 'invalid_runtime_check_with_js_interop_types',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs = LinterLintTemplate(
  name: 'invalid_runtime_check_with_js_interop_types',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidRuntimeCheckWithJsInteropTypesJsIsDart = LinterLintTemplate(
  name: 'invalid_runtime_check_with_js_interop_types',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs = LinterLintTemplate(
  name: 'invalid_runtime_check_with_js_interop_types',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs = LinterLintTemplate(
  name: 'invalid_runtime_check_with_js_interop_types',
  problemMessage:
      "Runtime check between '{0}' and '{1}' involves a runtime check between a "
      "JS interop value and an unrelated JS interop type that will always be "
      "true and won't check the underlying type.",
  correctionMessage:
      "Try using a JS interop member like 'isA' from 'dart:js_interop' to "
      "check the underlying type of JS interop values, or make the JS "
      "interop type a supertype using 'implements'.",
  uniqueName: 'invalid_runtime_check_with_js_interop_types_js_is_unrelated_js',
  withArguments:
      _withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments invariantBooleans = LinterLintWithoutArguments(
  name: 'invariant_booleans',
  problemMessage: "",
  uniqueName: 'invariant_booleans',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments iterableContainsUnrelatedType =
    LinterLintWithoutArguments(
      name: 'iterable_contains_unrelated_type',
      problemMessage: "",
      uniqueName: 'iterable_contains_unrelated_type',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments joinReturnWithAssignment =
    LinterLintWithoutArguments(
      name: 'join_return_with_assignment',
      problemMessage: "Assignment could be inlined in 'return' statement.",
      correctionMessage:
          "Try inlining the assigned value in the 'return' statement.",
      uniqueName: 'join_return_with_assignment',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments leadingNewlinesInMultilineStrings =
    LinterLintWithoutArguments(
      name: 'leading_newlines_in_multiline_strings',
      problemMessage:
          "Missing a newline at the beginning of a multiline string.",
      correctionMessage: "Try adding a newline at the beginning of the string.",
      uniqueName: 'leading_newlines_in_multiline_strings',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments libraryAnnotations =
    LinterLintWithoutArguments(
      name: 'library_annotations',
      problemMessage:
          "This annotation should be attached to a library directive.",
      correctionMessage: "Try attaching the annotation to a library directive.",
      hasPublishedDocs: true,
      uniqueName: 'library_annotations',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
libraryNames = LinterLintTemplate(
  name: 'library_names',
  problemMessage:
      "The library name '{0}' isn't a lower_case_with_underscores identifier.",
  correctionMessage:
      "Try changing the name to follow the lower_case_with_underscores "
      "style.",
  hasPublishedDocs: true,
  uniqueName: 'library_names',
  withArguments: _withArgumentsLibraryNames,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
libraryPrefixes = LinterLintTemplate(
  name: 'library_prefixes',
  problemMessage:
      "The prefix '{0}' isn't a lower_case_with_underscores identifier.",
  correctionMessage:
      "Try changing the prefix to follow the lower_case_with_underscores "
      "style.",
  hasPublishedDocs: true,
  uniqueName: 'library_prefixes',
  withArguments: _withArgumentsLibraryPrefixes,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments libraryPrivateTypesInPublicApi =
    LinterLintWithoutArguments(
      name: 'library_private_types_in_public_api',
      problemMessage: "Invalid use of a private type in a public API.",
      correctionMessage:
          "Try making the private type public, or making the API that uses the "
          "private type also be private.",
      hasPublishedDocs: true,
      uniqueName: 'library_private_types_in_public_api',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments linesLongerThan80Chars =
    LinterLintWithoutArguments(
      name: 'lines_longer_than_80_chars',
      problemMessage: "The line length exceeds the 80-character limit.",
      correctionMessage: "Try breaking the line across multiple lines.",
      uniqueName: 'lines_longer_than_80_chars',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments listRemoveUnrelatedType =
    LinterLintWithoutArguments(
      name: 'list_remove_unrelated_type',
      problemMessage: "",
      uniqueName: 'list_remove_unrelated_type',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments literalOnlyBooleanExpressions =
    LinterLintWithoutArguments(
      name: 'literal_only_boolean_expressions',
      problemMessage: "The Boolean expression has a constant value.",
      correctionMessage: "Try changing the expression.",
      hasPublishedDocs: true,
      uniqueName: 'literal_only_boolean_expressions',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
/// Object p1: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
matchingSuperParameters = LinterLintTemplate(
  name: 'matching_super_parameters',
  problemMessage:
      "The super parameter named '{0}'' does not share the same name as the "
      "corresponding parameter in the super constructor, '{1}'.",
  correctionMessage:
      "Try using the name of the corresponding parameter in the super "
      "constructor.",
  uniqueName: 'matching_super_parameters',
  withArguments: _withArgumentsMatchingSuperParameters,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments missingCodeBlockLanguageInDocComment =
    LinterLintWithoutArguments(
      name: 'missing_code_block_language_in_doc_comment',
      problemMessage: "The code block is missing a specified language.",
      correctionMessage: "Try adding a language to the code block.",
      uniqueName: 'missing_code_block_language_in_doc_comment',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments missingWhitespaceBetweenAdjacentStrings =
    LinterLintWithoutArguments(
      name: 'missing_whitespace_between_adjacent_strings',
      problemMessage: "Missing whitespace between adjacent strings.",
      correctionMessage: "Try adding whitespace between the strings.",
      hasPublishedDocs: true,
      uniqueName: 'missing_whitespace_between_adjacent_strings',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments noAdjacentStringsInList =
    LinterLintWithoutArguments(
      name: 'no_adjacent_strings_in_list',
      problemMessage: "Don't use adjacent strings in a list literal.",
      correctionMessage: "Try adding a comma between the strings.",
      hasPublishedDocs: true,
      uniqueName: 'no_adjacent_strings_in_list',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments noDefaultCases = LinterLintWithoutArguments(
  name: 'no_default_cases',
  problemMessage: "Invalid use of 'default' member in a switch.",
  correctionMessage:
      "Try enumerating all the possible values of the switch expression.",
  uniqueName: 'no_default_cases',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: undocumented
/// Object p1: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
noDuplicateCaseValues = LinterLintTemplate(
  name: 'no_duplicate_case_values',
  problemMessage:
      "The value of the case clause ('{0}') is equal to the value of an earlier "
      "case clause ('{1}').",
  correctionMessage: "Try removing or changing the value.",
  hasPublishedDocs: true,
  uniqueName: 'no_duplicate_case_values',
  withArguments: _withArgumentsNoDuplicateCaseValues,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
noLeadingUnderscoresForLibraryPrefixes = LinterLintTemplate(
  name: 'no_leading_underscores_for_library_prefixes',
  problemMessage: "The library prefix '{0}' starts with an underscore.",
  correctionMessage: "Try renaming the prefix to not start with an underscore.",
  hasPublishedDocs: true,
  uniqueName: 'no_leading_underscores_for_library_prefixes',
  withArguments: _withArgumentsNoLeadingUnderscoresForLibraryPrefixes,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
noLeadingUnderscoresForLocalIdentifiers = LinterLintTemplate(
  name: 'no_leading_underscores_for_local_identifiers',
  problemMessage: "The local variable '{0}' starts with an underscore.",
  correctionMessage:
      "Try renaming the variable to not start with an underscore.",
  hasPublishedDocs: true,
  uniqueName: 'no_leading_underscores_for_local_identifiers',
  withArguments: _withArgumentsNoLeadingUnderscoresForLocalIdentifiers,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments noLiteralBoolComparisons =
    LinterLintWithoutArguments(
      name: 'no_literal_bool_comparisons',
      problemMessage: "Unnecessary comparison to a boolean literal.",
      correctionMessage:
          "Remove the comparison and use the negate `!` operator if necessary.",
      uniqueName: 'no_literal_bool_comparisons',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments noLogicInCreateState =
    LinterLintWithoutArguments(
      name: 'no_logic_in_create_state',
      problemMessage: "Don't put any logic in 'createState'.",
      correctionMessage: "Try moving the logic out of 'createState'.",
      hasPublishedDocs: true,
      uniqueName: 'no_logic_in_create_state',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
nonConstantIdentifierNames = LinterLintTemplate(
  name: 'non_constant_identifier_names',
  problemMessage: "The variable name '{0}' isn't a lowerCamelCase identifier.",
  correctionMessage:
      "Try changing the name to follow the lowerCamelCase style.",
  hasPublishedDocs: true,
  uniqueName: 'non_constant_identifier_names',
  withArguments: _withArgumentsNonConstantIdentifierNames,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments noopPrimitiveOperations =
    LinterLintWithoutArguments(
      name: 'noop_primitive_operations',
      problemMessage: "The expression has no effect and can be removed.",
      correctionMessage: "Try removing the expression.",
      uniqueName: 'noop_primitive_operations',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments noRuntimetypeTostring =
    LinterLintWithoutArguments(
      name: 'no_runtimetype_tostring',
      problemMessage:
          "Using 'toString' on a 'Type' is not safe in production code.",
      correctionMessage:
          "Try removing the usage of 'toString' or restructuring the code.",
      uniqueName: 'no_runtimetype_tostring',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments noSelfAssignments = LinterLintWithoutArguments(
  name: 'no_self_assignments',
  problemMessage: "The variable or property is being assigned to itself.",
  correctionMessage: "Try removing the assignment that has no direct effect.",
  uniqueName: 'no_self_assignments',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments noSoloTests = LinterLintWithoutArguments(
  name: 'no_solo_tests',
  problemMessage: "Don't commit soloed tests.",
  correctionMessage:
      "Try removing the 'soloTest' annotation or 'solo_' prefix.",
  hasPublishedDocs: true,
  uniqueName: 'no_solo_tests',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments noTrailingSpaces = LinterLintWithoutArguments(
  name: 'no_trailing_spaces',
  problemMessage: "Don't create string literals with trailing spaces in tests.",
  correctionMessage: "Try removing the trailing spaces.",
  hasPublishedDocs: true,
  uniqueName: 'no_trailing_spaces',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments noWildcardVariableUses =
    LinterLintWithoutArguments(
      name: 'no_wildcard_variable_uses',
      problemMessage: "The referenced identifier is a wildcard.",
      correctionMessage: "Use an identifier name that is not a wildcard.",
      hasPublishedDocs: true,
      uniqueName: 'no_wildcard_variable_uses',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments
nullCheckOnNullableTypeParameter = LinterLintWithoutArguments(
  name: 'null_check_on_nullable_type_parameter',
  problemMessage:
      "The null check operator shouldn't be used on a variable whose type is a "
      "potentially nullable type parameter.",
  correctionMessage: "Try explicitly testing for 'null'.",
  hasPublishedDocs: true,
  uniqueName: 'null_check_on_nullable_type_parameter',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments nullClosures = LinterLintWithoutArguments(
  name: 'null_closures',
  problemMessage: "Closure can't be 'null' because it might be invoked.",
  correctionMessage: "Try providing a non-null closure.",
  uniqueName: 'null_closures',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments omitLocalVariableTypes =
    LinterLintWithoutArguments(
      name: 'omit_local_variable_types',
      problemMessage: "Unnecessary type annotation on a local variable.",
      correctionMessage: "Try removing the type annotation.",
      uniqueName: 'omit_local_variable_types',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments
omitObviousLocalVariableTypes = LinterLintWithoutArguments(
  name: 'omit_obvious_local_variable_types',
  problemMessage:
      "Omit the type annotation on a local variable when the type is obvious.",
  correctionMessage: "Try removing the type annotation.",
  uniqueName: 'omit_obvious_local_variable_types',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments omitObviousPropertyTypes =
    LinterLintWithoutArguments(
      name: 'omit_obvious_property_types',
      problemMessage: "The type annotation isn't needed because it is obvious.",
      correctionMessage: "Try removing the type annotation.",
      uniqueName: 'omit_obvious_property_types',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
oneMemberAbstracts = LinterLintTemplate(
  name: 'one_member_abstracts',
  problemMessage: "Unnecessary use of an abstract class.",
  correctionMessage:
      "Try making '{0}' a top-level function and removing the class.",
  uniqueName: 'one_member_abstracts',
  withArguments: _withArgumentsOneMemberAbstracts,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments onlyThrowErrors = LinterLintWithoutArguments(
  name: 'only_throw_errors',
  problemMessage:
      "Don't throw instances of classes that don't extend either 'Exception' or "
      "'Error'.",
  correctionMessage: "Try throwing a different class of object.",
  hasPublishedDocs: true,
  uniqueName: 'only_throw_errors',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
overriddenFields = LinterLintTemplate(
  name: 'overridden_fields',
  problemMessage: "Field overrides a field inherited from '{0}'.",
  correctionMessage:
      "Try removing the field, overriding the getter and setter if "
      "necessary.",
  hasPublishedDocs: true,
  uniqueName: 'overridden_fields',
  withArguments: _withArgumentsOverriddenFields,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments packageApiDocs = LinterLintWithoutArguments(
  name: 'package_api_docs',
  problemMessage: "Missing documentation for public API.",
  correctionMessage: "Try adding a documentation comment.",
  uniqueName: 'package_api_docs',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
packageNames = LinterLintTemplate(
  name: 'package_names',
  problemMessage:
      "The package name '{0}' isn't a lower_case_with_underscores identifier.",
  correctionMessage:
      "Try changing the name to follow the lower_case_with_underscores "
      "style.",
  hasPublishedDocs: true,
  uniqueName: 'package_names',
  withArguments: _withArgumentsPackageNames,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
packagePrefixedLibraryNames = LinterLintTemplate(
  name: 'package_prefixed_library_names',
  problemMessage:
      "The library name is not a dot-separated path prefixed by the package "
      "name.",
  correctionMessage: "Try changing the name to '{0}'.",
  hasPublishedDocs: true,
  uniqueName: 'package_prefixed_library_names',
  withArguments: _withArgumentsPackagePrefixedLibraryNames,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
parameterAssignments = LinterLintTemplate(
  name: 'parameter_assignments',
  problemMessage: "Invalid assignment to the parameter '{0}'.",
  correctionMessage: "Try using a local variable in place of the parameter.",
  uniqueName: 'parameter_assignments',
  withArguments: _withArgumentsParameterAssignments,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments preferAdjacentStringConcatenation =
    LinterLintWithoutArguments(
      name: 'prefer_adjacent_string_concatenation',
      problemMessage:
          "String literals shouldn't be concatenated by the '+' operator.",
      correctionMessage: "Try removing the operator to use adjacent strings.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_adjacent_string_concatenation',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferAssertsInInitializerLists =
    LinterLintWithoutArguments(
      name: 'prefer_asserts_in_initializer_lists',
      problemMessage: "Assert should be in the initializer list.",
      correctionMessage: "Try moving the assert to the initializer list.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_asserts_in_initializer_lists',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferAssertsWithMessage =
    LinterLintWithoutArguments(
      name: 'prefer_asserts_with_message',
      problemMessage: "Missing a message in an assert.",
      correctionMessage: "Try adding a message to the assert.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_asserts_with_message',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferBoolInAsserts =
    LinterLintWithoutArguments(
      name: 'prefer_bool_in_asserts',
      problemMessage: "",
      uniqueName: 'prefer_bool_in_asserts',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferCollectionLiterals =
    LinterLintWithoutArguments(
      name: 'prefer_collection_literals',
      problemMessage: "Unnecessary constructor invocation.",
      correctionMessage: "Try using a collection literal.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_collection_literals',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferConditionalAssignment =
    LinterLintWithoutArguments(
      name: 'prefer_conditional_assignment',
      problemMessage:
          "The 'if' statement could be replaced by a null-aware assignment.",
      correctionMessage:
          "Try using the '??=' operator to conditionally assign a value.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_conditional_assignment',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferConstConstructors =
    LinterLintWithoutArguments(
      name: 'prefer_const_constructors',
      problemMessage:
          "Use 'const' with the constructor to improve performance.",
      correctionMessage:
          "Try adding the 'const' keyword to the constructor invocation.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_const_constructors',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferConstConstructorsInImmutables =
    LinterLintWithoutArguments(
      name: 'prefer_const_constructors_in_immutables',
      problemMessage:
          "Constructors in '@immutable' classes should be declared as 'const'.",
      correctionMessage: "Try adding 'const' to the constructor declaration.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_const_constructors_in_immutables',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferConstDeclarations =
    LinterLintWithoutArguments(
      name: 'prefer_const_declarations',
      problemMessage:
          "Use 'const' for final variables initialized to a constant value.",
      correctionMessage: "Try replacing 'final' with 'const'.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_const_declarations',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferConstLiteralsToCreateImmutables =
    LinterLintWithoutArguments(
      name: 'prefer_const_literals_to_create_immutables',
      problemMessage:
          "Use 'const' literals as arguments to constructors of '@immutable' "
          "classes.",
      correctionMessage: "Try adding 'const' before the literal.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_const_literals_to_create_immutables',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferConstructorsOverStaticMethods =
    LinterLintWithoutArguments(
      name: 'prefer_constructors_over_static_methods',
      problemMessage: "Static method should be a constructor.",
      correctionMessage: "Try converting the method into a constructor.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_constructors_over_static_methods',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments
preferContainsAlwaysFalse = LinterLintWithoutArguments(
  name: 'prefer_contains',
  problemMessage:
      "Always 'false' because 'indexOf' is always greater than or equal to -1.",
  uniqueName: 'prefer_contains_always_false',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments
preferContainsAlwaysTrue = LinterLintWithoutArguments(
  name: 'prefer_contains',
  problemMessage:
      "Always 'true' because 'indexOf' is always greater than or equal to -1.",
  uniqueName: 'prefer_contains_always_true',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments preferContainsUseContains =
    LinterLintWithoutArguments(
      name: 'prefer_contains',
      problemMessage: "Unnecessary use of 'indexOf' to test for containment.",
      correctionMessage: "Try using 'contains'.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_contains_use_contains',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferDoubleQuotes =
    LinterLintWithoutArguments(
      name: 'prefer_double_quotes',
      problemMessage: "Unnecessary use of single quotes.",
      correctionMessage:
          "Try using double quotes unless the string contains double quotes.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_double_quotes',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferEqualForDefaultValues =
    LinterLintWithoutArguments(
      name: 'prefer_equal_for_default_values',
      problemMessage: "",
      uniqueName: 'prefer_equal_for_default_values',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferExpressionFunctionBodies =
    LinterLintWithoutArguments(
      name: 'prefer_expression_function_bodies',
      problemMessage: "Unnecessary use of a block function body.",
      correctionMessage: "Try using an expression function body.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_expression_function_bodies',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
preferFinalFields = LinterLintTemplate(
  name: 'prefer_final_fields',
  problemMessage: "The private field {0} could be 'final'.",
  correctionMessage: "Try making the field 'final'.",
  hasPublishedDocs: true,
  uniqueName: 'prefer_final_fields',
  withArguments: _withArgumentsPreferFinalFields,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments preferFinalInForEachPattern =
    LinterLintWithoutArguments(
      name: 'prefer_final_in_for_each',
      problemMessage: "The pattern should be final.",
      correctionMessage: "Try making the pattern final.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_final_in_for_each_pattern',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
preferFinalInForEachVariable = LinterLintTemplate(
  name: 'prefer_final_in_for_each',
  problemMessage: "The variable '{0}' should be final.",
  correctionMessage: "Try making the variable final.",
  uniqueName: 'prefer_final_in_for_each_variable',
  withArguments: _withArgumentsPreferFinalInForEachVariable,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments preferFinalLocals = LinterLintWithoutArguments(
  name: 'prefer_final_locals',
  problemMessage: "Local variables should be final.",
  correctionMessage: "Try making the variable final.",
  hasPublishedDocs: true,
  uniqueName: 'prefer_final_locals',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
preferFinalParameters = LinterLintTemplate(
  name: 'prefer_final_parameters',
  problemMessage: "The parameter '{0}' should be final.",
  correctionMessage: "Try making the parameter final.",
  hasPublishedDocs: true,
  uniqueName: 'prefer_final_parameters',
  withArguments: _withArgumentsPreferFinalParameters,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments preferForeach = LinterLintWithoutArguments(
  name: 'prefer_foreach',
  problemMessage:
      "Use 'forEach' and a tear-off rather than a 'for' loop to apply a function "
      "to every element.",
  correctionMessage:
      "Try using 'forEach' and a tear-off rather than a 'for' loop.",
  hasPublishedDocs: true,
  uniqueName: 'prefer_foreach',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments preferForElementsToMapFromiterable =
    LinterLintWithoutArguments(
      name: 'prefer_for_elements_to_map_fromiterable',
      problemMessage: "Use 'for' elements when building maps from iterables.",
      correctionMessage: "Try using a collection literal with a 'for' element.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_for_elements_to_map_fromiterable',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments
preferFunctionDeclarationsOverVariables = LinterLintWithoutArguments(
  name: 'prefer_function_declarations_over_variables',
  problemMessage:
      "Use a function declaration rather than a variable assignment to bind a "
      "function to a name.",
  correctionMessage:
      "Try rewriting the closure assignment as a function declaration.",
  hasPublishedDocs: true,
  uniqueName: 'prefer_function_declarations_over_variables',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
preferGenericFunctionTypeAliases = LinterLintTemplate(
  name: 'prefer_generic_function_type_aliases',
  problemMessage: "Use the generic function type syntax in 'typedef's.",
  correctionMessage: "Try using the generic function type syntax ('{0}').",
  hasPublishedDocs: true,
  uniqueName: 'prefer_generic_function_type_aliases',
  withArguments: _withArgumentsPreferGenericFunctionTypeAliases,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments preferIfElementsToConditionalExpressions =
    LinterLintWithoutArguments(
      name: 'prefer_if_elements_to_conditional_expressions',
      problemMessage: "Use an 'if' element to conditionally add elements.",
      correctionMessage:
          "Try using an 'if' element rather than a conditional expression.",
      uniqueName: 'prefer_if_elements_to_conditional_expressions',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferIfNullOperators =
    LinterLintWithoutArguments(
      name: 'prefer_if_null_operators',
      problemMessage:
          "Use the '??' operator rather than '?:' when testing for 'null'.",
      correctionMessage: "Try rewriting the code to use '??'.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_if_null_operators',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
preferInitializingFormals = LinterLintTemplate(
  name: 'prefer_initializing_formals',
  problemMessage:
      "Use an initializing formal to assign a parameter to a field.",
  correctionMessage:
      "Try using an initialing formal ('this.{0}') to initialize the field.",
  hasPublishedDocs: true,
  uniqueName: 'prefer_initializing_formals',
  withArguments: _withArgumentsPreferInitializingFormals,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments preferInlinedAddsMultiple =
    LinterLintWithoutArguments(
      name: 'prefer_inlined_adds',
      problemMessage: "The addition of multiple list items could be inlined.",
      correctionMessage: "Try adding the items to the list literal directly.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_inlined_adds_multiple',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferInlinedAddsSingle =
    LinterLintWithoutArguments(
      name: 'prefer_inlined_adds',
      problemMessage: "The addition of a list item could be inlined.",
      correctionMessage: "Try adding the item to the list literal directly.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_inlined_adds_single',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferInterpolationToComposeStrings =
    LinterLintWithoutArguments(
      name: 'prefer_interpolation_to_compose_strings',
      problemMessage: "Use interpolation to compose strings and values.",
      correctionMessage:
          "Try using string interpolation to build the composite string.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_interpolation_to_compose_strings',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferIntLiterals = LinterLintWithoutArguments(
  name: 'prefer_int_literals',
  problemMessage: "Unnecessary use of a 'double' literal.",
  correctionMessage: "Try using an 'int' literal.",
  uniqueName: 'prefer_int_literals',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments
preferIsEmptyAlwaysFalse = LinterLintWithoutArguments(
  name: 'prefer_is_empty',
  problemMessage:
      "The comparison is always 'false' because the length is always greater "
      "than or equal to 0.",
  uniqueName: 'prefer_is_empty_always_false',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments
preferIsEmptyAlwaysTrue = LinterLintWithoutArguments(
  name: 'prefer_is_empty',
  problemMessage:
      "The comparison is always 'true' because the length is always greater than "
      "or equal to 0.",
  uniqueName: 'prefer_is_empty_always_true',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments preferIsEmptyUseIsEmpty =
    LinterLintWithoutArguments(
      name: 'prefer_is_empty',
      problemMessage:
          "Use 'isEmpty' instead of 'length' to test whether the collection is "
          "empty.",
      correctionMessage: "Try rewriting the expression to use 'isEmpty'.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_is_empty_use_is_empty',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments
preferIsEmptyUseIsNotEmpty = LinterLintWithoutArguments(
  name: 'prefer_is_empty',
  problemMessage:
      "Use 'isNotEmpty' instead of 'length' to test whether the collection is "
      "empty.",
  correctionMessage: "Try rewriting the expression to use 'isNotEmpty'.",
  hasPublishedDocs: true,
  uniqueName: 'prefer_is_empty_use_is_not_empty',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments preferIsNotEmpty = LinterLintWithoutArguments(
  name: 'prefer_is_not_empty',
  problemMessage:
      "Use 'isNotEmpty' rather than negating the result of 'isEmpty'.",
  correctionMessage: "Try rewriting the expression to use 'isNotEmpty'.",
  hasPublishedDocs: true,
  uniqueName: 'prefer_is_not_empty',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments preferIsNotOperator =
    LinterLintWithoutArguments(
      name: 'prefer_is_not_operator',
      problemMessage:
          "Use the 'is!' operator rather than negating the value of the 'is' "
          "operator.",
      correctionMessage:
          "Try rewriting the condition to use the 'is!' operator.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_is_not_operator',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferIterableWheretype =
    LinterLintWithoutArguments(
      name: 'prefer_iterable_wheretype',
      problemMessage: "Use 'whereType' to select elements of a given type.",
      correctionMessage: "Try rewriting the expression to use 'whereType'.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_iterable_wheretype',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
preferMixin = LinterLintTemplate(
  name: 'prefer_mixin',
  problemMessage: "Only mixins should be mixed in.",
  correctionMessage: "Try converting '{0}' to a mixin.",
  uniqueName: 'prefer_mixin',
  withArguments: _withArgumentsPreferMixin,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments
preferNullAwareMethodCalls = LinterLintWithoutArguments(
  name: 'prefer_null_aware_method_calls',
  problemMessage:
      "Use a null-aware invocation of the 'call' method rather than explicitly "
      "testing for 'null'.",
  correctionMessage: "Try using '?.call()' to invoke the function.",
  uniqueName: 'prefer_null_aware_method_calls',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments preferNullAwareOperators =
    LinterLintWithoutArguments(
      name: 'prefer_null_aware_operators',
      problemMessage:
          "Use the null-aware operator '?.' rather than an explicit 'null' "
          "comparison.",
      correctionMessage: "Try using '?.'.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_null_aware_operators',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferRelativeImports =
    LinterLintWithoutArguments(
      name: 'prefer_relative_imports',
      problemMessage: "Use relative imports for files in the 'lib' directory.",
      correctionMessage: "Try converting the URI to a relative URI.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_relative_imports',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferSingleQuotes =
    LinterLintWithoutArguments(
      name: 'prefer_single_quotes',
      problemMessage: "Unnecessary use of double quotes.",
      correctionMessage:
          "Try using single quotes unless the string contains single quotes.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_single_quotes',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferSpreadCollections =
    LinterLintWithoutArguments(
      name: 'prefer_spread_collections',
      problemMessage: "The addition of multiple elements could be inlined.",
      correctionMessage:
          "Try using the spread operator ('...') to inline the addition.",
      uniqueName: 'prefer_spread_collections',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments preferTypingUninitializedVariablesForField =
    LinterLintWithoutArguments(
      name: 'prefer_typing_uninitialized_variables',
      problemMessage:
          "An uninitialized field should have an explicit type annotation.",
      correctionMessage: "Try adding a type annotation.",
      hasPublishedDocs: true,
      uniqueName: 'prefer_typing_uninitialized_variables_for_field',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments
preferTypingUninitializedVariablesForLocalVariable = LinterLintWithoutArguments(
  name: 'prefer_typing_uninitialized_variables',
  problemMessage:
      "An uninitialized variable should have an explicit type annotation.",
  correctionMessage: "Try adding a type annotation.",
  hasPublishedDocs: true,
  uniqueName: 'prefer_typing_uninitialized_variables_for_local_variable',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments preferVoidToNull = LinterLintWithoutArguments(
  name: 'prefer_void_to_null',
  problemMessage: "Unnecessary use of the type 'Null'.",
  correctionMessage: "Try using 'void' instead.",
  hasPublishedDocs: true,
  uniqueName: 'prefer_void_to_null',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments provideDeprecationMessage =
    LinterLintWithoutArguments(
      name: 'provide_deprecation_message',
      problemMessage: "Missing a deprecation message.",
      correctionMessage:
          "Try using the constructor to provide a message "
          "('@Deprecated(\"message\")').",
      hasPublishedDocs: true,
      uniqueName: 'provide_deprecation_message',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments publicMemberApiDocs =
    LinterLintWithoutArguments(
      name: 'public_member_api_docs',
      problemMessage: "Missing documentation for a public member.",
      correctionMessage: "Try adding documentation for the member.",
      hasPublishedDocs: true,
      uniqueName: 'public_member_api_docs',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
recursiveGetters = LinterLintTemplate(
  name: 'recursive_getters',
  problemMessage: "The getter '{0}' recursively returns itself.",
  correctionMessage: "Try changing the value being returned.",
  hasPublishedDocs: true,
  uniqueName: 'recursive_getters',
  withArguments: _withArgumentsRecursiveGetters,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments removeDeprecationsInBreakingVersions =
    LinterLintWithoutArguments(
      name: 'remove_deprecations_in_breaking_versions',
      problemMessage: "Remove deprecated elements in breaking versions.",
      correctionMessage: "Try removing the deprecated element.",
      hasPublishedDocs: true,
      uniqueName: 'remove_deprecations_in_breaking_versions',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments requireTrailingCommas =
    LinterLintWithoutArguments(
      name: 'require_trailing_commas',
      problemMessage: "Missing a required trailing comma.",
      correctionMessage: "Try adding a trailing comma.",
      uniqueName: 'require_trailing_commas',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
securePubspecUrls = LinterLintTemplate(
  name: 'secure_pubspec_urls',
  problemMessage:
      "The '{0}' protocol shouldn't be used because it isn't secure.",
  correctionMessage: "Try using a secure protocol, such as 'https'.",
  hasPublishedDocs: true,
  uniqueName: 'secure_pubspec_urls',
  withArguments: _withArgumentsSecurePubspecUrls,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// String memberName: The redundant member name.
/// String memberType: The type of the matched object. Whether a field,
///                    getter, or method.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required String memberType,
  })
>
simplifyVariablePattern = LinterLintTemplate(
  name: 'simplify_variable_pattern',
  problemMessage:
      "The {1} identification '{0}:' is redundant and can be removed.",
  correctionMessage: "Try removing the redundant {1} identification.",
  uniqueName: 'simplify_variable_pattern',
  withArguments: _withArgumentsSimplifyVariablePattern,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const LinterLintWithoutArguments sizedBoxForWhitespace =
    LinterLintWithoutArguments(
      name: 'sized_box_for_whitespace',
      problemMessage: "Use a 'SizedBox' to add whitespace to a layout.",
      correctionMessage: "Try using a 'SizedBox' rather than a 'Container'.",
      hasPublishedDocs: true,
      uniqueName: 'sized_box_for_whitespace',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
sizedBoxShrinkExpand = LinterLintTemplate(
  name: 'sized_box_shrink_expand',
  problemMessage:
      "Use 'SizedBox.{0}' to avoid needing to specify the 'height' and 'width'.",
  correctionMessage:
      "Try using 'SizedBox.{0}' and removing the 'height' and 'width' "
      "arguments.",
  hasPublishedDocs: true,
  uniqueName: 'sized_box_shrink_expand',
  withArguments: _withArgumentsSizedBoxShrinkExpand,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments slashForDocComments =
    LinterLintWithoutArguments(
      name: 'slash_for_doc_comments',
      problemMessage: "Use the end-of-line form ('///') for doc comments.",
      correctionMessage: "Try rewriting the comment to use '///'.",
      hasPublishedDocs: true,
      uniqueName: 'slash_for_doc_comments',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
sortChildPropertiesLast = LinterLintTemplate(
  name: 'sort_child_properties_last',
  problemMessage:
      "The '{0}' argument should be last in widget constructor invocations.",
  correctionMessage: "Try moving the argument to the end of the argument list.",
  hasPublishedDocs: true,
  uniqueName: 'sort_child_properties_last',
  withArguments: _withArgumentsSortChildPropertiesLast,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments
sortConstructorsFirst = LinterLintWithoutArguments(
  name: 'sort_constructors_first',
  problemMessage:
      "Constructor declarations should be before non-constructor declarations.",
  correctionMessage:
      "Try moving the constructor declaration before all other members.",
  hasPublishedDocs: true,
  uniqueName: 'sort_constructors_first',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments sortPubDependencies =
    LinterLintWithoutArguments(
      name: 'sort_pub_dependencies',
      problemMessage: "Dependencies not sorted alphabetically.",
      correctionMessage:
          "Try sorting the dependencies alphabetically (A to Z).",
      hasPublishedDocs: true,
      uniqueName: 'sort_pub_dependencies',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments sortUnnamedConstructorsFirst =
    LinterLintWithoutArguments(
      name: 'sort_unnamed_constructors_first',
      problemMessage: "Invalid location for the unnamed constructor.",
      correctionMessage:
          "Try moving the unnamed constructor before all other constructors.",
      hasPublishedDocs: true,
      uniqueName: 'sort_unnamed_constructors_first',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments specifyNonobviousLocalVariableTypes =
    LinterLintWithoutArguments(
      name: 'specify_nonobvious_local_variable_types',
      problemMessage:
          "Specify the type of a local variable when the type is non-obvious.",
      correctionMessage: "Try adding a type annotation.",
      uniqueName: 'specify_nonobvious_local_variable_types',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments specifyNonobviousPropertyTypes =
    LinterLintWithoutArguments(
      name: 'specify_nonobvious_property_types',
      problemMessage: "A type annotation is needed because it isn't obvious.",
      correctionMessage: "Try adding a type annotation.",
      uniqueName: 'specify_nonobvious_property_types',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments strictTopLevelInferenceAddType =
    LinterLintWithoutArguments(
      name: 'strict_top_level_inference',
      problemMessage: "Missing type annotation.",
      correctionMessage: "Try adding a type annotation.",
      uniqueName: 'strict_top_level_inference_add_type',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
strictTopLevelInferenceReplaceKeyword = LinterLintTemplate(
  name: 'strict_top_level_inference',
  problemMessage: "Missing type annotation.",
  correctionMessage: "Try replacing '{0}' with a type annotation.",
  uniqueName: 'strict_top_level_inference_replace_keyword',
  withArguments: _withArgumentsStrictTopLevelInferenceReplaceKeyword,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments strictTopLevelInferenceSplitToTypes =
    LinterLintWithoutArguments(
      name: 'strict_top_level_inference',
      problemMessage: "Missing type annotation.",
      correctionMessage:
          "Try splitting the declaration and specify the different type "
          "annotations.",
      uniqueName: 'strict_top_level_inference_split_to_types',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments superGoesLast = LinterLintWithoutArguments(
  name: 'super_goes_last',
  problemMessage: "",
  uniqueName: 'super_goes_last',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments switchOnType = LinterLintWithoutArguments(
  name: 'switch_on_type',
  problemMessage: "Avoid switch statements on a 'Type'.",
  correctionMessage: "Try using pattern matching on a variable instead.",
  hasPublishedDocs: true,
  uniqueName: 'switch_on_type',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
testTypesInEquals = LinterLintTemplate(
  name: 'test_types_in_equals',
  problemMessage: "Missing type test for '{0}' in '=='.",
  correctionMessage: "Try testing the type of '{0}'.",
  hasPublishedDocs: true,
  uniqueName: 'test_types_in_equals',
  withArguments: _withArgumentsTestTypesInEquals,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
throwInFinally = LinterLintTemplate(
  name: 'throw_in_finally',
  problemMessage: "Use of '{0}' in 'finally' block.",
  correctionMessage: "Try moving the '{0}' outside the 'finally' block.",
  hasPublishedDocs: true,
  uniqueName: 'throw_in_finally',
  withArguments: _withArgumentsThrowInFinally,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments
tightenTypeOfInitializingFormals = LinterLintWithoutArguments(
  name: 'tighten_type_of_initializing_formals',
  problemMessage:
      "Use a type annotation rather than 'assert' to enforce non-nullability.",
  correctionMessage: "Try adding a type annotation and removing the 'assert'.",
  hasPublishedDocs: true,
  uniqueName: 'tighten_type_of_initializing_formals',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments typeAnnotatePublicApis =
    LinterLintWithoutArguments(
      name: 'type_annotate_public_apis',
      problemMessage: "Missing type annotation on a public API.",
      correctionMessage: "Try adding a type annotation.",
      hasPublishedDocs: true,
      uniqueName: 'type_annotate_public_apis',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments typeInitFormals = LinterLintWithoutArguments(
  name: 'type_init_formals',
  problemMessage: "Don't needlessly type annotate initializing formals.",
  correctionMessage: "Try removing the type.",
  hasPublishedDocs: true,
  uniqueName: 'type_init_formals',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments typeLiteralInConstantPattern =
    LinterLintWithoutArguments(
      name: 'type_literal_in_constant_pattern',
      problemMessage: "Use 'TypeName _' instead of a type literal.",
      correctionMessage: "Replace with 'TypeName _'.",
      hasPublishedDocs: true,
      uniqueName: 'type_literal_in_constant_pattern',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unawaitedFutures = LinterLintWithoutArguments(
  name: 'unawaited_futures',
  problemMessage:
      "Missing an 'await' for the 'Future' computed by this expression.",
  correctionMessage:
      "Try adding an 'await' or wrapping the expression with 'unawaited'.",
  hasPublishedDocs: true,
  uniqueName: 'unawaited_futures',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments unintendedHtmlInDocComment =
    LinterLintWithoutArguments(
      name: 'unintended_html_in_doc_comment',
      problemMessage: "Angle brackets will be interpreted as HTML.",
      correctionMessage:
          "Try using backticks around the content with angle brackets, or try "
          "replacing `<` with `&lt;` and `>` with `&gt;`.",
      hasPublishedDocs: true,
      uniqueName: 'unintended_html_in_doc_comment',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryAsync = LinterLintWithoutArguments(
  name: 'unnecessary_async',
  problemMessage: "Don't make a function 'async' if it doesn't use 'await'.",
  correctionMessage: "Try removing the 'async' modifier.",
  uniqueName: 'unnecessary_async',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments unnecessaryAwaitInReturn =
    LinterLintWithoutArguments(
      name: 'unnecessary_await_in_return',
      problemMessage: "Unnecessary 'await'.",
      correctionMessage: "Try removing the 'await'.",
      uniqueName: 'unnecessary_await_in_return',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryBraceInStringInterps =
    LinterLintWithoutArguments(
      name: 'unnecessary_brace_in_string_interps',
      problemMessage: "Unnecessary braces in a string interpolation.",
      correctionMessage: "Try removing the braces.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_brace_in_string_interps',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryBreaks = LinterLintWithoutArguments(
  name: 'unnecessary_breaks',
  problemMessage: "Unnecessary 'break' statement.",
  correctionMessage: "Try removing the 'break'.",
  uniqueName: 'unnecessary_breaks',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments unnecessaryConst = LinterLintWithoutArguments(
  name: 'unnecessary_const',
  problemMessage: "Unnecessary 'const' keyword.",
  correctionMessage: "Try removing the keyword.",
  hasPublishedDocs: true,
  uniqueName: 'unnecessary_const',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments unnecessaryConstructorName =
    LinterLintWithoutArguments(
      name: 'unnecessary_constructor_name',
      problemMessage: "Unnecessary '.new' constructor name.",
      correctionMessage: "Try removing the '.new'.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_constructor_name',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryFinalWithoutType =
    LinterLintWithoutArguments(
      name: 'unnecessary_final',
      problemMessage: "Local variables should not be marked as 'final'.",
      correctionMessage: "Replace 'final' with 'var'.",
      uniqueName: 'unnecessary_final_without_type',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryFinalWithType =
    LinterLintWithoutArguments(
      name: 'unnecessary_final',
      problemMessage: "Local variables should not be marked as 'final'.",
      correctionMessage: "Remove the 'final'.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_final_with_type',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryGettersSetters =
    LinterLintWithoutArguments(
      name: 'unnecessary_getters_setters',
      problemMessage: "Unnecessary use of getter and setter to wrap a field.",
      correctionMessage:
          "Try removing the getter and setter and renaming the field.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_getters_setters',
      expectedTypes: [],
    );

/// Parameters:
/// String name: The diagnostic name.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unnecessaryIgnore = LinterLintTemplate(
  name: 'unnecessary_ignore',
  problemMessage:
      "The diagnostic '{0}' isn't produced at this location so it doesn't need "
      "to be ignored.",
  correctionMessage: "Try removing the ignore comment.",
  hasPublishedDocs: true,
  uniqueName: 'unnecessary_ignore',
  withArguments: _withArgumentsUnnecessaryIgnore,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: The diagnostic name.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unnecessaryIgnoreFile = LinterLintTemplate(
  name: 'unnecessary_ignore',
  problemMessage:
      "The diagnostic '{0}' isn't produced in this file so it doesn't need to be "
      "ignored.",
  correctionMessage: "Try removing the ignore comment.",
  uniqueName: 'unnecessary_ignore_file',
  withArguments: _withArgumentsUnnecessaryIgnoreFile,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: The diagnostic name.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unnecessaryIgnoreName = LinterLintTemplate(
  name: 'unnecessary_ignore',
  problemMessage:
      "The diagnostic '{0}' isn't produced at this location so it doesn't need "
      "to be ignored.",
  correctionMessage: "Try removing the name from the list.",
  uniqueName: 'unnecessary_ignore_name',
  withArguments: _withArgumentsUnnecessaryIgnoreName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: The diagnostic name.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unnecessaryIgnoreNameFile = LinterLintTemplate(
  name: 'unnecessary_ignore',
  problemMessage:
      "The diagnostic '{0}' isn't produced in this file so it doesn't need to be "
      "ignored.",
  correctionMessage: "Try removing the name from the list.",
  uniqueName: 'unnecessary_ignore_name_file',
  withArguments: _withArgumentsUnnecessaryIgnoreNameFile,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const LinterLintWithoutArguments unnecessaryLambdas =
    LinterLintWithoutArguments(
      name: 'unnecessary_lambdas',
      problemMessage: "Closure should be a tearoff.",
      correctionMessage: "Try using a tearoff rather than a closure.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_lambdas',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryLate = LinterLintWithoutArguments(
  name: 'unnecessary_late',
  problemMessage: "Unnecessary 'late' modifier.",
  correctionMessage: "Try removing the 'late'.",
  hasPublishedDocs: true,
  uniqueName: 'unnecessary_late',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments
unnecessaryLibraryDirective = LinterLintWithoutArguments(
  name: 'unnecessary_library_directive',
  problemMessage:
      "Library directives without comments or annotations should be avoided.",
  correctionMessage: "Try deleting the library directive.",
  uniqueName: 'unnecessary_library_directive',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments unnecessaryLibraryName =
    LinterLintWithoutArguments(
      name: 'unnecessary_library_name',
      problemMessage: "Library names are not necessary.",
      correctionMessage: "Remove the library name.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_library_name',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryNew = LinterLintWithoutArguments(
  name: 'unnecessary_new',
  problemMessage: "Unnecessary 'new' keyword.",
  correctionMessage: "Try removing the 'new' keyword.",
  hasPublishedDocs: true,
  uniqueName: 'unnecessary_new',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments
unnecessaryNullableForFinalVariableDeclarations = LinterLintWithoutArguments(
  name: 'unnecessary_nullable_for_final_variable_declarations',
  problemMessage: "Type could be non-nullable.",
  correctionMessage: "Try changing the type to be non-nullable.",
  hasPublishedDocs: true,
  uniqueName: 'unnecessary_nullable_for_final_variable_declarations',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments unnecessaryNullAwareAssignments =
    LinterLintWithoutArguments(
      name: 'unnecessary_null_aware_assignments',
      problemMessage: "Unnecessary assignment of 'null'.",
      correctionMessage: "Try removing the assignment.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_null_aware_assignments',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments
unnecessaryNullAwareOperatorOnExtensionOnNullable = LinterLintWithoutArguments(
  name: 'unnecessary_null_aware_operator_on_extension_on_nullable',
  problemMessage:
      "Unnecessary use of a null-aware operator to invoke an extension method on "
      "a nullable type.",
  correctionMessage: "Try removing the '?'.",
  hasPublishedDocs: true,
  uniqueName: 'unnecessary_null_aware_operator_on_extension_on_nullable',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments unnecessaryNullChecks =
    LinterLintWithoutArguments(
      name: 'unnecessary_null_checks',
      problemMessage: "Unnecessary use of a null check ('!').",
      correctionMessage: "Try removing the null check.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_null_checks',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryNullInIfNullOperators =
    LinterLintWithoutArguments(
      name: 'unnecessary_null_in_if_null_operators',
      problemMessage: "Unnecessary use of '??' with 'null'.",
      correctionMessage:
          "Try removing the '??' operator and the 'null' operand.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_null_in_if_null_operators',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryOverrides =
    LinterLintWithoutArguments(
      name: 'unnecessary_overrides',
      problemMessage: "Unnecessary override.",
      correctionMessage:
          "Try adding behavior in the overriding member or removing the "
          "override.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_overrides',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryParenthesis =
    LinterLintWithoutArguments(
      name: 'unnecessary_parenthesis',
      problemMessage: "Unnecessary use of parentheses.",
      correctionMessage: "Try removing the parentheses.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_parenthesis',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryRawStrings =
    LinterLintWithoutArguments(
      name: 'unnecessary_raw_strings',
      problemMessage: "Unnecessary use of a raw string.",
      correctionMessage: "Try using a normal string.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_raw_strings',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryStatements =
    LinterLintWithoutArguments(
      name: 'unnecessary_statements',
      problemMessage: "Unnecessary statement.",
      correctionMessage: "Try completing the statement or breaking it up.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_statements',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryStringEscapes =
    LinterLintWithoutArguments(
      name: 'unnecessary_string_escapes',
      problemMessage: "Unnecessary escape in string literal.",
      correctionMessage: "Remove the '\\' escape.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_string_escapes',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryStringInterpolations =
    LinterLintWithoutArguments(
      name: 'unnecessary_string_interpolations',
      problemMessage: "Unnecessary use of string interpolation.",
      correctionMessage:
          "Try replacing the string literal with the variable name.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_string_interpolations',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryThis = LinterLintWithoutArguments(
  name: 'unnecessary_this',
  problemMessage: "Unnecessary 'this.' qualifier.",
  correctionMessage: "Try removing 'this.'.",
  hasPublishedDocs: true,
  uniqueName: 'unnecessary_this',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments unnecessaryToListInSpreads =
    LinterLintWithoutArguments(
      name: 'unnecessary_to_list_in_spreads',
      problemMessage: "Unnecessary use of 'toList' in a spread.",
      correctionMessage: "Try removing the invocation of 'toList'.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_to_list_in_spreads',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryUnawaited =
    LinterLintWithoutArguments(
      name: 'unnecessary_unawaited',
      problemMessage: "Unnecessary use of 'unawaited'.",
      correctionMessage:
          "Try removing the use of 'unawaited', as the unawaited element is "
          "annotated with '@awaitNotRequired'.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_unawaited',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments unnecessaryUnderscores =
    LinterLintWithoutArguments(
      name: 'unnecessary_underscores',
      problemMessage: "Unnecessary use of multiple underscores.",
      correctionMessage: "Try using '_'.",
      hasPublishedDocs: true,
      uniqueName: 'unnecessary_underscores',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unreachableFromMain = LinterLintTemplate(
  name: 'unreachable_from_main',
  problemMessage: "Unreachable member '{0}' in an executable library.",
  correctionMessage: "Try referencing the member or removing it.",
  uniqueName: 'unreachable_from_main',
  withArguments: _withArgumentsUnreachableFromMain,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
/// Object p1: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
unrelatedTypeEqualityChecksInExpression = LinterLintTemplate(
  name: 'unrelated_type_equality_checks',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
unrelatedTypeEqualityChecksInPattern = LinterLintTemplate(
  name: 'unrelated_type_equality_checks',
  problemMessage:
      "The type of the operand ('{0}') isn't a subtype or a supertype of the "
      "value being matched ('{1}').",
  correctionMessage: "Try changing one or both of the operands.",
  hasPublishedDocs: true,
  uniqueName: 'unrelated_type_equality_checks_in_pattern',
  withArguments: _withArgumentsUnrelatedTypeEqualityChecksInPattern,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unsafeHtmlAttribute = LinterLintTemplate(
  name: 'unsafe_html',
  problemMessage: "Assigning to the attribute '{0}' is unsafe.",
  correctionMessage: "Try finding a different way to implement the page.",
  uniqueName: 'unsafe_html_attribute',
  withArguments: _withArgumentsUnsafeHtmlAttribute,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unsafeHtmlConstructor = LinterLintTemplate(
  name: 'unsafe_html',
  problemMessage: "Invoking the constructor '{0}' is unsafe.",
  correctionMessage: "Try finding a different way to implement the page.",
  uniqueName: 'unsafe_html_constructor',
  withArguments: _withArgumentsUnsafeHtmlConstructor,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unsafeHtmlMethod = LinterLintTemplate(
  name: 'unsafe_html',
  problemMessage: "Invoking the method '{0}' is unsafe.",
  correctionMessage: "Try finding a different way to implement the page.",
  uniqueName: 'unsafe_html_method',
  withArguments: _withArgumentsUnsafeHtmlMethod,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments unsafeVariance = LinterLintWithoutArguments(
  name: 'unsafe_variance',
  problemMessage:
      "This type is unsafe: a type parameter occurs in a non-covariant position.",
  correctionMessage:
      "Try using a more general type that doesn't contain any type "
      "parameters in such a position.",
  hasPublishedDocs: true,
  uniqueName: 'unsafe_variance',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments useBuildContextSynchronouslyAsyncUse =
    LinterLintWithoutArguments(
      name: 'use_build_context_synchronously',
      problemMessage: "Don't use 'BuildContext's across async gaps.",
      correctionMessage:
          "Try rewriting the code to not use the 'BuildContext', or guard the "
          "use with a 'mounted' check.",
      hasPublishedDocs: true,
      uniqueName: 'use_build_context_synchronously_async_use',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments
useBuildContextSynchronouslyWrongMounted = LinterLintWithoutArguments(
  name: 'use_build_context_synchronously',
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
const LinterLintWithoutArguments useColoredBox = LinterLintWithoutArguments(
  name: 'use_colored_box',
  problemMessage:
      "Use a 'ColoredBox' rather than a 'Container' with only a 'Color'.",
  correctionMessage: "Try replacing the 'Container' with a 'ColoredBox'.",
  hasPublishedDocs: true,
  uniqueName: 'use_colored_box',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments useDecoratedBox = LinterLintWithoutArguments(
  name: 'use_decorated_box',
  problemMessage:
      "Use 'DecoratedBox' rather than a 'Container' with only a 'Decoration'.",
  correctionMessage: "Try replacing the 'Container' with a 'DecoratedBox'.",
  hasPublishedDocs: true,
  uniqueName: 'use_decorated_box',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments useEnums = LinterLintWithoutArguments(
  name: 'use_enums',
  problemMessage: "Class should be an enum.",
  correctionMessage: "Try using an enum rather than a class.",
  uniqueName: 'use_enums',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments useFullHexValuesForFlutterColors =
    LinterLintWithoutArguments(
      name: 'use_full_hex_values_for_flutter_colors',
      problemMessage:
          "Instances of 'Color' should be created using an 8-digit hexadecimal "
          "integer (such as '0xFFFFFFFF').",
      hasPublishedDocs: true,
      uniqueName: 'use_full_hex_values_for_flutter_colors',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
useFunctionTypeSyntaxForParameters = LinterLintTemplate(
  name: 'use_function_type_syntax_for_parameters',
  problemMessage:
      "Use the generic function type syntax to declare the parameter '{0}'.",
  correctionMessage: "Try using the generic function type syntax.",
  hasPublishedDocs: true,
  uniqueName: 'use_function_type_syntax_for_parameters',
  withArguments: _withArgumentsUseFunctionTypeSyntaxForParameters,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments useIfNullToConvertNullsToBools =
    LinterLintWithoutArguments(
      name: 'use_if_null_to_convert_nulls_to_bools',
      problemMessage:
          "Use an if-null operator to convert a 'null' to a 'bool'.",
      correctionMessage: "Try using an if-null operator.",
      hasPublishedDocs: true,
      uniqueName: 'use_if_null_to_convert_nulls_to_bools',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
useIsEvenRatherThanModulo = LinterLintTemplate(
  name: 'use_is_even_rather_than_modulo',
  problemMessage: "Use '{0}' rather than '% 2'.",
  correctionMessage: "Try using '{0}'.",
  uniqueName: 'use_is_even_rather_than_modulo',
  withArguments: _withArgumentsUseIsEvenRatherThanModulo,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments
useKeyInWidgetConstructors = LinterLintWithoutArguments(
  name: 'use_key_in_widget_constructors',
  problemMessage:
      "Constructors for public widgets should have a named 'key' parameter.",
  correctionMessage: "Try adding a named parameter to the constructor.",
  hasPublishedDocs: true,
  uniqueName: 'use_key_in_widget_constructors',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments useLateForPrivateFieldsAndVariables =
    LinterLintWithoutArguments(
      name: 'use_late_for_private_fields_and_variables',
      problemMessage:
          "Use 'late' for private members with a non-nullable type.",
      correctionMessage: "Try making adding the modifier 'late'.",
      hasPublishedDocs: true,
      uniqueName: 'use_late_for_private_fields_and_variables',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
useNamedConstants = LinterLintTemplate(
  name: 'use_named_constants',
  problemMessage:
      "Use the constant '{0}' rather than a constructor returning the same "
      "object.",
  correctionMessage: "Try using '{0}'.",
  hasPublishedDocs: true,
  uniqueName: 'use_named_constants',
  withArguments: _withArgumentsUseNamedConstants,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments useNullAwareElements =
    LinterLintWithoutArguments(
      name: 'use_null_aware_elements',
      problemMessage:
          "Use the null-aware marker '?' rather than a null check via an 'if'.",
      correctionMessage: "Try using '?'.",
      hasPublishedDocs: true,
      uniqueName: 'use_null_aware_elements',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments useRawStrings = LinterLintWithoutArguments(
  name: 'use_raw_strings',
  problemMessage: "Use a raw string to avoid using escapes.",
  correctionMessage:
      "Try making the string a raw string and removing the escapes.",
  hasPublishedDocs: true,
  uniqueName: 'use_raw_strings',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments useRethrowWhenPossible =
    LinterLintWithoutArguments(
      name: 'use_rethrow_when_possible',
      problemMessage: "Use 'rethrow' to rethrow a caught exception.",
      correctionMessage: "Try replacing the 'throw' with a 'rethrow'.",
      hasPublishedDocs: true,
      uniqueName: 'use_rethrow_when_possible',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments useSettersToChangeProperties =
    LinterLintWithoutArguments(
      name: 'use_setters_to_change_properties',
      problemMessage: "The method is used to change a property.",
      correctionMessage: "Try converting the method to a setter.",
      hasPublishedDocs: true,
      uniqueName: 'use_setters_to_change_properties',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments useStringBuffers = LinterLintWithoutArguments(
  name: 'use_string_buffers',
  problemMessage: "Use a string buffer rather than '+' to compose strings.",
  correctionMessage: "Try writing the parts of a string to a string buffer.",
  hasPublishedDocs: true,
  uniqueName: 'use_string_buffers',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments useStringInPartOfDirectives =
    LinterLintWithoutArguments(
      name: 'use_string_in_part_of_directives',
      problemMessage: "The part-of directive uses a library name.",
      correctionMessage:
          "Try converting the directive to use the URI of the library.",
      hasPublishedDocs: true,
      uniqueName: 'use_string_in_part_of_directives',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
useSuperParametersMultiple = LinterLintTemplate(
  name: 'use_super_parameters',
  problemMessage: "Parameters '{0}' could be super parameters.",
  correctionMessage: "Trying converting '{0}' to super parameters.",
  hasPublishedDocs: true,
  uniqueName: 'use_super_parameters_multiple',
  withArguments: _withArgumentsUseSuperParametersMultiple,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
useSuperParametersSingle = LinterLintTemplate(
  name: 'use_super_parameters',
  problemMessage: "Parameter '{0}' could be a super parameter.",
  correctionMessage: "Trying converting '{0}' to a super parameter.",
  hasPublishedDocs: true,
  uniqueName: 'use_super_parameters_single',
  withArguments: _withArgumentsUseSuperParametersSingle,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const LinterLintWithoutArguments useTestThrowsMatchers =
    LinterLintWithoutArguments(
      name: 'use_test_throws_matchers',
      problemMessage:
          "Use the 'throwsA' matcher instead of using 'fail' when there is no "
          "exception thrown.",
      correctionMessage:
          "Try removing the try-catch and using 'throwsA' to expect an "
          "exception.",
      uniqueName: 'use_test_throws_matchers',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments useToAndAsIfApplicable =
    LinterLintWithoutArguments(
      name: 'use_to_and_as_if_applicable',
      problemMessage: "Start the name of the method with 'to' or 'as'.",
      correctionMessage: "Try renaming the method to use either 'to' or 'as'.",
      uniqueName: 'use_to_and_as_if_applicable',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments useTruncatingDivision =
    LinterLintWithoutArguments(
      name: 'use_truncating_division',
      problemMessage: "Use truncating division.",
      correctionMessage:
          "Try using truncating division, '~/', instead of regular division "
          "('/') followed by 'toInt()'.",
      hasPublishedDocs: true,
      uniqueName: 'use_truncating_division',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments validRegexps = LinterLintWithoutArguments(
  name: 'valid_regexps',
  problemMessage: "Invalid regular expression syntax.",
  correctionMessage: "Try correcting the regular expression.",
  hasPublishedDocs: true,
  uniqueName: 'valid_regexps',
  expectedTypes: [],
);

/// No parameters.
const LinterLintWithoutArguments varWithNoTypeAnnotation =
    LinterLintWithoutArguments(
      name: 'var_with_no_type_annotation',
      problemMessage:
          "Avoid declaring parameters with `var` and no type annotation.",
      correctionMessage:
          "Try removing the keyword 'var' or replacing `var` with a type "
          "annotation.",
      uniqueName: 'var_with_no_type_annotation',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments visitRegisteredNodes =
    LinterLintWithoutArguments(
      name: 'visit_registered_nodes',
      problemMessage: "Declare 'visit' methods for all registered node types.",
      correctionMessage:
          "Try declaring a 'visit' method for all registered node types.",
      hasPublishedDocs: true,
      uniqueName: 'visit_registered_nodes',
      expectedTypes: [],
    );

/// No parameters.
const LinterLintWithoutArguments voidChecks = LinterLintWithoutArguments(
  name: 'void_checks',
  problemMessage: "Assignment to a variable of type 'void'.",
  correctionMessage:
      "Try removing the assignment or changing the type of the variable.",
  hasPublishedDocs: true,
  uniqueName: 'void_checks',
  expectedTypes: [],
);

LocatableDiagnostic _withArgumentsAlwaysDeclareReturnTypesOfFunctions({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.alwaysDeclareReturnTypesOfFunctions, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsAlwaysDeclareReturnTypesOfMethods({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.alwaysDeclareReturnTypesOfMethods, [p0]);
}

LocatableDiagnostic _withArgumentsAlwaysSpecifyTypesReplaceKeyword({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.alwaysSpecifyTypesReplaceKeyword, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsAlwaysSpecifyTypesSpecifyType({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.alwaysSpecifyTypesSpecifyType, [p0]);
}

LocatableDiagnostic _withArgumentsAnalyzerPublicApiBadType({
  required String types,
}) {
  return LocatableDiagnosticImpl(diag.analyzerPublicApiBadType, [types]);
}

LocatableDiagnostic _withArgumentsAnalyzerPublicApiExperimentalInconsistency({
  required String types,
}) {
  return LocatableDiagnosticImpl(
    diag.analyzerPublicApiExperimentalInconsistency,
    [types],
  );
}

LocatableDiagnostic _withArgumentsAnalyzerPublicApiExportsNonPublicName({
  required String elements,
}) {
  return LocatableDiagnosticImpl(diag.analyzerPublicApiExportsNonPublicName, [
    elements,
  ]);
}

LocatableDiagnostic _withArgumentsAnnotateOverrides({required Object p0}) {
  return LocatableDiagnosticImpl(diag.annotateOverrides, [p0]);
}

LocatableDiagnostic _withArgumentsAnnotateRedeclares({required Object p0}) {
  return LocatableDiagnosticImpl(diag.annotateRedeclares, [p0]);
}

LocatableDiagnostic _withArgumentsAvoidCatchingErrorsSubclass({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.avoidCatchingErrorsSubclass, [p0]);
}

LocatableDiagnostic _withArgumentsAvoidEqualsAndHashCodeOnMutableClasses({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.avoidEqualsAndHashCodeOnMutableClasses, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsAvoidEscapingInnerQuotes({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.avoidEscapingInnerQuotes, [p0, p1]);
}

LocatableDiagnostic _withArgumentsAvoidRenamingMethodParameters({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.avoidRenamingMethodParameters, [p0, p1]);
}

LocatableDiagnostic _withArgumentsAvoidShadowingTypeParameters({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.avoidShadowingTypeParameters, [p0, p1]);
}

LocatableDiagnostic _withArgumentsAvoidSingleCascadeInExpressionStatements({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(
    diag.avoidSingleCascadeInExpressionStatements,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsAvoidTypesAsParameterNamesFormalParameter({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(
    diag.avoidTypesAsParameterNamesFormalParameter,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsAvoidTypesAsParameterNamesTypeParameter({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.avoidTypesAsParameterNamesTypeParameter, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsAvoidUnusedConstructorParameters({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.avoidUnusedConstructorParameters, [p0]);
}

LocatableDiagnostic _withArgumentsAwaitOnlyFutures({required Object p0}) {
  return LocatableDiagnosticImpl(diag.awaitOnlyFutures, [p0]);
}

LocatableDiagnostic _withArgumentsCamelCaseExtensions({required Object p0}) {
  return LocatableDiagnosticImpl(diag.camelCaseExtensions, [p0]);
}

LocatableDiagnostic _withArgumentsCamelCaseTypes({required Object p0}) {
  return LocatableDiagnosticImpl(diag.camelCaseTypes, [p0]);
}

LocatableDiagnostic _withArgumentsCollectionMethodsUnrelatedType({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.collectionMethodsUnrelatedType, [p0, p1]);
}

LocatableDiagnostic _withArgumentsConditionalUriDoesNotExist({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.conditionalUriDoesNotExist, [p0]);
}

LocatableDiagnostic _withArgumentsConstantIdentifierNames({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.constantIdentifierNames, [p0]);
}

LocatableDiagnostic _withArgumentsControlFlowInFinally({required Object p0}) {
  return LocatableDiagnosticImpl(diag.controlFlowInFinally, [p0]);
}

LocatableDiagnostic _withArgumentsCurlyBracesInFlowControlStructures({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.curlyBracesInFlowControlStructures, [p0]);
}

LocatableDiagnostic _withArgumentsDependOnReferencedPackages({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.dependOnReferencedPackages, [p0]);
}

LocatableDiagnostic
_withArgumentsDeprecatedMemberUseFromSamePackageWithMessage({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(
    diag.deprecatedMemberUseFromSamePackageWithMessage,
    [p0, p1],
  );
}

LocatableDiagnostic
_withArgumentsDeprecatedMemberUseFromSamePackageWithoutMessage({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(
    diag.deprecatedMemberUseFromSamePackageWithoutMessage,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsDirectivesOrderingDart({required Object p0}) {
  return LocatableDiagnosticImpl(diag.directivesOrderingDart, [p0]);
}

LocatableDiagnostic _withArgumentsDirectivesOrderingPackageBeforeRelative({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.directivesOrderingPackageBeforeRelative, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsExhaustiveCases({required Object p0}) {
  return LocatableDiagnosticImpl(diag.exhaustiveCases, [p0]);
}

LocatableDiagnostic _withArgumentsFileNames({required Object p0}) {
  return LocatableDiagnosticImpl(diag.fileNames, [p0]);
}

LocatableDiagnostic _withArgumentsHashAndEquals({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.hashAndEquals, [p0, p1]);
}

LocatableDiagnostic _withArgumentsImplicitReopen({
  required Object p0,
  required Object p1,
  required Object p2,
  required Object p3,
}) {
  return LocatableDiagnosticImpl(diag.implicitReopen, [p0, p1, p2, p3]);
}

LocatableDiagnostic
_withArgumentsInvalidRuntimeCheckWithJsInteropTypesDartAsJs({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(
    diag.invalidRuntimeCheckWithJsInteropTypesDartAsJs,
    [p0, p1],
  );
}

LocatableDiagnostic
_withArgumentsInvalidRuntimeCheckWithJsInteropTypesDartIsJs({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(
    diag.invalidRuntimeCheckWithJsInteropTypesDartIsJs,
    [p0, p1],
  );
}

LocatableDiagnostic
_withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsAsDart({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(
    diag.invalidRuntimeCheckWithJsInteropTypesJsAsDart,
    [p0, p1],
  );
}

LocatableDiagnostic
_withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(
    diag.invalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs,
    [p0, p1],
  );
}

LocatableDiagnostic
_withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsDart({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(
    diag.invalidRuntimeCheckWithJsInteropTypesJsIsDart,
    [p0, p1],
  );
}

LocatableDiagnostic
_withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(
    diag.invalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs,
    [p0, p1],
  );
}

LocatableDiagnostic
_withArgumentsInvalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(
    diag.invalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs,
    [p0, p1],
  );
}

LocatableDiagnostic _withArgumentsLibraryNames({required Object p0}) {
  return LocatableDiagnosticImpl(diag.libraryNames, [p0]);
}

LocatableDiagnostic _withArgumentsLibraryPrefixes({required Object p0}) {
  return LocatableDiagnosticImpl(diag.libraryPrefixes, [p0]);
}

LocatableDiagnostic _withArgumentsMatchingSuperParameters({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.matchingSuperParameters, [p0, p1]);
}

LocatableDiagnostic _withArgumentsNoDuplicateCaseValues({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.noDuplicateCaseValues, [p0, p1]);
}

LocatableDiagnostic _withArgumentsNoLeadingUnderscoresForLibraryPrefixes({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.noLeadingUnderscoresForLibraryPrefixes, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsNoLeadingUnderscoresForLocalIdentifiers({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.noLeadingUnderscoresForLocalIdentifiers, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsNonConstantIdentifierNames({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.nonConstantIdentifierNames, [p0]);
}

LocatableDiagnostic _withArgumentsOneMemberAbstracts({required Object p0}) {
  return LocatableDiagnosticImpl(diag.oneMemberAbstracts, [p0]);
}

LocatableDiagnostic _withArgumentsOverriddenFields({required Object p0}) {
  return LocatableDiagnosticImpl(diag.overriddenFields, [p0]);
}

LocatableDiagnostic _withArgumentsPackageNames({required Object p0}) {
  return LocatableDiagnosticImpl(diag.packageNames, [p0]);
}

LocatableDiagnostic _withArgumentsPackagePrefixedLibraryNames({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.packagePrefixedLibraryNames, [p0]);
}

LocatableDiagnostic _withArgumentsParameterAssignments({required Object p0}) {
  return LocatableDiagnosticImpl(diag.parameterAssignments, [p0]);
}

LocatableDiagnostic _withArgumentsPreferFinalFields({required Object p0}) {
  return LocatableDiagnosticImpl(diag.preferFinalFields, [p0]);
}

LocatableDiagnostic _withArgumentsPreferFinalInForEachVariable({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.preferFinalInForEachVariable, [p0]);
}

LocatableDiagnostic _withArgumentsPreferFinalParameters({required Object p0}) {
  return LocatableDiagnosticImpl(diag.preferFinalParameters, [p0]);
}

LocatableDiagnostic _withArgumentsPreferGenericFunctionTypeAliases({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.preferGenericFunctionTypeAliases, [p0]);
}

LocatableDiagnostic _withArgumentsPreferInitializingFormals({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.preferInitializingFormals, [p0]);
}

LocatableDiagnostic _withArgumentsPreferMixin({required Object p0}) {
  return LocatableDiagnosticImpl(diag.preferMixin, [p0]);
}

LocatableDiagnostic _withArgumentsRecursiveGetters({required Object p0}) {
  return LocatableDiagnosticImpl(diag.recursiveGetters, [p0]);
}

LocatableDiagnostic _withArgumentsSecurePubspecUrls({required Object p0}) {
  return LocatableDiagnosticImpl(diag.securePubspecUrls, [p0]);
}

LocatableDiagnostic _withArgumentsSimplifyVariablePattern({
  required String memberName,
  required String memberType,
}) {
  return LocatableDiagnosticImpl(diag.simplifyVariablePattern, [
    memberName,
    memberType,
  ]);
}

LocatableDiagnostic _withArgumentsSizedBoxShrinkExpand({required Object p0}) {
  return LocatableDiagnosticImpl(diag.sizedBoxShrinkExpand, [p0]);
}

LocatableDiagnostic _withArgumentsSortChildPropertiesLast({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.sortChildPropertiesLast, [p0]);
}

LocatableDiagnostic _withArgumentsStrictTopLevelInferenceReplaceKeyword({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.strictTopLevelInferenceReplaceKeyword, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsTestTypesInEquals({required Object p0}) {
  return LocatableDiagnosticImpl(diag.testTypesInEquals, [p0]);
}

LocatableDiagnostic _withArgumentsThrowInFinally({required Object p0}) {
  return LocatableDiagnosticImpl(diag.throwInFinally, [p0]);
}

LocatableDiagnostic _withArgumentsUnnecessaryIgnore({required String name}) {
  return LocatableDiagnosticImpl(diag.unnecessaryIgnore, [name]);
}

LocatableDiagnostic _withArgumentsUnnecessaryIgnoreFile({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.unnecessaryIgnoreFile, [name]);
}

LocatableDiagnostic _withArgumentsUnnecessaryIgnoreName({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.unnecessaryIgnoreName, [name]);
}

LocatableDiagnostic _withArgumentsUnnecessaryIgnoreNameFile({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.unnecessaryIgnoreNameFile, [name]);
}

LocatableDiagnostic _withArgumentsUnreachableFromMain({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unreachableFromMain, [p0]);
}

LocatableDiagnostic _withArgumentsUnrelatedTypeEqualityChecksInExpression({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.unrelatedTypeEqualityChecksInExpression, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsUnrelatedTypeEqualityChecksInPattern({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.unrelatedTypeEqualityChecksInPattern, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsUnsafeHtmlAttribute({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unsafeHtmlAttribute, [p0]);
}

LocatableDiagnostic _withArgumentsUnsafeHtmlConstructor({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unsafeHtmlConstructor, [p0]);
}

LocatableDiagnostic _withArgumentsUnsafeHtmlMethod({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unsafeHtmlMethod, [p0]);
}

LocatableDiagnostic _withArgumentsUseFunctionTypeSyntaxForParameters({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.useFunctionTypeSyntaxForParameters, [p0]);
}

LocatableDiagnostic _withArgumentsUseIsEvenRatherThanModulo({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.useIsEvenRatherThanModulo, [p0]);
}

LocatableDiagnostic _withArgumentsUseNamedConstants({required Object p0}) {
  return LocatableDiagnosticImpl(diag.useNamedConstants, [p0]);
}

LocatableDiagnostic _withArgumentsUseSuperParametersMultiple({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.useSuperParametersMultiple, [p0]);
}

LocatableDiagnostic _withArgumentsUseSuperParametersSingle({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.useSuperParametersSingle, [p0]);
}
