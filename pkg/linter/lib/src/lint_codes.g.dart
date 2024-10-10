// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/linter/messages.yaml' and run
// 'dart run pkg/linter/tool/generate_lints.dart' to update.

// We allow some snake_case and SCREAMING_SNAKE_CASE identifiers in generated
// code, as they match names declared in the source configuration files.
// ignore_for_file: constant_identifier_names

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

// Generator currently outputs double quotes for simplicity.
// ignore_for_file: prefer_single_quotes

import 'analyzer.dart';

class LinterLintCode extends LintCode {
  static const LintCode always_declare_return_types_of_functions =
      LinterLintCode(
    LintNames.always_declare_return_types,
    "The function '{0}' should have a return type but doesn't.",
    correctionMessage: "Try adding a return type to the function.",
    hasPublishedDocs: true,
    uniqueName: 'always_declare_return_types_of_functions',
  );

  static const LintCode always_declare_return_types_of_methods = LinterLintCode(
    LintNames.always_declare_return_types,
    "The method '{0}' should have a return type but doesn't.",
    correctionMessage: "Try adding a return type to the method.",
    hasPublishedDocs: true,
    uniqueName: 'always_declare_return_types_of_methods',
  );

  static const LintCode always_put_control_body_on_new_line = LinterLintCode(
    LintNames.always_put_control_body_on_new_line,
    "Statement should be on a separate line.",
    correctionMessage: "Try moving the statement to a new line.",
    hasPublishedDocs: true,
  );

  static const LintCode always_put_required_named_parameters_first =
      LinterLintCode(
    LintNames.always_put_required_named_parameters_first,
    "Required named parameters should be before optional named parameters.",
    correctionMessage:
        "Try moving the required named parameter to be before any optional "
        "named parameters.",
    hasPublishedDocs: true,
  );

  static const LintCode always_specify_types_add_type = LinterLintCode(
    LintNames.always_specify_types,
    "Missing type annotation.",
    correctionMessage: "Try adding a type annotation.",
    uniqueName: 'always_specify_types_add_type',
  );

  static const LintCode always_specify_types_replace_keyword = LinterLintCode(
    LintNames.always_specify_types,
    "Missing type annotation.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
    uniqueName: 'always_specify_types_replace_keyword',
  );

  static const LintCode always_specify_types_specify_type = LinterLintCode(
    LintNames.always_specify_types,
    "Missing type annotation.",
    correctionMessage: "Try specifying the type '{0}'.",
    uniqueName: 'always_specify_types_specify_type',
  );

  static const LintCode always_specify_types_split_to_types = LinterLintCode(
    LintNames.always_specify_types,
    "Missing type annotation.",
    correctionMessage:
        "Try splitting the declaration and specify the different type "
        "annotations.",
    uniqueName: 'always_specify_types_split_to_types',
  );

  static const LintCode always_use_package_imports = LinterLintCode(
    LintNames.always_use_package_imports,
    "Use 'package:' imports for files in the 'lib' directory.",
    correctionMessage: "Try converting the URI to a 'package:' URI.",
    hasPublishedDocs: true,
  );

  static const LintCode annotate_overrides = LinterLintCode(
    LintNames.annotate_overrides,
    "The member '{0}' overrides an inherited member but isn't annotated with "
    "'@override'.",
    correctionMessage: "Try adding the '@override' annotation.",
    hasPublishedDocs: true,
  );

  static const LintCode annotate_redeclares = LinterLintCode(
    LintNames.annotate_redeclares,
    "The member '{0}' is redeclaring but isn't annotated with '@redeclare'.",
    correctionMessage: "Try adding the '@redeclare' annotation.",
  );

  static const LintCode avoid_annotating_with_dynamic = LinterLintCode(
    LintNames.avoid_annotating_with_dynamic,
    "Unnecessary 'dynamic' type annotation.",
    correctionMessage: "Try removing the type 'dynamic'.",
  );

  static const LintCode avoid_bool_literals_in_conditional_expressions =
      LinterLintCode(
    LintNames.avoid_bool_literals_in_conditional_expressions,
    "Conditional expressions with a 'bool' literal can be simplified.",
    correctionMessage:
        "Try rewriting the expression to use either '&&' or '||'.",
  );

  static const LintCode avoid_catches_without_on_clauses = LinterLintCode(
    LintNames.avoid_catches_without_on_clauses,
    "Catch clause should use 'on' to specify the type of exception being "
    "caught.",
    correctionMessage: "Try adding an 'on' clause before the 'catch'.",
  );

  static const LintCode avoid_catching_errors_class = LinterLintCode(
    LintNames.avoid_catching_errors,
    "The type 'Error' should not be caught.",
    correctionMessage:
        "Try removing the catch or catching an 'Exception' instead.",
    uniqueName: 'avoid_catching_errors_class',
  );

  static const LintCode avoid_catching_errors_subclass = LinterLintCode(
    LintNames.avoid_catching_errors,
    "The type '{0}' should not be caught because it is a subclass of 'Error'.",
    correctionMessage:
        "Try removing the catch or catching an 'Exception' instead.",
    uniqueName: 'avoid_catching_errors_subclass',
  );

  static const LintCode avoid_classes_with_only_static_members = LinterLintCode(
    LintNames.avoid_classes_with_only_static_members,
    "Classes should define instance members.",
    correctionMessage:
        "Try adding instance behavior or moving the members out of the class.",
  );

  static const LintCode avoid_double_and_int_checks = LinterLintCode(
    LintNames.avoid_double_and_int_checks,
    "Explicit check for double or int.",
    correctionMessage: "Try removing the check.",
  );

  static const LintCode avoid_dynamic_calls = LinterLintCode(
    LintNames.avoid_dynamic_calls,
    "Method invocation or property access on a 'dynamic' target.",
    correctionMessage: "Try giving the target a type.",
  );

