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

import 'analyzer.dart';

class LinterLintCode extends LintCode {
  /// Parameters:
  /// Object p0: undocumented
  static const LintCode alwaysDeclareReturnTypesOfFunctions = LinterLintCode(
    LintNames.always_declare_return_types,
    "The function '{0}' should have a return type but doesn't.",
    correctionMessage: "Try adding a return type to the function.",
    hasPublishedDocs: true,
    uniqueName: 'always_declare_return_types_of_functions',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode alwaysDeclareReturnTypesOfMethods = LinterLintCode(
    LintNames.always_declare_return_types,
    "The method '{0}' should have a return type but doesn't.",
    correctionMessage: "Try adding a return type to the method.",
    hasPublishedDocs: true,
    uniqueName: 'always_declare_return_types_of_methods',
  );

  /// No parameters.
  static const LintCode alwaysPutControlBodyOnNewLine = LinterLintCode(
    LintNames.always_put_control_body_on_new_line,
    "Statement should be on a separate line.",
    correctionMessage: "Try moving the statement to a new line.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode alwaysPutRequiredNamedParametersFirst = LinterLintCode(
    LintNames.always_put_required_named_parameters_first,
    "Required named parameters should be before optional named parameters.",
    correctionMessage:
        "Try moving the required named parameter to be before any optional "
        "named parameters.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode alwaysSpecifyTypesAddType = LinterLintCode(
    LintNames.always_specify_types,
    "Missing type annotation.",
    correctionMessage: "Try adding a type annotation.",
    uniqueName: 'always_specify_types_add_type',
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode alwaysSpecifyTypesReplaceKeyword = LinterLintCode(
    LintNames.always_specify_types,
    "Missing type annotation.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
    uniqueName: 'always_specify_types_replace_keyword',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode alwaysSpecifyTypesSpecifyType = LinterLintCode(
    LintNames.always_specify_types,
    "Missing type annotation.",
    correctionMessage: "Try specifying the type '{0}'.",
    uniqueName: 'always_specify_types_specify_type',
  );

  /// No parameters.
  static const LintCode alwaysSpecifyTypesSplitToTypes = LinterLintCode(
    LintNames.always_specify_types,
    "Missing type annotation.",
    correctionMessage:
        "Try splitting the declaration and specify the different type "
        "annotations.",
    uniqueName: 'always_specify_types_split_to_types',
  );

  /// No parameters.
  static const LintCode alwaysUsePackageImports = LinterLintCode(
    LintNames.always_use_package_imports,
    "Use 'package:' imports for files in the 'lib' directory.",
    correctionMessage: "Try converting the URI to a 'package:' URI.",
    hasPublishedDocs: true,
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
  static const LintCode analyzerPublicApiBadPartDirective = LinterLintCode(
    LintNames.analyzer_public_api_bad_part_directive,
    "Part directives in the analyzer public API should point to files in the "
    "analyzer public API.",
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
  static const LintCode analyzerPublicApiBadType = LinterLintCode(
    LintNames.analyzer_public_api_bad_type,
    "Element makes use of type(s) which is not part of the analyzer public "
    "API: {0}.",
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
  static const LintCode analyzerPublicApiExportsNonPublicName = LinterLintCode(
    LintNames.analyzer_public_api_exports_non_public_name,
    "Export directive exports element(s) that are not part of the analyzer "
    "public API: {0}.",
  );

  /// Lint issued if a top level declaration in the analyzer public API has a
  /// name ending in `Impl`.
  ///
  /// Such declarations are not meant to be members of the analyzer public API,
  /// so if they are either declared outside of `package:analyzer/src`, or
  /// marked with `@AnalyzerPublicApi(...)`, that is almost certainly a mistake.
  ///
  /// No parameters.
  static const LintCode analyzerPublicApiImplInPublicApi = LinterLintCode(
    LintNames.analyzer_public_api_impl_in_public_api,
    "Declarations in the analyzer public API should not end in \"Impl\".",
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode annotateOverrides = LinterLintCode(
    LintNames.annotate_overrides,
    "The member '{0}' overrides an inherited member but isn't annotated with "
    "'@override'.",
    correctionMessage: "Try adding the '@override' annotation.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode annotateRedeclares = LinterLintCode(
    LintNames.annotate_redeclares,
    "The member '{0}' is redeclaring but isn't annotated with '@redeclare'.",
    correctionMessage: "Try adding the '@redeclare' annotation.",
  );

  /// No parameters.
  static const LintCode avoidAnnotatingWithDynamic = LinterLintCode(
    LintNames.avoid_annotating_with_dynamic,
    "Unnecessary 'dynamic' type annotation.",
    correctionMessage: "Try removing the type 'dynamic'.",
  );

  /// No parameters.
  static const LintCode avoidBoolLiteralsInConditionalExpressions =
      LinterLintCode(
        LintNames.avoid_bool_literals_in_conditional_expressions,
        "Conditional expressions with a 'bool' literal can be simplified.",
        correctionMessage:
            "Try rewriting the expression to use either '&&' or '||'.",
      );

  /// No parameters.
  static const LintCode avoidCatchesWithoutOnClauses = LinterLintCode(
    LintNames.avoid_catches_without_on_clauses,
    "Catch clause should use 'on' to specify the type of exception being "
    "caught.",
    correctionMessage: "Try adding an 'on' clause before the 'catch'.",
  );

  /// No parameters.
  static const LintCode avoidCatchingErrorsClass = LinterLintCode(
    LintNames.avoid_catching_errors,
    "The type 'Error' should not be caught.",
    correctionMessage:
        "Try removing the catch or catching an 'Exception' instead.",
    uniqueName: 'avoid_catching_errors_class',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode avoidCatchingErrorsSubclass = LinterLintCode(
    LintNames.avoid_catching_errors,
    "The type '{0}' should not be caught because it is a subclass of 'Error'.",
    correctionMessage:
        "Try removing the catch or catching an 'Exception' instead.",
    uniqueName: 'avoid_catching_errors_subclass',
  );

  /// No parameters.
  static const LintCode avoidClassesWithOnlyStaticMembers = LinterLintCode(
    LintNames.avoid_classes_with_only_static_members,
    "Classes should define instance members.",
    correctionMessage:
        "Try adding instance behavior or moving the members out of the class.",
  );

  /// No parameters.
  static const LintCode avoidDoubleAndIntChecks = LinterLintCode(
    LintNames.avoid_double_and_int_checks,
    "Explicit check for double or int.",
    correctionMessage: "Try removing the check.",
  );

  /// No parameters.
  static const LintCode avoidDynamicCalls = LinterLintCode(
    LintNames.avoid_dynamic_calls,
    "Method invocation or property access on a 'dynamic' target.",
    correctionMessage: "Try giving the target a type.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode avoidEmptyElse = LinterLintCode(
    LintNames.avoid_empty_else,
    "Empty statements are not allowed in an 'else' clause.",
    correctionMessage:
        "Try removing the empty statement or removing the else clause.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode avoidEqualsAndHashCodeOnMutableClasses = LinterLintCode(
    LintNames.avoid_equals_and_hash_code_on_mutable_classes,
    "The method '{0}' should not be overridden in classes not annotated with "
    "'@immutable'.",
    correctionMessage:
        "Try removing the override or annotating the class with '@immutable'.",
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode avoidEscapingInnerQuotes = LinterLintCode(
    LintNames.avoid_escaping_inner_quotes,
    "Unnecessary escape of '{0}'.",
    correctionMessage: "Try changing the outer quotes to '{1}'.",
  );

  /// No parameters.
  static const LintCode avoidFieldInitializersInConstClasses = LinterLintCode(
    LintNames.avoid_field_initializers_in_const_classes,
    "Fields in 'const' classes should not have initializers.",
    correctionMessage:
        "Try converting the field to a getter or initialize the field in the "
        "constructors.",
  );

  /// No parameters.
  static const LintCode avoidFinalParameters = LinterLintCode(
    LintNames.avoid_final_parameters,
    "Parameters should not be marked as 'final'.",
    correctionMessage: "Try removing the keyword 'final'.",
  );

  /// No parameters.
  static const LintCode avoidFunctionLiteralsInForeachCalls = LinterLintCode(
    LintNames.avoid_function_literals_in_foreach_calls,
    "Function literals shouldn't be passed to 'forEach'.",
    correctionMessage: "Try using a 'for' loop.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode avoidFutureorVoid = LinterLintCode(
    LintNames.avoid_futureor_void,
    "Don't use the type 'FutureOr<void>'.",
    correctionMessage: "Try using 'Future<void>?' or 'void'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode avoidImplementingValueTypes = LinterLintCode(
    LintNames.avoid_implementing_value_types,
    "Classes that override '==' should not be implemented.",
    correctionMessage: "Try removing the class from the 'implements' clause.",
  );

  /// No parameters.
  static const LintCode avoidInitToNull = LinterLintCode(
    LintNames.avoid_init_to_null,
    "Redundant initialization to 'null'.",
    correctionMessage: "Try removing the initializer.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode avoidJsRoundedInts = LinterLintCode(
    LintNames.avoid_js_rounded_ints,
    "Integer literal can't be represented exactly when compiled to JavaScript.",
    correctionMessage: "Try using a 'BigInt' to represent the value.",
  );

  /// No parameters.
  static const LintCode avoidMultipleDeclarationsPerLine = LinterLintCode(
    LintNames.avoid_multiple_declarations_per_line,
    "Multiple variables declared on a single line.",
    correctionMessage:
        "Try splitting the variable declarations into multiple lines.",
  );

  /// No parameters.
  static const LintCode avoidNullChecksInEqualityOperators = LinterLintCode(
    LintNames.avoid_null_checks_in_equality_operators,
    "Unnecessary null comparison in implementation of '=='.",
    correctionMessage: "Try removing the comparison.",
  );

  /// No parameters.
  static const LintCode avoidPositionalBooleanParameters = LinterLintCode(
    LintNames.avoid_positional_boolean_parameters,
    "'bool' parameters should be named parameters.",
    correctionMessage: "Try converting the parameter to a named parameter.",
  );

  /// No parameters.
  static const LintCode avoidPrint = LinterLintCode(
    LintNames.avoid_print,
    "Don't invoke 'print' in production code.",
    correctionMessage: "Try using a logging framework.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode avoidPrivateTypedefFunctions = LinterLintCode(
    LintNames.avoid_private_typedef_functions,
    "The typedef is unnecessary because it is only used in one place.",
    correctionMessage: "Try inlining the type or using it in other places.",
  );

  /// No parameters.
  static const LintCode avoidRedundantArgumentValues = LinterLintCode(
    LintNames.avoid_redundant_argument_values,
    "The value of the argument is redundant because it matches the default "
    "value.",
    correctionMessage: "Try removing the argument.",
  );

  /// No parameters.
  static const LintCode avoidRelativeLibImports = LinterLintCode(
    LintNames.avoid_relative_lib_imports,
    "Can't use a relative path to import a library in 'lib'.",
    correctionMessage:
        "Try fixing the relative path or changing the import to a 'package:' "
        "import.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode avoidRenamingMethodParameters = LinterLintCode(
    LintNames.avoid_renaming_method_parameters,
    "The parameter name '{0}' doesn't match the name '{1}' in the overridden "
    "method.",
    correctionMessage: "Try changing the name to '{1}'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode avoidReturnTypesOnSetters = LinterLintCode(
    LintNames.avoid_return_types_on_setters,
    "Unnecessary return type on a setter.",
    correctionMessage: "Try removing the return type.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode avoidReturningNullForVoidFromFunction = LinterLintCode(
    LintNames.avoid_returning_null_for_void,
    "Don't return 'null' from a function with a return type of 'void'.",
    correctionMessage: "Try removing the 'null'.",
    hasPublishedDocs: true,
    uniqueName: 'avoid_returning_null_for_void_from_function',
  );

  /// No parameters.
  static const LintCode avoidReturningNullForVoidFromMethod = LinterLintCode(
    LintNames.avoid_returning_null_for_void,
    "Don't return 'null' from a method with a return type of 'void'.",
    correctionMessage: "Try removing the 'null'.",
    hasPublishedDocs: true,
    uniqueName: 'avoid_returning_null_for_void_from_method',
  );

  /// No parameters.
  static const LintCode avoidReturningThis = LinterLintCode(
    LintNames.avoid_returning_this,
    "Don't return 'this' from a method.",
    correctionMessage:
        "Try changing the return type to 'void' and removing the return.",
  );

  /// No parameters.
  static const LintCode avoidSettersWithoutGetters = LinterLintCode(
    LintNames.avoid_setters_without_getters,
    "Setter has no corresponding getter.",
    correctionMessage:
        "Try adding a corresponding getter or removing the setter.",
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode avoidShadowingTypeParameters = LinterLintCode(
    LintNames.avoid_shadowing_type_parameters,
    "The type parameter '{0}' shadows a type parameter from the enclosing {1}.",
    correctionMessage: "Try renaming one of the type parameters.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode avoidSingleCascadeInExpressionStatements =
      LinterLintCode(
        LintNames.avoid_single_cascade_in_expression_statements,
        "Unnecessary cascade expression.",
        correctionMessage: "Try using the operator '{0}'.",
        hasPublishedDocs: true,
      );

  /// No parameters.
  static const LintCode avoidSlowAsyncIo = LinterLintCode(
    LintNames.avoid_slow_async_io,
    "Use of an async 'dart:io' method.",
    correctionMessage: "Try using the synchronous version of the method.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode avoidTypeToString = LinterLintCode(
    LintNames.avoid_type_to_string,
    "Using 'toString' on a 'Type' is not safe in production code.",
    correctionMessage:
        "Try a normal type check or compare the 'runtimeType' directly.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode
  avoidTypesAsParameterNamesFormalParameter = LinterLintCode(
    LintNames.avoid_types_as_parameter_names,
    "The parameter name '{0}' matches a visible type name.",
    correctionMessage:
        "Try adding a name for the parameter or changing the parameter name to "
        "not match an existing type.",
    hasPublishedDocs: true,
    uniqueName: 'avoid_types_as_parameter_names_formal_parameter',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode
  avoidTypesAsParameterNamesTypeParameter = LinterLintCode(
    LintNames.avoid_types_as_parameter_names,
    "The type parameter name '{0}' matches a visible type name.",
    correctionMessage:
        "Try changing the type parameter name to not match an existing type.",
    hasPublishedDocs: true,
    uniqueName: 'avoid_types_as_parameter_names_type_parameter',
  );

  /// No parameters.
  static const LintCode avoidTypesOnClosureParameters = LinterLintCode(
    LintNames.avoid_types_on_closure_parameters,
    "Unnecessary type annotation on a function expression parameter.",
    correctionMessage: "Try removing the type annotation.",
  );

  /// No parameters.
  static const LintCode avoidUnnecessaryContainers = LinterLintCode(
    LintNames.avoid_unnecessary_containers,
    "Unnecessary instance of 'Container'.",
    correctionMessage:
        "Try removing the 'Container' (but not its children) from the widget "
        "tree.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode avoidUnusedConstructorParameters = LinterLintCode(
    LintNames.avoid_unused_constructor_parameters,
    "The parameter '{0}' is not used in the constructor.",
    correctionMessage: "Try using the parameter or removing it.",
  );

  /// No parameters.
  static const LintCode avoidVoidAsync = LinterLintCode(
    LintNames.avoid_void_async,
    "An 'async' function should have a 'Future' return type when it doesn't "
    "return a value.",
    correctionMessage: "Try changing the return type.",
  );

  /// No parameters.
  static const LintCode avoidWebLibrariesInFlutter = LinterLintCode(
    LintNames.avoid_web_libraries_in_flutter,
    "Don't use web-only libraries outside Flutter web plugins.",
    correctionMessage: "Try finding a different library for your needs.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode awaitOnlyFutures = LinterLintCode(
    LintNames.await_only_futures,
    "Uses 'await' on an instance of '{0}', which is not a subtype of 'Future'.",
    correctionMessage: "Try removing the 'await' or changing the expression.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode camelCaseExtensions = LinterLintCode(
    LintNames.camel_case_extensions,
    "The extension name '{0}' isn't an UpperCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the UpperCamelCase style.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode camelCaseTypes = LinterLintCode(
    LintNames.camel_case_types,
    "The type name '{0}' isn't an UpperCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the UpperCamelCase style.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode cancelSubscriptions = LinterLintCode(
    LintNames.cancel_subscriptions,
    "Uncancelled instance of 'StreamSubscription'.",
    correctionMessage:
        "Try invoking 'cancel' in the function in which the "
        "'StreamSubscription' was created.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode cascadeInvocations = LinterLintCode(
    LintNames.cascade_invocations,
    "Unnecessary duplication of receiver.",
    correctionMessage: "Try using a cascade to avoid the duplication.",
  );

  /// No parameters.
  static const LintCode castNullableToNonNullable = LinterLintCode(
    LintNames.cast_nullable_to_non_nullable,
    "Don't cast a nullable value to a non-nullable type.",
    correctionMessage:
        "Try adding a not-null assertion ('!') to make the type non-nullable.",
  );

  /// No parameters.
  static const LintCode closeSinks = LinterLintCode(
    LintNames.close_sinks,
    "Unclosed instance of 'Sink'.",
    correctionMessage:
        "Try invoking 'close' in the function in which the 'Sink' was created.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode collectionMethodsUnrelatedType = LinterLintCode(
    LintNames.collection_methods_unrelated_type,
    "The argument type '{0}' isn't related to '{1}'.",
    correctionMessage: "Try changing the argument or element type to match.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode combinatorsOrdering = LinterLintCode(
    LintNames.combinators_ordering,
    "Sort combinator names alphabetically.",
    correctionMessage: "Try sorting the combinator names alphabetically.",
  );

  /// No parameters.
  static const LintCode commentReferences = LinterLintCode(
    LintNames.comment_references,
    "The referenced name isn't visible in scope.",
    correctionMessage: "Try adding an import for the referenced name.",
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode conditionalUriDoesNotExist = LinterLintCode(
    LintNames.conditional_uri_does_not_exist,
    "The target of the conditional URI '{0}' doesn't exist.",
    correctionMessage:
        "Try creating the file referenced by the URI, or try using a URI for a "
        "file that does exist.",
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode constantIdentifierNames = LinterLintCode(
    LintNames.constant_identifier_names,
    "The constant name '{0}' isn't a lowerCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the lowerCamelCase style.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode controlFlowInFinally = LinterLintCode(
    LintNames.control_flow_in_finally,
    "Use of '{0}' in a 'finally' clause.",
    correctionMessage: "Try restructuring the code.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode curlyBracesInFlowControlStructures = LinterLintCode(
    LintNames.curly_braces_in_flow_control_structures,
    "Statements in {0} should be enclosed in a block.",
    correctionMessage: "Try wrapping the statement in a block.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode danglingLibraryDocComments = LinterLintCode(
    LintNames.dangling_library_doc_comments,
    "Dangling library doc comment.",
    correctionMessage: "Add a 'library' directive after the library comment.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode dependOnReferencedPackages = LinterLintCode(
    LintNames.depend_on_referenced_packages,
    "The imported package '{0}' isn't a dependency of the importing package.",
    correctionMessage:
        "Try adding a dependency for '{0}' in the 'pubspec.yaml' file.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode deprecatedConsistencyConstructor = LinterLintCode(
    LintNames.deprecated_consistency,
    "Constructors in a deprecated class should be deprecated.",
    correctionMessage: "Try marking the constructor as deprecated.",
    uniqueName: 'deprecated_consistency_constructor',
  );

  /// No parameters.
  static const LintCode deprecatedConsistencyField = LinterLintCode(
    LintNames.deprecated_consistency,
    "Fields that are initialized by a deprecated parameter should be "
    "deprecated.",
    correctionMessage: "Try marking the field as deprecated.",
    uniqueName: 'deprecated_consistency_field',
  );

  /// No parameters.
  static const LintCode deprecatedConsistencyParameter = LinterLintCode(
    LintNames.deprecated_consistency,
    "Parameters that initialize a deprecated field should be deprecated.",
    correctionMessage: "Try marking the parameter as deprecated.",
    uniqueName: 'deprecated_consistency_parameter',
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode
  deprecatedMemberUseFromSamePackageWithMessage = LinterLintCode(
    LintNames.deprecated_member_use_from_same_package,
    "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement, "
        "if a replacement is specified.",
    uniqueName: 'deprecated_member_use_from_same_package_with_message',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode
  deprecatedMemberUseFromSamePackageWithoutMessage = LinterLintCode(
    LintNames.deprecated_member_use_from_same_package,
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement, "
        "if a replacement is specified.",
    uniqueName: 'deprecated_member_use_from_same_package_without_message',
  );

  /// No parameters.
  static const LintCode diagnosticDescribeAllProperties = LinterLintCode(
    LintNames.diagnostic_describe_all_properties,
    "The public property isn't described by either 'debugFillProperties' or "
    "'debugDescribeChildren'.",
    correctionMessage: "Try describing the property.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode directivesOrderingAlphabetical = LinterLintCode(
    LintNames.directives_ordering,
    "Sort directive sections alphabetically.",
    correctionMessage: "Try sorting the directives.",
    uniqueName: 'directives_ordering_alphabetical',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode directivesOrderingDart = LinterLintCode(
    LintNames.directives_ordering,
    "Place 'dart:' {0} before other {0}.",
    correctionMessage: "Try sorting the directives.",
    uniqueName: 'directives_ordering_dart',
  );

  /// No parameters.
  static const LintCode directivesOrderingExports = LinterLintCode(
    LintNames.directives_ordering,
    "Specify exports in a separate section after all imports.",
    correctionMessage: "Try sorting the directives.",
    uniqueName: 'directives_ordering_exports',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode directivesOrderingPackageBeforeRelative =
      LinterLintCode(
        LintNames.directives_ordering,
        "Place 'package:' {0} before relative {0}.",
        correctionMessage: "Try sorting the directives.",
        uniqueName: 'directives_ordering_package_before_relative',
      );

  /// No parameters.
  static const LintCode discardedFutures = LinterLintCode(
    LintNames.discarded_futures,
    "'Future'-returning calls in a non-'async' function.",
    correctionMessage:
        "Try converting the enclosing function to be 'async' and then 'await' "
        "the future, or wrap the expression in 'unawaited'.",
  );

  /// No parameters.
  static const LintCode doNotUseEnvironment = LinterLintCode(
    LintNames.do_not_use_environment,
    "Invalid use of an environment declaration.",
    correctionMessage: "Try removing the environment declaration usage.",
  );

  /// No parameters.
  static const LintCode documentIgnores = LinterLintCode(
    LintNames.document_ignores,
    "Missing documentation explaining why the diagnostic is ignored.",
    correctionMessage:
        "Try adding a comment immediately above the ignore comment.",
  );

  /// No parameters.
  static const LintCode emptyCatches = LinterLintCode(
    LintNames.empty_catches,
    "Empty catch block.",
    correctionMessage:
        "Try adding statements to the block, adding a comment to the block, or "
        "removing the 'catch' clause.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode emptyConstructorBodies = LinterLintCode(
    LintNames.empty_constructor_bodies,
    "Empty constructor bodies should be written using a ';' rather than '{}'.",
    correctionMessage: "Try replacing the constructor body with ';'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode emptyStatements = LinterLintCode(
    LintNames.empty_statements,
    "Unnecessary empty statement.",
    correctionMessage:
        "Try removing the empty statement or restructuring the code.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode eolAtEndOfFile = LinterLintCode(
    LintNames.eol_at_end_of_file,
    "Missing a newline at the end of the file.",
    correctionMessage: "Try adding a newline at the end of the file.",
  );

  /// No parameters.
  static const LintCode eraseDartTypeExtensionTypes = LinterLintCode(
    LintNames.erase_dart_type_extension_types,
    "Unsafe use of 'DartType' in an 'is' check.",
    correctionMessage:
        "Ensure DartType extension types are erased by using a helper method.",
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode exhaustiveCases = LinterLintCode(
    LintNames.exhaustive_cases,
    "Missing case clauses for some constants in '{0}'.",
    correctionMessage: "Try adding case clauses for the missing constants.",
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode fileNames = LinterLintCode(
    LintNames.file_names,
    "The file name '{0}' isn't a lower_case_with_underscores identifier.",
    correctionMessage:
        "Try changing the name to follow the lower_case_with_underscores "
        "style.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode flutterStyleTodos = LinterLintCode(
    LintNames.flutter_style_todos,
    "To-do comment doesn't follow the Flutter style.",
    correctionMessage: "Try following the Flutter style for to-do comments.",
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode hashAndEquals = LinterLintCode(
    LintNames.hash_and_equals,
    "Missing a corresponding override of '{0}'.",
    correctionMessage: "Try overriding '{0}' or removing '{1}'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode implementationImports = LinterLintCode(
    LintNames.implementation_imports,
    "Import of a library in the 'lib/src' directory of another package.",
    correctionMessage:
        "Try importing a public library that exports this library, or removing "
        "the import.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode implicitCallTearoffs = LinterLintCode(
    LintNames.implicit_call_tearoffs,
    "Implicit tear-off of the 'call' method.",
    correctionMessage: "Try explicitly tearing off the 'call' method.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  /// Object p2: undocumented
  /// Object p3: undocumented
  static const LintCode implicitReopen = LinterLintCode(
    LintNames.implicit_reopen,
    "The {0} '{1}' reopens '{2}' because it is not marked '{3}'.",
    correctionMessage:
        "Try marking '{1}' '{3}' or annotating it with '@reopen'.",
  );

  /// No parameters.
  static const LintCode invalidCasePatterns = LinterLintCode(
    LintNames.invalid_case_patterns,
    "This expression is not valid in a 'case' clause in Dart 3.0.",
    correctionMessage: "Try refactoring the expression to be valid in 3.0.",
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode
  invalidRuntimeCheckWithJsInteropTypesDartAsJs = LinterLintCode(
    LintNames.invalid_runtime_check_with_js_interop_types,
    "Cast from '{0}' to '{1}' casts a Dart value to a JS interop type, which "
    "might not be platform-consistent.",
    correctionMessage:
        "Try using conversion methods from 'dart:js_interop' to convert "
        "between Dart types and JS interop types.",
    hasPublishedDocs: true,
    uniqueName: 'invalid_runtime_check_with_js_interop_types_dart_as_js',
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode
  invalidRuntimeCheckWithJsInteropTypesDartIsJs = LinterLintCode(
    LintNames.invalid_runtime_check_with_js_interop_types,
    "Runtime check between '{0}' and '{1}' checks whether a Dart value is a JS "
    "interop type, which might not be platform-consistent.",
    uniqueName: 'invalid_runtime_check_with_js_interop_types_dart_is_js',
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode
  invalidRuntimeCheckWithJsInteropTypesJsAsDart = LinterLintCode(
    LintNames.invalid_runtime_check_with_js_interop_types,
    "Cast from '{0}' to '{1}' casts a JS interop value to a Dart type, which "
    "might not be platform-consistent.",
    correctionMessage:
        "Try using conversion methods from 'dart:js_interop' to convert "
        "between JS interop types and Dart types.",
    uniqueName: 'invalid_runtime_check_with_js_interop_types_js_as_dart',
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode
  invalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs = LinterLintCode(
    LintNames.invalid_runtime_check_with_js_interop_types,
    "Cast from '{0}' to '{1}' casts a JS interop value to an incompatible JS "
    "interop type, which might not be platform-consistent.",
    uniqueName:
        'invalid_runtime_check_with_js_interop_types_js_as_incompatible_js',
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode
  invalidRuntimeCheckWithJsInteropTypesJsIsDart = LinterLintCode(
    LintNames.invalid_runtime_check_with_js_interop_types,
    "Runtime check between '{0}' and '{1}' checks whether a JS interop value "
    "is a Dart type, which might not be platform-consistent.",
    uniqueName: 'invalid_runtime_check_with_js_interop_types_js_is_dart',
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode
  invalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs = LinterLintCode(
    LintNames.invalid_runtime_check_with_js_interop_types,
    "Runtime check between '{0}' and '{1}' involves a non-trivial runtime "
    "check between two JS interop types that might not be "
    "platform-consistent.",
    correctionMessage:
        "Try using a JS interop member like 'isA' from 'dart:js_interop' to "
        "check the underlying type of JS interop values.",
    uniqueName:
        'invalid_runtime_check_with_js_interop_types_js_is_inconsistent_js',
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode
  invalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs = LinterLintCode(
    LintNames.invalid_runtime_check_with_js_interop_types,
    "Runtime check between '{0}' and '{1}' involves a runtime check between a "
    "JS interop value and an unrelated JS interop type that will always be "
    "true and won't check the underlying type.",
    correctionMessage:
        "Try using a JS interop member like 'isA' from 'dart:js_interop' to "
        "check the underlying type of JS interop values, or make the JS "
        "interop type a supertype using 'implements'.",
    uniqueName:
        'invalid_runtime_check_with_js_interop_types_js_is_unrelated_js',
  );

  /// No parameters.
  static const LintCode joinReturnWithAssignment = LinterLintCode(
    LintNames.join_return_with_assignment,
    "Assignment could be inlined in 'return' statement.",
    correctionMessage:
        "Try inlining the assigned value in the 'return' statement.",
  );

  /// No parameters.
  static const LintCode leadingNewlinesInMultilineStrings = LinterLintCode(
    LintNames.leading_newlines_in_multiline_strings,
    "Missing a newline at the beginning of a multiline string.",
    correctionMessage: "Try adding a newline at the beginning of the string.",
  );

  /// No parameters.
  static const LintCode libraryAnnotations = LinterLintCode(
    LintNames.library_annotations,
    "This annotation should be attached to a library directive.",
    correctionMessage: "Try attaching the annotation to a library directive.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode libraryNames = LinterLintCode(
    LintNames.library_names,
    "The library name '{0}' isn't a lower_case_with_underscores identifier.",
    correctionMessage:
        "Try changing the name to follow the lower_case_with_underscores "
        "style.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode libraryPrefixes = LinterLintCode(
    LintNames.library_prefixes,
    "The prefix '{0}' isn't a lower_case_with_underscores identifier.",
    correctionMessage:
        "Try changing the prefix to follow the lower_case_with_underscores "
        "style.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode libraryPrivateTypesInPublicApi = LinterLintCode(
    LintNames.library_private_types_in_public_api,
    "Invalid use of a private type in a public API.",
    correctionMessage:
        "Try making the private type public, or making the API that uses the "
        "private type also be private.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode linesLongerThan80Chars = LinterLintCode(
    LintNames.lines_longer_than_80_chars,
    "The line length exceeds the 80-character limit.",
    correctionMessage: "Try breaking the line across multiple lines.",
  );

  /// No parameters.
  static const LintCode literalOnlyBooleanExpressions = LinterLintCode(
    LintNames.literal_only_boolean_expressions,
    "The Boolean expression has a constant value.",
    correctionMessage: "Try changing the expression.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode matchingSuperParameters = LinterLintCode(
    LintNames.matching_super_parameters,
    "The super parameter named '{0}'' does not share the same name as the "
    "corresponding parameter in the super constructor, '{1}'.",
    correctionMessage:
        "Try using the name of the corresponding parameter in the super "
        "constructor.",
  );

  /// No parameters.
  static const LintCode missingCodeBlockLanguageInDocComment = LinterLintCode(
    LintNames.missing_code_block_language_in_doc_comment,
    "The code block is missing a specified language.",
    correctionMessage: "Try adding a language to the code block.",
  );

  /// No parameters.
  static const LintCode missingWhitespaceBetweenAdjacentStrings =
      LinterLintCode(
        LintNames.missing_whitespace_between_adjacent_strings,
        "Missing whitespace between adjacent strings.",
        correctionMessage: "Try adding whitespace between the strings.",
        hasPublishedDocs: true,
      );

  /// No parameters.
  static const LintCode noAdjacentStringsInList = LinterLintCode(
    LintNames.no_adjacent_strings_in_list,
    "Don't use adjacent strings in a list literal.",
    correctionMessage: "Try adding a comma between the strings.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode noDefaultCases = LinterLintCode(
    LintNames.no_default_cases,
    "Invalid use of 'default' member in a switch.",
    correctionMessage:
        "Try enumerating all the possible values of the switch expression.",
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode noDuplicateCaseValues = LinterLintCode(
    LintNames.no_duplicate_case_values,
    "The value of the case clause ('{0}') is equal to the value of an earlier "
    "case clause ('{1}').",
    correctionMessage: "Try removing or changing the value.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode noLeadingUnderscoresForLibraryPrefixes = LinterLintCode(
    LintNames.no_leading_underscores_for_library_prefixes,
    "The library prefix '{0}' starts with an underscore.",
    correctionMessage:
        "Try renaming the prefix to not start with an underscore.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode noLeadingUnderscoresForLocalIdentifiers =
      LinterLintCode(
        LintNames.no_leading_underscores_for_local_identifiers,
        "The local variable '{0}' starts with an underscore.",
        correctionMessage:
            "Try renaming the variable to not start with an underscore.",
        hasPublishedDocs: true,
      );

  /// No parameters.
  static const LintCode noLiteralBoolComparisons = LinterLintCode(
    LintNames.no_literal_bool_comparisons,
    "Unnecessary comparison to a boolean literal.",
    correctionMessage:
        "Remove the comparison and use the negate `!` operator if necessary.",
  );

  /// No parameters.
  static const LintCode noLogicInCreateState = LinterLintCode(
    LintNames.no_logic_in_create_state,
    "Don't put any logic in 'createState'.",
    correctionMessage: "Try moving the logic out of 'createState'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode noRuntimetypeTostring = LinterLintCode(
    LintNames.no_runtimeType_toString,
    "Using 'toString' on a 'Type' is not safe in production code.",
    correctionMessage:
        "Try removing the usage of 'toString' or restructuring the code.",
  );

  /// No parameters.
  static const LintCode noSelfAssignments = LinterLintCode(
    LintNames.no_self_assignments,
    "The variable or property is being assigned to itself.",
    correctionMessage: "Try removing the assignment that has no direct effect.",
  );

  /// No parameters.
  static const LintCode noSoloTests = LinterLintCode(
    LintNames.no_solo_tests,
    "Don't commit soloed tests.",
    correctionMessage:
        "Try removing the 'soloTest' annotation or 'solo_' prefix.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode noTrailingSpaces = LinterLintCode(
    LintNames.no_trailing_spaces,
    "Don't create string literals with trailing spaces in tests.",
    correctionMessage: "Try removing the trailing spaces.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode noWildcardVariableUses = LinterLintCode(
    LintNames.no_wildcard_variable_uses,
    "The referenced identifier is a wildcard.",
    correctionMessage: "Use an identifier name that is not a wildcard.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode nonConstantIdentifierNames = LinterLintCode(
    LintNames.non_constant_identifier_names,
    "The variable name '{0}' isn't a lowerCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the lowerCamelCase style.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode noopPrimitiveOperations = LinterLintCode(
    LintNames.noop_primitive_operations,
    "The expression has no effect and can be removed.",
    correctionMessage: "Try removing the expression.",
  );

  /// No parameters.
  static const LintCode nullCheckOnNullableTypeParameter = LinterLintCode(
    LintNames.null_check_on_nullable_type_parameter,
    "The null check operator shouldn't be used on a variable whose type is a "
    "potentially nullable type parameter.",
    correctionMessage: "Try explicitly testing for 'null'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode nullClosures = LinterLintCode(
    LintNames.null_closures,
    "Closure can't be 'null' because it might be invoked.",
    correctionMessage: "Try providing a non-null closure.",
  );

  /// No parameters.
  static const LintCode omitLocalVariableTypes = LinterLintCode(
    LintNames.omit_local_variable_types,
    "Unnecessary type annotation on a local variable.",
    correctionMessage: "Try removing the type annotation.",
  );

  /// No parameters.
  static const LintCode omitObviousLocalVariableTypes = LinterLintCode(
    LintNames.omit_obvious_local_variable_types,
    "Omit the type annotation on a local variable when the type is obvious.",
    correctionMessage: "Try removing the type annotation.",
  );

  /// No parameters.
  static const LintCode omitObviousPropertyTypes = LinterLintCode(
    LintNames.omit_obvious_property_types,
    "The type annotation isn't needed because it is obvious.",
    correctionMessage: "Try removing the type annotation.",
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode oneMemberAbstracts = LinterLintCode(
    LintNames.one_member_abstracts,
    "Unnecessary use of an abstract class.",
    correctionMessage:
        "Try making '{0}' a top-level function and removing the class.",
  );

  /// No parameters.
  static const LintCode onlyThrowErrors = LinterLintCode(
    LintNames.only_throw_errors,
    "Don't throw instances of classes that don't extend either 'Exception' or "
    "'Error'.",
    correctionMessage: "Try throwing a different class of object.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode overriddenFields = LinterLintCode(
    LintNames.overridden_fields,
    "Field overrides a field inherited from '{0}'.",
    correctionMessage:
        "Try removing the field, overriding the getter and setter if "
        "necessary.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode packageNames = LinterLintCode(
    LintNames.package_names,
    "The package name '{0}' isn't a lower_case_with_underscores identifier.",
    correctionMessage:
        "Try changing the name to follow the lower_case_with_underscores "
        "style.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode packagePrefixedLibraryNames = LinterLintCode(
    LintNames.package_prefixed_library_names,
    "The library name is not a dot-separated path prefixed by the package "
    "name.",
    correctionMessage: "Try changing the name to '{0}'.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode parameterAssignments = LinterLintCode(
    LintNames.parameter_assignments,
    "Invalid assignment to the parameter '{0}'.",
    correctionMessage: "Try using a local variable in place of the parameter.",
  );

  /// No parameters.
  static const LintCode preferAdjacentStringConcatenation = LinterLintCode(
    LintNames.prefer_adjacent_string_concatenation,
    "String literals shouldn't be concatenated by the '+' operator.",
    correctionMessage: "Try removing the operator to use adjacent strings.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferAssertsInInitializerLists = LinterLintCode(
    LintNames.prefer_asserts_in_initializer_lists,
    "Assert should be in the initializer list.",
    correctionMessage: "Try moving the assert to the initializer list.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferAssertsWithMessage = LinterLintCode(
    LintNames.prefer_asserts_with_message,
    "Missing a message in an assert.",
    correctionMessage: "Try adding a message to the assert.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferCollectionLiterals = LinterLintCode(
    LintNames.prefer_collection_literals,
    "Unnecessary constructor invocation.",
    correctionMessage: "Try using a collection literal.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferConditionalAssignment = LinterLintCode(
    LintNames.prefer_conditional_assignment,
    "The 'if' statement could be replaced by a null-aware assignment.",
    correctionMessage:
        "Try using the '??=' operator to conditionally assign a value.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferConstConstructors = LinterLintCode(
    LintNames.prefer_const_constructors,
    "Use 'const' with the constructor to improve performance.",
    correctionMessage:
        "Try adding the 'const' keyword to the constructor invocation.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferConstConstructorsInImmutables = LinterLintCode(
    LintNames.prefer_const_constructors_in_immutables,
    "Constructors in '@immutable' classes should be declared as 'const'.",
    correctionMessage: "Try adding 'const' to the constructor declaration.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferConstDeclarations = LinterLintCode(
    LintNames.prefer_const_declarations,
    "Use 'const' for final variables initialized to a constant value.",
    correctionMessage: "Try replacing 'final' with 'const'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferConstLiteralsToCreateImmutables = LinterLintCode(
    LintNames.prefer_const_literals_to_create_immutables,
    "Use 'const' literals as arguments to constructors of '@immutable' "
    "classes.",
    correctionMessage: "Try adding 'const' before the literal.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferConstructorsOverStaticMethods = LinterLintCode(
    LintNames.prefer_constructors_over_static_methods,
    "Static method should be a constructor.",
    correctionMessage: "Try converting the method into a constructor.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferContainsAlwaysFalse = LinterLintCode(
    LintNames.prefer_contains,
    "Always 'false' because 'indexOf' is always greater than or equal to -1.",
    uniqueName: 'prefer_contains_always_false',
  );

  /// No parameters.
  static const LintCode preferContainsAlwaysTrue = LinterLintCode(
    LintNames.prefer_contains,
    "Always 'true' because 'indexOf' is always greater than or equal to -1.",
    uniqueName: 'prefer_contains_always_true',
  );

  /// No parameters.
  static const LintCode preferContainsUseContains = LinterLintCode(
    LintNames.prefer_contains,
    "Unnecessary use of 'indexOf' to test for containment.",
    correctionMessage: "Try using 'contains'.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_contains_use_contains',
  );

  /// No parameters.
  static const LintCode preferDoubleQuotes = LinterLintCode(
    LintNames.prefer_double_quotes,
    "Unnecessary use of single quotes.",
    correctionMessage:
        "Try using double quotes unless the string contains double quotes.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferExpressionFunctionBodies = LinterLintCode(
    LintNames.prefer_expression_function_bodies,
    "Unnecessary use of a block function body.",
    correctionMessage: "Try using an expression function body.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode preferFinalFields = LinterLintCode(
    LintNames.prefer_final_fields,
    "The private field {0} could be 'final'.",
    correctionMessage: "Try making the field 'final'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferFinalInForEachPattern = LinterLintCode(
    LintNames.prefer_final_in_for_each,
    "The pattern should be final.",
    correctionMessage: "Try making the pattern final.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_final_in_for_each_pattern',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode preferFinalInForEachVariable = LinterLintCode(
    LintNames.prefer_final_in_for_each,
    "The variable '{0}' should be final.",
    correctionMessage: "Try making the variable final.",
    uniqueName: 'prefer_final_in_for_each_variable',
  );

  /// No parameters.
  static const LintCode preferFinalLocals = LinterLintCode(
    LintNames.prefer_final_locals,
    "Local variables should be final.",
    correctionMessage: "Try making the variable final.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode preferFinalParameters = LinterLintCode(
    LintNames.prefer_final_parameters,
    "The parameter '{0}' should be final.",
    correctionMessage: "Try making the parameter final.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferForElementsToMapFromiterable = LinterLintCode(
    LintNames.prefer_for_elements_to_map_fromIterable,
    "Use 'for' elements when building maps from iterables.",
    correctionMessage: "Try using a collection literal with a 'for' element.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferForeach = LinterLintCode(
    LintNames.prefer_foreach,
    "Use 'forEach' and a tear-off rather than a 'for' loop to apply a function "
    "to every element.",
    correctionMessage:
        "Try using 'forEach' and a tear-off rather than a 'for' loop.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode
  preferFunctionDeclarationsOverVariables = LinterLintCode(
    LintNames.prefer_function_declarations_over_variables,
    "Use a function declaration rather than a variable assignment to bind a "
    "function to a name.",
    correctionMessage:
        "Try rewriting the closure assignment as a function declaration.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode preferGenericFunctionTypeAliases = LinterLintCode(
    LintNames.prefer_generic_function_type_aliases,
    "Use the generic function type syntax in 'typedef's.",
    correctionMessage: "Try using the generic function type syntax ('{0}').",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferIfElementsToConditionalExpressions =
      LinterLintCode(
        LintNames.prefer_if_elements_to_conditional_expressions,
        "Use an 'if' element to conditionally add elements.",
        correctionMessage:
            "Try using an 'if' element rather than a conditional expression.",
      );

  /// No parameters.
  static const LintCode preferIfNullOperators = LinterLintCode(
    LintNames.prefer_if_null_operators,
    "Use the '??' operator rather than '?:' when testing for 'null'.",
    correctionMessage: "Try rewriting the code to use '??'.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode preferInitializingFormals = LinterLintCode(
    LintNames.prefer_initializing_formals,
    "Use an initializing formal to assign a parameter to a field.",
    correctionMessage:
        "Try using an initialing formal ('this.{0}') to initialize the field.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferInlinedAddsMultiple = LinterLintCode(
    LintNames.prefer_inlined_adds,
    "The addition of multiple list items could be inlined.",
    correctionMessage: "Try adding the items to the list literal directly.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_inlined_adds_multiple',
  );

  /// No parameters.
  static const LintCode preferInlinedAddsSingle = LinterLintCode(
    LintNames.prefer_inlined_adds,
    "The addition of a list item could be inlined.",
    correctionMessage: "Try adding the item to the list literal directly.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_inlined_adds_single',
  );

  /// No parameters.
  static const LintCode preferIntLiterals = LinterLintCode(
    LintNames.prefer_int_literals,
    "Unnecessary use of a 'double' literal.",
    correctionMessage: "Try using an 'int' literal.",
  );

  /// No parameters.
  static const LintCode preferInterpolationToComposeStrings = LinterLintCode(
    LintNames.prefer_interpolation_to_compose_strings,
    "Use interpolation to compose strings and values.",
    correctionMessage:
        "Try using string interpolation to build the composite string.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferIsEmptyAlwaysFalse = LinterLintCode(
    LintNames.prefer_is_empty,
    "The comparison is always 'false' because the length is always greater "
    "than or equal to 0.",
    uniqueName: 'prefer_is_empty_always_false',
  );

  /// No parameters.
  static const LintCode preferIsEmptyAlwaysTrue = LinterLintCode(
    LintNames.prefer_is_empty,
    "The comparison is always 'true' because the length is always greater than "
    "or equal to 0.",
    uniqueName: 'prefer_is_empty_always_true',
  );

  /// No parameters.
  static const LintCode preferIsEmptyUseIsEmpty = LinterLintCode(
    LintNames.prefer_is_empty,
    "Use 'isEmpty' instead of 'length' to test whether the collection is "
    "empty.",
    correctionMessage: "Try rewriting the expression to use 'isEmpty'.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_is_empty_use_is_empty',
  );

  /// No parameters.
  static const LintCode preferIsEmptyUseIsNotEmpty = LinterLintCode(
    LintNames.prefer_is_empty,
    "Use 'isNotEmpty' instead of 'length' to test whether the collection is "
    "empty.",
    correctionMessage: "Try rewriting the expression to use 'isNotEmpty'.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_is_empty_use_is_not_empty',
  );

  /// No parameters.
  static const LintCode preferIsNotEmpty = LinterLintCode(
    LintNames.prefer_is_not_empty,
    "Use 'isNotEmpty' rather than negating the result of 'isEmpty'.",
    correctionMessage: "Try rewriting the expression to use 'isNotEmpty'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferIsNotOperator = LinterLintCode(
    LintNames.prefer_is_not_operator,
    "Use the 'is!' operator rather than negating the value of the 'is' "
    "operator.",
    correctionMessage: "Try rewriting the condition to use the 'is!' operator.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferIterableWheretype = LinterLintCode(
    LintNames.prefer_iterable_whereType,
    "Use 'whereType' to select elements of a given type.",
    correctionMessage: "Try rewriting the expression to use 'whereType'.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode preferMixin = LinterLintCode(
    LintNames.prefer_mixin,
    "Only mixins should be mixed in.",
    correctionMessage: "Try converting '{0}' to a mixin.",
  );

  /// No parameters.
  static const LintCode preferNullAwareMethodCalls = LinterLintCode(
    LintNames.prefer_null_aware_method_calls,
    "Use a null-aware invocation of the 'call' method rather than explicitly "
    "testing for 'null'.",
    correctionMessage: "Try using '?.call()' to invoke the function.",
  );

  /// No parameters.
  static const LintCode preferNullAwareOperators = LinterLintCode(
    LintNames.prefer_null_aware_operators,
    "Use the null-aware operator '?.' rather than an explicit 'null' "
    "comparison.",
    correctionMessage: "Try using '?.'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferRelativeImports = LinterLintCode(
    LintNames.prefer_relative_imports,
    "Use relative imports for files in the 'lib' directory.",
    correctionMessage: "Try converting the URI to a relative URI.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferSingleQuotes = LinterLintCode(
    LintNames.prefer_single_quotes,
    "Unnecessary use of double quotes.",
    correctionMessage:
        "Try using single quotes unless the string contains single quotes.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode preferSpreadCollections = LinterLintCode(
    LintNames.prefer_spread_collections,
    "The addition of multiple elements could be inlined.",
    correctionMessage:
        "Try using the spread operator ('...') to inline the addition.",
  );

  /// No parameters.
  static const LintCode preferTypingUninitializedVariablesForField =
      LinterLintCode(
        LintNames.prefer_typing_uninitialized_variables,
        "An uninitialized field should have an explicit type annotation.",
        correctionMessage: "Try adding a type annotation.",
        hasPublishedDocs: true,
        uniqueName: 'prefer_typing_uninitialized_variables_for_field',
      );

  /// No parameters.
  static const LintCode preferTypingUninitializedVariablesForLocalVariable =
      LinterLintCode(
        LintNames.prefer_typing_uninitialized_variables,
        "An uninitialized variable should have an explicit type annotation.",
        correctionMessage: "Try adding a type annotation.",
        hasPublishedDocs: true,
        uniqueName: 'prefer_typing_uninitialized_variables_for_local_variable',
      );

  /// No parameters.
  static const LintCode preferVoidToNull = LinterLintCode(
    LintNames.prefer_void_to_null,
    "Unnecessary use of the type 'Null'.",
    correctionMessage: "Try using 'void' instead.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode provideDeprecationMessage = LinterLintCode(
    LintNames.provide_deprecation_message,
    "Missing a deprecation message.",
    correctionMessage:
        "Try using the constructor to provide a message "
        "('@Deprecated(\"message\")').",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode publicMemberApiDocs = LinterLintCode(
    LintNames.public_member_api_docs,
    "Missing documentation for a public member.",
    correctionMessage: "Try adding documentation for the member.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode recursiveGetters = LinterLintCode(
    LintNames.recursive_getters,
    "The getter '{0}' recursively returns itself.",
    correctionMessage: "Try changing the value being returned.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode requireTrailingCommas = LinterLintCode(
    LintNames.require_trailing_commas,
    "Missing a required trailing comma.",
    correctionMessage: "Try adding a trailing comma.",
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode securePubspecUrls = LinterLintCode(
    LintNames.secure_pubspec_urls,
    "The '{0}' protocol shouldn't be used because it isn't secure.",
    correctionMessage: "Try using a secure protocol, such as 'https'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode sizedBoxForWhitespace = LinterLintCode(
    LintNames.sized_box_for_whitespace,
    "Use a 'SizedBox' to add whitespace to a layout.",
    correctionMessage: "Try using a 'SizedBox' rather than a 'Container'.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode sizedBoxShrinkExpand = LinterLintCode(
    LintNames.sized_box_shrink_expand,
    "Use 'SizedBox.{0}' to avoid needing to specify the 'height' and 'width'.",
    correctionMessage:
        "Try using 'SizedBox.{0}' and removing the 'height' and 'width' "
        "arguments.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode slashForDocComments = LinterLintCode(
    LintNames.slash_for_doc_comments,
    "Use the end-of-line form ('///') for doc comments.",
    correctionMessage: "Try rewriting the comment to use '///'.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode sortChildPropertiesLast = LinterLintCode(
    LintNames.sort_child_properties_last,
    "The '{0}' argument should be last in widget constructor invocations.",
    correctionMessage:
        "Try moving the argument to the end of the argument list.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode sortConstructorsFirst = LinterLintCode(
    LintNames.sort_constructors_first,
    "Constructor declarations should be before non-constructor declarations.",
    correctionMessage:
        "Try moving the constructor declaration before all other members.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode sortPubDependencies = LinterLintCode(
    LintNames.sort_pub_dependencies,
    "Dependencies not sorted alphabetically.",
    correctionMessage: "Try sorting the dependencies alphabetically (A to Z).",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode sortUnnamedConstructorsFirst = LinterLintCode(
    LintNames.sort_unnamed_constructors_first,
    "Invalid location for the unnamed constructor.",
    correctionMessage:
        "Try moving the unnamed constructor before all other constructors.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode specifyNonobviousLocalVariableTypes = LinterLintCode(
    LintNames.specify_nonobvious_local_variable_types,
    "Specify the type of a local variable when the type is non-obvious.",
    correctionMessage: "Try adding a type annotation.",
  );

  /// No parameters.
  static const LintCode specifyNonobviousPropertyTypes = LinterLintCode(
    LintNames.specify_nonobvious_property_types,
    "A type annotation is needed because it isn't obvious.",
    correctionMessage: "Try adding a type annotation.",
  );

  /// No parameters.
  static const LintCode strictTopLevelInferenceAddType = LinterLintCode(
    LintNames.strict_top_level_inference,
    "Missing type annotation.",
    correctionMessage: "Try adding a type annotation.",
    uniqueName: 'strict_top_level_inference_add_type',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode strictTopLevelInferenceReplaceKeyword = LinterLintCode(
    LintNames.strict_top_level_inference,
    "Missing type annotation.",
    correctionMessage: "Try replacing '{0}' with a type annotation.",
    uniqueName: 'strict_top_level_inference_replace_keyword',
  );

  /// No parameters.
  static const LintCode strictTopLevelInferenceSplitToTypes = LinterLintCode(
    LintNames.strict_top_level_inference,
    "Missing type annotation.",
    correctionMessage:
        "Try splitting the declaration and specify the different type "
        "annotations.",
    uniqueName: 'strict_top_level_inference_split_to_types',
  );

  /// No parameters.
  static const LintCode switchOnType = LinterLintCode(
    LintNames.switch_on_type,
    "Avoid switch statements on a 'Type'.",
    correctionMessage: "Try using pattern matching on a variable instead.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode testTypesInEquals = LinterLintCode(
    LintNames.test_types_in_equals,
    "Missing type test for '{0}' in '=='.",
    correctionMessage: "Try testing the type of '{0}'.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode throwInFinally = LinterLintCode(
    LintNames.throw_in_finally,
    "Use of '{0}' in 'finally' block.",
    correctionMessage: "Try moving the '{0}' outside the 'finally' block.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode tightenTypeOfInitializingFormals = LinterLintCode(
    LintNames.tighten_type_of_initializing_formals,
    "Use a type annotation rather than 'assert' to enforce non-nullability.",
    correctionMessage:
        "Try adding a type annotation and removing the 'assert'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode typeAnnotatePublicApis = LinterLintCode(
    LintNames.type_annotate_public_apis,
    "Missing type annotation on a public API.",
    correctionMessage: "Try adding a type annotation.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode typeInitFormals = LinterLintCode(
    LintNames.type_init_formals,
    "Don't needlessly type annotate initializing formals.",
    correctionMessage: "Try removing the type.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode typeLiteralInConstantPattern = LinterLintCode(
    LintNames.type_literal_in_constant_pattern,
    "Use 'TypeName _' instead of a type literal.",
    correctionMessage: "Replace with 'TypeName _'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unawaitedFutures = LinterLintCode(
    LintNames.unawaited_futures,
    "Missing an 'await' for the 'Future' computed by this expression.",
    correctionMessage:
        "Try adding an 'await' or wrapping the expression with 'unawaited'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unintendedHtmlInDocComment = LinterLintCode(
    LintNames.unintended_html_in_doc_comment,
    "Angle brackets will be interpreted as HTML.",
    correctionMessage:
        "Try using backticks around the content with angle brackets, or try "
        "replacing `<` with `&lt;` and `>` with `&gt;`.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryAsync = LinterLintCode(
    LintNames.unnecessary_async,
    "Don't make a function 'async' if it doesn't use 'await'.",
    correctionMessage: "Try removing the 'async' modifier.",
  );

  /// No parameters.
  static const LintCode unnecessaryAwaitInReturn = LinterLintCode(
    LintNames.unnecessary_await_in_return,
    "Unnecessary 'await'.",
    correctionMessage: "Try removing the 'await'.",
  );

  /// No parameters.
  static const LintCode unnecessaryBraceInStringInterps = LinterLintCode(
    LintNames.unnecessary_brace_in_string_interps,
    "Unnecessary braces in a string interpolation.",
    correctionMessage: "Try removing the braces.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryBreaks = LinterLintCode(
    LintNames.unnecessary_breaks,
    "Unnecessary 'break' statement.",
    correctionMessage: "Try removing the 'break'.",
  );

  /// No parameters.
  static const LintCode unnecessaryConst = LinterLintCode(
    LintNames.unnecessary_const,
    "Unnecessary 'const' keyword.",
    correctionMessage: "Try removing the keyword.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryConstructorName = LinterLintCode(
    LintNames.unnecessary_constructor_name,
    "Unnecessary '.new' constructor name.",
    correctionMessage: "Try removing the '.new'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryFinalWithType = LinterLintCode(
    LintNames.unnecessary_final,
    "Local variables should not be marked as 'final'.",
    correctionMessage: "Remove the 'final'.",
    hasPublishedDocs: true,
    uniqueName: 'unnecessary_final_with_type',
  );

  /// No parameters.
  static const LintCode unnecessaryFinalWithoutType = LinterLintCode(
    LintNames.unnecessary_final,
    "Local variables should not be marked as 'final'.",
    correctionMessage: "Replace 'final' with 'var'.",
    uniqueName: 'unnecessary_final_without_type',
  );

  /// No parameters.
  static const LintCode unnecessaryGettersSetters = LinterLintCode(
    LintNames.unnecessary_getters_setters,
    "Unnecessary use of getter and setter to wrap a field.",
    correctionMessage:
        "Try removing the getter and setter and renaming the field.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode unnecessaryIgnore = LinterLintCode(
    LintNames.unnecessary_ignore,
    "The diagnostic '{0}' isn't produced at this location so it doesn't need "
    "to be ignored.",
    correctionMessage: "Try removing the ignore comment.",
    hasPublishedDocs: true,
    uniqueName: 'unnecessary_ignore',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode unnecessaryIgnoreFile = LinterLintCode(
    LintNames.unnecessary_ignore,
    "The diagnostic '{0}' isn't produced in this file so it doesn't need to be "
    "ignored.",
    correctionMessage: "Try removing the ignore comment.",
    uniqueName: 'unnecessary_ignore_file',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode unnecessaryIgnoreName = LinterLintCode(
    LintNames.unnecessary_ignore,
    "The diagnostic '{0}' isn't produced at this location so it doesn't need "
    "to be ignored.",
    correctionMessage: "Try removing the name from the list.",
    uniqueName: 'unnecessary_ignore_name',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode unnecessaryIgnoreNameFile = LinterLintCode(
    LintNames.unnecessary_ignore,
    "The diagnostic '{0}' isn't produced in this file so it doesn't need to be "
    "ignored.",
    correctionMessage: "Try removing the name from the list.",
    uniqueName: 'unnecessary_ignore_name_file',
  );

  /// No parameters.
  static const LintCode unnecessaryLambdas = LinterLintCode(
    LintNames.unnecessary_lambdas,
    "Closure should be a tearoff.",
    correctionMessage: "Try using a tearoff rather than a closure.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryLate = LinterLintCode(
    LintNames.unnecessary_late,
    "Unnecessary 'late' modifier.",
    correctionMessage: "Try removing the 'late'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryLibraryDirective = LinterLintCode(
    LintNames.unnecessary_library_directive,
    "Library directives without comments or annotations should be avoided.",
    correctionMessage: "Try deleting the library directive.",
  );

  /// No parameters.
  static const LintCode unnecessaryLibraryName = LinterLintCode(
    LintNames.unnecessary_library_name,
    "Library names are not necessary.",
    correctionMessage: "Remove the library name.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryNew = LinterLintCode(
    LintNames.unnecessary_new,
    "Unnecessary 'new' keyword.",
    correctionMessage: "Try removing the 'new' keyword.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryNullAwareAssignments = LinterLintCode(
    LintNames.unnecessary_null_aware_assignments,
    "Unnecessary assignment of 'null'.",
    correctionMessage: "Try removing the assignment.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode
  unnecessaryNullAwareOperatorOnExtensionOnNullable = LinterLintCode(
    LintNames.unnecessary_null_aware_operator_on_extension_on_nullable,
    "Unnecessary use of a null-aware operator to invoke an extension method on "
    "a nullable type.",
    correctionMessage: "Try removing the '?'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryNullChecks = LinterLintCode(
    LintNames.unnecessary_null_checks,
    "Unnecessary use of a null check ('!').",
    correctionMessage: "Try removing the null check.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryNullInIfNullOperators = LinterLintCode(
    LintNames.unnecessary_null_in_if_null_operators,
    "Unnecessary use of '??' with 'null'.",
    correctionMessage: "Try removing the '??' operator and the 'null' operand.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryNullableForFinalVariableDeclarations =
      LinterLintCode(
        LintNames.unnecessary_nullable_for_final_variable_declarations,
        "Type could be non-nullable.",
        correctionMessage: "Try changing the type to be non-nullable.",
        hasPublishedDocs: true,
      );

  /// No parameters.
  static const LintCode unnecessaryOverrides = LinterLintCode(
    LintNames.unnecessary_overrides,
    "Unnecessary override.",
    correctionMessage:
        "Try adding behavior in the overriding member or removing the "
        "override.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryParenthesis = LinterLintCode(
    LintNames.unnecessary_parenthesis,
    "Unnecessary use of parentheses.",
    correctionMessage: "Try removing the parentheses.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryRawStrings = LinterLintCode(
    LintNames.unnecessary_raw_strings,
    "Unnecessary use of a raw string.",
    correctionMessage: "Try using a normal string.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryStatements = LinterLintCode(
    LintNames.unnecessary_statements,
    "Unnecessary statement.",
    correctionMessage: "Try completing the statement or breaking it up.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryStringEscapes = LinterLintCode(
    LintNames.unnecessary_string_escapes,
    "Unnecessary escape in string literal.",
    correctionMessage: "Remove the '\\' escape.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryStringInterpolations = LinterLintCode(
    LintNames.unnecessary_string_interpolations,
    "Unnecessary use of string interpolation.",
    correctionMessage:
        "Try replacing the string literal with the variable name.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryThis = LinterLintCode(
    LintNames.unnecessary_this,
    "Unnecessary 'this.' qualifier.",
    correctionMessage: "Try removing 'this.'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryToListInSpreads = LinterLintCode(
    LintNames.unnecessary_to_list_in_spreads,
    "Unnecessary use of 'toList' in a spread.",
    correctionMessage: "Try removing the invocation of 'toList'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryUnawaited = LinterLintCode(
    LintNames.unnecessary_unawaited,
    "Unnecessary use of 'unawaited'.",
    correctionMessage:
        "Try removing the use of 'unawaited', as the unawaited element is "
        "annotated with '@awaitNotRequired'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode unnecessaryUnderscores = LinterLintCode(
    LintNames.unnecessary_underscores,
    "Unnecessary use of multiple underscores.",
    correctionMessage: "Try using '_'.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode unreachableFromMain = LinterLintCode(
    LintNames.unreachable_from_main,
    "Unreachable member '{0}' in an executable library.",
    correctionMessage: "Try referencing the member or removing it.",
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode
  unrelatedTypeEqualityChecksInExpression = LinterLintCode(
    LintNames.unrelated_type_equality_checks,
    "The type of the right operand ('{0}') isn't a subtype or a supertype of "
    "the left operand ('{1}').",
    correctionMessage: "Try changing one or both of the operands.",
    hasPublishedDocs: true,
    uniqueName: 'unrelated_type_equality_checks_in_expression',
  );

  /// Parameters:
  /// Object p0: undocumented
  /// Object p1: undocumented
  static const LintCode unrelatedTypeEqualityChecksInPattern = LinterLintCode(
    LintNames.unrelated_type_equality_checks,
    "The type of the operand ('{0}') isn't a subtype or a supertype of the "
    "value being matched ('{1}').",
    correctionMessage: "Try changing one or both of the operands.",
    hasPublishedDocs: true,
    uniqueName: 'unrelated_type_equality_checks_in_pattern',
  );

  /// No parameters.
  static const LintCode unsafeVariance = LinterLintCode(
    LintNames.unsafe_variance,
    "This type is unsafe: a type parameter occurs in a non-covariant position.",
    correctionMessage:
        "Try using a more general type that doesn't contain any type "
        "parameters in such a position.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode useBuildContextSynchronouslyAsyncUse = LinterLintCode(
    LintNames.use_build_context_synchronously,
    "Don't use 'BuildContext's across async gaps.",
    correctionMessage:
        "Try rewriting the code to not use the 'BuildContext', or guard the "
        "use with a 'mounted' check.",
    hasPublishedDocs: true,
    uniqueName: 'use_build_context_synchronously_async_use',
  );

  /// No parameters.
  static const LintCode
  useBuildContextSynchronouslyWrongMounted = LinterLintCode(
    LintNames.use_build_context_synchronously,
    "Don't use 'BuildContext's across async gaps, guarded by an unrelated "
    "'mounted' check.",
    correctionMessage:
        "Guard a 'State.context' use with a 'mounted' check on the State, and "
        "other BuildContext use with a 'mounted' check on the BuildContext.",
    hasPublishedDocs: true,
    uniqueName: 'use_build_context_synchronously_wrong_mounted',
  );

  /// No parameters.
  static const LintCode useColoredBox = LinterLintCode(
    LintNames.use_colored_box,
    "Use a 'ColoredBox' rather than a 'Container' with only a 'Color'.",
    correctionMessage: "Try replacing the 'Container' with a 'ColoredBox'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode useDecoratedBox = LinterLintCode(
    LintNames.use_decorated_box,
    "Use 'DecoratedBox' rather than a 'Container' with only a 'Decoration'.",
    correctionMessage: "Try replacing the 'Container' with a 'DecoratedBox'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode useEnums = LinterLintCode(
    LintNames.use_enums,
    "Class should be an enum.",
    correctionMessage: "Try using an enum rather than a class.",
  );

  /// No parameters.
  static const LintCode useFullHexValuesForFlutterColors = LinterLintCode(
    LintNames.use_full_hex_values_for_flutter_colors,
    "Instances of 'Color' should be created using an 8-digit hexadecimal "
    "integer (such as '0xFFFFFFFF').",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode useFunctionTypeSyntaxForParameters = LinterLintCode(
    LintNames.use_function_type_syntax_for_parameters,
    "Use the generic function type syntax to declare the parameter '{0}'.",
    correctionMessage: "Try using the generic function type syntax.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode useIfNullToConvertNullsToBools = LinterLintCode(
    LintNames.use_if_null_to_convert_nulls_to_bools,
    "Use an if-null operator to convert a 'null' to a 'bool'.",
    correctionMessage: "Try using an if-null operator.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode useIsEvenRatherThanModulo = LinterLintCode(
    LintNames.use_is_even_rather_than_modulo,
    "Use '{0}' rather than '% 2'.",
    correctionMessage: "Try using '{0}'.",
  );

  /// No parameters.
  static const LintCode useKeyInWidgetConstructors = LinterLintCode(
    LintNames.use_key_in_widget_constructors,
    "Constructors for public widgets should have a named 'key' parameter.",
    correctionMessage: "Try adding a named parameter to the constructor.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode useLateForPrivateFieldsAndVariables = LinterLintCode(
    LintNames.use_late_for_private_fields_and_variables,
    "Use 'late' for private members with a non-nullable type.",
    correctionMessage: "Try making adding the modifier 'late'.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode useNamedConstants = LinterLintCode(
    LintNames.use_named_constants,
    "Use the constant '{0}' rather than a constructor returning the same "
    "object.",
    correctionMessage: "Try using '{0}'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode useNullAwareElements = LinterLintCode(
    LintNames.use_null_aware_elements,
    "Use the null-aware marker '?' rather than a null check via an 'if'.",
    correctionMessage: "Try using '?'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode useRawStrings = LinterLintCode(
    LintNames.use_raw_strings,
    "Use a raw string to avoid using escapes.",
    correctionMessage:
        "Try making the string a raw string and removing the escapes.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode useRethrowWhenPossible = LinterLintCode(
    LintNames.use_rethrow_when_possible,
    "Use 'rethrow' to rethrow a caught exception.",
    correctionMessage: "Try replacing the 'throw' with a 'rethrow'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode useSettersToChangeProperties = LinterLintCode(
    LintNames.use_setters_to_change_properties,
    "The method is used to change a property.",
    correctionMessage: "Try converting the method to a setter.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode useStringBuffers = LinterLintCode(
    LintNames.use_string_buffers,
    "Use a string buffer rather than '+' to compose strings.",
    correctionMessage: "Try writing the parts of a string to a string buffer.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode useStringInPartOfDirectives = LinterLintCode(
    LintNames.use_string_in_part_of_directives,
    "The part-of directive uses a library name.",
    correctionMessage:
        "Try converting the directive to use the URI of the library.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode useSuperParametersMultiple = LinterLintCode(
    LintNames.use_super_parameters,
    "Parameters '{0}' could be super parameters.",
    correctionMessage: "Trying converting '{0}' to super parameters.",
    hasPublishedDocs: true,
    uniqueName: 'use_super_parameters_multiple',
  );

  /// Parameters:
  /// Object p0: undocumented
  static const LintCode useSuperParametersSingle = LinterLintCode(
    LintNames.use_super_parameters,
    "Parameter '{0}' could be a super parameter.",
    correctionMessage: "Trying converting '{0}' to a super parameter.",
    hasPublishedDocs: true,
    uniqueName: 'use_super_parameters_single',
  );

  /// No parameters.
  static const LintCode useTestThrowsMatchers = LinterLintCode(
    LintNames.use_test_throws_matchers,
    "Use the 'throwsA' matcher instead of using 'fail' when there is no "
    "exception thrown.",
    correctionMessage:
        "Try removing the try-catch and using 'throwsA' to expect an "
        "exception.",
  );

  /// No parameters.
  static const LintCode useToAndAsIfApplicable = LinterLintCode(
    LintNames.use_to_and_as_if_applicable,
    "Start the name of the method with 'to' or 'as'.",
    correctionMessage: "Try renaming the method to use either 'to' or 'as'.",
  );

  /// No parameters.
  static const LintCode useTruncatingDivision = LinterLintCode(
    LintNames.use_truncating_division,
    "Use truncating division.",
    correctionMessage:
        "Try using truncating division, '~/', instead of regular division "
        "('/') followed by 'toInt()'.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode validRegexps = LinterLintCode(
    LintNames.valid_regexps,
    "Invalid regular expression syntax.",
    correctionMessage: "Try correcting the regular expression.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode visitRegisteredNodes = LinterLintCode(
    LintNames.visit_registered_nodes,
    "Declare 'visit' methods for all registered node types.",
    correctionMessage:
        "Try declaring a 'visit' method for all registered node types.",
    hasPublishedDocs: true,
  );

  /// No parameters.
  static const LintCode voidChecks = LinterLintCode(
    LintNames.void_checks,
    "Assignment to a variable of type 'void'.",
    correctionMessage:
        "Try removing the assignment or changing the type of the variable.",
    hasPublishedDocs: true,
  );

  /// A lint code that removed lints can specify as their `lintCode`.
  ///
  /// Avoid other usages as it should be made unnecessary and removed.
  static const LintCode removedLint = LinterLintCode(
    'removed_lint',
    'Removed lint.',
  );

  const LinterLintCode(
    super.name,
    super.problemMessage, {
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
}