  static const LintCode avoid_empty_else = LinterLintCode(
    LintNames.avoid_empty_else,
    "Empty statements are not allowed in an 'else' clause.",
    correctionMessage:
        "Try removing the empty statement or removing the else clause.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_equals_and_hash_code_on_mutable_classes =
      LinterLintCode(
    LintNames.avoid_equals_and_hash_code_on_mutable_classes,
    "The method '{0}' should not be overridden in classes not annotated with "
    "'@immutable'.",
    correctionMessage:
        "Try removing the override or annotating the class with '@immutable'.",
  );

  static const LintCode avoid_escaping_inner_quotes = LinterLintCode(
    LintNames.avoid_escaping_inner_quotes,
    "Unnecessary escape of '{0}'.",
    correctionMessage: "Try changing the outer quotes to '{1}'.",
  );

  static const LintCode avoid_field_initializers_in_const_classes =
      LinterLintCode(
    LintNames.avoid_field_initializers_in_const_classes,
    "Fields in 'const' classes should not have initializers.",
    correctionMessage:
        "Try converting the field to a getter or initialize the field in the "
        "constructors.",
  );

  static const LintCode avoid_final_parameters = LinterLintCode(
    LintNames.avoid_final_parameters,
    "Parameters should not be marked as 'final'.",
    correctionMessage: "Try removing the keyword 'final'.",
  );

  static const LintCode avoid_function_literals_in_foreach_calls =
      LinterLintCode(
    LintNames.avoid_function_literals_in_foreach_calls,
    "Function literals shouldn't be passed to 'forEach'.",
    correctionMessage: "Try using a 'for' loop.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_futureor_void = LinterLintCode(
    LintNames.avoid_futureor_void,
    "Don't use the type 'FutureOr<void>'.",
    correctionMessage: "Try using 'Future<void>?' or 'void'.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_implementing_value_types = LinterLintCode(
    LintNames.avoid_implementing_value_types,
    "Classes that override '==' should not be implemented.",
    correctionMessage: "Try removing the class from the 'implements' clause.",
  );

  static const LintCode avoid_init_to_null = LinterLintCode(
    LintNames.avoid_init_to_null,
    "Redundant initialization to 'null'.",
    correctionMessage: "Try removing the initializer.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_js_rounded_ints = LinterLintCode(
    LintNames.avoid_js_rounded_ints,
    "Integer literal can't be represented exactly when compiled to JavaScript.",
    correctionMessage: "Try using a 'BigInt' to represent the value.",
  );

  static const LintCode avoid_multiple_declarations_per_line = LinterLintCode(
    LintNames.avoid_multiple_declarations_per_line,
    "Multiple variables declared on a single line.",
    correctionMessage:
        "Try splitting the variable declarations into multiple lines.",
  );

  static const LintCode avoid_null_checks_in_equality_operators =
      LinterLintCode(
    LintNames.avoid_null_checks_in_equality_operators,
    "Unnecessary null comparison in implementation of '=='.",
    correctionMessage: "Try removing the comparison.",
  );

  static const LintCode avoid_positional_boolean_parameters = LinterLintCode(
    LintNames.avoid_positional_boolean_parameters,
    "'bool' parameters should be named parameters.",
    correctionMessage: "Try converting the parameter to a named parameter.",
  );

  static const LintCode avoid_print = LinterLintCode(
    LintNames.avoid_print,
    "Don't invoke 'print' in production code.",
    correctionMessage: "Try using a logging framework.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_private_typedef_functions = LinterLintCode(
    LintNames.avoid_private_typedef_functions,
    "The typedef is unnecessary because it is only used in one place.",
    correctionMessage: "Try inlining the type or using it in other places.",
  );

  static const LintCode avoid_redundant_argument_values = LinterLintCode(
    LintNames.avoid_redundant_argument_values,
    "The value of the argument is redundant because it matches the default "
    "value.",
    correctionMessage: "Try removing the argument.",
  );

  static const LintCode avoid_relative_lib_imports = LinterLintCode(
    LintNames.avoid_relative_lib_imports,
    "Can't use a relative path to import a library in 'lib'.",
    correctionMessage:
        "Try fixing the relative path or changing the import to a 'package:' "
        "import.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_renaming_method_parameters = LinterLintCode(
    LintNames.avoid_renaming_method_parameters,
    "The parameter name '{0}' doesn't match the name '{1}' in the overridden "
    "method.",
    correctionMessage: "Try changing the name to '{1}'.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_return_types_on_setters = LinterLintCode(
    LintNames.avoid_return_types_on_setters,
    "Unnecessary return type on a setter.",
    correctionMessage: "Try removing the return type.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_returning_null_for_void_from_function =
      LinterLintCode(
    LintNames.avoid_returning_null_for_void,
    "Don't return 'null' from a function with a return type of 'void'.",
    correctionMessage: "Try removing the 'null'.",
    hasPublishedDocs: true,
    uniqueName: 'avoid_returning_null_for_void_from_function',
  );

  static const LintCode avoid_returning_null_for_void_from_method =
      LinterLintCode(
    LintNames.avoid_returning_null_for_void,
    "Don't return 'null' from a method with a return type of 'void'.",
    correctionMessage: "Try removing the 'null'.",
    hasPublishedDocs: true,
    uniqueName: 'avoid_returning_null_for_void_from_method',
  );

  static const LintCode avoid_returning_this = LinterLintCode(
    LintNames.avoid_returning_this,
    "Don't return 'this' from a method.",
    correctionMessage:
        "Try changing the return type to 'void' and removing the return.",
  );

  static const LintCode avoid_setters_without_getters = LinterLintCode(
    LintNames.avoid_setters_without_getters,
    "Setter has no corresponding getter.",
    correctionMessage:
        "Try adding a corresponding getter or removing the setter.",
  );

  static const LintCode avoid_shadowing_type_parameters = LinterLintCode(
    LintNames.avoid_shadowing_type_parameters,
    "The type parameter '{0}' shadows a type parameter from the enclosing {1}.",
    correctionMessage: "Try renaming one of the type parameters.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_single_cascade_in_expression_statements =
      LinterLintCode(
    LintNames.avoid_single_cascade_in_expression_statements,
    "Unnecessary cascade expression.",
    correctionMessage: "Try using the operator '{0}'.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_slow_async_io = LinterLintCode(
    LintNames.avoid_slow_async_io,
    "Use of an async 'dart:io' method.",
    correctionMessage: "Try using the synchronous version of the method.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_type_to_string = LinterLintCode(
    LintNames.avoid_type_to_string,
    "Using 'toString' on a 'Type' is not safe in production code.",
    correctionMessage:
        "Try a normal type check or compare the 'runtimeType' directly.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_types_as_parameter_names = LinterLintCode(
    LintNames.avoid_types_as_parameter_names,
    "The parameter name '{0}' matches a visible type name.",
    correctionMessage:
        "Try adding a name for the parameter or changing the parameter name to "
        "not match an existing type.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_types_on_closure_parameters = LinterLintCode(
    LintNames.avoid_types_on_closure_parameters,
    "Unnecessary type annotation on a function expression parameter.",
    correctionMessage: "Try removing the type annotation.",
  );

  static const LintCode avoid_unnecessary_containers = LinterLintCode(
    LintNames.avoid_unnecessary_containers,
    "Unnecessary instance of 'Container'.",
    correctionMessage:
        "Try removing the 'Container' (but not its children) from the widget "
        "tree.",
    hasPublishedDocs: true,
  );

  static const LintCode avoid_unused_constructor_parameters = LinterLintCode(
    LintNames.avoid_unused_constructor_parameters,
    "The parameter '{0}' is not used in the constructor.",
    correctionMessage: "Try using the parameter or removing it.",
  );

  static const LintCode avoid_void_async = LinterLintCode(
    LintNames.avoid_void_async,
    "An 'async' function should have a 'Future' return type when it doesn't "
    "return a value.",
    correctionMessage: "Try changing the return type.",
  );

  static const LintCode avoid_web_libraries_in_flutter = LinterLintCode(
    LintNames.avoid_web_libraries_in_flutter,
    "Don't use web-only libraries outside Flutter web plugins.",
    correctionMessage: "Try finding a different library for your needs.",
    hasPublishedDocs: true,
  );

  static const LintCode await_only_futures = LinterLintCode(
    LintNames.await_only_futures,
    "Uses 'await' on an instance of '{0}', which is not a subtype of 'Future'.",
    correctionMessage: "Try removing the 'await' or changing the expression.",
    hasPublishedDocs: true,
  );

  static const LintCode camel_case_extensions = LinterLintCode(
    LintNames.camel_case_extensions,
    "The extension name '{0}' isn't an UpperCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the UpperCamelCase style.",
    hasPublishedDocs: true,
  );

  static const LintCode camel_case_types = LinterLintCode(
    LintNames.camel_case_types,
    "The type name '{0}' isn't an UpperCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the UpperCamelCase style.",
    hasPublishedDocs: true,
  );

  static const LintCode cancel_subscriptions = LinterLintCode(
    LintNames.cancel_subscriptions,
    "Uncancelled instance of 'StreamSubscription'.",
    correctionMessage: "Try invoking 'cancel' in the function in which the "
        "'StreamSubscription' was created.",
    hasPublishedDocs: true,
  );

  static const LintCode cascade_invocations = LinterLintCode(
    LintNames.cascade_invocations,
    "Unnecessary duplication of receiver.",
    correctionMessage: "Try using a cascade to avoid the duplication.",
  );

  static const LintCode cast_nullable_to_non_nullable = LinterLintCode(
    LintNames.cast_nullable_to_non_nullable,
    "Don't cast a nullable value to a non-nullable type.",
    correctionMessage:
        "Try adding a not-null assertion ('!') to make the type non-nullable.",
  );

  static const LintCode close_sinks = LinterLintCode(
    LintNames.close_sinks,
    "Unclosed instance of 'Sink'.",
    correctionMessage:
        "Try invoking 'close' in the function in which the 'Sink' was created.",
    hasPublishedDocs: true,
  );

  static const LintCode collection_methods_unrelated_type = LinterLintCode(
    LintNames.collection_methods_unrelated_type,
    "The argument type '{0}' isn't related to '{1}'.",
    correctionMessage: "Try changing the argument or element type to match.",
    hasPublishedDocs: true,
  );

  static const LintCode combinators_ordering = LinterLintCode(
    LintNames.combinators_ordering,
    "Sort combinator names alphabetically.",
    correctionMessage: "Try sorting the combinator names alphabetically.",
  );

  static const LintCode comment_references = LinterLintCode(
    LintNames.comment_references,
    "The referenced name isn't visible in scope.",
    correctionMessage: "Try adding an import for the referenced name.",
  );

  static const LintCode conditional_uri_does_not_exist = LinterLintCode(
    LintNames.conditional_uri_does_not_exist,
    "The target of the conditional URI '{0}' doesn't exist.",
    correctionMessage:
        "Try creating the file referenced by the URI, or try using a URI for a "
        "file that does exist.",
  );

  static const LintCode constant_identifier_names = LinterLintCode(
    LintNames.constant_identifier_names,
    "The constant name '{0}' isn't a lowerCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the lowerCamelCase style.",
    hasPublishedDocs: true,
  );

  static const LintCode control_flow_in_finally = LinterLintCode(
    LintNames.control_flow_in_finally,
    "Use of '{0}' in a 'finally' clause.",
    correctionMessage: "Try restructuring the code.",
    hasPublishedDocs: true,
  );

  static const LintCode curly_braces_in_flow_control_structures =
      LinterLintCode(
    LintNames.curly_braces_in_flow_control_structures,
    "Statements in {0} should be enclosed in a block.",
    correctionMessage: "Try wrapping the statement in a block.",
    hasPublishedDocs: true,
  );

  static const LintCode dangling_library_doc_comments = LinterLintCode(
    LintNames.dangling_library_doc_comments,
    "Dangling library doc comment.",
    correctionMessage: "Add a 'library' directive after the library comment.",
    hasPublishedDocs: true,
  );

  static const LintCode depend_on_referenced_packages = LinterLintCode(
    LintNames.depend_on_referenced_packages,
    "The imported package '{0}' isn't a dependency of the importing package.",
    correctionMessage:
        "Try adding a dependency for '{0}' in the 'pubspec.yaml' file.",
    hasPublishedDocs: true,
  );

  static const LintCode deprecated_consistency_constructor = LinterLintCode(
    LintNames.deprecated_consistency,
    "Constructors in a deprecated class should be deprecated.",
    correctionMessage: "Try marking the constructor as deprecated.",
    uniqueName: 'deprecated_consistency_constructor',
  );

  static const LintCode deprecated_consistency_field = LinterLintCode(
    LintNames.deprecated_consistency,
    "Fields that are initialized by a deprecated parameter should be "
    "deprecated.",
    correctionMessage: "Try marking the field as deprecated.",
    uniqueName: 'deprecated_consistency_field',
  );

  static const LintCode deprecated_consistency_parameter = LinterLintCode(
    LintNames.deprecated_consistency,
    "Parameters that initialize a deprecated field should be deprecated.",
    correctionMessage: "Try marking the parameter as deprecated.",
    uniqueName: 'deprecated_consistency_parameter',
  );

  static const LintCode deprecated_member_use_from_same_package_with_message =
      LinterLintCode(
    LintNames.deprecated_member_use_from_same_package,
    "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement, "
        "if a replacement is specified.",
    uniqueName: 'deprecated_member_use_from_same_package_with_message',
  );

  static const LintCode
      deprecated_member_use_from_same_package_without_message = LinterLintCode(
    LintNames.deprecated_member_use_from_same_package,
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement, "
        "if a replacement is specified.",
    uniqueName: 'deprecated_member_use_from_same_package_without_message',
  );

  static const LintCode diagnostic_describe_all_properties = LinterLintCode(
    LintNames.diagnostic_describe_all_properties,
    "The public property isn't described by either 'debugFillProperties' or "
    "'debugDescribeChildren'.",
    correctionMessage: "Try describing the property.",
  );

  static const LintCode directives_ordering_alphabetical = LinterLintCode(
    LintNames.directives_ordering,
    "Sort directive sections alphabetically.",
    correctionMessage: "Try sorting the directives.",
    uniqueName: 'directives_ordering_alphabetical',
  );

  static const LintCode directives_ordering_dart = LinterLintCode(
    LintNames.directives_ordering,
    "Place 'dart:' {0}s before other {0}s.",
    correctionMessage: "Try sorting the directives.",
    uniqueName: 'directives_ordering_dart',
  );

  static const LintCode directives_ordering_exports = LinterLintCode(
    LintNames.directives_ordering,
    "Specify exports in a separate section after all imports.",
    correctionMessage: "Try sorting the directives.",
    uniqueName: 'directives_ordering_exports',
  );

  static const LintCode directives_ordering_package_before_relative =
      LinterLintCode(
    LintNames.directives_ordering,
    "Place 'package:' {0}s before relative {0}s.",
    correctionMessage: "Try sorting the directives.",
    uniqueName: 'directives_ordering_package_before_relative',
  );

  static const LintCode discarded_futures = LinterLintCode(
    LintNames.discarded_futures,
    "Asynchronous function invoked in a non-'async' function.",
    correctionMessage:
        "Try converting the enclosing function to be 'async' and then 'await' "
        "the future.",
  );

  static const LintCode do_not_use_environment = LinterLintCode(
    LintNames.do_not_use_environment,
    "Invalid use of an environment declaration.",
    correctionMessage: "Try removing the environment declaration usage.",
  );

  static const LintCode document_ignores = LinterLintCode(
    LintNames.document_ignores,
    "Missing documentation explaining why the diagnostic is ignored.",
    correctionMessage:
        "Try adding a comment immediately above the ignore comment.",
  );

  static const LintCode empty_catches = LinterLintCode(
    LintNames.empty_catches,
    "Empty catch block.",
    correctionMessage:
        "Try adding statements to the block, adding a comment to the block, or "
        "removing the 'catch' clause.",
    hasPublishedDocs: true,
  );

  static const LintCode empty_constructor_bodies = LinterLintCode(
    LintNames.empty_constructor_bodies,
    "Empty constructor bodies should be written using a ';' rather than '{}'.",
    correctionMessage: "Try replacing the constructor body with ';'.",
    hasPublishedDocs: true,
  );

  static const LintCode empty_statements = LinterLintCode(
    LintNames.empty_statements,
    "Unnecessary empty statement.",
    correctionMessage:
        "Try removing the empty statement or restructuring the code.",
    hasPublishedDocs: true,
  );

  static const LintCode eol_at_end_of_file = LinterLintCode(
    LintNames.eol_at_end_of_file,
    "Missing a newline at the end of the file.",
    correctionMessage: "Try adding a newline at the end of the file.",
  );

  static const LintCode erase_dart_type_extension_types = LinterLintCode(
    LintNames.erase_dart_type_extension_types,
    "Unsafe use of 'DartType' in an 'is' check.",
    correctionMessage:
        "Ensure DartType extension types are erased by using a helper method.",
  );

  static const LintCode exhaustive_cases = LinterLintCode(
    LintNames.exhaustive_cases,
    "Missing case clauses for some constants in '{0}'.",
    correctionMessage: "Try adding case clauses for the missing constants.",
  );

  static const LintCode file_names = LinterLintCode(
    LintNames.file_names,
    "The file name '{0}' isn't a lower_case_with_underscores identifier.",
    correctionMessage:
        "Try changing the name to follow the lower_case_with_underscores "
        "style.",
    hasPublishedDocs: true,
  );

  static const LintCode flutter_style_todos = LinterLintCode(
    LintNames.flutter_style_todos,
    "To-do comment doesn't follow the Flutter style.",
    correctionMessage: "Try following the Flutter style for to-do comments.",
  );

  static const LintCode hash_and_equals = LinterLintCode(
    LintNames.hash_and_equals,
    "Missing a corresponding override of '{0}'.",
    correctionMessage: "Try overriding '{0}' or removing '{1}'.",
    hasPublishedDocs: true,
  );

  static const LintCode implementation_imports = LinterLintCode(
    LintNames.implementation_imports,
    "Import of a library in the 'lib/src' directory of another package.",
    correctionMessage:
        "Try importing a public library that exports this library, or removing "
        "the import.",
    hasPublishedDocs: true,
  );

  static const LintCode implicit_call_tearoffs = LinterLintCode(
    LintNames.implicit_call_tearoffs,
    "Implicit tear-off of the 'call' method.",
    correctionMessage: "Try explicitly tearing off the 'call' method.",
    hasPublishedDocs: true,
  );

  static const LintCode implicit_reopen = LinterLintCode(
    LintNames.implicit_reopen,
    "The {0} '{1}' reopens '{2}' because it is not marked '{3}'.",
    correctionMessage:
        "Try marking '{1}' '{3}' or annotating it with '@reopen'.",
  );

  static const LintCode invalid_case_patterns = LinterLintCode(
    LintNames.invalid_case_patterns,
    "This expression is not valid in a 'case' clause in Dart 3.0.",
    correctionMessage: "Try refactoring the expression to be valid in 3.0.",
  );

  static const LintCode invalid_runtime_check_with_js_interop_types_dart_as_js =
      LinterLintCode(
    LintNames.invalid_runtime_check_with_js_interop_types,
    "Cast from '{0}' to '{1}' casts a Dart value to a JS interop type, which "
    "might not be platform-consistent.",
    correctionMessage:
        "Try using conversion methods from 'dart:js_interop' to convert "
        "between Dart types and JS interop types.",
    uniqueName: 'invalid_runtime_check_with_js_interop_types_dart_as_js',
  );

  static const LintCode invalid_runtime_check_with_js_interop_types_dart_is_js =
      LinterLintCode(
    LintNames.invalid_runtime_check_with_js_interop_types,
    "Runtime check between '{0}' and '{1}' checks whether a Dart value is a JS "
    "interop type, which might not be platform-consistent.",
    uniqueName: 'invalid_runtime_check_with_js_interop_types_dart_is_js',
  );

  static const LintCode invalid_runtime_check_with_js_interop_types_js_as_dart =
      LinterLintCode(
    LintNames.invalid_runtime_check_with_js_interop_types,
    "Cast from '{0}' to '{1}' casts a JS interop value to a Dart type, which "
    "might not be platform-consistent.",
    correctionMessage:
        "Try using conversion methods from 'dart:js_interop' to convert "
        "between JS interop types and Dart types.",
    uniqueName: 'invalid_runtime_check_with_js_interop_types_js_as_dart',
  );

  static const LintCode
      invalid_runtime_check_with_js_interop_types_js_as_incompatible_js =
      LinterLintCode(
    LintNames.invalid_runtime_check_with_js_interop_types,
    "Cast from '{0}' to '{1}' casts a JS interop value to an incompatible JS "
    "interop type, which might not be platform-consistent.",
    uniqueName:
        'invalid_runtime_check_with_js_interop_types_js_as_incompatible_js',
  );

  static const LintCode invalid_runtime_check_with_js_interop_types_js_is_dart =
      LinterLintCode(
    LintNames.invalid_runtime_check_with_js_interop_types,
    "Runtime check between '{0}' and '{1}' checks whether a JS interop value "
    "is a Dart type, which might not be platform-consistent.",
    uniqueName: 'invalid_runtime_check_with_js_interop_types_js_is_dart',
  );

  static const LintCode
      invalid_runtime_check_with_js_interop_types_js_is_inconsistent_js =
      LinterLintCode(
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

  static const LintCode
      invalid_runtime_check_with_js_interop_types_js_is_unrelated_js =
      LinterLintCode(
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

  static const LintCode join_return_with_assignment = LinterLintCode(
    LintNames.join_return_with_assignment,
    "Assignment could be inlined in 'return' statement.",
    correctionMessage:
        "Try inlining the assigned value in the 'return' statement.",
  );

  static const LintCode leading_newlines_in_multiline_strings = LinterLintCode(
    LintNames.leading_newlines_in_multiline_strings,
    "Missing a newline at the beginning of a multiline string.",
    correctionMessage: "Try adding a newline at the beginning of the string.",
  );

  static const LintCode library_annotations = LinterLintCode(
    LintNames.library_annotations,
    "This annotation should be attached to a library directive.",
    correctionMessage: "Try attaching the annotation to a library directive.",
  );

  static const LintCode library_names = LinterLintCode(
    LintNames.library_names,
    "The library name '{0}' isn't a lower_case_with_underscores identifier.",
    correctionMessage:
        "Try changing the name to follow the lower_case_with_underscores "
        "style.",
    hasPublishedDocs: true,
  );

  static const LintCode library_prefixes = LinterLintCode(
    LintNames.library_prefixes,
    "The prefix '{0}' isn't a lower_case_with_underscores identifier.",
    correctionMessage:
        "Try changing the prefix to follow the lower_case_with_underscores "
        "style.",
    hasPublishedDocs: true,
  );

  static const LintCode library_private_types_in_public_api = LinterLintCode(
    LintNames.library_private_types_in_public_api,
    "Invalid use of a private type in a public API.",
    correctionMessage:
        "Try making the private type public, or making the API that uses the "
        "private type also be private.",
    hasPublishedDocs: true,
  );

  static const LintCode lines_longer_than_80_chars = LinterLintCode(
    LintNames.lines_longer_than_80_chars,
    "The line length exceeds the 80-character limit.",
    correctionMessage: "Try breaking the line across multiple lines.",
  );

  static const LintCode literal_only_boolean_expressions = LinterLintCode(
    LintNames.literal_only_boolean_expressions,
    "The Boolean expression has a constant value.",
    correctionMessage: "Try changing the expression.",
    hasPublishedDocs: true,
  );

  static const LintCode matching_super_parameters = LinterLintCode(
    LintNames.matching_super_parameters,
    "The super parameter named '{0}'' does not share the same name as the "
    "corresponding parameter in the super constructor, '{1}'.",
    correctionMessage:
        "Try using the name of the corresponding parameter in the super "
        "constructor.",
  );

  static const LintCode missing_code_block_language_in_doc_comment =
      LinterLintCode(
    LintNames.missing_code_block_language_in_doc_comment,
    "The code block is missing a specified language.",
    correctionMessage: "Try adding a language to the code block.",
  );

  static const LintCode missing_whitespace_between_adjacent_strings =
      LinterLintCode(
    LintNames.missing_whitespace_between_adjacent_strings,
    "Missing whitespace between adjacent strings.",
    correctionMessage: "Try adding whitespace between the strings.",
  );

  static const LintCode no_adjacent_strings_in_list = LinterLintCode(
    LintNames.no_adjacent_strings_in_list,
    "Don't use adjacent strings in a list literal.",
    correctionMessage: "Try adding a comma between the strings.",
    hasPublishedDocs: true,
  );

  static const LintCode no_default_cases = LinterLintCode(
    LintNames.no_default_cases,
    "Invalid use of 'default' member in a switch.",
    correctionMessage:
        "Try enumerating all the possible values of the switch expression.",
  );

  static const LintCode no_duplicate_case_values = LinterLintCode(
    LintNames.no_duplicate_case_values,
    "The value of the case clause ('{0}') is equal to the value of an earlier "
    "case clause ('{1}').",
    correctionMessage: "Try removing or changing the value.",
    hasPublishedDocs: true,
  );

  static const LintCode no_leading_underscores_for_library_prefixes =
      LinterLintCode(
    LintNames.no_leading_underscores_for_library_prefixes,
    "The library prefix '{0}' starts with an underscore.",
    correctionMessage:
        "Try renaming the prefix to not start with an underscore.",
    hasPublishedDocs: true,
  );

  static const LintCode no_leading_underscores_for_local_identifiers =
      LinterLintCode(
    LintNames.no_leading_underscores_for_local_identifiers,
    "The local variable '{0}' starts with an underscore.",
    correctionMessage:
        "Try renaming the variable to not start with an underscore.",
    hasPublishedDocs: true,
  );

  static const LintCode no_literal_bool_comparisons = LinterLintCode(
    LintNames.no_literal_bool_comparisons,
    "Unnecessary comparison to a boolean literal.",
    correctionMessage:
        "Remove the comparison and use the negate `!` operator if necessary.",
  );

  static const LintCode no_logic_in_create_state = LinterLintCode(
    LintNames.no_logic_in_create_state,
    "Don't put any logic in 'createState'.",
    correctionMessage: "Try moving the logic out of 'createState'.",
    hasPublishedDocs: true,
  );

  static const LintCode no_runtimeType_toString = LinterLintCode(
    LintNames.no_runtimeType_toString,
    "Using 'toString' on a 'Type' is not safe in production code.",
    correctionMessage:
        "Try removing the usage of 'toString' or restructuring the code.",
  );

  static const LintCode no_self_assignments = LinterLintCode(
    LintNames.no_self_assignments,
    "The variable or property is being assigned to itself.",
    correctionMessage: "Try removing the assignment that has no direct effect.",
  );

  static const LintCode no_wildcard_variable_uses = LinterLintCode(
    LintNames.no_wildcard_variable_uses,
    "The referenced identifier is a wildcard.",
    correctionMessage: "Use an identifier name that is not a wildcard.",
    hasPublishedDocs: true,
  );

  static const LintCode non_constant_identifier_names = LinterLintCode(
    LintNames.non_constant_identifier_names,
    "The variable name '{0}' isn't a lowerCamelCase identifier.",
    correctionMessage:
        "Try changing the name to follow the lowerCamelCase style.",
    hasPublishedDocs: true,
  );

  static const LintCode noop_primitive_operations = LinterLintCode(
    LintNames.noop_primitive_operations,
    "The expression has no effect and can be removed.",
    correctionMessage: "Try removing the expression.",
  );

  static const LintCode null_check_on_nullable_type_parameter = LinterLintCode(
    LintNames.null_check_on_nullable_type_parameter,
    "The null check operator shouldn't be used on a variable whose type is a "
    "potentially nullable type parameter.",
    correctionMessage: "Try explicitly testing for 'null'.",
    hasPublishedDocs: true,
  );

  static const LintCode null_closures = LinterLintCode(
    LintNames.null_closures,
    "Closure can't be 'null' because it might be invoked.",
    correctionMessage: "Try providing a non-null closure.",
  );

  static const LintCode omit_local_variable_types = LinterLintCode(
    LintNames.omit_local_variable_types,
    "Unnecessary type annotation on a local variable.",
    correctionMessage: "Try removing the type annotation.",
  );

  static const LintCode omit_obvious_local_variable_types = LinterLintCode(
    LintNames.omit_obvious_local_variable_types,
    "Omit the type annotation on a local variable when the type is obvious.",
    correctionMessage: "Try removing the type annotation.",
  );

  static const LintCode one_member_abstracts = LinterLintCode(
    LintNames.one_member_abstracts,
    "Unnecessary use of an abstract class.",
    correctionMessage:
        "Try making '{0}' a top-level function and removing the class.",
  );

  static const LintCode only_throw_errors = LinterLintCode(
    LintNames.only_throw_errors,
    "Don't throw instances of classes that don't extend either 'Exception' or "
    "'Error'.",
    correctionMessage: "Try throwing a different class of object.",
  );

  static const LintCode overridden_fields = LinterLintCode(
    LintNames.overridden_fields,
    "Field overrides a field inherited from '{0}'.",
    correctionMessage:
        "Try removing the field, overriding the getter and setter if "
        "necessary.",
    hasPublishedDocs: true,
  );

  static const LintCode package_api_docs = LinterLintCode(
    LintNames.package_api_docs,
    "Missing documentation for public API.",
    correctionMessage: "Try adding a documentation comment.",
  );

  static const LintCode package_names = LinterLintCode(
    LintNames.package_names,
    "The package name '{0}' isn't a lower_case_with_underscores identifier.",
    correctionMessage:
        "Try changing the name to follow the lower_case_with_underscores "
        "style.",
    hasPublishedDocs: true,
  );

  static const LintCode package_prefixed_library_names = LinterLintCode(
    LintNames.package_prefixed_library_names,
    "The library name is not a dot-separated path prefixed by the package "
    "name.",
    correctionMessage: "Try changing the name to '{0}'.",
    hasPublishedDocs: true,
  );

  static const LintCode parameter_assignments = LinterLintCode(
    LintNames.parameter_assignments,
    "Invalid assignment to the parameter '{0}'.",
    correctionMessage: "Try using a local variable in place of the parameter.",
  );

  static const LintCode prefer_adjacent_string_concatenation = LinterLintCode(
    LintNames.prefer_adjacent_string_concatenation,
    "String literals shouldn't be concatenated by the '+' operator.",
    correctionMessage: "Try removing the operator to use adjacent strings.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_asserts_in_initializer_lists = LinterLintCode(
    LintNames.prefer_asserts_in_initializer_lists,
    "Assert should be in the initializer list.",
    correctionMessage: "Try moving the assert to the initializer list.",
  );

  static const LintCode prefer_asserts_with_message = LinterLintCode(
    LintNames.prefer_asserts_with_message,
    "Missing a message in an assert.",
    correctionMessage: "Try adding a message to the assert.",
  );

  static const LintCode prefer_collection_literals = LinterLintCode(
    LintNames.prefer_collection_literals,
    "Unnecessary constructor invocation.",
    correctionMessage: "Try using a collection literal.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_conditional_assignment = LinterLintCode(
    LintNames.prefer_conditional_assignment,
    "The 'if' statement could be replaced by a null-aware assignment.",
    correctionMessage:
        "Try using the '??=' operator to conditionally assign a value.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_const_constructors = LinterLintCode(
    LintNames.prefer_const_constructors,
    "Use 'const' with the constructor to improve performance.",
    correctionMessage:
        "Try adding the 'const' keyword to the constructor invocation.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_const_constructors_in_immutables =
      LinterLintCode(
    LintNames.prefer_const_constructors_in_immutables,
    "Constructors in '@immutable' classes should be declared as 'const'.",
    correctionMessage: "Try adding 'const' to the constructor declaration.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_const_declarations = LinterLintCode(
    LintNames.prefer_const_declarations,
    "Use 'const' for final variables initialized to a constant value.",
    correctionMessage: "Try replacing 'final' with 'const'.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_const_literals_to_create_immutables =
      LinterLintCode(
    LintNames.prefer_const_literals_to_create_immutables,
    "Use 'const' literals as arguments to constructors of '@immutable' "
    "classes.",
    correctionMessage: "Try adding 'const' before the literal.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_constructors_over_static_methods =
      LinterLintCode(
    LintNames.prefer_constructors_over_static_methods,
    "Static method should be a constructor.",
    correctionMessage: "Try converting the method into a constructor.",
  );

  static const LintCode prefer_contains_always_false = LinterLintCode(
    LintNames.prefer_contains,
    "Always 'false' because 'indexOf' is always greater than or equal to -1.",
    uniqueName: 'prefer_contains_always_false',
  );

  static const LintCode prefer_contains_always_true = LinterLintCode(
    LintNames.prefer_contains,
    "Always 'true' because 'indexOf' is always greater than or equal to -1.",
    uniqueName: 'prefer_contains_always_true',
  );

  static const LintCode prefer_contains_use_contains = LinterLintCode(
    LintNames.prefer_contains,
    "Unnecessary use of 'indexOf' to test for containment.",
    correctionMessage: "Try using 'contains'.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_contains_use_contains',
  );

  static const LintCode prefer_double_quotes = LinterLintCode(
    LintNames.prefer_double_quotes,
    "Unnecessary use of single quotes.",
    correctionMessage:
        "Try using double quotes unless the string contains double quotes.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_expression_function_bodies = LinterLintCode(
    LintNames.prefer_expression_function_bodies,
    "Unnecessary use of a block function body.",
    correctionMessage: "Try using an expression function body.",
  );

  static const LintCode prefer_final_fields = LinterLintCode(
    LintNames.prefer_final_fields,
    "The private field {0} could be 'final'.",
    correctionMessage: "Try making the field 'final'.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_final_in_for_each_pattern = LinterLintCode(
    LintNames.prefer_final_in_for_each,
    "The pattern should be final.",
    correctionMessage: "Try making the pattern final.",
    uniqueName: 'prefer_final_in_for_each_pattern',
  );

  static const LintCode prefer_final_in_for_each_variable = LinterLintCode(
    LintNames.prefer_final_in_for_each,
    "The variable '{0}' should be final.",
    correctionMessage: "Try making the variable final.",
    uniqueName: 'prefer_final_in_for_each_variable',
  );

  static const LintCode prefer_final_locals = LinterLintCode(
    LintNames.prefer_final_locals,
    "Local variables should be final.",
    correctionMessage: "Try making the variable final.",
  );

  static const LintCode prefer_final_parameters = LinterLintCode(
    LintNames.prefer_final_parameters,
    "The parameter '{0}' should be final.",
    correctionMessage: "Try making the parameter final.",
  );

  static const LintCode prefer_for_elements_to_map_fromIterable =
      LinterLintCode(
    LintNames.prefer_for_elements_to_map_fromIterable,
    "Use 'for' elements when building maps from iterables.",
    correctionMessage: "Try using a collection literal with a 'for' element.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_foreach = LinterLintCode(
    LintNames.prefer_foreach,
    "Use 'forEach' rather than a 'for' loop to apply a function to every "
    "element.",
    correctionMessage: "Try using 'forEach' rather than a 'for' loop.",
  );

  static const LintCode prefer_function_declarations_over_variables =
      LinterLintCode(
    LintNames.prefer_function_declarations_over_variables,
    "Use a function declaration rather than a variable assignment to bind a "
    "function to a name.",
    correctionMessage:
        "Try rewriting the closure assignment as a function declaration.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_generic_function_type_aliases = LinterLintCode(
    LintNames.prefer_generic_function_type_aliases,
    "Use the generic function type syntax in 'typedef's.",
    correctionMessage: "Try using the generic function type syntax ('{0}').",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_if_elements_to_conditional_expressions =
      LinterLintCode(
    LintNames.prefer_if_elements_to_conditional_expressions,
    "Use an 'if' element to conditionally add elements.",
    correctionMessage:
        "Try using an 'if' element rather than a conditional expression.",
  );

  static const LintCode prefer_if_null_operators = LinterLintCode(
    LintNames.prefer_if_null_operators,
    "Use the '??' operator rather than '?:' when testing for 'null'.",
    correctionMessage: "Try rewriting the code to use '??'.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_initializing_formals = LinterLintCode(
    LintNames.prefer_initializing_formals,
    "Use an initializing formal to assign a parameter to a field.",
    correctionMessage:
        "Try using an initialing formal ('this.{0}') to initialize the field.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_inlined_adds_multiple = LinterLintCode(
    LintNames.prefer_inlined_adds,
    "The addition of multiple list items could be inlined.",
    correctionMessage: "Try adding the items to the list literal directly.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_inlined_adds_multiple',
  );

  static const LintCode prefer_inlined_adds_single = LinterLintCode(
    LintNames.prefer_inlined_adds,
    "The addition of a list item could be inlined.",
    correctionMessage: "Try adding the item to the list literal directly.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_inlined_adds_single',
  );

  static const LintCode prefer_int_literals = LinterLintCode(
    LintNames.prefer_int_literals,
    "Unnecessary use of a 'double' literal.",
    correctionMessage: "Try using an 'int' literal.",
  );

  static const LintCode prefer_interpolation_to_compose_strings =
      LinterLintCode(
    LintNames.prefer_interpolation_to_compose_strings,
    "Use interpolation to compose strings and values.",
    correctionMessage:
        "Try using string interpolation to build the composite string.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_is_empty_always_false = LinterLintCode(
    LintNames.prefer_is_empty,
    "The comparison is always 'false' because the length is always greater "
    "than or equal to 0.",
    uniqueName: 'prefer_is_empty_always_false',
  );

  static const LintCode prefer_is_empty_always_true = LinterLintCode(
    LintNames.prefer_is_empty,
    "The comparison is always 'true' because the length is always greater than "
    "or equal to 0.",
    uniqueName: 'prefer_is_empty_always_true',
  );

  static const LintCode prefer_is_empty_use_is_empty = LinterLintCode(
    LintNames.prefer_is_empty,
    "Use 'isEmpty' instead of 'length' to test whether the collection is "
    "empty.",
    correctionMessage: "Try rewriting the expression to use 'isEmpty'.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_is_empty_use_is_empty',
  );

  static const LintCode prefer_is_empty_use_is_not_empty = LinterLintCode(
    LintNames.prefer_is_empty,
    "Use 'isNotEmpty' instead of 'length' to test whether the collection is "
    "empty.",
    correctionMessage: "Try rewriting the expression to use 'isNotEmpty'.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_is_empty_use_is_not_empty',
  );

  static const LintCode prefer_is_not_empty = LinterLintCode(
    LintNames.prefer_is_not_empty,
    "Use 'isNotEmpty' rather than negating the result of 'isEmpty'.",
    correctionMessage: "Try rewriting the expression to use 'isNotEmpty'.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_is_not_operator = LinterLintCode(
    LintNames.prefer_is_not_operator,
    "Use the 'is!' operator rather than negating the value of the 'is' "
    "operator.",
    correctionMessage: "Try rewriting the condition to use the 'is!' operator.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_iterable_whereType = LinterLintCode(
    LintNames.prefer_iterable_whereType,
    "Use 'whereType' to select elements of a given type.",
    correctionMessage: "Try rewriting the expression to use 'whereType'.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_mixin = LinterLintCode(
    LintNames.prefer_mixin,
    "Only mixins should be mixed in.",
    correctionMessage: "Try converting '{0}' to a mixin.",
  );

  static const LintCode prefer_null_aware_method_calls = LinterLintCode(
    LintNames.prefer_null_aware_method_calls,
    "Use a null-aware invocation of the 'call' method rather than explicitly "
    "testing for 'null'.",
    correctionMessage: "Try using '?.call()' to invoke the function.",
  );

  static const LintCode prefer_null_aware_operators = LinterLintCode(
    LintNames.prefer_null_aware_operators,
    "Use the null-aware operator '?.' rather than an explicit 'null' "
    "comparison.",
    correctionMessage: "Try using '?.'.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_relative_imports = LinterLintCode(
    LintNames.prefer_relative_imports,
    "Use relative imports for files in the 'lib' directory.",
    correctionMessage: "Try converting the URI to a relative URI.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_single_quotes = LinterLintCode(
    LintNames.prefer_single_quotes,
    "Unnecessary use of double quotes.",
    correctionMessage:
        "Try using single quotes unless the string contains single quotes.",
    hasPublishedDocs: true,
  );

  static const LintCode prefer_spread_collections = LinterLintCode(
    LintNames.prefer_spread_collections,
    "The addition of multiple elements could be inlined.",
    correctionMessage:
        "Try using the spread operator ('...') to inline the addition.",
  );

  static const LintCode prefer_typing_uninitialized_variables_for_field =
      LinterLintCode(
    LintNames.prefer_typing_uninitialized_variables,
    "An uninitialized field should have an explicit type annotation.",
    correctionMessage: "Try adding a type annotation.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_typing_uninitialized_variables_for_field',
  );

  static const LintCode
      prefer_typing_uninitialized_variables_for_local_variable = LinterLintCode(
    LintNames.prefer_typing_uninitialized_variables,
    "An uninitialized variable should have an explicit type annotation.",
    correctionMessage: "Try adding a type annotation.",
    hasPublishedDocs: true,
    uniqueName: 'prefer_typing_uninitialized_variables_for_local_variable',
  );

  static const LintCode prefer_void_to_null = LinterLintCode(
    LintNames.prefer_void_to_null,
    "Unnecessary use of the type 'Null'.",
    correctionMessage: "Try using 'void' instead.",
    hasPublishedDocs: true,
  );

  static const LintCode provide_deprecation_message = LinterLintCode(
    LintNames.provide_deprecation_message,
    "Missing a deprecation message.",
    correctionMessage: "Try using the constructor to provide a message "
        "('@Deprecated(\"message\")').",
    hasPublishedDocs: true,
  );

  static const LintCode public_member_api_docs = LinterLintCode(
    LintNames.public_member_api_docs,
    "Missing documentation for a public member.",
    correctionMessage: "Try adding documentation for the member.",
  );

  static const LintCode recursive_getters = LinterLintCode(
    LintNames.recursive_getters,
    "The getter '{0}' recursively returns itself.",
    correctionMessage: "Try changing the value being returned.",
    hasPublishedDocs: true,
  );

  static const LintCode require_trailing_commas = LinterLintCode(
    LintNames.require_trailing_commas,
    "Missing a required trailing comma.",
    correctionMessage: "Try adding a trailing comma.",
  );

  static const LintCode secure_pubspec_urls = LinterLintCode(
    LintNames.secure_pubspec_urls,
    "The '{0}' protocol shouldn't be used because it isn't secure.",
    correctionMessage: "Try using a secure protocol, such as 'https'.",
    hasPublishedDocs: true,
  );

  static const LintCode sized_box_for_whitespace = LinterLintCode(
    LintNames.sized_box_for_whitespace,
    "Use a 'SizedBox' to add whitespace to a layout.",
    correctionMessage: "Try using a 'SizedBox' rather than a 'Container'.",
    hasPublishedDocs: true,
  );

  static const LintCode sized_box_shrink_expand = LinterLintCode(
    LintNames.sized_box_shrink_expand,
    "Use 'SizedBox.{0}' to avoid needing to specify the 'height' and 'width'.",
    correctionMessage:
        "Try using 'SizedBox.{0}' and removing the 'height' and 'width' "
        "arguments.",
    hasPublishedDocs: true,
  );

  static const LintCode slash_for_doc_comments = LinterLintCode(
    LintNames.slash_for_doc_comments,
    "Use the end-of-line form ('///') for doc comments.",
    correctionMessage: "Try rewriting the comment to use '///'.",
    hasPublishedDocs: true,
  );

  static const LintCode sort_child_properties_last = LinterLintCode(
    LintNames.sort_child_properties_last,
    "The '{0}' argument should be last in widget constructor invocations.",
    correctionMessage:
        "Try moving the argument to the end of the argument list.",
    hasPublishedDocs: true,
  );

  static const LintCode sort_constructors_first = LinterLintCode(
    LintNames.sort_constructors_first,
    "Constructor declarations should be before non-constructor declarations.",
    correctionMessage:
        "Try moving the constructor declaration before all other members.",
    hasPublishedDocs: true,
  );

  static const LintCode sort_pub_dependencies = LinterLintCode(
    LintNames.sort_pub_dependencies,
    "Dependencies not sorted alphabetically.",
    correctionMessage: "Try sorting the dependencies alphabetically (A to Z).",
    hasPublishedDocs: true,
  );

  static const LintCode sort_unnamed_constructors_first = LinterLintCode(
    LintNames.sort_unnamed_constructors_first,
    "Invalid location for the unnamed constructor.",
    correctionMessage:
        "Try moving the unnamed constructor before all other constructors.",
    hasPublishedDocs: true,
  );

  static const LintCode specify_nonobvious_local_variable_types =
      LinterLintCode(
    LintNames.specify_nonobvious_local_variable_types,
    "Specify the type of a local variable when the type is non-obvious.",
    correctionMessage: "Try adding a type annotation.",
  );

  static const LintCode test_types_in_equals = LinterLintCode(
    LintNames.test_types_in_equals,
    "Missing type test for '{0}' in '=='.",
    correctionMessage: "Try testing the type of '{0}'.",
    hasPublishedDocs: true,
  );

  static const LintCode throw_in_finally = LinterLintCode(
    LintNames.throw_in_finally,
    "Use of '{0}' in 'finally' block.",
    correctionMessage: "Try moving the '{0}' outside the 'finally' block.",
    hasPublishedDocs: true,
  );

  static const LintCode tighten_type_of_initializing_formals = LinterLintCode(
    LintNames.tighten_type_of_initializing_formals,
    "Use a type annotation rather than 'assert' to enforce non-nullability.",
    correctionMessage:
        "Try adding a type annotation and removing the 'assert'.",
  );

  static const LintCode type_annotate_public_apis = LinterLintCode(
    LintNames.type_annotate_public_apis,
    "Missing type annotation on a public API.",
    correctionMessage: "Try adding a type annotation.",
  );

  static const LintCode type_init_formals = LinterLintCode(
    LintNames.type_init_formals,
    "Don't needlessly type annotate initializing formals.",
    correctionMessage: "Try removing the type.",
    hasPublishedDocs: true,
  );

  static const LintCode type_literal_in_constant_pattern = LinterLintCode(
    LintNames.type_literal_in_constant_pattern,
    "Use 'TypeName _' instead of a type literal.",
    correctionMessage: "Replace with 'TypeName _'.",
    hasPublishedDocs: true,
  );

  static const LintCode unawaited_futures = LinterLintCode(
    LintNames.unawaited_futures,
    "Missing an 'await' for the 'Future' computed by this expression.",
    correctionMessage:
        "Try adding an 'await' or wrapping the expression with 'unawaited'.",
    hasPublishedDocs: true,
  );

  static const LintCode unintended_html_in_doc_comment = LinterLintCode(
    LintNames.unintended_html_in_doc_comment,
    "Angle brackets will be interpreted as HTML.",
    correctionMessage:
        "Try using backticks around the content with angle brackets, or try "
        "replacing `<` with `&lt;` and `>` with `&gt;`.",
  );

  static const LintCode unnecessary_await_in_return = LinterLintCode(
    LintNames.unnecessary_await_in_return,
    "Unnecessary 'await'.",
    correctionMessage: "Try removing the 'await'.",
  );

  static const LintCode unnecessary_brace_in_string_interps = LinterLintCode(
    LintNames.unnecessary_brace_in_string_interps,
    "Unnecessary braces in a string interpolation.",
    correctionMessage: "Try removing the braces.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_breaks = LinterLintCode(
    LintNames.unnecessary_breaks,
    "Unnecessary 'break' statement.",
    correctionMessage: "Try removing the 'break'.",
  );

  static const LintCode unnecessary_const = LinterLintCode(
    LintNames.unnecessary_const,
    "Unnecessary 'const' keyword.",
    correctionMessage: "Try removing the keyword.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_constructor_name = LinterLintCode(
    LintNames.unnecessary_constructor_name,
    "Unnecessary '.new' constructor name.",
    correctionMessage: "Try removing the '.new'.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_final_with_type = LinterLintCode(
    LintNames.unnecessary_final,
    "Local variables should not be marked as 'final'.",
    correctionMessage: "Remove the 'final'.",
    hasPublishedDocs: true,
    uniqueName: 'unnecessary_final_with_type',
  );

  static const LintCode unnecessary_final_without_type = LinterLintCode(
    LintNames.unnecessary_final,
    "Local variables should not be marked as 'final'.",
    correctionMessage: "Replace 'final' with 'var'.",
    uniqueName: 'unnecessary_final_without_type',
  );

  static const LintCode unnecessary_getters_setters = LinterLintCode(
    LintNames.unnecessary_getters_setters,
    "Unnecessary use of getter and setter to wrap a field.",
    correctionMessage:
        "Try removing the getter and setter and renaming the field.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_lambdas = LinterLintCode(
    LintNames.unnecessary_lambdas,
    "Closure should be a tearoff.",
    correctionMessage: "Try using a tearoff rather than a closure.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_late = LinterLintCode(
    LintNames.unnecessary_late,
    "Unnecessary 'late' modifier.",
    correctionMessage: "Try removing the 'late'.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_library_directive = LinterLintCode(
    LintNames.unnecessary_library_directive,
    "Library directives without comments or annotations should be avoided.",
    correctionMessage: "Try deleting the library directive.",
  );

  static const LintCode unnecessary_library_name = LinterLintCode(
    LintNames.unnecessary_library_name,
    "Library names are not necessary.",
    correctionMessage: "Remove the library name.",
  );

  static const LintCode unnecessary_new = LinterLintCode(
    LintNames.unnecessary_new,
    "Unnecessary 'new' keyword.",
    correctionMessage: "Try removing the 'new' keyword.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_null_aware_assignments = LinterLintCode(
    LintNames.unnecessary_null_aware_assignments,
    "Unnecessary assignment of 'null'.",
    correctionMessage: "Try removing the assignment.",
    hasPublishedDocs: true,
  );

  static const LintCode
      unnecessary_null_aware_operator_on_extension_on_nullable = LinterLintCode(
    LintNames.unnecessary_null_aware_operator_on_extension_on_nullable,
    "Unnecessary use of a null-aware operator to invoke an extension method on "
    "a nullable type.",
    correctionMessage: "Try removing the '?'.",
  );

  static const LintCode unnecessary_null_checks = LinterLintCode(
    LintNames.unnecessary_null_checks,
    "Unnecessary use of a null check ('!').",
    correctionMessage: "Try removing the null check.",
  );

  static const LintCode unnecessary_null_in_if_null_operators = LinterLintCode(
    LintNames.unnecessary_null_in_if_null_operators,
    "Unnecessary use of '??' with 'null'.",
    correctionMessage: "Try removing the '??' operator and the 'null' operand.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_nullable_for_final_variable_declarations =
      LinterLintCode(
    LintNames.unnecessary_nullable_for_final_variable_declarations,
    "Type could be non-nullable.",
    correctionMessage: "Try changing the type to be non-nullable.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_overrides = LinterLintCode(
    LintNames.unnecessary_overrides,
    "Unnecessary override.",
    correctionMessage:
        "Try adding behavior in the overriding member or removing the "
        "override.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_parenthesis = LinterLintCode(
    LintNames.unnecessary_parenthesis,
    "Unnecessary use of parentheses.",
    correctionMessage: "Try removing the parentheses.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_raw_strings = LinterLintCode(
    LintNames.unnecessary_raw_strings,
    "Unnecessary use of a raw string.",
    correctionMessage: "Try using a normal string.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_statements = LinterLintCode(
    LintNames.unnecessary_statements,
    "Unnecessary statement.",
    correctionMessage: "Try completing the statement or breaking it up.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_string_escapes = LinterLintCode(
    LintNames.unnecessary_string_escapes,
    "Unnecessary escape in string literal.",
    correctionMessage: "Remove the '\\' escape.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_string_interpolations = LinterLintCode(
    LintNames.unnecessary_string_interpolations,
    "Unnecessary use of string interpolation.",
    correctionMessage:
        "Try replacing the string literal with the variable name.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_this = LinterLintCode(
    LintNames.unnecessary_this,
    "Unnecessary 'this.' qualifier.",
    correctionMessage: "Try removing 'this.'.",
    hasPublishedDocs: true,
  );

  static const LintCode unnecessary_to_list_in_spreads = LinterLintCode(
    LintNames.unnecessary_to_list_in_spreads,
    "Unnecessary use of 'toList' in a spread.",
    correctionMessage: "Try removing the invocation of 'toList'.",
    hasPublishedDocs: true,
  );

  static const LintCode unreachable_from_main = LinterLintCode(
    LintNames.unreachable_from_main,
    "Unreachable member '{0}' in an executable library.",
    correctionMessage: "Try referencing the member or removing it.",
  );

  static const LintCode unrelated_type_equality_checks_in_expression =
      LinterLintCode(
    LintNames.unrelated_type_equality_checks,
    "The type of the right operand ('{0}') isn't a subtype or a supertype of "
    "the left operand ('{1}').",
    correctionMessage: "Try changing one or both of the operands.",
    hasPublishedDocs: true,
    uniqueName: 'unrelated_type_equality_checks_in_expression',
  );

  static const LintCode unrelated_type_equality_checks_in_pattern =
      LinterLintCode(
    LintNames.unrelated_type_equality_checks,
    "The type of the operand ('{0}') isn't a subtype or a supertype of the "
    "value being matched ('{1}').",
    correctionMessage: "Try changing one or both of the operands.",
    hasPublishedDocs: true,
    uniqueName: 'unrelated_type_equality_checks_in_pattern',
  );

  static const LintCode unsafe_html_attribute = LinterLintCode(
    LintNames.unsafe_html,
    "Assigning to the attribute '{0}' is unsafe.",
    correctionMessage: "Try finding a different way to implement the page.",
    uniqueName: 'unsafe_html_attribute',
  );

  static const LintCode unsafe_html_constructor = LinterLintCode(
    LintNames.unsafe_html,
    "Invoking the constructor '{0}' is unsafe.",
    correctionMessage: "Try finding a different way to implement the page.",
    uniqueName: 'unsafe_html_constructor',
  );

  static const LintCode unsafe_html_method = LinterLintCode(
    LintNames.unsafe_html,
    "Invoking the method '{0}' is unsafe.",
    correctionMessage: "Try finding a different way to implement the page.",
    uniqueName: 'unsafe_html_method',
  );

  static const LintCode use_build_context_synchronously_async_use =
      LinterLintCode(
    LintNames.use_build_context_synchronously,
    "Don't use 'BuildContext's across async gaps.",
    correctionMessage:
        "Try rewriting the code to not use the 'BuildContext', or guard the "
        "use with a 'mounted' check.",
    hasPublishedDocs: true,
    uniqueName: 'use_build_context_synchronously_async_use',
  );

  static const LintCode use_build_context_synchronously_wrong_mounted =
      LinterLintCode(
    LintNames.use_build_context_synchronously,
    "Don't use 'BuildContext's across async gaps, guarded by an unrelated "
    "'mounted' check.",
    correctionMessage:
        "Guard a 'State.context' use with a 'mounted' check on the State, and "
        "other BuildContext use with a 'mounted' check on the BuildContext.",
    hasPublishedDocs: true,
    uniqueName: 'use_build_context_synchronously_wrong_mounted',
  );

  static const LintCode use_colored_box = LinterLintCode(
    LintNames.use_colored_box,
    "Use a 'ColoredBox' rather than a 'Container' with only a 'Color'.",
    correctionMessage: "Try replacing the 'Container' with a 'ColoredBox'.",
    hasPublishedDocs: true,
  );

  static const LintCode use_decorated_box = LinterLintCode(
    LintNames.use_decorated_box,
    "Use 'DecoratedBox' rather than a 'Container' with only a 'Decoration'.",
    correctionMessage: "Try replacing the 'Container' with a 'DecoratedBox'.",
    hasPublishedDocs: true,
  );

  static const LintCode use_enums = LinterLintCode(
    LintNames.use_enums,
    "Class should be an enum.",
    correctionMessage: "Try using an enum rather than a class.",
  );

  static const LintCode use_full_hex_values_for_flutter_colors = LinterLintCode(
    LintNames.use_full_hex_values_for_flutter_colors,
    "Instances of 'Color' should be created using an 8-digit hexadecimal "
    "integer (such as '0xFFFFFFFF').",
    hasPublishedDocs: true,
  );

  static const LintCode use_function_type_syntax_for_parameters =
      LinterLintCode(
    LintNames.use_function_type_syntax_for_parameters,
    "Use the generic function type syntax to declare the parameter '{0}'.",
    correctionMessage: "Try using the generic function type syntax.",
    hasPublishedDocs: true,
  );

  static const LintCode use_if_null_to_convert_nulls_to_bools = LinterLintCode(
    LintNames.use_if_null_to_convert_nulls_to_bools,
    "Use an if-null operator to convert a 'null' to a 'bool'.",
    correctionMessage: "Try using an if-null operator.",
    hasPublishedDocs: true,
  );

  static const LintCode use_is_even_rather_than_modulo = LinterLintCode(
    LintNames.use_is_even_rather_than_modulo,
    "Use '{0}' rather than '% 2'.",
    correctionMessage: "Try using '{0}'.",
  );

  static const LintCode use_key_in_widget_constructors = LinterLintCode(
    LintNames.use_key_in_widget_constructors,
    "Constructors for public widgets should have a named 'key' parameter.",
    correctionMessage: "Try adding a named parameter to the constructor.",
    hasPublishedDocs: true,
  );

  static const LintCode use_late_for_private_fields_and_variables =
      LinterLintCode(
    LintNames.use_late_for_private_fields_and_variables,
    "Use 'late' for private members with a non-nullable type.",
    correctionMessage: "Try making adding the modifier 'late'.",
    hasPublishedDocs: true,
  );

  static const LintCode use_named_constants = LinterLintCode(
    LintNames.use_named_constants,
    "Use the constant '{0}' rather than a constructor returning the same "
    "object.",
    correctionMessage: "Try using '{0}'.",
    hasPublishedDocs: true,
  );

  static const LintCode use_raw_strings = LinterLintCode(
    LintNames.use_raw_strings,
    "Use a raw string to avoid using escapes.",
    correctionMessage:
        "Try making the string a raw string and removing the escapes.",
    hasPublishedDocs: true,
  );

  static const LintCode use_rethrow_when_possible = LinterLintCode(
    LintNames.use_rethrow_when_possible,
    "Use 'rethrow' to rethrow a caught exception.",
    correctionMessage: "Try replacing the 'throw' with a 'rethrow'.",
    hasPublishedDocs: true,
  );

  static const LintCode use_setters_to_change_properties = LinterLintCode(
    LintNames.use_setters_to_change_properties,
    "The method is used to change a property.",
    correctionMessage: "Try converting the method to a setter.",
    hasPublishedDocs: true,
  );

  static const LintCode use_string_buffers = LinterLintCode(
    LintNames.use_string_buffers,
    "Use a string buffer rather than '+' to compose strings.",
    correctionMessage: "Try writing the parts of a string to a string buffer.",
    hasPublishedDocs: true,
  );

  static const LintCode use_string_in_part_of_directives = LinterLintCode(
    LintNames.use_string_in_part_of_directives,
    "The part-of directive uses a library name.",
    correctionMessage:
        "Try converting the directive to use the URI of the library.",
    hasPublishedDocs: true,
  );

  static const LintCode use_super_parameters_multiple = LinterLintCode(
    LintNames.use_super_parameters,
    "Parameters '{0}' could be super parameters.",
    correctionMessage: "Trying converting '{0}' to super parameters.",
    hasPublishedDocs: true,
    uniqueName: 'use_super_parameters_multiple',
  );

  static const LintCode use_super_parameters_single = LinterLintCode(
    LintNames.use_super_parameters,
    "Parameter '{0}' could be a super parameter.",
    correctionMessage: "Trying converting '{0}' to a super parameter.",
    hasPublishedDocs: true,
    uniqueName: 'use_super_parameters_single',
  );

  static const LintCode use_test_throws_matchers = LinterLintCode(
    LintNames.use_test_throws_matchers,
    "Use the 'throwsA' matcher instead of using 'fail' when there is no "
    "exception thrown.",
    correctionMessage:
        "Try removing the try-catch and using 'throwsA' to expect an "
        "exception.",
  );

  static const LintCode use_to_and_as_if_applicable = LinterLintCode(
    LintNames.use_to_and_as_if_applicable,
    "Start the name of the method with 'to' or 'as'.",
    correctionMessage: "Try renaming the method to use either 'to' or 'as'.",
  );

  static const LintCode use_truncating_division = LinterLintCode(
    LintNames.use_truncating_division,
    "Use truncating division.",
    correctionMessage:
        "Try using truncating division, '~/', instead of regular division "
        "('/') followed by 'toInt()'.",
  );

  static const LintCode valid_regexps = LinterLintCode(
    LintNames.valid_regexps,
    "Invalid regular expression syntax.",
    correctionMessage: "Try correcting the regular expression.",
    hasPublishedDocs: true,
  );

  static const LintCode void_checks = LinterLintCode(
    LintNames.void_checks,
    "Assignment to a variable of type 'void'.",
    correctionMessage:
        "Try removing the assignment or changing the type of the variable.",
    hasPublishedDocs: true,
  );

  /// A lint code that removed lints can specify as their `lintCode`.
  ///
  /// Avoid other usages as it should be made unnecessary and removed.
  static const LintCode removed_lint = LinterLintCode(
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
