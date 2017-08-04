// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The messages in this file should follow the [Guide for Writing
/// Diagnostics](../../../../front_end/lib/src/fasta/diagnostics.md).
///
/// Other things to keep in mind:
///
/// An INFO message should always be preceded by a non-INFO message, and the
/// INFO messages are additional details about the preceding non-INFO
/// message. For example, consider duplicated elements. First report a WARNING
/// or ERROR about the duplicated element, and then report an INFO about the
/// location of the existing element.
library dart2js.messages;

import 'package:front_end/src/fasta/scanner.dart' show ErrorToken, Token;
import 'generated/shared_messages.dart' as shared_messages;
import 'invariant.dart' show failedAt;
import 'spannable.dart' show CURRENT_ELEMENT_SPANNABLE;

const DONT_KNOW_HOW_TO_FIX = "Computer says no!";

/// Keys for the [MessageTemplate]s.
enum MessageKind {
  ABSTRACT_CLASS_INSTANTIATION,
  ABSTRACT_GETTER,
  ABSTRACT_METHOD,
  ABSTRACT_SETTER,
  ACCESSED_IN_CLOSURE,
  ACCESSED_IN_CLOSURE_HERE,
  ADDITIONAL_ARGUMENT,
  ADDITIONAL_TYPE_ARGUMENT,
  ALREADY_INITIALIZED,
  AMBIGUOUS_LOCATION,
  AMBIGUOUS_REEXPORT,
  ASSERT_IS_GIVEN_NAMED_ARGUMENTS,
  ASSIGNING_FINAL_FIELD_IN_SUPER,
  ASSIGNING_METHOD,
  ASSIGNING_METHOD_IN_SUPER,
  ASSIGNING_TYPE,
  ASYNC_AWAIT_NOT_SUPPORTED,
  ASYNC_KEYWORD_AS_IDENTIFIER,
  ASYNC_MODIFIER_ON_ABSTRACT_METHOD,
  ASYNC_MODIFIER_ON_CONSTRUCTOR,
  ASYNC_MODIFIER_ON_SETTER,
  AWAIT_MEMBER_NOT_FOUND,
  AWAIT_MEMBER_NOT_FOUND_IN_CLOSURE,
  BAD_INPUT_CHARACTER,
  BEFORE_TOP_LEVEL,
  BINARY_OPERATOR_BAD_ARITY,
  BODY_EXPECTED,
  CANNOT_EXTEND,
  CANNOT_EXTEND_ENUM,
  CANNOT_EXTEND_MALFORMED,
  CANNOT_FIND_CONSTRUCTOR,
  CANNOT_FIND_UNNAMED_CONSTRUCTOR,
  CANNOT_IMPLEMENT,
  CANNOT_IMPLEMENT_ENUM,
  CANNOT_IMPLEMENT_MALFORMED,
  CANNOT_INSTANTIATE_ENUM,
  CANNOT_INSTANTIATE_TYPE_VARIABLE,
  CANNOT_INSTANTIATE_TYPEDEF,
  CANNOT_MIXIN,
  CANNOT_MIXIN_ENUM,
  CANNOT_MIXIN_MALFORMED,
  CANNOT_OVERRIDE_FIELD_WITH_METHOD,
  CANNOT_OVERRIDE_FIELD_WITH_METHOD_CONT,
  CANNOT_OVERRIDE_GETTER_WITH_METHOD,
  CANNOT_OVERRIDE_GETTER_WITH_METHOD_CONT,
  CANNOT_OVERRIDE_METHOD_WITH_FIELD,
  CANNOT_OVERRIDE_METHOD_WITH_FIELD_CONT,
  CANNOT_OVERRIDE_METHOD_WITH_GETTER,
  CANNOT_OVERRIDE_METHOD_WITH_GETTER_CONT,
  CANNOT_RESOLVE,
  CANNOT_RESOLVE_AWAIT,
  CANNOT_RESOLVE_AWAIT_IN_CLOSURE,
  CANNOT_RESOLVE_CONSTRUCTOR,
  CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT,
  UNDEFINED_STATIC_GETTER_BUT_SETTER,
  CANNOT_RESOLVE_IN_INITIALIZER,
  UNDEFINED_STATIC_SETTER_BUT_GETTER,
  CANNOT_RESOLVE_TYPE,
  RETURN_IN_GENERATIVE_CONSTRUCTOR,
  CLASS_NAME_EXPECTED,
  COMPILER_CRASHED,
  COMPLEX_RETURNING_NSM,
  COMPLEX_THROWING_NSM,
  CONSIDER_ANALYZE_ALL,
  CONST_CALLS_NON_CONST,
  CONST_CALLS_NON_CONST_FOR_IMPLICIT,
  CONST_CONSTRUCTOR_WITH_BODY,
  CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS,
  CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_CONSTRUCTOR,
  CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_FIELD,
  CONST_FACTORY,
  CONST_LOOP_VARIABLE,
  CONST_MAP_KEY_OVERRIDES_EQUALS,
  CONST_WITHOUT_INITIALIZER,
  CONSTRUCTOR_CALL_EXPECTED,
  CONSTRUCTOR_IS_NOT_CONST,
  CONSTRUCTOR_WITH_RETURN_TYPE,
  CYCLIC_CLASS_HIERARCHY,
  CYCLIC_COMPILE_TIME_CONSTANTS,
  CYCLIC_REDIRECTING_FACTORY,
  CYCLIC_TYPE_VARIABLE,
  CYCLIC_TYPEDEF,
  CYCLIC_TYPEDEF_ONE,
  DART_EXT_NOT_SUPPORTED,
  DEFERRED_COMPILE_TIME_CONSTANT,
  DEFERRED_COMPILE_TIME_CONSTANT_CONSTRUCTION,
  DEFERRED_LIBRARY_DART_2_DART,
  DEFERRED_LIBRARY_DUPLICATE_PREFIX,
  DEFERRED_LIBRARY_WITHOUT_PREFIX,
  DEFERRED_OLD_SYNTAX,
  DEFERRED_TYPE_ANNOTATION,
  DIRECTLY_THROWING_NSM,
  DISALLOWED_LIBRARY_IMPORT,
  DUPLICATE_DEFINITION,
  DUPLICATE_EXPORT,
  DUPLICATE_EXPORT_CONT,
  DUPLICATE_EXPORT_DECL,
  DUPLICATE_EXTENDS_IMPLEMENTS,
  DUPLICATE_IMPLEMENTS,
  DUPLICATE_IMPORT,
  DUPLICATE_INITIALIZER,
  DUPLICATE_LABEL,
  DUPLICATE_SERIALIZED_LIBRARY,
  DUPLICATE_SUPER_INITIALIZER,
  DUPLICATE_TYPE_VARIABLE_NAME,
  DUPLICATED_LIBRARY_NAME,
  DUPLICATED_LIBRARY_RESOURCE,
  DUPLICATED_PART_OF,
  DUPLICATED_RESOURCE,
  EMPTY_CATCH_DECLARATION,
  EMPTY_ENUM_DECLARATION,
  EMPTY_NAMED_PARAMETER_LIST,
  EMPTY_OPTIONAL_PARAMETER_LIST,
  EMPTY_HIDE,
  EMPTY_SHOW,
  EQUAL_MAP_ENTRY_KEY,
  EXISTING_DEFINITION,
  EXISTING_LABEL,
  EXPECTED_IDENTIFIER_NOT_RESERVED_WORD,
  EXPONENT_MISSING,
  EXPORT_BEFORE_PARTS,
  EXTERNAL_WITH_BODY,
  EXTRA_CATCH_DECLARATION,
  EXTRA_FORMALS,
  EXTRANEOUS_MODIFIER,
  EXTRANEOUS_MODIFIER_REPLACE,
  FACTORY_REDIRECTION_IN_NON_FACTORY,
  FINAL_FUNCTION_TYPE_PARAMETER,
  FINAL_WITHOUT_INITIALIZER,
  FORIN_NOT_ASSIGNABLE,
  FORMAL_DECLARED_CONST,
  FORMAL_DECLARED_STATIC,
  FROM_ENVIRONMENT_MUST_BE_CONST,
  FUNCTION_TYPE_FORMAL_WITH_DEFAULT,
  FUNCTION_WITH_INITIALIZER,
  GENERIC,
  GETTER_MISMATCH,
  UNDEFINED_INSTANCE_GETTER_BUT_SETTER,
  HEX_DIGIT_EXPECTED,
  HIDDEN_HINTS,
  HIDDEN_IMPLICIT_IMPORT,
  HIDDEN_IMPORT,
  HIDDEN_WARNINGS,
  HIDDEN_WARNINGS_HINTS,
  IF_NULL_ASSIGNING_TYPE,
  ILLEGAL_CONST_FIELD_MODIFIER,
  ILLEGAL_CONSTRUCTOR_MODIFIERS,
  ILLEGAL_FINAL_METHOD_MODIFIER,
  ILLEGAL_MIXIN_APPLICATION_MODIFIERS,
  ILLEGAL_MIXIN_CONSTRUCTOR,
  ILLEGAL_MIXIN_CYCLE,
  ILLEGAL_MIXIN_OBJECT,
  ILLEGAL_MIXIN_SUPER_USE,
  ILLEGAL_MIXIN_SUPERCLASS,
  ILLEGAL_MIXIN_WITH_SUPER,
  ILLEGAL_SETTER_FORMALS,
  ILLEGAL_STATIC,
  ILLEGAL_SUPER_SEND,
  IMPORT_BEFORE_PARTS,
  IMPORT_EXPERIMENTAL_MIRRORS,
  IMPORT_PART_OF,
  IMPORT_PART_OF_HERE,
  IMPORTED_HERE,
  INHERIT_GETTER_AND_METHOD,
  INHERITED_EXPLICIT_GETTER,
  INHERITED_IMPLICIT_GETTER,
  INHERITED_METHOD,
  INJECTED_PUBLIC_MEMBER,
  INIT_STATIC_FIELD,
  INITIALIZING_FORMAL_NOT_ALLOWED,
  INSTANCE_STATIC_SAME_NAME,
  INSTANCE_STATIC_SAME_NAME_CONT,
  INTERNAL_LIBRARY,
  INTERNAL_LIBRARY_FROM,
  INVALID_ARGUMENT_AFTER_NAMED,
  INVALID_AWAIT,
  INVALID_AWAIT_FOR,
  INVALID_AWAIT_FOR_IN,
  INVALID_BREAK,
  INVALID_CASE_DEFAULT,
  INVALID_CONSTRUCTOR_ARGUMENTS,
  INVALID_CONSTRUCTOR_NAME,
  INVALID_CONTINUE,
  INVALID_FOR_IN,
  INVALID_INITIALIZER,
  INVALID_METADATA,
  INVALID_METADATA_GENERIC,
  INVALID_OVERRIDDEN_FIELD,
  INVALID_OVERRIDDEN_GETTER,
  INVALID_OVERRIDDEN_METHOD,
  INVALID_OVERRIDDEN_SETTER,
  INVALID_OVERRIDE_FIELD,
  INVALID_OVERRIDE_FIELD_WITH_GETTER,
  INVALID_OVERRIDE_FIELD_WITH_SETTER,
  INVALID_OVERRIDE_GETTER,
  INVALID_OVERRIDE_GETTER_WITH_FIELD,
  INVALID_OVERRIDE_METHOD,
  INVALID_OVERRIDE_SETTER,
  INVALID_OVERRIDE_SETTER_WITH_FIELD,
  INVALID_PACKAGE_CONFIG,
  INVALID_PACKAGE_URI,
  INVALID_PARAMETER,
  INVALID_RECEIVER_IN_INITIALIZER,
  INVALID_SOURCE_FILE_LOCATION,
  INVALID_SYMBOL,
  INVALID_INLINE_FUNCTION_TYPE,
  INVALID_SYNC_MODIFIER,
  INVALID_TYPE_VARIABLE_BOUND,
  INVALID_UNNAMED_CONSTRUCTOR_NAME,
  INVALID_URI,
  INVALID_USE_OF_SUPER,
  INVALID_YIELD,
  JS_INTEROP_CLASS_CANNOT_EXTEND_DART_CLASS,
  JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER,
  JS_INTEROP_INDEX_NOT_SUPPORTED,
  JS_INTEROP_METHOD_WITH_NAMED_ARGUMENTS,
  JS_OBJECT_LITERAL_CONSTRUCTOR_WITH_POSITIONAL_ARGUMENTS,
  JS_PLACEHOLDER_CAPTURE,
  LIBRARY_NAME_MISMATCH,
  LIBRARY_NOT_FOUND,
  LIBRARY_NOT_SUPPORTED,
  LIBRARY_TAG_MUST_BE_FIRST,
  LIBRARY_URI_MISMATCH,
  MAIN_HAS_PART_OF,
  MAIN_NOT_A_FUNCTION,
  MAIN_WITH_EXTRA_PARAMETER,
  MALFORMED_STRING_LITERAL,
  UNDEFINED_GETTER,
  MEMBER_NOT_STATIC,
  MEMBER_USES_CLASS_NAME,
  UNDEFINED_METHOD,
  MINUS_OPERATOR_BAD_ARITY,
  MIRROR_BLOAT,
  MIRROR_IMPORT,
  MIRROR_IMPORT_NO_USAGE,
  MIRRORS_CANNOT_FIND_IN_ELEMENT,
  MIRRORS_CANNOT_RESOLVE_IN_CURRENT_LIBRARY,
  MIRRORS_CANNOT_RESOLVE_IN_LIBRARY,
  MIRRORS_EXPECTED_STRING,
  MIRRORS_EXPECTED_STRING_OR_LIST,
  MIRRORS_EXPECTED_STRING_OR_TYPE,
  MIRRORS_EXPECTED_STRING_TYPE_OR_LIST,
  MIRRORS_LIBRARY_NOT_SUPPORT_BY_BACKEND,
  MISSING_ARGUMENT,
  MISSING_ENUM_CASES,
  MISSING_FACTORY_KEYWORD,
  MISSING_FORMALS,
  MISSING_LIBRARY_NAME,
  MISSING_MAIN,
  MISSING_PART_OF_TAG,
  MISSING_TOKEN_AFTER_THIS,
  MISSING_TOKEN_BEFORE_THIS,
  MISSING_TYPE_ARGUMENT,
  MULTI_INHERITANCE,
  NAMED_ARGUMENT_NOT_FOUND,
  NAMED_FUNCTION_EXPRESSION,
  NATIVE_NOT_SUPPORTED,
  NO_BREAK_TARGET,
  NO_CATCH_NOR_FINALLY,
  NO_COMMON_SUBTYPES,
  NO_CONTINUE_TARGET,
  NO_INSTANCE_AVAILABLE,
  NO_MATCHING_CONSTRUCTOR,
  NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT,
  NO_STATIC_OVERRIDE,
  NO_STATIC_OVERRIDE_CONT,
  NO_SUCH_LIBRARY_MEMBER,
  NO_SUCH_METHOD_IN_NATIVE,
  NO_SUCH_SUPER_MEMBER,
  NO_SUPER_IN_STATIC,
  NO_THIS_AVAILABLE,
  NON_CONST_BLOAT,
  NOT_A_COMPILE_TIME_CONSTANT,
  NOT_A_FIELD,
  NOT_A_PREFIX,
  NOT_A_TYPE,
  NOT_ASSIGNABLE,
  NOT_CALLABLE,
  NOT_INSTANCE_FIELD,
  NOT_MORE_SPECIFIC,
  NOT_MORE_SPECIFIC_SUBTYPE,
  NOT_MORE_SPECIFIC_SUGGESTION,
  NULL_NOT_ALLOWED,
  ONLY_ONE_LIBRARY_TAG,
  OPERATOR_NAMED_PARAMETERS,
  UNDEFINED_OPERATOR,
  OPERATOR_OPTIONAL_PARAMETERS,
  OPTIONAL_PARAMETER_IN_CATCH,
  OVERRIDE_EQUALS_NOT_HASH_CODE,
  PARAMETER_NAME_EXPECTED,
  PARAMETER_WITH_MODIFIER_IN_CATCH,
  PARAMETER_WITH_TYPE_IN_CATCH,
  PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION,
  PATCH_NO_GETTER,
  PATCH_NO_SETTER,
  PATCH_NON_CLASS,
  PATCH_NON_CONSTRUCTOR,
  PATCH_NON_EXISTING,
  PATCH_NON_EXTERNAL,
  PATCH_NON_FUNCTION,
  PATCH_NON_GETTER,
  PATCH_NON_SETTER,
  PATCH_NONPATCHABLE,
  PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH,
  PATCH_OPTIONAL_PARAMETER_NAMED_MISMATCH,
  PATCH_PARAMETER_MISMATCH,
  PATCH_PARAMETER_TYPE_MISMATCH,
  PATCH_POINT_TO_CLASS,
  PATCH_POINT_TO_CONSTRUCTOR,
  PATCH_POINT_TO_FUNCTION,
  PATCH_POINT_TO_GETTER,
  PATCH_POINT_TO_PARAMETER,
  PATCH_POINT_TO_SETTER,
  PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH,
  PATCH_RETURN_TYPE_MISMATCH,
  PATCH_TYPE_VARIABLES_MISMATCH,
  PLEASE_REPORT_THE_CRASH,
  POSITIONAL_PARAMETER_WITH_EQUALS,
  POTENTIAL_MUTATION,
  POTENTIAL_MUTATION_HERE,
  POTENTIAL_MUTATION_IN_CLOSURE,
  POTENTIAL_MUTATION_IN_CLOSURE_HERE,
  PREAMBLE,
  PREFIX_AS_EXPRESSION,
  PRIVATE_ACCESS,
  PRIVATE_IDENTIFIER,
  PRIVATE_NAMED_PARAMETER,
  READ_URI_ERROR,
  READ_SELF_ERROR,
  REDIRECTING_CONSTRUCTOR_CYCLE,
  REDIRECTING_CONSTRUCTOR_HAS_BODY,
  REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER,
  REDIRECTING_FACTORY_WITH_DEFAULT,
  REFERENCE_IN_INITIALIZATION,
  REQUIRED_PARAMETER_WITH_DEFAULT,
  RETURN_IN_GENERATOR,
  RETURN_NOTHING,
  RETURN_VALUE_IN_VOID,
  SETTER_MISMATCH,
  UNDEFINED_SETTER,
  UNDEFINED_SUPER_SETTER,
  STATIC_FUNCTION_BLOAT,
  STRING_EXPECTED,
  SUPER_CALL_TO_FACTORY,
  SUPER_INITIALIZER_IN_OBJECT,
  SWITCH_CASE_FORBIDDEN,
  SWITCH_CASE_TYPES_NOT_EQUAL,
  SWITCH_CASE_TYPES_NOT_EQUAL_CASE,
  SWITCH_CASE_VALUE_OVERRIDES_EQUALS,
  TERNARY_OPERATOR_BAD_ARITY,
  THIS_CALL_TO_FACTORY,
  THIS_IS_THE_DECLARATION,
  THIS_IS_THE_METHOD,
  THIS_IS_THE_PART_OF_TAG,
  THIS_PROPERTY,
  RETHROW_OUTSIDE_CATCH,
  TOP_LEVEL_VARIABLE_DECLARED_STATIC,
  TYPE_ARGUMENT_COUNT_MISMATCH,
  TYPE_VARIABLE_IN_CONSTANT,
  TYPE_VARIABLE_WITHIN_STATIC_MEMBER,
  TYPE_VARIABLE_FROM_METHOD_NOT_REIFIED,
  TYPE_VARIABLE_FROM_METHOD_CONSIDERED_DYNAMIC,
  TYPEDEF_FORMAL_WITH_DEFAULT,
  UNARY_OPERATOR_BAD_ARITY,
  UNBOUND_LABEL,
  UNIMPLEMENTED_EXPLICIT_GETTER,
  UNIMPLEMENTED_EXPLICIT_SETTER,
  UNIMPLEMENTED_GETTER,
  UNIMPLEMENTED_GETTER_ONE,
  UNIMPLEMENTED_IMPLICIT_GETTER,
  UNIMPLEMENTED_IMPLICIT_SETTER,
  UNIMPLEMENTED_METHOD,
  UNIMPLEMENTED_METHOD_CONT,
  UNIMPLEMENTED_METHOD_ONE,
  UNIMPLEMENTED_SETTER,
  UNIMPLEMENTED_SETTER_ONE,
  UNMATCHED_TOKEN,
  UNRECOGNIZED_VERSION_OF_LOOKUP_MAP,
  UNSUPPORTED_BANG_EQ_EQ,
  UNSUPPORTED_EQ_EQ_EQ,
  UNSUPPORTED_LITERAL_SYMBOL,
  UNSUPPORTED_PREFIX_PLUS,
  MISSING_EXPRESSION_IN_THROW,
  UNTERMINATED_COMMENT,
  UNTERMINATED_STRING,
  UNTERMINATED_TOKEN,
  UNUSED_CLASS,
  UNUSED_LABEL,
  UNUSED_METHOD,
  UNUSED_TYPEDEF,
  VAR_FUNCTION_TYPE_PARAMETER,
  VOID_EXPRESSION,
  VOID_NOT_ALLOWED,
  VOID_VARIABLE,
  WRONG_ARGUMENT_FOR_JS,
  WRONG_ARGUMENT_FOR_JS_FIRST,
  WRONG_ARGUMENT_FOR_JS_SECOND,
  WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT,
  WRONG_NUMBER_OF_ARGUMENTS_FOR_ASSERT,
  YIELDING_MODIFIER_ON_ARROW_BODY,
}

/// A message template for an error, warning, hint or info message generated
/// by the compiler. Each template is associated with a [MessageKind] that
/// uniquely identifies the message template.
// TODO(johnniwinther): For Infos, consider adding a reference to the
// error/warning/hint that they belong to.
class MessageTemplate {
  final MessageKind kind;

  /// Should describe what is wrong and why.
  final String template;

  /// Should describe how to fix the problem. Elided when using --terse option.
  final String howToFix;

  /**
   *  Examples will be checked by
   *  tests/compiler/dart2js/message_kind_test.dart.
   *
   *  An example is either a String containing the example source code or a Map
   *  from filenames to source code. In the latter case, the filename for the
   *  main library code must be 'main.dart'.
   */
  final List examples;

  /// Additional options needed for the examples to work.
  final List<String> options;

  const MessageTemplate(this.kind, this.template,
      {this.howToFix, this.examples, this.options: const <String>[]});

  /// All templates used by the compiler.
  ///
  /// The map is complete mapping from [MessageKind] to their corresponding
  /// [MessageTemplate].
  // The key type is a union of MessageKind and SharedMessageKind.
  static final Map<dynamic, MessageTemplate> TEMPLATES = <dynamic,
      MessageTemplate>{}
    ..addAll(shared_messages.TEMPLATES)
    ..addAll(const <MessageKind, MessageTemplate>{
      /// Do not use this. It is here for legacy and debugging. It violates item
      /// 4 of the guide lines for error messages in the beginning of the file.
      MessageKind.GENERIC:
          const MessageTemplate(MessageKind.GENERIC, '#{text}'),

      MessageKind.VOID_EXPRESSION: const MessageTemplate(
          MessageKind.VOID_EXPRESSION, "Expression does not yield a value."),

      MessageKind.VOID_VARIABLE: const MessageTemplate(
          MessageKind.VOID_VARIABLE, "Variable cannot be of type void."),

      MessageKind.RETURN_VALUE_IN_VOID: const MessageTemplate(
          MessageKind.RETURN_VALUE_IN_VOID,
          "Cannot return value from void function."),

      MessageKind.RETURN_NOTHING: const MessageTemplate(
          MessageKind.RETURN_NOTHING,
          "Value of type '#{returnType}' expected."),

      MessageKind.MISSING_ARGUMENT: const MessageTemplate(
          MessageKind.MISSING_ARGUMENT,
          "Missing argument of type '#{argumentType}'."),

      MessageKind.ADDITIONAL_ARGUMENT: const MessageTemplate(
          MessageKind.ADDITIONAL_ARGUMENT, "Additional argument."),

      MessageKind.NAMED_ARGUMENT_NOT_FOUND: const MessageTemplate(
          MessageKind.NAMED_ARGUMENT_NOT_FOUND,
          "No named argument '#{argumentName}' found on method."),

      MessageKind.AWAIT_MEMBER_NOT_FOUND: const MessageTemplate(
          MessageKind.AWAIT_MEMBER_NOT_FOUND,
          "No member named 'await' in class '#{className}'.",
          howToFix: "Did you mean to add the 'async' marker "
              "to '#{functionName}'?",
          examples: const [
            """
class A {
  m() => await -3;
}
main() => new A().m();
"""
          ]),

      MessageKind.AWAIT_MEMBER_NOT_FOUND_IN_CLOSURE: const MessageTemplate(
          MessageKind.AWAIT_MEMBER_NOT_FOUND_IN_CLOSURE,
          "No member named 'await' in class '#{className}'.",
          howToFix: "Did you mean to add the 'async' marker "
              "to the enclosing function?",
          examples: const [
            """
class A {
  m() => () => await -3;
}
main() => new A().m();
"""
          ]),

      MessageKind.NOT_CALLABLE: const MessageTemplate(
          MessageKind.NOT_CALLABLE, "'#{elementName}' is not callable."),

      MessageKind.MEMBER_NOT_STATIC: const MessageTemplate(
          MessageKind.MEMBER_NOT_STATIC,
          "'#{className}.#{memberName}' is not static."),

      MessageKind.NO_INSTANCE_AVAILABLE: const MessageTemplate(
          MessageKind.NO_INSTANCE_AVAILABLE,
          "'#{name}' is only available in instance methods."),

      MessageKind.NO_THIS_AVAILABLE: const MessageTemplate(
          MessageKind.NO_THIS_AVAILABLE,
          "'this' is only available in instance methods."),

      MessageKind.PRIVATE_ACCESS: const MessageTemplate(
          MessageKind.PRIVATE_ACCESS,
          "'#{name}' is declared private within library "
          "'#{libraryName}'."),

      MessageKind.THIS_IS_THE_DECLARATION: const MessageTemplate(
          MessageKind.THIS_IS_THE_DECLARATION,
          "This is the declaration of '#{name}'."),

      MessageKind.THIS_IS_THE_METHOD: const MessageTemplate(
          MessageKind.THIS_IS_THE_METHOD, "This is the method declaration."),

      MessageKind.CANNOT_RESOLVE: const MessageTemplate(
          MessageKind.CANNOT_RESOLVE, "Cannot resolve '#{name}'."),

      MessageKind.CANNOT_RESOLVE_AWAIT: const MessageTemplate(
          MessageKind.CANNOT_RESOLVE_AWAIT, "Cannot resolve '#{name}'.",
          howToFix: "Did you mean to add the 'async' marker "
              "to '#{functionName}'?",
          examples: const [
            "main() => await -3;",
            "foo() => await -3; main() => foo();"
          ]),

      MessageKind.CANNOT_RESOLVE_AWAIT_IN_CLOSURE: const MessageTemplate(
          MessageKind.CANNOT_RESOLVE_AWAIT_IN_CLOSURE,
          "Cannot resolve '#{name}'.",
          howToFix: "Did you mean to add the 'async' marker "
              "to the enclosing function?",
          examples: const [
            "main() { (() => await -3)(); }",
          ]),

      MessageKind.CANNOT_RESOLVE_IN_INITIALIZER: const MessageTemplate(
          MessageKind.CANNOT_RESOLVE_IN_INITIALIZER,
          "Cannot resolve '#{name}'. It would be implicitly looked up on this "
          "instance, but instances are not available in initializers.",
          howToFix: "Try correcting the unresolved reference or move the "
              "initialization to a constructor body.",
          examples: const [
            """
class A {
  var test = unresolvedName;
}
main() => new A();
"""
          ]),

      MessageKind.CANNOT_RESOLVE_CONSTRUCTOR: const MessageTemplate(
          MessageKind.CANNOT_RESOLVE_CONSTRUCTOR,
          "Cannot resolve constructor '#{constructorName}'."),

      MessageKind.CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT:
          const MessageTemplate(
              MessageKind.CANNOT_RESOLVE_CONSTRUCTOR_FOR_IMPLICIT,
              "cannot resolve constructor '#{constructorName}' "
              "for implicit super call.",
              howToFix:
                  "Try explicitly invoking a constructor of the super class",
              examples: const [
            """
class A {
  A.foo() {}
}
class B extends A {
  B();
}
main() => new B();
"""
          ]),

      MessageKind.INVALID_UNNAMED_CONSTRUCTOR_NAME: const MessageTemplate(
          MessageKind.INVALID_UNNAMED_CONSTRUCTOR_NAME,
          "Unnamed constructor name must be '#{name}'."),

      MessageKind.INVALID_CONSTRUCTOR_NAME: const MessageTemplate(
          MessageKind.INVALID_CONSTRUCTOR_NAME,
          "Constructor name must start with '#{name}'."),

      MessageKind.CANNOT_RESOLVE_TYPE: const MessageTemplate(
          MessageKind.CANNOT_RESOLVE_TYPE,
          "Cannot resolve type '#{typeName}'."),

      MessageKind.DUPLICATE_DEFINITION: const MessageTemplate(
          MessageKind.DUPLICATE_DEFINITION,
          "Duplicate definition of '#{name}'.",
          options: const ["--initializing-formal-access"],
          howToFix: "Try to rename or remove this definition.",
          examples: const [
            """
class C {
  void f() {}
  int get f => 1;
}

main() {
  new C();
}
""",
            """
class C {
  int x;
  C(this.x, int x);
}

main() {
  new C(4, 2);
}
""",
            """
class C {
  int x;
  C(int x, this.x);
}

main() {
  new C(4, 2);
}
""",
            """
class C {
  int x;
  C(this.x, this.x);
}

main() {
  new C(4, 2);
}
"""
          ]),

      MessageKind.EXISTING_DEFINITION: const MessageTemplate(
          MessageKind.EXISTING_DEFINITION, "Existing definition of '#{name}'."),

      MessageKind.DUPLICATE_IMPORT: const MessageTemplate(
          MessageKind.DUPLICATE_IMPORT, "Duplicate import of '#{name}'."),

      MessageKind.HIDDEN_IMPORT: const MessageTemplate(
          MessageKind.HIDDEN_IMPORT,
          "'#{name}' from library '#{hiddenUri}' is hidden by '#{name}' "
          "from library '#{hidingUri}'.",
          howToFix:
              "Try adding 'hide #{name}' to the import of '#{hiddenUri}'.",
          examples: const [
            const {
              'main.dart': """
import 'dart:async'; // This imports a class Future.
import 'future.dart';

void main() => new Future();""",
              'future.dart': """
library future;

class Future {}"""
            },
            const {
              'main.dart': """
import 'future.dart';
import 'dart:async'; // This imports a class Future.

void main() => new Future();""",
              'future.dart': """
library future;

class Future {}"""
            },
            const {
              'main.dart': """
import 'export.dart';
import 'dart:async'; // This imports a class Future.

void main() => new Future();""",
              'future.dart': """
library future;

class Future {}""",
              'export.dart': """
library export;

export 'future.dart';"""
            },
            const {
              'main.dart': """
import 'future.dart' as prefix;
import 'dart:async' as prefix; // This imports a class Future.

void main() => new prefix.Future();""",
              'future.dart': """
library future;

class Future {}"""
            }
          ]),

      MessageKind.HIDDEN_IMPLICIT_IMPORT: const MessageTemplate(
          MessageKind.HIDDEN_IMPLICIT_IMPORT,
          "'#{name}' from library '#{hiddenUri}' is hidden by '#{name}' "
          "from library '#{hidingUri}'.",
          howToFix: "Try adding an explicit "
              "'import \"#{hiddenUri}\" hide #{name}'.",
          examples: const [
            const {
              'main.dart': """
// This hides the implicit import of class Type from dart:core.
import 'type.dart';

void main() => new Type();""",
              'type.dart': """
library type;

class Type {}"""
            },
            const {
              'conflictsWithDart.dart': """
library conflictsWithDart;

class Duration {
  static var x = 100;
}
""",
              'conflictsWithDartAsWell.dart': """
library conflictsWithDartAsWell;

class Duration {
  static var x = 100;
}
""",
              'main.dart': r"""
library testDartConflicts;

import 'conflictsWithDart.dart';
import 'conflictsWithDartAsWell.dart';

main() {
  print("Hail Caesar ${Duration.x}");
}
"""
            }
          ]),

      MessageKind.DUPLICATE_EXPORT: const MessageTemplate(
          MessageKind.DUPLICATE_EXPORT, "Duplicate export of '#{name}'.",
          howToFix: "Try adding 'hide #{name}' to one of the exports.",
          examples: const [
            const {
              'main.dart': """
export 'decl1.dart';
export 'decl2.dart';

main() {}""",
              'decl1.dart': "class Class {}",
              'decl2.dart': "class Class {}"
            }
          ]),

      MessageKind.DUPLICATE_EXPORT_CONT: const MessageTemplate(
          MessageKind.DUPLICATE_EXPORT_CONT,
          "This is another export of '#{name}'."),

      MessageKind.DUPLICATE_EXPORT_DECL: const MessageTemplate(
          MessageKind.DUPLICATE_EXPORT_DECL,
          "The exported '#{name}' from export #{uriString} is defined here."),

      MessageKind.EMPTY_HIDE: const MessageTemplate(MessageKind.EMPTY_HIDE,
          "Library '#{uri}' doesn't export a '#{name}' declaration.",
          howToFix: "Try removing '#{name}' the 'hide' clause.",
          examples: const [
            const {
              'main.dart': """
import 'dart:core' hide Foo;

main() {}"""
            },
            const {
              'main.dart': """
export 'dart:core' hide Foo;

main() {}"""
            },
          ]),

      MessageKind.EMPTY_SHOW: const MessageTemplate(MessageKind.EMPTY_SHOW,
          "Library '#{uri}' doesn't export a '#{name}' declaration.",
          howToFix: "Try removing '#{name}' from the 'show' clause.",
          examples: const [
            const {
              'main.dart': """
import 'dart:core' show Foo;

main() {}"""
            },
            const {
              'main.dart': """
export 'dart:core' show Foo;

main() {}"""
            },
          ]),

      MessageKind.EMPTY_OPTIONAL_PARAMETER_LIST: const MessageTemplate(
          MessageKind.EMPTY_OPTIONAL_PARAMETER_LIST,
          "Optional parameter lists cannot be empty.",
          howToFix: "Try adding an optional parameter to the list.",
          examples: const [
            const {
              'main.dart': """
foo([]) {}

main() {
  foo();
}"""
            }
          ]),

      MessageKind.EMPTY_NAMED_PARAMETER_LIST: const MessageTemplate(
          MessageKind.EMPTY_NAMED_PARAMETER_LIST,
          "Named parameter lists cannot be empty.",
          howToFix: "Try adding a named parameter to the list.",
          examples: const [
            const {
              'main.dart': """
foo({}) {}

main() {
  foo();
}"""
            }
          ]),

      MessageKind.NOT_A_TYPE: const MessageTemplate(
          MessageKind.NOT_A_TYPE, "'#{node}' is not a type."),

      MessageKind.NOT_A_PREFIX: const MessageTemplate(
          MessageKind.NOT_A_PREFIX, "'#{node}' is not a prefix."),

      MessageKind.PREFIX_AS_EXPRESSION: const MessageTemplate(
          MessageKind.PREFIX_AS_EXPRESSION,
          "Library prefix '#{prefix}' is not a valid expression."),

      MessageKind.CANNOT_FIND_CONSTRUCTOR: const MessageTemplate(
          MessageKind.CANNOT_FIND_CONSTRUCTOR,
          "Cannot find constructor '#{constructorName}' in class "
          "'#{className}'."),

      MessageKind.CANNOT_FIND_UNNAMED_CONSTRUCTOR: const MessageTemplate(
          MessageKind.CANNOT_FIND_UNNAMED_CONSTRUCTOR,
          "Cannot find unnamed constructor in class "
          "'#{className}'."),

      MessageKind.CYCLIC_CLASS_HIERARCHY: const MessageTemplate(
          MessageKind.CYCLIC_CLASS_HIERARCHY,
          "'#{className}' creates a cycle in the class hierarchy."),

      MessageKind.CYCLIC_REDIRECTING_FACTORY: const MessageTemplate(
          MessageKind.CYCLIC_REDIRECTING_FACTORY,
          'Redirecting factory leads to a cyclic redirection.'),

      MessageKind.INVALID_RECEIVER_IN_INITIALIZER: const MessageTemplate(
          MessageKind.INVALID_RECEIVER_IN_INITIALIZER,
          "Field initializer expected."),

      MessageKind.NO_SUPER_IN_STATIC: const MessageTemplate(
          MessageKind.NO_SUPER_IN_STATIC,
          "'super' is only available in instance methods."),

      MessageKind.DUPLICATE_INITIALIZER: const MessageTemplate(
          MessageKind.DUPLICATE_INITIALIZER,
          "Field '#{fieldName}' is initialized more than once."),

      MessageKind.ALREADY_INITIALIZED: const MessageTemplate(
          MessageKind.ALREADY_INITIALIZED,
          "'#{fieldName}' was already initialized here."),

      MessageKind.INIT_STATIC_FIELD: const MessageTemplate(
          MessageKind.INIT_STATIC_FIELD,
          "Cannot initialize static field '#{fieldName}'."),

      MessageKind.NOT_A_FIELD: const MessageTemplate(
          MessageKind.NOT_A_FIELD, "'#{fieldName}' is not a field."),

      MessageKind.CONSTRUCTOR_CALL_EXPECTED: const MessageTemplate(
          MessageKind.CONSTRUCTOR_CALL_EXPECTED,
          "only call to 'this' or 'super' constructor allowed."),

      MessageKind.INVALID_FOR_IN: const MessageTemplate(
          MessageKind.INVALID_FOR_IN, "Invalid for-in variable declaration."),

      MessageKind.INVALID_INITIALIZER: const MessageTemplate(
          MessageKind.INVALID_INITIALIZER, "Invalid initializer."),

      MessageKind.FUNCTION_WITH_INITIALIZER: const MessageTemplate(
          MessageKind.FUNCTION_WITH_INITIALIZER,
          "Only constructors can have initializers."),

      MessageKind.REDIRECTING_CONSTRUCTOR_CYCLE: const MessageTemplate(
          MessageKind.REDIRECTING_CONSTRUCTOR_CYCLE,
          "Cyclic constructor redirection."),

      MessageKind.REDIRECTING_CONSTRUCTOR_HAS_BODY: const MessageTemplate(
          MessageKind.REDIRECTING_CONSTRUCTOR_HAS_BODY,
          "Redirecting constructor can't have a body."),

      MessageKind.REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER:
          const MessageTemplate(
              MessageKind.REDIRECTING_CONSTRUCTOR_HAS_INITIALIZER,
              "Redirecting constructor cannot have other initializers."),

      MessageKind.SUPER_INITIALIZER_IN_OBJECT: const MessageTemplate(
          MessageKind.SUPER_INITIALIZER_IN_OBJECT,
          "'Object' cannot have a super initializer."),

      MessageKind.DUPLICATE_SUPER_INITIALIZER: const MessageTemplate(
          MessageKind.DUPLICATE_SUPER_INITIALIZER,
          "Cannot have more than one super initializer."),

      MessageKind.SUPER_CALL_TO_FACTORY: const MessageTemplate(
          MessageKind.SUPER_CALL_TO_FACTORY,
          "The target of the superinitializer must be a generative "
          "constructor.",
          howToFix: "Try calling another constructor on the superclass.",
          examples: const [
            """
class Super {
  factory Super() => null;
}
class Class extends Super {}
main() => new Class();
""",
            """
class Super {
  factory Super() => null;
}
class Class extends Super {
  Class();
}
main() => new Class();
""",
            """
class Super {
  factory Super() => null;
}
class Class extends Super {
  Class() : super();
}
main() => new Class();
""",
            """
class Super {
  factory Super.foo() => null;
}
class Class extends Super {
  Class() : super.foo();
}
main() => new Class();
"""
          ]),

      MessageKind.THIS_CALL_TO_FACTORY: const MessageTemplate(
          MessageKind.THIS_CALL_TO_FACTORY,
          "The target of the redirection clause must be a generative "
          "constructor",
          howToFix: "Try redirecting to another constructor.",
          examples: const [
            """
class Class {
  factory Class() => null;
  Class.foo() : this();
}
main() => new Class.foo();
""",
            """
class Class {
  factory Class.foo() => null;
  Class() : this.foo();
}
main() => new Class();
"""
          ]),

      MessageKind.INVALID_CONSTRUCTOR_ARGUMENTS: const MessageTemplate(
          MessageKind.INVALID_CONSTRUCTOR_ARGUMENTS,
          "Arguments do not match the expected parameters of constructor "
          "'#{constructorName}'."),

      MessageKind.NO_MATCHING_CONSTRUCTOR: const MessageTemplate(
          MessageKind.NO_MATCHING_CONSTRUCTOR,
          "'super' call arguments and constructor parameters do not match."),

      MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT: const MessageTemplate(
          MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT,
          "Implicit 'super' call arguments and constructor parameters "
          "do not match."),

      MessageKind.CONST_CALLS_NON_CONST: const MessageTemplate(
          MessageKind.CONST_CALLS_NON_CONST,
          "'const' constructor cannot call a non-const constructor."),

      MessageKind.CONST_CALLS_NON_CONST_FOR_IMPLICIT: const MessageTemplate(
          MessageKind.CONST_CALLS_NON_CONST_FOR_IMPLICIT,
          "'const' constructor cannot call a non-const constructor. "
          "This constructor has an implicit call to a "
          "super non-const constructor.",
          howToFix: "Try making the super constructor const.",
          examples: const [
            """
class C {
  C(); // missing const
}
class D extends C {
  final d;
  const D(this.d);
}
main() => new D(0);"""
          ]),

      MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS: const MessageTemplate(
          MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS,
          "Can't declare constructor 'const' on class #{className} "
          "because the class contains non-final instance fields.",
          howToFix: "Try making all fields final.",
          examples: const [
            """
class C {
  // 'a' must be declared final to allow for the const constructor.
  var a;
  const C(this.a);
}

main() => new C(0);"""
          ]),

      MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_FIELD:
          const MessageTemplate(
              MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_FIELD,
              "This non-final field prevents using const constructors."),

      MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_CONSTRUCTOR:
          const MessageTemplate(
              MessageKind.CONST_CONSTRUCTOR_WITH_NONFINAL_FIELDS_CONSTRUCTOR,
              "This const constructor is not allowed due to "
              "non-final fields."),

      MessageKind.FROM_ENVIRONMENT_MUST_BE_CONST: const MessageTemplate(
          MessageKind.FROM_ENVIRONMENT_MUST_BE_CONST,
          "#{className}.fromEnvironment can only be used as a "
          "const constructor.",
          howToFix: "Try replacing `new` with `const`.",
          examples: const ["main() { new bool.fromEnvironment('X'); }"]),

      MessageKind.INITIALIZING_FORMAL_NOT_ALLOWED: const MessageTemplate(
          MessageKind.INITIALIZING_FORMAL_NOT_ALLOWED,
          "Initializing formal parameter only allowed in generative "
          "constructor."),

      MessageKind.INVALID_PARAMETER: const MessageTemplate(
          MessageKind.INVALID_PARAMETER, "Cannot resolve parameter."),

      MessageKind.NOT_INSTANCE_FIELD: const MessageTemplate(
          MessageKind.NOT_INSTANCE_FIELD,
          "'#{fieldName}' is not an instance field."),

      MessageKind.THIS_PROPERTY: const MessageTemplate(
          MessageKind.THIS_PROPERTY, "Expected an identifier."),

      MessageKind.NO_CATCH_NOR_FINALLY: const MessageTemplate(
          MessageKind.NO_CATCH_NOR_FINALLY, "Expected 'catch' or 'finally'."),

      MessageKind.EMPTY_CATCH_DECLARATION: const MessageTemplate(
          MessageKind.EMPTY_CATCH_DECLARATION,
          "Expected an identifier in catch declaration."),

      MessageKind.EXTRA_CATCH_DECLARATION: const MessageTemplate(
          MessageKind.EXTRA_CATCH_DECLARATION,
          "Extra parameter in catch declaration."),

      MessageKind.PARAMETER_WITH_TYPE_IN_CATCH: const MessageTemplate(
          MessageKind.PARAMETER_WITH_TYPE_IN_CATCH,
          "Cannot use type annotations in catch."),

      MessageKind.PARAMETER_WITH_MODIFIER_IN_CATCH: const MessageTemplate(
          MessageKind.PARAMETER_WITH_MODIFIER_IN_CATCH,
          "Cannot use modifiers in catch."),

      MessageKind.OPTIONAL_PARAMETER_IN_CATCH: const MessageTemplate(
          MessageKind.OPTIONAL_PARAMETER_IN_CATCH,
          "Cannot use optional parameters in catch."),

      MessageKind.UNBOUND_LABEL: const MessageTemplate(
          MessageKind.UNBOUND_LABEL, "Cannot resolve label '#{labelName}'."),

      MessageKind.NO_BREAK_TARGET: const MessageTemplate(
          MessageKind.NO_BREAK_TARGET,
          "'break' statement not inside switch or loop."),

      MessageKind.NO_CONTINUE_TARGET: const MessageTemplate(
          MessageKind.NO_CONTINUE_TARGET,
          "'continue' statement not inside loop."),

      MessageKind.EXISTING_LABEL: const MessageTemplate(
          MessageKind.EXISTING_LABEL,
          "Original declaration of duplicate label '#{labelName}'."),

      MessageKind.DUPLICATE_LABEL: const MessageTemplate(
          MessageKind.DUPLICATE_LABEL,
          "Duplicate declaration of label '#{labelName}'."),

      MessageKind.UNUSED_LABEL: const MessageTemplate(
          MessageKind.UNUSED_LABEL, "Unused label '#{labelName}'."),

      MessageKind.INVALID_CONTINUE: const MessageTemplate(
          MessageKind.INVALID_CONTINUE,
          "Target of continue is not a loop or switch case."),

      MessageKind.INVALID_BREAK: const MessageTemplate(
          MessageKind.INVALID_BREAK, "Target of break is not a statement."),

      MessageKind.DUPLICATE_TYPE_VARIABLE_NAME: const MessageTemplate(
          MessageKind.DUPLICATE_TYPE_VARIABLE_NAME,
          "Type variable '#{typeVariableName}' already declared."),

      MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER: const MessageTemplate(
          MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER,
          "Cannot refer to type variable '#{typeVariableName}' "
          "within a static member."),

      MessageKind.TYPE_VARIABLE_IN_CONSTANT: const MessageTemplate(
          MessageKind.TYPE_VARIABLE_IN_CONSTANT,
          "Constant expressions can't refer to type variables.",
          howToFix: "Try removing the type variable or replacing it with a "
              "concrete type.",
          examples: const [
            """
class C<T> {
  const C();

  m(T t) => const C<T>();
}

void main() => new C().m(null);
"""
          ]),

      MessageKind.TYPE_VARIABLE_FROM_METHOD_NOT_REIFIED: const MessageTemplate(
          MessageKind.TYPE_VARIABLE_FROM_METHOD_NOT_REIFIED,
          "Method type variables do not have a runtime value.",
          howToFix: "Try using the upper bound of the type variable, "
              "or refactor the code to avoid needing this runtime value.",
          examples: const [
            """
// Method type variables are not reified, so they cannot be returned.
Type f<T>() => T;

main() => f<int>();
""",
            """
// Method type variables are not reified, so they cannot be tested dynamically.
bool f<T>(Object o) => o is T;

main() => f<int>(42);
"""
          ]),

      MessageKind.TYPE_VARIABLE_FROM_METHOD_CONSIDERED_DYNAMIC:
          const MessageTemplate(
              MessageKind.TYPE_VARIABLE_FROM_METHOD_CONSIDERED_DYNAMIC,
              "Method type variables are treated as `dynamic` in `as` "
              "expressions.",
              howToFix:
                  "Try using the upper bound of the type variable, or check "
                  "that the blind success of the test does not introduce bugs.",
              examples: const [
            """
// Method type variables are not reified, so they cannot be tested dynamically.
bool f<T>(Object o) => o as T;

main() => f<int>(42);
"""
          ]),

      MessageKind.INVALID_TYPE_VARIABLE_BOUND: const MessageTemplate(
          MessageKind.INVALID_TYPE_VARIABLE_BOUND,
          "'#{typeArgument}' is not a subtype of bound '#{bound}' for "
          "type variable '#{typeVariable}' of type '#{thisType}'.",
          howToFix: "Try to change or remove the type argument.",
          examples: const [
            """
class C<T extends num> {}

// 'String' is not a valid instantiation of T with bound num.'.
main() => new C<String>();
"""
          ]),

      MessageKind.INVALID_USE_OF_SUPER: const MessageTemplate(
          MessageKind.INVALID_USE_OF_SUPER, "'super' not allowed here."),

      MessageKind.INVALID_CASE_DEFAULT: const MessageTemplate(
          MessageKind.INVALID_CASE_DEFAULT,
          "'default' only allowed on last case of a switch."),

      MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL: const MessageTemplate(
          MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL,
          "'case' expressions do not all have type '#{type}'."),

      MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL_CASE: const MessageTemplate(
          MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL_CASE,
          "'case' expression of type '#{type}'."),

      MessageKind.SWITCH_CASE_FORBIDDEN: const MessageTemplate(
          MessageKind.SWITCH_CASE_FORBIDDEN,
          "'case' expression may not be of type '#{type}'."),

      MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS: const MessageTemplate(
          MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS,
          "'case' expression type '#{type}' overrides 'operator =='."),

      MessageKind.INVALID_ARGUMENT_AFTER_NAMED: const MessageTemplate(
          MessageKind.INVALID_ARGUMENT_AFTER_NAMED,
          "Unnamed argument after named argument."),

      MessageKind.INVALID_AWAIT_FOR_IN: const MessageTemplate(
          MessageKind.INVALID_AWAIT_FOR_IN,
          "'await' is only supported in methods with an 'async' or "
          "'async*' body modifier.",
          howToFix: "Try adding 'async' or 'async*' to the method body or "
              "removing the 'await' keyword.",
          examples: const [
            """
main(o) sync* {
  await for (var e in o) {}
}"""
          ]),

      MessageKind.INVALID_AWAIT: const MessageTemplate(
          MessageKind.INVALID_AWAIT,
          "'await' is only supported in methods with an 'async' or "
          "'async*' body modifier.",
          howToFix: "Try adding 'async' or 'async*' to the method body.",
          examples: const [
            """
main(o) sync* {
  await null;
}"""
          ]),

      MessageKind.INVALID_YIELD: const MessageTemplate(
          MessageKind.INVALID_YIELD,
          "'yield' is only supported in methods with a 'sync*' or "
          "'async*' body modifier.",
          howToFix: "Try adding 'sync*' or 'async*' to the method body.",
          examples: const [
            """
main(o) async {
  yield 0;
}"""
          ]),

      MessageKind.NOT_A_COMPILE_TIME_CONSTANT: const MessageTemplate(
          MessageKind.NOT_A_COMPILE_TIME_CONSTANT,
          "Not a compile-time constant."),

      MessageKind.DEFERRED_COMPILE_TIME_CONSTANT: const MessageTemplate(
          MessageKind.DEFERRED_COMPILE_TIME_CONSTANT,
          "A deferred value cannot be used as a compile-time constant."),

      MessageKind.DEFERRED_COMPILE_TIME_CONSTANT_CONSTRUCTION:
          const MessageTemplate(
              MessageKind.DEFERRED_COMPILE_TIME_CONSTANT_CONSTRUCTION,
              "A deferred class cannot be used to create a "
              "compile-time constant."),

      MessageKind.CYCLIC_COMPILE_TIME_CONSTANTS: const MessageTemplate(
          MessageKind.CYCLIC_COMPILE_TIME_CONSTANTS,
          "Cycle in the compile-time constant computation."),

      MessageKind.CONSTRUCTOR_IS_NOT_CONST: const MessageTemplate(
          MessageKind.CONSTRUCTOR_IS_NOT_CONST,
          "Constructor is not a 'const' constructor."),

      MessageKind.CONST_MAP_KEY_OVERRIDES_EQUALS: const MessageTemplate(
          MessageKind.CONST_MAP_KEY_OVERRIDES_EQUALS,
          "Const-map key type '#{type}' overrides 'operator =='."),

      MessageKind.NO_SUCH_LIBRARY_MEMBER: const MessageTemplate(
          MessageKind.NO_SUCH_LIBRARY_MEMBER,
          "'#{libraryName}' has no member named '#{memberName}'."),

      MessageKind.CANNOT_INSTANTIATE_TYPEDEF: const MessageTemplate(
          MessageKind.CANNOT_INSTANTIATE_TYPEDEF,
          "Cannot instantiate typedef '#{typedefName}'."),

      MessageKind.REQUIRED_PARAMETER_WITH_DEFAULT: const MessageTemplate(
          MessageKind.REQUIRED_PARAMETER_WITH_DEFAULT,
          "Non-optional parameters can't have a default value.",
          howToFix:
              "Try removing the default value or making the parameter optional.",
          examples: const [
            """
main() {
  foo(a: 1) => print(a);
  foo(2);
}""",
            """
main() {
  foo(a = 1) => print(a);
  foo(2);
}"""
          ]),

      MessageKind.POSITIONAL_PARAMETER_WITH_EQUALS: const MessageTemplate(
          MessageKind.POSITIONAL_PARAMETER_WITH_EQUALS,
          "Positional optional parameters can't use ':' to specify a "
          "default value.",
          howToFix: "Try replacing ':' with '='.",
          examples: const [
            """
main() {
  foo([a: 1]) => print(a);
  foo(2);
}"""
          ]),

      MessageKind.TYPEDEF_FORMAL_WITH_DEFAULT: const MessageTemplate(
          MessageKind.TYPEDEF_FORMAL_WITH_DEFAULT,
          "A parameter of a typedef can't specify a default value.",
          howToFix: "Try removing the default value.",
          examples: const [
            """
typedef void F([int arg = 0]);

main() {
  F f;
}""",
            """
typedef void F({int arg: 0});

main() {
  F f;
}"""
          ]),

      MessageKind.FUNCTION_TYPE_FORMAL_WITH_DEFAULT: const MessageTemplate(
          MessageKind.FUNCTION_TYPE_FORMAL_WITH_DEFAULT,
          "A function type parameter can't specify a default value.",
          howToFix: "Try removing the default value.",
          examples: const [
            """
foo(f(int i, [a = 1])) {}

main() {
  foo(1, 2);
}""",
            """
foo(f(int i, {a: 1})) {}

main() {
  foo(1, a: 2);
}"""
          ]),

      MessageKind.REDIRECTING_FACTORY_WITH_DEFAULT: const MessageTemplate(
          MessageKind.REDIRECTING_FACTORY_WITH_DEFAULT,
          "A parameter of a redirecting factory constructor can't specify a "
          "default value.",
          howToFix: "Try removing the default value.",
          examples: const [
            """
class A {
  A([a]);
  factory A.foo([a = 1]) = A;
}

main() {
  new A.foo(1);
}""",
            """
class A {
  A({a});
  factory A.foo({a: 1}) = A;
}

main() {
  new A.foo(a: 1);
}"""
          ]),

      MessageKind.FORMAL_DECLARED_CONST: const MessageTemplate(
          MessageKind.FORMAL_DECLARED_CONST,
          "A formal parameter can't be declared const.",
          howToFix: "Try removing 'const'.",
          examples: const [
            """
foo(const x) {}
main() => foo(42);
""",
            """
foo({const x}) {}
main() => foo(42);
""",
            """
foo([const x]) {}
main() => foo(42);
"""
          ]),

      MessageKind.FORMAL_DECLARED_STATIC: const MessageTemplate(
          MessageKind.FORMAL_DECLARED_STATIC,
          "A formal parameter can't be declared static.",
          howToFix: "Try removing 'static'.",
          examples: const [
            """
foo(static x) {}
main() => foo(42);
""",
            """
foo({static x}) {}
main() => foo(42);
""",
            """
foo([static x]) {}
main() => foo(42);
"""
          ]),

      MessageKind.FINAL_FUNCTION_TYPE_PARAMETER: const MessageTemplate(
          MessageKind.FINAL_FUNCTION_TYPE_PARAMETER,
          "A function type parameter can't be declared final.",
          howToFix: "Try removing 'final'.",
          examples: const [
            """
foo(final int x(int a)) {}
main() => foo((y) => 42);
""",
            """
foo({final int x(int a)}) {}
main() => foo((y) => 42);
""",
            """
foo([final int x(int a)]) {}
main() => foo((y) => 42);
"""
          ]),

      MessageKind.VAR_FUNCTION_TYPE_PARAMETER: const MessageTemplate(
          MessageKind.VAR_FUNCTION_TYPE_PARAMETER,
          "A function type parameter can't be declared with 'var'.",
          howToFix: "Try removing 'var'.",
          examples: const [
            """
foo(var int x(int a)) {}
main() => foo((y) => 42);
""",
            """
foo({var int x(int a)}) {}
main() => foo((y) => 42);
""",
            """
foo([var int x(int a)]) {}
main() => foo((y) => 42);
"""
          ]),

      MessageKind.CANNOT_INSTANTIATE_TYPE_VARIABLE: const MessageTemplate(
          MessageKind.CANNOT_INSTANTIATE_TYPE_VARIABLE,
          "Cannot instantiate type variable '#{typeVariableName}'."),

      MessageKind.CYCLIC_TYPE_VARIABLE: const MessageTemplate(
          MessageKind.CYCLIC_TYPE_VARIABLE,
          "Type variable '#{typeVariableName}' is a supertype of itself."),

      MessageKind.CYCLIC_TYPEDEF: const MessageTemplate(
          MessageKind.CYCLIC_TYPEDEF, "A typedef can't refer to itself.",
          howToFix: "Try removing all references to '#{typedefName}' "
              "in the definition of '#{typedefName}'.",
          examples: const [
            """
typedef F F(); // The return type 'F' is a self-reference.
main() { F f = null; }"""
          ]),

      MessageKind.CYCLIC_TYPEDEF_ONE: const MessageTemplate(
          MessageKind.CYCLIC_TYPEDEF_ONE,
          "A typedef can't refer to itself through another typedef.",
          howToFix: "Try removing all references to "
              "'#{otherTypedefName}' in the definition of '#{typedefName}'.",
          examples: const [
            """
typedef G F(); // The return type 'G' is a self-reference through typedef 'G'.
typedef F G(); // The return type 'F' is a self-reference through typedef 'F'.
main() { F f = null; }""",
            """
typedef G F(); // The return type 'G' creates a self-reference.
typedef H G(); // The return type 'H' creates a self-reference.
typedef H(F f); // The argument type 'F' creates a self-reference.
main() { F f = null; }"""
          ]),

      MessageKind.CLASS_NAME_EXPECTED: const MessageTemplate(
          MessageKind.CLASS_NAME_EXPECTED, "Class name expected."),

      MessageKind.CANNOT_EXTEND: const MessageTemplate(
          MessageKind.CANNOT_EXTEND, "'#{type}' cannot be extended."),

      MessageKind.CANNOT_IMPLEMENT: const MessageTemplate(
          MessageKind.CANNOT_IMPLEMENT, "'#{type}' cannot be implemented."),

      // TODO(johnnwinther): Split messages into reasons for malformedness.
      MessageKind.CANNOT_EXTEND_MALFORMED: const MessageTemplate(
          MessageKind.CANNOT_EXTEND_MALFORMED,
          "Class '#{className}' can't extend the type '#{malformedType}' "
          "because it is malformed.",
          howToFix:
              "Try correcting the malformed type annotation or removing the "
              "'extends' clause.",
          examples: const [
            """
class A extends Malformed {}
main() => new A();"""
          ]),

      MessageKind.CANNOT_IMPLEMENT_MALFORMED: const MessageTemplate(
          MessageKind.CANNOT_IMPLEMENT_MALFORMED,
          "Class '#{className}' can't implement the type '#{malformedType}' "
          "because it is malformed.",
          howToFix:
              "Try correcting the malformed type annotation or removing the "
              "type from the 'implements' clause.",
          examples: const [
            """
class A implements Malformed {}
main() => new A();"""
          ]),

      MessageKind.CANNOT_MIXIN_MALFORMED: const MessageTemplate(
          MessageKind.CANNOT_MIXIN_MALFORMED,
          "Class '#{className}' can't mixin the type '#{malformedType}' "
          "because it is malformed.",
          howToFix:
              "Try correcting the malformed type annotation or removing the "
              "type from the 'with' clause.",
          examples: const [
            """
class A extends Object with Malformed {}
main() => new A();"""
          ]),

      MessageKind.CANNOT_MIXIN: const MessageTemplate(
          MessageKind.CANNOT_MIXIN, "The type '#{type}' can't be mixed in.",
          howToFix: "Try removing '#{type}' from the 'with' clause.",
          examples: const [
            """
class C extends Object with String {}

main() => new C();
""",
            """
class C = Object with String;

main() => new C();
"""
          ]),

      MessageKind.CANNOT_EXTEND_ENUM: const MessageTemplate(
          MessageKind.CANNOT_EXTEND_ENUM,
          "Class '#{className}' can't extend the type '#{enumType}' because "
          "it is declared by an enum.",
          howToFix: "Try making '#{enumType}' a normal class or removing the "
              "'extends' clause.",
          examples: const [
            """
enum Enum { A }
class B extends Enum {}
main() => new B();"""
          ]),

      MessageKind.CANNOT_IMPLEMENT_ENUM: const MessageTemplate(
          MessageKind.CANNOT_IMPLEMENT_ENUM,
          "Class '#{className}' can't implement the type '#{enumType}' "
          "because it is declared by an enum.",
          howToFix: "Try making '#{enumType}' a normal class or removing the "
              "type from the 'implements' clause.",
          examples: const [
            """
enum Enum { A }
class B implements Enum {}
main() => new B();"""
          ]),

      MessageKind.CANNOT_MIXIN_ENUM: const MessageTemplate(
          MessageKind.CANNOT_MIXIN_ENUM,
          "Class '#{className}' can't mixin the type '#{enumType}' because it "
          "is declared by an enum.",
          howToFix: "Try making '#{enumType}' a normal class or removing the "
              "type from the 'with' clause.",
          examples: const [
            """
enum Enum { A }
class B extends Object with Enum {}
main() => new B();"""
          ]),

      MessageKind.CANNOT_INSTANTIATE_ENUM: const MessageTemplate(
          MessageKind.CANNOT_INSTANTIATE_ENUM,
          "Enum type '#{enumName}' cannot be instantiated.",
          howToFix: "Try making '#{enumType}' a normal class or use an enum "
              "constant.",
          examples: const [
            """
enum Enum { A }
main() => new Enum(0);""",
            """
enum Enum { A }
main() => const Enum(0);"""
          ]),

      MessageKind.EMPTY_ENUM_DECLARATION: const MessageTemplate(
          MessageKind.EMPTY_ENUM_DECLARATION,
          "Enum '#{enumName}' must contain at least one value.",
          howToFix: "Try adding an enum constant or making #{enumName} a "
              "normal class.",
          examples: const [
            """
enum Enum {}
main() { Enum e; }"""
          ]),

      MessageKind.MISSING_ENUM_CASES: const MessageTemplate(
          MessageKind.MISSING_ENUM_CASES,
          "Missing enum constants in switch statement: #{enumValues}.",
          howToFix: "Try adding the missing constants or a default case.",
          examples: const [
            """
enum Enum { A, B }
main() {
  switch (Enum.A) {
  case Enum.B: break;
  }
}""",
            """
enum Enum { A, B, C }
main() {
  switch (Enum.A) {
  case Enum.B: break;
  }
}"""
          ]),

      MessageKind.DUPLICATE_EXTENDS_IMPLEMENTS: const MessageTemplate(
          MessageKind.DUPLICATE_EXTENDS_IMPLEMENTS,
          "'#{type}' can not be both extended and implemented."),

      MessageKind.DUPLICATE_IMPLEMENTS: const MessageTemplate(
          MessageKind.DUPLICATE_IMPLEMENTS,
          "'#{type}' must not occur more than once "
          "in the implements clause."),

      MessageKind.MULTI_INHERITANCE: const MessageTemplate(
          MessageKind.MULTI_INHERITANCE,
          "Dart2js does not currently support inheritance of the same class "
          "with different type arguments: Both #{firstType} and #{secondType} "
          "are supertypes of #{thisType}."),

      MessageKind.ILLEGAL_SUPER_SEND: const MessageTemplate(
          MessageKind.ILLEGAL_SUPER_SEND,
          "'#{name}' cannot be called on super."),

      MessageKind.ADDITIONAL_TYPE_ARGUMENT: const MessageTemplate(
          MessageKind.ADDITIONAL_TYPE_ARGUMENT, "Additional type argument."),

      MessageKind.MISSING_TYPE_ARGUMENT: const MessageTemplate(
          MessageKind.MISSING_TYPE_ARGUMENT, "Missing type argument."),

      // TODO(johnniwinther): Use ADDITIONAL_TYPE_ARGUMENT or
      // MISSING_TYPE_ARGUMENT instead.
      MessageKind.TYPE_ARGUMENT_COUNT_MISMATCH: const MessageTemplate(
          MessageKind.TYPE_ARGUMENT_COUNT_MISMATCH,
          "Incorrect number of type arguments on '#{type}'."),

      MessageKind.GETTER_MISMATCH: const MessageTemplate(
          MessageKind.GETTER_MISMATCH, "Setter disagrees on: '#{modifiers}'."),

      MessageKind.SETTER_MISMATCH: const MessageTemplate(
          MessageKind.SETTER_MISMATCH, "Getter disagrees on: '#{modifiers}'."),

      MessageKind.ILLEGAL_SETTER_FORMALS: const MessageTemplate(
          MessageKind.ILLEGAL_SETTER_FORMALS,
          "A setter must have exactly one argument."),

      MessageKind.NO_STATIC_OVERRIDE: const MessageTemplate(
          MessageKind.NO_STATIC_OVERRIDE,
          "Static member cannot override instance member '#{memberName}' of "
          "'#{className}'."),

      MessageKind.NO_STATIC_OVERRIDE_CONT: const MessageTemplate(
          MessageKind.NO_STATIC_OVERRIDE_CONT,
          "This is the instance member that cannot be overridden "
          "by a static member."),

      MessageKind.INSTANCE_STATIC_SAME_NAME: const MessageTemplate(
          MessageKind.INSTANCE_STATIC_SAME_NAME,
          "Instance member '#{memberName}' and static member of "
          "superclass '#{className}' have the same name."),

      MessageKind.INSTANCE_STATIC_SAME_NAME_CONT: const MessageTemplate(
          MessageKind.INSTANCE_STATIC_SAME_NAME_CONT,
          "This is the static member with the same name."),

      MessageKind.INVALID_OVERRIDE_METHOD: const MessageTemplate(
          MessageKind.INVALID_OVERRIDE_METHOD,
          "The type '#{declaredType}' of method '#{name}' declared in "
          "'#{class}' is not a subtype of the overridden method type "
          "'#{inheritedType}' inherited from '#{inheritedClass}'."),

      MessageKind.INVALID_OVERRIDDEN_METHOD: const MessageTemplate(
          MessageKind.INVALID_OVERRIDDEN_METHOD,
          "This is the overridden method '#{name}' declared in class "
          "'#{class}'."),

      MessageKind.INVALID_OVERRIDE_GETTER: const MessageTemplate(
          MessageKind.INVALID_OVERRIDE_GETTER,
          "The type '#{declaredType}' of getter '#{name}' declared in "
          "'#{class}' is not assignable to the type '#{inheritedType}' of the "
          "overridden getter inherited from '#{inheritedClass}'."),

      MessageKind.INVALID_OVERRIDDEN_GETTER: const MessageTemplate(
          MessageKind.INVALID_OVERRIDDEN_GETTER,
          "This is the overridden getter '#{name}' declared in class "
          "'#{class}'."),

      MessageKind.INVALID_OVERRIDE_GETTER_WITH_FIELD: const MessageTemplate(
          MessageKind.INVALID_OVERRIDE_GETTER_WITH_FIELD,
          "The type '#{declaredType}' of field '#{name}' declared in "
          "'#{class}' is not assignable to the type '#{inheritedType}' of the "
          "overridden getter inherited from '#{inheritedClass}'."),

      MessageKind.INVALID_OVERRIDE_FIELD_WITH_GETTER: const MessageTemplate(
          MessageKind.INVALID_OVERRIDE_FIELD_WITH_GETTER,
          "The type '#{declaredType}' of getter '#{name}' declared in "
          "'#{class}' is not assignable to the type '#{inheritedType}' of the "
          "overridden field inherited from '#{inheritedClass}'."),

      MessageKind.INVALID_OVERRIDE_SETTER: const MessageTemplate(
          MessageKind.INVALID_OVERRIDE_SETTER,
          "The type '#{declaredType}' of setter '#{name}' declared in "
          "'#{class}' is not assignable to the type '#{inheritedType}' of the "
          "overridden setter inherited from '#{inheritedClass}'."),

      MessageKind.INVALID_OVERRIDDEN_SETTER: const MessageTemplate(
          MessageKind.INVALID_OVERRIDDEN_SETTER,
          "This is the overridden setter '#{name}' declared in class "
          "'#{class}'."),

      MessageKind.INVALID_OVERRIDE_SETTER_WITH_FIELD: const MessageTemplate(
          MessageKind.INVALID_OVERRIDE_SETTER_WITH_FIELD,
          "The type '#{declaredType}' of field '#{name}' declared in "
          "'#{class}' is not assignable to the type '#{inheritedType}' of the "
          "overridden setter inherited from '#{inheritedClass}'."),

      MessageKind.INVALID_OVERRIDE_FIELD_WITH_SETTER: const MessageTemplate(
          MessageKind.INVALID_OVERRIDE_FIELD_WITH_SETTER,
          "The type '#{declaredType}' of setter '#{name}' declared in "
          "'#{class}' is not assignable to the type '#{inheritedType}' of the "
          "overridden field inherited from '#{inheritedClass}'."),

      MessageKind.INVALID_OVERRIDE_FIELD: const MessageTemplate(
          MessageKind.INVALID_OVERRIDE_FIELD,
          "The type '#{declaredType}' of field '#{name}' declared in "
          "'#{class}' is not assignable to the type '#{inheritedType}' of the "
          "overridden field inherited from '#{inheritedClass}'."),

      MessageKind.INVALID_OVERRIDDEN_FIELD: const MessageTemplate(
          MessageKind.INVALID_OVERRIDDEN_FIELD,
          "This is the overridden field '#{name}' declared in class "
          "'#{class}'."),

      MessageKind.CANNOT_OVERRIDE_FIELD_WITH_METHOD: const MessageTemplate(
          MessageKind.CANNOT_OVERRIDE_FIELD_WITH_METHOD,
          "Method '#{name}' in '#{class}' can't override field from "
          "'#{inheritedClass}'."),

      MessageKind.CANNOT_OVERRIDE_FIELD_WITH_METHOD_CONT: const MessageTemplate(
          MessageKind.CANNOT_OVERRIDE_FIELD_WITH_METHOD_CONT,
          "This is the field that cannot be overridden by a method."),

      MessageKind.CANNOT_OVERRIDE_METHOD_WITH_FIELD: const MessageTemplate(
          MessageKind.CANNOT_OVERRIDE_METHOD_WITH_FIELD,
          "Field '#{name}' in '#{class}' can't override method from "
          "'#{inheritedClass}'."),

      MessageKind.CANNOT_OVERRIDE_METHOD_WITH_FIELD_CONT: const MessageTemplate(
          MessageKind.CANNOT_OVERRIDE_METHOD_WITH_FIELD_CONT,
          "This is the method that cannot be overridden by a field."),

      MessageKind.CANNOT_OVERRIDE_GETTER_WITH_METHOD: const MessageTemplate(
          MessageKind.CANNOT_OVERRIDE_GETTER_WITH_METHOD,
          "Method '#{name}' in '#{class}' can't override getter from "
          "'#{inheritedClass}'."),

      MessageKind.CANNOT_OVERRIDE_GETTER_WITH_METHOD_CONT:
          const MessageTemplate(
              MessageKind.CANNOT_OVERRIDE_GETTER_WITH_METHOD_CONT,
              "This is the getter that cannot be overridden by a method."),

      MessageKind.CANNOT_OVERRIDE_METHOD_WITH_GETTER: const MessageTemplate(
          MessageKind.CANNOT_OVERRIDE_METHOD_WITH_GETTER,
          "Getter '#{name}' in '#{class}' can't override method from "
          "'#{inheritedClass}'."),

      MessageKind.CANNOT_OVERRIDE_METHOD_WITH_GETTER_CONT:
          const MessageTemplate(
              MessageKind.CANNOT_OVERRIDE_METHOD_WITH_GETTER_CONT,
              "This is the method that cannot be overridden by a getter."),

      MessageKind.MISSING_FORMALS: const MessageTemplate(
          MessageKind.MISSING_FORMALS, "Formal parameters are missing."),

      MessageKind.EXTRA_FORMALS: const MessageTemplate(
          MessageKind.EXTRA_FORMALS, "Formal parameters are not allowed here."),

      MessageKind.UNARY_OPERATOR_BAD_ARITY: const MessageTemplate(
          MessageKind.UNARY_OPERATOR_BAD_ARITY,
          "Operator '#{operatorName}' must have no parameters."),

      MessageKind.MINUS_OPERATOR_BAD_ARITY: const MessageTemplate(
          MessageKind.MINUS_OPERATOR_BAD_ARITY,
          "Operator '-' must have 0 or 1 parameters."),

      MessageKind.BINARY_OPERATOR_BAD_ARITY: const MessageTemplate(
          MessageKind.BINARY_OPERATOR_BAD_ARITY,
          "Operator '#{operatorName}' must have exactly 1 parameter."),

      MessageKind.TERNARY_OPERATOR_BAD_ARITY: const MessageTemplate(
          MessageKind.TERNARY_OPERATOR_BAD_ARITY,
          "Operator '#{operatorName}' must have exactly 2 parameters."),

      MessageKind.OPERATOR_OPTIONAL_PARAMETERS: const MessageTemplate(
          MessageKind.OPERATOR_OPTIONAL_PARAMETERS,
          "Operator '#{operatorName}' cannot have optional parameters."),

      MessageKind.OPERATOR_NAMED_PARAMETERS: const MessageTemplate(
          MessageKind.OPERATOR_NAMED_PARAMETERS,
          "Operator '#{operatorName}' cannot have named parameters."),

      MessageKind.ILLEGAL_FINAL_METHOD_MODIFIER: const MessageTemplate(
          MessageKind.ILLEGAL_FINAL_METHOD_MODIFIER,
          "Cannot have final modifier on method."),

      MessageKind.ILLEGAL_CONST_FIELD_MODIFIER: const MessageTemplate(
          MessageKind.ILLEGAL_CONST_FIELD_MODIFIER,
          "Cannot have const modifier on non-static field.",
          howToFix:
              "Try adding a static modifier, or removing the const modifier.",
          examples: const [
            """
class C {
  const int a = 1;
}

main() => new C();"""
          ]),

      MessageKind.ILLEGAL_CONSTRUCTOR_MODIFIERS: const MessageTemplate(
          MessageKind.ILLEGAL_CONSTRUCTOR_MODIFIERS,
          "Illegal constructor modifiers: '#{modifiers}'."),

      MessageKind.ILLEGAL_MIXIN_APPLICATION_MODIFIERS: const MessageTemplate(
          MessageKind.ILLEGAL_MIXIN_APPLICATION_MODIFIERS,
          "Illegal mixin application modifiers: '#{modifiers}'."),

      MessageKind.ILLEGAL_MIXIN_SUPERCLASS: const MessageTemplate(
          MessageKind.ILLEGAL_MIXIN_SUPERCLASS,
          "Class used as mixin must have Object as superclass."),

      MessageKind.ILLEGAL_MIXIN_OBJECT: const MessageTemplate(
          MessageKind.ILLEGAL_MIXIN_OBJECT, "Cannot use Object as mixin."),

      MessageKind.ILLEGAL_MIXIN_CONSTRUCTOR: const MessageTemplate(
          MessageKind.ILLEGAL_MIXIN_CONSTRUCTOR,
          "Class used as mixin cannot have non-factory constructor."),

      MessageKind.ILLEGAL_MIXIN_CYCLE: const MessageTemplate(
          MessageKind.ILLEGAL_MIXIN_CYCLE,
          "Class used as mixin introduces mixin cycle: "
          "'#{mixinName1}' <-> '#{mixinName2}'."),

      MessageKind.ILLEGAL_MIXIN_WITH_SUPER: const MessageTemplate(
          MessageKind.ILLEGAL_MIXIN_WITH_SUPER,
          "Cannot use class '#{className}' as a mixin because it uses "
          "'super'."),

      MessageKind.ILLEGAL_MIXIN_SUPER_USE: const MessageTemplate(
          MessageKind.ILLEGAL_MIXIN_SUPER_USE,
          "Use of 'super' in class used as mixin."),

      MessageKind.PARAMETER_NAME_EXPECTED: const MessageTemplate(
          MessageKind.PARAMETER_NAME_EXPECTED, "parameter name expected."),

      MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER: const MessageTemplate(
          MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER,
          "Cannot resolve setter."),

      MessageKind.ASSIGNING_FINAL_FIELD_IN_SUPER: const MessageTemplate(
          MessageKind.ASSIGNING_FINAL_FIELD_IN_SUPER,
          "Cannot assign a value to final field '#{name}' "
          "in superclass '#{superclassName}'."),

      MessageKind.ASSIGNING_METHOD: const MessageTemplate(
          MessageKind.ASSIGNING_METHOD, "Cannot assign a value to a method."),

      MessageKind.ASSIGNING_METHOD_IN_SUPER: const MessageTemplate(
          MessageKind.ASSIGNING_METHOD_IN_SUPER,
          "Cannot assign a value to method '#{name}' "
          "in superclass '#{superclassName}'."),

      MessageKind.ASSIGNING_TYPE: const MessageTemplate(
          MessageKind.ASSIGNING_TYPE, "Cannot assign a value to a type."),

      MessageKind.IF_NULL_ASSIGNING_TYPE: const MessageTemplate(
          MessageKind.IF_NULL_ASSIGNING_TYPE,
          "Cannot assign a value to a type. Note that types are never null, "
          "so this ??= assignment has no effect.",
          howToFix: "Try removing the '??=' assignment.",
          examples: const [
            "class A {} main() { print(A ??= 3);}",
          ]),

      MessageKind.VOID_NOT_ALLOWED: const MessageTemplate(
          MessageKind.VOID_NOT_ALLOWED,
          "Type 'void' can't be used here because it isn't a return type.",
          howToFix:
              "Try removing 'void' keyword or replace it with 'var', 'final', "
              "or a type.",
          examples: const [
            "void x; main() {}",
            "foo(void x) {} main() { foo(null); }",
          ]),

      MessageKind.NULL_NOT_ALLOWED: const MessageTemplate(
          MessageKind.NULL_NOT_ALLOWED, "`null` can't be used here."),

      MessageKind.BEFORE_TOP_LEVEL: const MessageTemplate(
          MessageKind.BEFORE_TOP_LEVEL,
          "Part header must come before top-level definitions."),

      MessageKind.IMPORT_PART_OF: const MessageTemplate(
          MessageKind.IMPORT_PART_OF,
          "The imported library must not have a 'part-of' directive.",
          howToFix: "Try removing the 'part-of' directive or replacing the "
              "import of the library with a 'part' directive.",
          examples: const [
            const {
              'main.dart': """
library library;

import 'part.dart';

main() {}
""",
              'part.dart': """
part of library;
"""
            }
          ]),

      MessageKind.IMPORT_PART_OF_HERE: const MessageTemplate(
          MessageKind.IMPORT_PART_OF_HERE, "The library is imported here."),

      MessageKind.MAIN_HAS_PART_OF: const MessageTemplate(
          MessageKind.MAIN_HAS_PART_OF,
          "The main application file must not have a 'part-of' directive.",
          howToFix: "Try removing the 'part-of' directive or starting "
              "compilation from another file.",
          examples: const [
            const {
              'main.dart': """
part of library;

main() {}
"""
            }
          ]),

      MessageKind.LIBRARY_NAME_MISMATCH: const MessageTemplate(
          MessageKind.LIBRARY_NAME_MISMATCH,
          "Expected part of library name '#{libraryName}'.",
          howToFix: "Try changing the directive to 'part of #{libraryName};'.",
          examples: const [
            const {
              'main.dart': """
library lib.foo;

part 'part.dart';

main() {}
""",
              'part.dart': """
part of lib.bar;
"""
            }
          ]),

      MessageKind.LIBRARY_URI_MISMATCH: const MessageTemplate(
          MessageKind.LIBRARY_URI_MISMATCH,
          "Expected URI of library '#{libraryUri}'.",
          howToFix: "Try changing the directive to 'part of "
              "\"#{libraryUri}\";'.",
          examples: const [
            const {
              'main.dart': """
library lib.foo;

part 'part.dart';

main() {}
""",
              'part.dart': """
part of 'not-main.dart';
"""
            }
          ]),

      MessageKind.MISSING_LIBRARY_NAME: const MessageTemplate(
          MessageKind.MISSING_LIBRARY_NAME,
          "Library has no name. Part directive expected library name "
          "to be '#{libraryName}'.",
          howToFix: "Try adding 'library #{libraryName};' to the library.",
          examples: const [
            const {
              'main.dart': """
part 'part.dart';

main() {}
""",
              'part.dart': """
part of lib.foo;
"""
            }
          ]),

      MessageKind.THIS_IS_THE_PART_OF_TAG: const MessageTemplate(
          MessageKind.THIS_IS_THE_PART_OF_TAG,
          "This is the part of directive."),

      MessageKind.MISSING_PART_OF_TAG: const MessageTemplate(
          MessageKind.MISSING_PART_OF_TAG,
          "This file has no part-of tag, but it is being used as a part."),

      MessageKind.DUPLICATED_PART_OF: const MessageTemplate(
          MessageKind.DUPLICATED_PART_OF, "Duplicated part-of directive."),

      MessageKind.DUPLICATED_LIBRARY_NAME: const MessageTemplate(
          MessageKind.DUPLICATED_LIBRARY_NAME,
          "Duplicated library name '#{libraryName}'."),

      MessageKind.DUPLICATED_RESOURCE: const MessageTemplate(
          MessageKind.DUPLICATED_RESOURCE,
          "The resource '#{resourceUri}' is loaded through both "
          "'#{canonicalUri1}' and '#{canonicalUri2}'."),

      MessageKind.DUPLICATED_LIBRARY_RESOURCE: const MessageTemplate(
          MessageKind.DUPLICATED_LIBRARY_RESOURCE,
          "The library '#{libraryName}' in '#{resourceUri}' is loaded through "
          "both '#{canonicalUri1}' and '#{canonicalUri2}'."),

      // This is used as an exception.
      MessageKind.INVALID_SOURCE_FILE_LOCATION:
          const MessageTemplate(MessageKind.INVALID_SOURCE_FILE_LOCATION, '''
Invalid offset (#{offset}) in source map.
File: #{fileName}
Length: #{length}'''),

      MessageKind.TOP_LEVEL_VARIABLE_DECLARED_STATIC: const MessageTemplate(
          MessageKind.TOP_LEVEL_VARIABLE_DECLARED_STATIC,
          "Top-level variable cannot be declared static."),

      MessageKind.REFERENCE_IN_INITIALIZATION: const MessageTemplate(
          MessageKind.REFERENCE_IN_INITIALIZATION,
          "Variable '#{variableName}' is referenced during its "
          "initialization.",
          howToFix:
              "If you are trying to reference a shadowed variable, rename "
              "one of the variables.",
          examples: const [
            """
foo(t) {
  var t = t;
  return t;
}

main() => foo(1);
"""
          ]),

      MessageKind.CONST_WITHOUT_INITIALIZER: const MessageTemplate(
          MessageKind.CONST_WITHOUT_INITIALIZER,
          "A constant variable must be initialized.",
          howToFix: "Try adding an initializer or "
              "removing the 'const' modifier.",
          examples: const [
            """
void main() {
  const c; // This constant variable must be initialized.
}"""
          ]),

      MessageKind.FINAL_WITHOUT_INITIALIZER: const MessageTemplate(
          MessageKind.FINAL_WITHOUT_INITIALIZER,
          "A final variable must be initialized.",
          howToFix: "Try adding an initializer or "
              "removing the 'final' modifier.",
          examples: const [
            "class C { static final field; } main() => C.field;"
          ]),

      MessageKind.CONST_LOOP_VARIABLE: const MessageTemplate(
          MessageKind.CONST_LOOP_VARIABLE,
          "A loop variable cannot be constant.",
          howToFix: "Try remove the 'const' modifier or "
              "replacing it with a 'final' modifier.",
          examples: const [
            """
void main() {
  for (const c in []) {}
}"""
          ]),

      MessageKind.MEMBER_USES_CLASS_NAME: const MessageTemplate(
          MessageKind.MEMBER_USES_CLASS_NAME,
          "Member variable can't have the same name as the class it is "
          "declared in.",
          howToFix: "Try renaming the variable.",
          examples: const [
            """
class A { var A; }
main() {
  var a = new A();
  a.A = 1;
}
""",
            """
class A { static var A; }
main() => A.A = 1;
"""
          ]),

      MessageKind.WRONG_NUMBER_OF_ARGUMENTS_FOR_ASSERT: const MessageTemplate(
          MessageKind.WRONG_NUMBER_OF_ARGUMENTS_FOR_ASSERT,
          "Wrong number of arguments to assert. Should be 1, but given "
          "#{argumentCount}."),

      MessageKind.ASSERT_IS_GIVEN_NAMED_ARGUMENTS: const MessageTemplate(
          MessageKind.ASSERT_IS_GIVEN_NAMED_ARGUMENTS,
          "'assert' takes no named arguments, but given #{argumentCount}."),

      MessageKind.FACTORY_REDIRECTION_IN_NON_FACTORY: const MessageTemplate(
          MessageKind.FACTORY_REDIRECTION_IN_NON_FACTORY,
          "Factory redirection only allowed in factories."),

      MessageKind.MISSING_FACTORY_KEYWORD: const MessageTemplate(
          MessageKind.MISSING_FACTORY_KEYWORD,
          "Did you forget a factory keyword here?"),

      MessageKind.NO_SUCH_METHOD_IN_NATIVE: const MessageTemplate(
          MessageKind.NO_SUCH_METHOD_IN_NATIVE,
          "'NoSuchMethod' is not supported for classes that extend native "
          "classes."),

      MessageKind.DEFERRED_LIBRARY_DART_2_DART: const MessageTemplate(
          MessageKind.DEFERRED_LIBRARY_DART_2_DART,
          "Deferred loading is not supported by the dart backend yet. "
          "The output will not be split."),

      MessageKind.DEFERRED_LIBRARY_WITHOUT_PREFIX: const MessageTemplate(
          MessageKind.DEFERRED_LIBRARY_WITHOUT_PREFIX,
          "This import is deferred but there is no prefix keyword.",
          howToFix: "Try adding a prefix to the import."),

      MessageKind.DEFERRED_OLD_SYNTAX: const MessageTemplate(
          MessageKind.DEFERRED_OLD_SYNTAX,
          "The DeferredLibrary annotation is obsolete.",
          howToFix:
              "Use the \"import 'lib.dart' deferred as prefix\" syntax instead."),

      MessageKind.DEFERRED_LIBRARY_DUPLICATE_PREFIX: const MessageTemplate(
          MessageKind.DEFERRED_LIBRARY_DUPLICATE_PREFIX,
          "The prefix of this deferred import is not unique.",
          howToFix: "Try changing the import prefix."),

      MessageKind.DEFERRED_TYPE_ANNOTATION: const MessageTemplate(
          MessageKind.DEFERRED_TYPE_ANNOTATION,
          "The type #{node} is deferred. "
          "Deferred types are not valid as type annotations.",
          howToFix: "Try using a non-deferred abstract class as an interface."),

      MessageKind.ILLEGAL_STATIC: const MessageTemplate(
          MessageKind.ILLEGAL_STATIC,
          "Modifier static is only allowed on functions declared in "
          "a class."),

      MessageKind.STATIC_FUNCTION_BLOAT: const MessageTemplate(
          MessageKind.STATIC_FUNCTION_BLOAT,
          "Using '#{class}.#{name}' may lead to unnecessarily large "
          "generated code.",
          howToFix: "Try adding '@MirrorsUsed(...)' as described at "
              "https://goo.gl/Akrrog."),

      MessageKind.NON_CONST_BLOAT: const MessageTemplate(
          MessageKind.NON_CONST_BLOAT,
          "Using 'new #{name}' may lead to unnecessarily large generated "
          "code.",
          howToFix:
              "Try using 'const #{name}' or adding '@MirrorsUsed(...)' as "
              "described at https://goo.gl/Akrrog."),

      MessageKind.STRING_EXPECTED: const MessageTemplate(
          MessageKind.STRING_EXPECTED,
          "Expected a 'String', but got an instance of '#{type}'."),

      MessageKind.PRIVATE_IDENTIFIER: const MessageTemplate(
          MessageKind.PRIVATE_IDENTIFIER,
          "'#{value}' is not a valid Symbol name because it starts with "
          "'_'."),

      MessageKind.PRIVATE_NAMED_PARAMETER: const MessageTemplate(
          MessageKind.PRIVATE_NAMED_PARAMETER,
          "Named optional parameter can't have a library private name.",
          howToFix:
              "Try removing the '_' or making the parameter positional or "
              "required.",
          examples: const ["""foo({int _p}) {} main() => foo();"""]),

      MessageKind.UNSUPPORTED_LITERAL_SYMBOL: const MessageTemplate(
          MessageKind.UNSUPPORTED_LITERAL_SYMBOL,
          "Symbol literal '##{value}' is currently unsupported by dart2js."),

      MessageKind.INVALID_SYMBOL: const MessageTemplate(
          MessageKind.INVALID_SYMBOL,
          '''
'#{value}' is not a valid Symbol name because is not:
 * an empty String,
 * a user defined operator,
 * a qualified non-private identifier optionally followed by '=', or
 * a qualified non-private identifier followed by '.' and a user-defined '''
          "operator."),

      MessageKind.AMBIGUOUS_REEXPORT: const MessageTemplate(
          MessageKind.AMBIGUOUS_REEXPORT,
          "'#{name}' is (re)exported by multiple libraries."),

      MessageKind.AMBIGUOUS_LOCATION: const MessageTemplate(
          MessageKind.AMBIGUOUS_LOCATION, "'#{name}' is defined here."),

      MessageKind.IMPORTED_HERE: const MessageTemplate(
          MessageKind.IMPORTED_HERE, "'#{name}' is imported here."),

      MessageKind.OVERRIDE_EQUALS_NOT_HASH_CODE: const MessageTemplate(
          MessageKind.OVERRIDE_EQUALS_NOT_HASH_CODE,
          "The class '#{class}' overrides 'operator==', "
          "but not 'get hashCode'."),

      MessageKind.INTERNAL_LIBRARY_FROM: const MessageTemplate(
          MessageKind.INTERNAL_LIBRARY_FROM,
          "Internal library '#{resolvedUri}' is not accessible from "
          "'#{importingUri}'."),

      MessageKind.INTERNAL_LIBRARY: const MessageTemplate(
          MessageKind.INTERNAL_LIBRARY,
          "Internal library '#{resolvedUri}' is not accessible."),

      MessageKind.JS_INTEROP_CLASS_CANNOT_EXTEND_DART_CLASS:
          const MessageTemplate(
              MessageKind.JS_INTEROP_CLASS_CANNOT_EXTEND_DART_CLASS,
              "Js-interop class '#{cls}' cannot extend from the non js-interop "
              "class '#{superclass}'.",
              howToFix: "Annotate the superclass with @JS.",
              examples: const [
            """
              import 'package:js/js.dart';

              class Foo { }

              @JS()
              class Bar extends Foo { }

              main() {
                new Bar();
              }
              """
          ]),

      MessageKind.JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER: const MessageTemplate(
          MessageKind.JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER,
          "Member '#{member}' in js-interop class '#{cls}' is not external.",
          howToFix: "Mark all interop methods external",
          examples: const [
            """
              import 'package:js/js.dart';

              @JS()
              class Foo {
                bar() {}
              }

              main() {
                new Foo().bar();
              }
              """
          ]),

      MessageKind.JS_INTEROP_METHOD_WITH_NAMED_ARGUMENTS: const MessageTemplate(
          MessageKind.JS_INTEROP_METHOD_WITH_NAMED_ARGUMENTS,
          "Js-interop method '#{method}' has named arguments but is not "
          "a factory constructor of an @anonymous @JS class.",
          howToFix: "Remove all named arguments from js-interop method or "
              "in the case of a factory constructor annotate the class "
              "as @anonymous.",
          examples: const [
            """
              import 'package:js/js.dart';

              @JS()
              class Foo {
                external bar(foo, {baz});
              }

              main() {
                new Foo().bar(4, baz: 5);
              }
              """
          ]),
      MessageKind.JS_INTEROP_INDEX_NOT_SUPPORTED: const MessageTemplate(
          MessageKind.JS_INTEROP_INDEX_NOT_SUPPORTED,
          "Js-interop does not support [] and []= operator methods.",
          howToFix: "Try replacing [] and []= operator methods with normal "
              "methods.",
          examples: const [
            """
        import 'package:js/js.dart';

        @JS()
        class Foo {
          external operator [](arg);
        }

        main() {
          new Foo()[0];
        }
        """,
            """
        import 'package:js/js.dart';

        @JS()
        class Foo {
          external operator []=(arg, value);
        }

        main() {
          new Foo()[0] = 1;
        }
        """
          ]),

      MessageKind.JS_OBJECT_LITERAL_CONSTRUCTOR_WITH_POSITIONAL_ARGUMENTS:
          const MessageTemplate(
              MessageKind
                  .JS_OBJECT_LITERAL_CONSTRUCTOR_WITH_POSITIONAL_ARGUMENTS,
              "Parameter '#{parameter}' in anonymous js-interop class '#{cls}' "
              "object literal constructor is positional instead of named."
              ".",
              howToFix: "Make all arguments in external factory object literal "
                  "constructors named.",
              examples: const [
            """
              import 'package:js/js.dart';

              @anonymous
              @JS()
              class Foo {
                external factory Foo(foo, {baz});
              }

              main() {
                new Foo(5, baz: 5);
              }
              """
          ]),

      MessageKind.LIBRARY_NOT_FOUND: const MessageTemplate(
          MessageKind.LIBRARY_NOT_FOUND, "Library not found '#{resolvedUri}'."),

      MessageKind.LIBRARY_NOT_SUPPORTED: const MessageTemplate(
          MessageKind.LIBRARY_NOT_SUPPORTED,
          "Library not supported '#{resolvedUri}'.",
          howToFix: "Try removing the dependency or enabling support using "
              "the '--categories' option.",
          examples: const [
            /*
              """
              import 'dart:io';
              main() {}
              """
          */
          ]),
      // TODO(johnniwinther): Enable example when message_kind_test.dart
      // supports library loader callbacks.

      MessageKind.UNSUPPORTED_EQ_EQ_EQ: const MessageTemplate(
          MessageKind.UNSUPPORTED_EQ_EQ_EQ,
          "'===' is not an operator. "
          "Did you mean '#{lhs} == #{rhs}' or 'identical(#{lhs}, #{rhs})'?"),

      MessageKind.UNSUPPORTED_BANG_EQ_EQ: const MessageTemplate(
          MessageKind.UNSUPPORTED_BANG_EQ_EQ,
          "'!==' is not an operator. "
          "Did you mean '#{lhs} != #{rhs}' or '!identical(#{lhs}, #{rhs})'?"),

      MessageKind.UNSUPPORTED_PREFIX_PLUS: const MessageTemplate(
          MessageKind.UNSUPPORTED_PREFIX_PLUS, "'+' is not a prefix operator. ",
          howToFix: "Try removing '+'.",
          examples: const [
            "main() => +2;  // No longer a valid way to write '2'"
          ]),

      MessageKind.MIRRORS_EXPECTED_STRING: const MessageTemplate(
          MessageKind.MIRRORS_EXPECTED_STRING,
          "Can't use '#{name}' here because it's an instance of '#{type}' "
          "and a 'String' value is expected.",
          howToFix: "Did you forget to add quotes?",
          examples: const [
            """
// 'Foo' is a type literal, not a string.
@MirrorsUsed(symbols: const [Foo])
import 'dart:mirrors';

class Foo {}

main() {}
"""
          ]),

      MessageKind.MIRRORS_EXPECTED_STRING_OR_TYPE: const MessageTemplate(
          MessageKind.MIRRORS_EXPECTED_STRING_OR_TYPE,
          "Can't use '#{name}' here because it's an instance of '#{type}' "
          "and a 'String' or 'Type' value is expected.",
          howToFix: "Did you forget to add quotes?",
          examples: const [
            """
// 'main' is a method, not a class.
@MirrorsUsed(targets: const [main])
import 'dart:mirrors';

main() {}
"""
          ]),

      MessageKind.MIRRORS_EXPECTED_STRING_OR_LIST: const MessageTemplate(
          MessageKind.MIRRORS_EXPECTED_STRING_OR_LIST,
          "Can't use '#{name}' here because it's an instance of '#{type}' "
          "and a 'String' or 'List' value is expected.",
          howToFix: "Did you forget to add quotes?",
          examples: const [
            """
// 'Foo' is not a string.
@MirrorsUsed(symbols: Foo)
import 'dart:mirrors';

class Foo {}

main() {}
"""
          ]),

      MessageKind.MIRRORS_EXPECTED_STRING_TYPE_OR_LIST: const MessageTemplate(
          MessageKind.MIRRORS_EXPECTED_STRING_TYPE_OR_LIST,
          "Can't use '#{name}' here because it's an instance of '#{type}' "
          "but a 'String', 'Type', or 'List' value is expected.",
          howToFix: "Did you forget to add quotes?",
          examples: const [
            """
// '1' is not a string.
@MirrorsUsed(targets: 1)
import 'dart:mirrors';

main() {}
"""
          ]),

      MessageKind.MIRRORS_CANNOT_RESOLVE_IN_CURRENT_LIBRARY: const MessageTemplate(
          MessageKind.MIRRORS_CANNOT_RESOLVE_IN_CURRENT_LIBRARY,
          "Can't find '#{name}' in the current library.",
          // TODO(ahe): The closest identifiers in edit distance would be nice.
          howToFix: "Did you forget to add an import?",
          examples: const [
            """
// 'window' is not in scope because dart:html isn't imported.
@MirrorsUsed(targets: 'window')
import 'dart:mirrors';

main() {}
"""
          ]),

      MessageKind.MIRRORS_CANNOT_RESOLVE_IN_LIBRARY: const MessageTemplate(
          MessageKind.MIRRORS_CANNOT_RESOLVE_IN_LIBRARY,
          "Can't find '#{name}' in the library '#{library}'.",
          // TODO(ahe): The closest identifiers in edit distance would be nice.
          howToFix: "Is '#{name}' spelled right?",
          examples: const [
            """
// 'List' is misspelled.
@MirrorsUsed(targets: 'dart.core.Lsit')
import 'dart:mirrors';

main() {}
"""
          ]),

      MessageKind.MIRRORS_CANNOT_FIND_IN_ELEMENT: const MessageTemplate(
          MessageKind.MIRRORS_CANNOT_FIND_IN_ELEMENT,
          "Can't find '#{name}' in '#{element}'.",
          // TODO(ahe): The closest identifiers in edit distance would be nice.
          howToFix: "Is '#{name}' spelled right?",
          examples: const [
            """
// 'addAll' is misspelled.
@MirrorsUsed(targets: 'dart.core.List.addAl')
import 'dart:mirrors';

main() {}
"""
          ]),

      MessageKind.INVALID_URI: const MessageTemplate(
          MessageKind.INVALID_URI, "'#{uri}' is not a valid URI.",
          howToFix: DONT_KNOW_HOW_TO_FIX,
          examples: const [
            """
// can't have a '[' in a URI
import '../../Udyn[mic ils/expect.dart';

main() {}
"""
          ]),

      MessageKind.INVALID_PACKAGE_CONFIG: const MessageTemplate(
          MessageKind.INVALID_PACKAGE_CONFIG,
          """Package config file '#{uri}' is invalid.
#{exception}""",
          howToFix: DONT_KNOW_HOW_TO_FIX),

      MessageKind.INVALID_PACKAGE_URI: const MessageTemplate(
          MessageKind.INVALID_PACKAGE_URI,
          "'#{uri}' is not a valid package URI (#{exception}).",
          howToFix: DONT_KNOW_HOW_TO_FIX,
          examples: const [
            """
// can't have a 'top level' package URI
import 'package:foo.dart';

main() {}
""",
            """
// can't have 2 slashes
import 'package://foo/foo.dart';

main() {}
""",
            """
// package name must be valid
import 'package:not\valid/foo.dart';

main() {}
"""
          ]),

      MessageKind.READ_URI_ERROR: const MessageTemplate(
          MessageKind.READ_URI_ERROR, "Can't read '#{uri}' (#{exception}).",
          // Don't know how to fix since the underlying error is unknown.
          howToFix: DONT_KNOW_HOW_TO_FIX,
          examples: const [
            """
// 'foo.dart' does not exist.
import 'foo.dart';

main() {}
"""
          ]),

      MessageKind.READ_SELF_ERROR:
          const MessageTemplate(MessageKind.READ_SELF_ERROR, "#{exception}",
              // Don't know how to fix since the underlying error is unknown.
              howToFix: DONT_KNOW_HOW_TO_FIX),

      MessageKind.ABSTRACT_CLASS_INSTANTIATION: const MessageTemplate(
          MessageKind.ABSTRACT_CLASS_INSTANTIATION,
          "Can't instantiate abstract class.",
          howToFix: DONT_KNOW_HOW_TO_FIX,
          examples: const ["abstract class A {} main() { new A(); }"]),

      MessageKind.BODY_EXPECTED: const MessageTemplate(
          MessageKind.BODY_EXPECTED, "Expected a function body or '=>'.",
          // TODO(ahe): In some scenarios, we can suggest removing the 'static'
          // keyword.
          howToFix: "Try adding {}.",
          examples: const ["main();"]),

      MessageKind.MIRROR_BLOAT: const MessageTemplate(
          MessageKind.MIRROR_BLOAT,
          "#{count} methods retained for use by dart:mirrors out of #{total}"
          " total methods (#{percentage}%)."),

      MessageKind.MIRROR_IMPORT: const MessageTemplate(
          MessageKind.MIRROR_IMPORT, "Import of 'dart:mirrors'."),

      MessageKind.MIRROR_IMPORT_NO_USAGE: const MessageTemplate(
          MessageKind.MIRROR_IMPORT_NO_USAGE,
          "This import is not annotated with @MirrorsUsed, which may lead to "
          "unnecessarily large generated code.",
          howToFix: "Try adding '@MirrorsUsed(...)' as described at "
              "https://goo.gl/Akrrog."),

      MessageKind.JS_PLACEHOLDER_CAPTURE: const MessageTemplate(
          MessageKind.JS_PLACEHOLDER_CAPTURE,
          "JS code must not use '#' placeholders inside functions.",
          howToFix:
              "Use an immediately called JavaScript function to capture the"
              " the placeholder values as JavaScript function parameters."),

      MessageKind.WRONG_ARGUMENT_FOR_JS: const MessageTemplate(
          MessageKind.WRONG_ARGUMENT_FOR_JS,
          "JS expression must take two or more arguments."),

      MessageKind.WRONG_ARGUMENT_FOR_JS_FIRST: const MessageTemplate(
          MessageKind.WRONG_ARGUMENT_FOR_JS_FIRST,
          "JS expression must take two or more arguments."),

      MessageKind.WRONG_ARGUMENT_FOR_JS_SECOND: const MessageTemplate(
          MessageKind.WRONG_ARGUMENT_FOR_JS_SECOND,
          "JS second argument must be a string literal."),

      MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT:
          const MessageTemplate(
              MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT,
              "Argument for 'JS_INTERCEPTOR_CONSTANT' must be a type constant."),

      MessageKind.EXPECTED_IDENTIFIER_NOT_RESERVED_WORD: const MessageTemplate(
          MessageKind.EXPECTED_IDENTIFIER_NOT_RESERVED_WORD,
          "'#{keyword}' is a reserved word and can't be used here.",
          howToFix: "Try using a different name.",
          examples: const ["do() {} main() {}"]),

      MessageKind.NAMED_FUNCTION_EXPRESSION: const MessageTemplate(
          MessageKind.NAMED_FUNCTION_EXPRESSION,
          "Function expression '#{name}' cannot be named.",
          howToFix: "Try removing the name.",
          examples: const ["main() { var f = func() {}; }"]),

      MessageKind.UNUSED_METHOD: const MessageTemplate(
          MessageKind.UNUSED_METHOD, "The method '#{name}' is never called.",
          howToFix: "Consider deleting it.",
          examples: const ["deadCode() {} main() {}"]),

      MessageKind.UNUSED_CLASS: const MessageTemplate(
          MessageKind.UNUSED_CLASS, "The class '#{name}' is never used.",
          howToFix: "Consider deleting it.",
          examples: const ["class DeadCode {} main() {}"]),

      MessageKind.UNUSED_TYPEDEF: const MessageTemplate(
          MessageKind.UNUSED_TYPEDEF, "The typedef '#{name}' is never used.",
          howToFix: "Consider deleting it.",
          examples: const ["typedef DeadCode(); main() {}"]),

      MessageKind.ABSTRACT_METHOD: const MessageTemplate(
          MessageKind.ABSTRACT_METHOD,
          "The method '#{name}' has no implementation in "
          "class '#{class}'.",
          howToFix: "Try adding a body to '#{name}' or declaring "
              "'#{class}' to be 'abstract'.",
          examples: const [
            """
class Class {
  method();
}
main() => new Class().method();
"""
          ]),

      MessageKind.ABSTRACT_GETTER: const MessageTemplate(
          MessageKind.ABSTRACT_GETTER,
          "The getter '#{name}' has no implementation in "
          "class '#{class}'.",
          howToFix: "Try adding a body to '#{name}' or declaring "
              "'#{class}' to be 'abstract'.",
          examples: const [
            """
class Class {
  get getter;
}
main() => new Class();
"""
          ]),

      MessageKind.ABSTRACT_SETTER: const MessageTemplate(
          MessageKind.ABSTRACT_SETTER,
          "The setter '#{name}' has no implementation in "
          "class '#{class}'.",
          howToFix: "Try adding a body to '#{name}' or declaring "
              "'#{class}' to be 'abstract'.",
          examples: const [
            """
class Class {
  set setter(_);
}
main() => new Class();
"""
          ]),

      MessageKind.INHERIT_GETTER_AND_METHOD: const MessageTemplate(
          MessageKind.INHERIT_GETTER_AND_METHOD,
          "The class '#{class}' can't inherit both getters and methods "
          "by the named '#{name}'.",
          howToFix: DONT_KNOW_HOW_TO_FIX,
          examples: const [
            """
class A {
  get member => null;
}
class B {
  member() {}
}
class Class implements A, B {
}
main() => new Class();
"""
          ]),

      MessageKind.INHERITED_METHOD: const MessageTemplate(
          MessageKind.INHERITED_METHOD,
          "The inherited method '#{name}' is declared here in class "
          "'#{class}'."),

      MessageKind.INHERITED_EXPLICIT_GETTER: const MessageTemplate(
          MessageKind.INHERITED_EXPLICIT_GETTER,
          "The inherited getter '#{name}' is declared here in class "
          "'#{class}'."),

      MessageKind.INHERITED_IMPLICIT_GETTER: const MessageTemplate(
          MessageKind.INHERITED_IMPLICIT_GETTER,
          "The inherited getter '#{name}' is implicitly declared by this "
          "field in class '#{class}'."),

      MessageKind.UNIMPLEMENTED_METHOD_ONE: const MessageTemplate(
          MessageKind.UNIMPLEMENTED_METHOD_ONE,
          "'#{class}' doesn't implement '#{method}' "
          "declared in '#{declarer}'.",
          howToFix: "Try adding an implementation of '#{name}' or declaring "
              "'#{class}' to be 'abstract'.",
          examples: const [
            """
abstract class I {
  m();
}
class C implements I {}
main() => new C();
""",
            """
abstract class I {
  m();
}
class C extends I {}
main() => new C();
"""
          ]),

      MessageKind.UNIMPLEMENTED_METHOD: const MessageTemplate(
          MessageKind.UNIMPLEMENTED_METHOD,
          "'#{class}' doesn't implement '#{method}'.",
          howToFix: "Try adding an implementation of '#{name}' or declaring "
              "'#{class}' to be 'abstract'.",
          examples: const [
            """
abstract class I {
  m();
}

abstract class J {
  m();
}

class C implements I, J {}

main() {
 new C();
}
""",
            """
abstract class I {
  m();
}

abstract class J {
  m();
}

class C extends I implements J {}

main() {
 new C();
}
"""
          ]),

      MessageKind.UNIMPLEMENTED_METHOD_CONT: const MessageTemplate(
          MessageKind.UNIMPLEMENTED_METHOD_CONT,
          "The method '#{name}' is declared here in class '#{class}'."),

      MessageKind.UNIMPLEMENTED_SETTER_ONE: const MessageTemplate(
          MessageKind.UNIMPLEMENTED_SETTER_ONE,
          "'#{class}' doesn't implement the setter '#{name}' "
          "declared in '#{declarer}'.",
          howToFix: "Try adding an implementation of '#{name}' or declaring "
              "'#{class}' to be 'abstract'.",
          examples: const [
            """
abstract class I {
  set m(_);
}
class C implements I {}
class D implements I {
  set m(_) {}
}
main() {
 new D().m = 0;
 new C();
}
"""
          ]),

      MessageKind.UNIMPLEMENTED_SETTER: const MessageTemplate(
          MessageKind.UNIMPLEMENTED_SETTER,
          "'#{class}' doesn't implement the setter '#{name}'.",
          howToFix: "Try adding an implementation of '#{name}' or declaring "
              "'#{class}' to be 'abstract'.",
          examples: const [
            """
abstract class I {
  set m(_);
}
abstract class J {
  set m(_);
}
class C implements I, J {}
main() => new C();
""",
            """
abstract class I {
  set m(_);
}
abstract class J {
  set m(_);
}
class C extends I implements J {}
main() => new C();
"""
          ]),

      MessageKind.UNIMPLEMENTED_EXPLICIT_SETTER: const MessageTemplate(
          MessageKind.UNIMPLEMENTED_EXPLICIT_SETTER,
          "The setter '#{name}' is declared here in class '#{class}'."),

      MessageKind.UNIMPLEMENTED_IMPLICIT_SETTER: const MessageTemplate(
          MessageKind.UNIMPLEMENTED_IMPLICIT_SETTER,
          "The setter '#{name}' is implicitly declared by this field "
          "in class '#{class}'."),

      MessageKind.UNIMPLEMENTED_GETTER_ONE: const MessageTemplate(
          MessageKind.UNIMPLEMENTED_GETTER_ONE,
          "'#{class}' doesn't implement the getter '#{name}' "
          "declared in '#{declarer}'.",
          howToFix: "Try adding an implementation of '#{name}' or declaring "
              "'#{class}' to be 'abstract'.",
          examples: const [
            """
abstract class I {
  get m;
}
class C implements I {}
main() => new C();
""",
            """
abstract class I {
  get m;
}
class C extends I {}
main() => new C();
"""
          ]),

      MessageKind.UNIMPLEMENTED_GETTER: const MessageTemplate(
          MessageKind.UNIMPLEMENTED_GETTER,
          "'#{class}' doesn't implement the getter '#{name}'.",
          howToFix: "Try adding an implementation of '#{name}' or declaring "
              "'#{class}' to be 'abstract'.",
          examples: const [
            """
abstract class I {
  get m;
}
abstract class J {
  get m;
}
class C implements I, J {}
main() => new C();
""",
            """
abstract class I {
  get m;
}
abstract class J {
  get m;
}
class C extends I implements J {}
main() => new C();
"""
          ]),

      MessageKind.UNIMPLEMENTED_EXPLICIT_GETTER: const MessageTemplate(
          MessageKind.UNIMPLEMENTED_EXPLICIT_GETTER,
          "The getter '#{name}' is declared here in class '#{class}'."),

      MessageKind.UNIMPLEMENTED_IMPLICIT_GETTER: const MessageTemplate(
          MessageKind.UNIMPLEMENTED_IMPLICIT_GETTER,
          "The getter '#{name}' is implicitly declared by this field "
          "in class '#{class}'."),

      MessageKind.INVALID_METADATA: const MessageTemplate(
          MessageKind.INVALID_METADATA,
          "A metadata annotation must be either a reference to a compile-time "
          "constant variable or a call to a constant constructor.",
          howToFix:
              "Try using a different constant value or referencing it through a "
              "constant variable.",
          examples: const ['@Object main() {}', '@print main() {}']),

      MessageKind.INVALID_METADATA_GENERIC: const MessageTemplate(
          MessageKind.INVALID_METADATA_GENERIC,
          "A metadata annotation using a constant constructor cannot use type "
          "arguments.",
          howToFix:
              "Try removing the type arguments or referencing the constant "
              "through a constant variable.",
          examples: const [
            '''
class C<T> {
  const C();
}
@C<int>() main() {}
'''
          ]),

      MessageKind.EQUAL_MAP_ENTRY_KEY: const MessageTemplate(
          MessageKind.EQUAL_MAP_ENTRY_KEY,
          "An entry with the same key already exists in the map.",
          howToFix:
              "Try removing the previous entry or changing the key in one "
              "of the entries.",
          examples: const [
            """
main() {
  var m = const {'foo': 1, 'foo': 2};
}"""
          ]),

      MessageKind.BAD_INPUT_CHARACTER: const MessageTemplate(
          MessageKind.BAD_INPUT_CHARACTER,
          "Character U+#{characterHex} isn't allowed here.",
          howToFix: DONT_KNOW_HOW_TO_FIX,
          examples: const [
            """
main() {
  String x = ç;
}
"""
          ]),

      MessageKind.UNTERMINATED_STRING: const MessageTemplate(
          MessageKind.UNTERMINATED_STRING, "String must end with #{quote}.",
          howToFix: DONT_KNOW_HOW_TO_FIX,
          examples: const [
            """
main() {
  return '
;
}
""",
            """
main() {
  return \"
;
}
""",
            """
main() {
  return r'
;
}
""",
            """
main() {
  return r\"
;
}
""",
            """
main() => '''
""",
            """
main() => \"\"\"
""",
            """
main() => r'''
""",
            """
main() => r\"\"\"
"""
          ]),

      MessageKind.UNMATCHED_TOKEN: const MessageTemplate(
          MessageKind.UNMATCHED_TOKEN,
          "Can't find '#{end}' to match '#{begin}'.",
          howToFix: DONT_KNOW_HOW_TO_FIX,
          examples: const [
            "main(",
            "main(){",
            "main(){[}",
            // TODO(ahe): https://github.com/dart-lang/sdk/issues/28495
            // "main(){]}",
          ]),

      MessageKind.UNTERMINATED_TOKEN: const MessageTemplate(
          MessageKind.UNTERMINATED_TOKEN,
          // This is a fall-back message that shouldn't happen.
          "Incomplete token."),

      MessageKind.EXPONENT_MISSING: const MessageTemplate(
          MessageKind.EXPONENT_MISSING,
          "Numbers in exponential notation should always contain an exponent"
          " (an integer number with an optional sign).",
          howToFix: "Make sure there is an exponent, and remove any whitespace "
              "before it.",
          examples: const [
            """
main() {
  var i = 1e;
}
"""
          ]),

      MessageKind.HEX_DIGIT_EXPECTED: const MessageTemplate(
          MessageKind.HEX_DIGIT_EXPECTED,
          "A hex digit (0-9 or A-F) must follow '0x'.",
          howToFix:
              DONT_KNOW_HOW_TO_FIX, // Seems obvious from the error message.
          examples: const [
            """
main() {
  var i = 0x;
}
"""
          ]),

      MessageKind.MALFORMED_STRING_LITERAL: const MessageTemplate(
          MessageKind.MALFORMED_STRING_LITERAL,
          r"A '$' has special meaning inside a string, and must be followed by "
          "an identifier or an expression in curly braces ({}).",
          howToFix: r"Try adding a backslash (\) to escape the '$'.",
          examples: const [
            r"""
main() {
  return '$';
}
""",
            r'''
main() {
  return "$";
}
''',
            r"""
main() {
  return '''$''';
}
""",
            r'''
main() {
  return """$""";
}
'''
          ]),

      MessageKind.UNTERMINATED_COMMENT: const MessageTemplate(
          MessageKind.UNTERMINATED_COMMENT,
          "Comment starting with '/*' must end with '*/'.",
          howToFix: DONT_KNOW_HOW_TO_FIX,
          examples: const [
            r"""
main() {
}
/*"""
          ]),

      MessageKind.MISSING_TOKEN_BEFORE_THIS: const MessageTemplate(
          MessageKind.MISSING_TOKEN_BEFORE_THIS,
          "Expected '#{token}' before this.",
          // Consider the second example below: the parser expects a ')' before
          // 'y', but a ',' would also have worked. We don't have enough
          // information to give a good suggestion.
          howToFix: DONT_KNOW_HOW_TO_FIX,
          examples: const [
            "main() => true ? 1;",
            "main() => foo(x: 1 y: 2);",
          ]),

      MessageKind.MISSING_TOKEN_AFTER_THIS: const MessageTemplate(
          MessageKind.MISSING_TOKEN_AFTER_THIS,
          "Expected '#{token}' after this.",
          // See [MISSING_TOKEN_BEFORE_THIS], we don't have enough information
          // to give a good suggestion.
          howToFix: DONT_KNOW_HOW_TO_FIX,
          examples: const [
            "main(x) {x}",
            """
class S1 {}
class S2 {}
class S3 {}
class A = S1 with S2, S3
main() => new A();
"""
          ]),

      MessageKind.CONSIDER_ANALYZE_ALL: const MessageTemplate(
          MessageKind.CONSIDER_ANALYZE_ALL,
          "Could not find '#{main}'.  Nothing will be analyzed.",
          howToFix: "Try using '--analyze-all' to analyze everything.",
          examples: const ['']),

      MessageKind.MISSING_MAIN: const MessageTemplate(
          MessageKind.MISSING_MAIN, "Could not find '#{main}'.",
          howToFix: "Try adding a method named '#{main}' to your program."
          /* No example, test uses '--analyze-only' which will produce the above
           * message [CONSIDER_ANALYZE_ALL].  An example for a human operator
           * would be an empty file.*/
          ),

      MessageKind.MAIN_NOT_A_FUNCTION: const MessageTemplate(
          MessageKind.MAIN_NOT_A_FUNCTION, "'#{main}' is not a function.",
          howToFix: DONT_KNOW_HOW_TO_FIX, /* Don't state the obvious. */
          examples: const ['var main;']),

      MessageKind.MAIN_WITH_EXTRA_PARAMETER: const MessageTemplate(
          MessageKind.MAIN_WITH_EXTRA_PARAMETER,
          "'#{main}' cannot have more than two parameters.",
          howToFix: DONT_KNOW_HOW_TO_FIX,
          /* Don't state the obvious. */
          examples: const ['main(a, b, c) {}']),

      MessageKind.COMPILER_CRASHED: const MessageTemplate(
          MessageKind.COMPILER_CRASHED,
          "The compiler crashed when compiling this element."),

      MessageKind.PLEASE_REPORT_THE_CRASH:
          const MessageTemplate(MessageKind.PLEASE_REPORT_THE_CRASH, '''
The compiler is broken.

When compiling the above element, the compiler crashed. It is not
possible to tell if this is caused by a problem in your program or
not. Regardless, the compiler should not crash.

The Dart team would greatly appreciate if you would take a moment to
report this problem at http://dartbug.com/new.

Please include the following information:

* the name and version of your operating system,

* the Dart SDK build number (#{buildId}), and

* the entire message you see here (including the full stack trace
  below as well as the source location above).
'''),

      MessageKind.POTENTIAL_MUTATION: const MessageTemplate(
          MessageKind.POTENTIAL_MUTATION,
          "Variable '#{variableName}' is not known to be of type "
          "'#{shownType}' because it is potentially mutated in the scope for "
          "promotion."),

      MessageKind.POTENTIAL_MUTATION_HERE: const MessageTemplate(
          MessageKind.POTENTIAL_MUTATION_HERE,
          "Variable '#{variableName}' is potentially mutated here."),

      MessageKind.POTENTIAL_MUTATION_IN_CLOSURE: const MessageTemplate(
          MessageKind.POTENTIAL_MUTATION_IN_CLOSURE,
          "Variable '#{variableName}' is not known to be of type "
          "'#{shownType}' because it is potentially mutated within a closure."),

      MessageKind.POTENTIAL_MUTATION_IN_CLOSURE_HERE: const MessageTemplate(
          MessageKind.POTENTIAL_MUTATION_IN_CLOSURE_HERE,
          "Variable '#{variableName}' is potentially mutated in a "
          "closure here."),

      MessageKind.ACCESSED_IN_CLOSURE: const MessageTemplate(
          MessageKind.ACCESSED_IN_CLOSURE,
          "Variable '#{variableName}' is not known to be of type "
          "'#{shownType}' because it is accessed by a closure in the scope for "
          "promotion and potentially mutated in the scope of "
          "'#{variableName}'."),

      MessageKind.ACCESSED_IN_CLOSURE_HERE: const MessageTemplate(
          MessageKind.ACCESSED_IN_CLOSURE_HERE,
          "Variable '#{variableName}' is accessed in a closure here."),

      MessageKind.NOT_MORE_SPECIFIC: const MessageTemplate(
          MessageKind.NOT_MORE_SPECIFIC,
          "Variable '#{variableName}' is not shown to have type "
          "'#{shownType}' because '#{shownType}' is not more specific than the "
          "known type '#{knownType}' of '#{variableName}'."),

      MessageKind.NOT_MORE_SPECIFIC_SUBTYPE: const MessageTemplate(
          MessageKind.NOT_MORE_SPECIFIC_SUBTYPE,
          "Variable '#{variableName}' is not shown to have type "
          "'#{shownType}' because '#{shownType}' is not a subtype of the "
          "known type '#{knownType}' of '#{variableName}'."),

      MessageKind.NOT_MORE_SPECIFIC_SUGGESTION: const MessageTemplate(
          MessageKind.NOT_MORE_SPECIFIC_SUGGESTION,
          "Variable '#{variableName}' is not shown to have type "
          "'#{shownType}' because '#{shownType}' is not more specific than the "
          "known type '#{knownType}' of '#{variableName}'.",
          howToFix:
              "Try replacing '#{shownType}' with '#{shownTypeSuggestion}'."),

      MessageKind.NO_COMMON_SUBTYPES: const MessageTemplate(
          MessageKind.NO_COMMON_SUBTYPES,
          "Types '#{left}' and '#{right}' have no common subtypes."),

      MessageKind.HIDDEN_WARNINGS_HINTS: const MessageTemplate(
          MessageKind.HIDDEN_WARNINGS_HINTS,
          "#{warnings} warning(s) and #{hints} hint(s) suppressed in #{uri}."),

      MessageKind.HIDDEN_WARNINGS: const MessageTemplate(
          MessageKind.HIDDEN_WARNINGS,
          "#{warnings} warning(s) suppressed in #{uri}."),

      MessageKind.HIDDEN_HINTS: const MessageTemplate(
          MessageKind.HIDDEN_HINTS, "#{hints} hint(s) suppressed in #{uri}."),

      MessageKind.PREAMBLE: const MessageTemplate(
          MessageKind.PREAMBLE,
          "When run on the command-line, the compiled output might"
          " require a preamble file located in:\n"
          "  <sdk>/lib/_internal/js_runtime/lib/preambles."),

      MessageKind.INVALID_INLINE_FUNCTION_TYPE: const MessageTemplate(
        MessageKind.INVALID_INLINE_FUNCTION_TYPE,
        "Invalid inline function type.",
        howToFix: "Try changing the inline function type (as in 'int f()') to"
            " a prefixed function type using the `Function` keyword (as in "
            "'int Function() f').",
        examples: const [
          "typedef F = Function(int f(String x)); main() { F f; }"
        ],
      ),

      MessageKind.INVALID_SYNC_MODIFIER: const MessageTemplate(
          MessageKind.INVALID_SYNC_MODIFIER, "Invalid modifier 'sync'.",
          howToFix: "Try replacing 'sync' with 'sync*'.",
          examples: const ["main() sync {}"]),

      MessageKind.INVALID_AWAIT_FOR: const MessageTemplate(
          MessageKind.INVALID_AWAIT_FOR,
          "'await' is only supported on for-in loops.",
          howToFix: "Try rewriting the loop as a for-in loop or removing the "
              "'await' keyword.",
          examples: const [
            """
main() async* {
  await for (int i = 0; i < 10; i++) {}
}
"""
          ]),

      MessageKind.ASYNC_AWAIT_NOT_SUPPORTED: const MessageTemplate(
          MessageKind.ASYNC_AWAIT_NOT_SUPPORTED,
          "The async/sync* syntax is not supported on the current platform."),

      MessageKind.ASYNC_MODIFIER_ON_ABSTRACT_METHOD: const MessageTemplate(
          MessageKind.ASYNC_MODIFIER_ON_ABSTRACT_METHOD,
          "The modifier '#{modifier}' is not allowed on an abstract method.",
          options: const ['--enable-async'],
          howToFix: "Try removing the '#{modifier}' modifier or adding a "
              "body to the method.",
          examples: const [
            """
abstract class A {
  method() async;
}
class B extends A {
  method() {}
}
main() {
  A a = new B();
  a.method();
}
"""
          ]),

      MessageKind.ASYNC_MODIFIER_ON_CONSTRUCTOR: const MessageTemplate(
          MessageKind.ASYNC_MODIFIER_ON_CONSTRUCTOR,
          "The modifier '#{modifier}' is not allowed on constructors.",
          options: const ['--enable-async'],
          howToFix: "Try removing the '#{modifier}' modifier.",
          examples: const [
            """
class A {
  A() async;
}
main() => new A();""",
            """
class A {
  A();
  factory A.a() async* {}
}
main() => new A.a();"""
          ]),

      MessageKind.ASYNC_MODIFIER_ON_SETTER: const MessageTemplate(
          MessageKind.ASYNC_MODIFIER_ON_SETTER,
          "The modifier '#{modifier}' is not allowed on setters.",
          options: const ['--enable-async'],
          howToFix: "Try removing the '#{modifier}' modifier.",
          examples: const [
            """
class A {
  set foo(v) async {}
}
main() => new A().foo = 0;"""
          ]),

      MessageKind.YIELDING_MODIFIER_ON_ARROW_BODY: const MessageTemplate(
          MessageKind.YIELDING_MODIFIER_ON_ARROW_BODY,
          "The modifier '#{modifier}' is not allowed on methods implemented "
          "using '=>'.",
          options: const ['--enable-async'],
          howToFix: "Try removing the '#{modifier}' modifier or implementing "
              "the method body using a block: '{ ... }'.",
          examples: const ["main() sync* => null;", "main() async* => null;"]),

      // TODO(johnniwinther): Check for 'async' as identifier.
      MessageKind.ASYNC_KEYWORD_AS_IDENTIFIER: const MessageTemplate(
          MessageKind.ASYNC_KEYWORD_AS_IDENTIFIER,
          "'#{keyword}' cannot be used as an identifier in a function body "
          "marked with '#{modifier}'.",
          options: const ['--enable-async'],
          howToFix: "Try removing the '#{modifier}' modifier or renaming the "
              "identifier.",
          examples: const [
            """
main() async {
 var await;
}""",
            """
main() async* {
 var yield;
}""",
            """
main() sync* {
 var yield;
}"""
          ]),

      MessageKind.NATIVE_NOT_SUPPORTED: const MessageTemplate(
          MessageKind.NATIVE_NOT_SUPPORTED,
          "'native' modifier is not supported.",
          howToFix: "Try removing the 'native' implementation or analyzing the "
              "code with the --allow-native-extensions option.",
          examples: const [
            """
main() native "Main";
"""
          ]),

      MessageKind.DART_EXT_NOT_SUPPORTED: const MessageTemplate(
          MessageKind.DART_EXT_NOT_SUPPORTED,
          "The 'dart-ext' scheme is not supported.",
          howToFix: "Try analyzing the code with the --allow-native-extensions "
              "option.",
          examples: const [
            """
import 'dart-ext:main';

main() {}
"""
          ]),

      MessageKind.LIBRARY_TAG_MUST_BE_FIRST: const MessageTemplate(
          MessageKind.LIBRARY_TAG_MUST_BE_FIRST,
          "The library declaration should come before other declarations.",
          howToFix: "Try moving the declaration to the top of the file.",
          examples: const [
            """
import 'dart:core';
library foo;
main() {}
""",
          ]),

      MessageKind.ONLY_ONE_LIBRARY_TAG: const MessageTemplate(
          MessageKind.ONLY_ONE_LIBRARY_TAG,
          "There can only be one library declaration.",
          howToFix: "Try removing all other library declarations.",
          examples: const [
            """
library foo;
library bar;
main() {}
""",
            """
library foo;
import 'dart:core';
library bar;
main() {}
""",
          ]),

      MessageKind.IMPORT_BEFORE_PARTS: const MessageTemplate(
          MessageKind.IMPORT_BEFORE_PARTS,
          "Import declarations should come before parts.",
          howToFix: "Try moving this import further up in the file.",
          examples: const [
            const <String, String>{
              'main.dart': """
library test.main;
part 'part.dart';
import 'dart:core';
main() {}
""",
              'part.dart': """
part of test.main;
""",
            }
          ]),

      MessageKind.EXPORT_BEFORE_PARTS: const MessageTemplate(
          MessageKind.EXPORT_BEFORE_PARTS,
          "Export declarations should come before parts.",
          howToFix: "Try moving this export further up in the file.",
          examples: const [
            const <String, String>{
              'main.dart': """
library test.main;
part 'part.dart';
export 'dart:core';
main() {}
""",
              'part.dart': """
part of test.main;
""",
            }
          ]),

      //////////////////////////////////////////////////////////////////////////////
      // Patch errors start.
      //////////////////////////////////////////////////////////////////////////////

      MessageKind.PATCH_TYPE_VARIABLES_MISMATCH: const MessageTemplate(
          MessageKind.PATCH_TYPE_VARIABLES_MISMATCH,
          "Patch type variables do not match "
          "type variables on origin method '#{methodName}'."),

      MessageKind.PATCH_RETURN_TYPE_MISMATCH: const MessageTemplate(
          MessageKind.PATCH_RETURN_TYPE_MISMATCH,
          "Patch return type '#{patchReturnType}' does not match "
          "'#{originReturnType}' on origin method '#{methodName}'."),

      MessageKind.PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH: const MessageTemplate(
          MessageKind.PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH,
          "Required parameter count of patch method "
          "(#{patchParameterCount}) does not match parameter count on origin "
          "method '#{methodName}' (#{originParameterCount})."),

      MessageKind.PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH: const MessageTemplate(
          MessageKind.PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH,
          "Optional parameter count of patch method "
          "(#{patchParameterCount}) does not match parameter count on origin "
          "method '#{methodName}' (#{originParameterCount})."),

      MessageKind.PATCH_OPTIONAL_PARAMETER_NAMED_MISMATCH:
          const MessageTemplate(
              MessageKind.PATCH_OPTIONAL_PARAMETER_NAMED_MISMATCH,
              "Optional parameters of origin and patch method "
              "'#{methodName}' must both be either named or positional."),

      MessageKind.PATCH_PARAMETER_MISMATCH: const MessageTemplate(
          MessageKind.PATCH_PARAMETER_MISMATCH,
          "Patch method parameter '#{patchParameter}' does not match "
          "'#{originParameter}' on origin method '#{methodName}'."),

      MessageKind.PATCH_PARAMETER_TYPE_MISMATCH: const MessageTemplate(
          MessageKind.PATCH_PARAMETER_TYPE_MISMATCH,
          "Patch method parameter '#{parameterName}' type "
          "'#{patchParameterType}' does not match '#{originParameterType}' on "
          "origin method '#{methodName}'."),

      MessageKind.PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION: const MessageTemplate(
          MessageKind.PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION,
          "External method without an implementation."),

      MessageKind.PATCH_POINT_TO_FUNCTION: const MessageTemplate(
          MessageKind.PATCH_POINT_TO_FUNCTION,
          "This is the function patch '#{functionName}'."),

      MessageKind.PATCH_POINT_TO_CLASS: const MessageTemplate(
          MessageKind.PATCH_POINT_TO_CLASS,
          "This is the class patch '#{className}'."),

      MessageKind.PATCH_POINT_TO_GETTER: const MessageTemplate(
          MessageKind.PATCH_POINT_TO_GETTER,
          "This is the getter patch '#{getterName}'."),

      MessageKind.PATCH_POINT_TO_SETTER: const MessageTemplate(
          MessageKind.PATCH_POINT_TO_SETTER,
          "This is the setter patch '#{setterName}'."),

      MessageKind.PATCH_POINT_TO_CONSTRUCTOR: const MessageTemplate(
          MessageKind.PATCH_POINT_TO_CONSTRUCTOR,
          "This is the constructor patch '#{constructorName}'."),

      MessageKind.PATCH_POINT_TO_PARAMETER: const MessageTemplate(
          MessageKind.PATCH_POINT_TO_PARAMETER,
          "This is the patch parameter '#{parameterName}'."),

      MessageKind.PATCH_NON_EXISTING: const MessageTemplate(
          MessageKind.PATCH_NON_EXISTING,
          "Origin does not exist for patch '#{name}'."),

      // TODO(ahe): Eventually, this error should be removed as it will be
      // handled by the regular parser.
      MessageKind.PATCH_NONPATCHABLE: const MessageTemplate(
          MessageKind.PATCH_NONPATCHABLE,
          "Only classes and functions can be patched."),

      MessageKind.PATCH_NON_EXTERNAL: const MessageTemplate(
          MessageKind.PATCH_NON_EXTERNAL,
          "Only external functions can be patched."),

      MessageKind.PATCH_NON_CLASS: const MessageTemplate(
          MessageKind.PATCH_NON_CLASS,
          "Patching non-class with class patch '#{className}'."),

      MessageKind.PATCH_NON_GETTER: const MessageTemplate(
          MessageKind.PATCH_NON_GETTER,
          "Cannot patch non-getter '#{name}' with getter patch."),

      MessageKind.PATCH_NO_GETTER: const MessageTemplate(
          MessageKind.PATCH_NO_GETTER,
          "No getter found for getter patch '#{getterName}'."),

      MessageKind.PATCH_NON_SETTER: const MessageTemplate(
          MessageKind.PATCH_NON_SETTER,
          "Cannot patch non-setter '#{name}' with setter patch."),

      MessageKind.PATCH_NO_SETTER: const MessageTemplate(
          MessageKind.PATCH_NO_SETTER,
          "No setter found for setter patch '#{setterName}'."),

      MessageKind.PATCH_NON_CONSTRUCTOR: const MessageTemplate(
          MessageKind.PATCH_NON_CONSTRUCTOR,
          "Cannot patch non-constructor with constructor patch "
          "'#{constructorName}'."),

      MessageKind.PATCH_NON_FUNCTION: const MessageTemplate(
          MessageKind.PATCH_NON_FUNCTION,
          "Cannot patch non-function with function patch "
          "'#{functionName}'."),

      MessageKind.INJECTED_PUBLIC_MEMBER: const MessageTemplate(
          MessageKind.INJECTED_PUBLIC_MEMBER,
          "Non-patch members in patch libraries must be private."),

      MessageKind.EXTERNAL_WITH_BODY: const MessageTemplate(
          MessageKind.EXTERNAL_WITH_BODY,
          "External function '#{functionName}' cannot have a function body.",
          howToFix:
              "Try removing the 'external' modifier or the function body.",
          examples: const [
            """
import 'package:js/js.dart';
@JS()
external foo() => 0;
main() => foo();
""",
            """
import 'package:js/js.dart';
@JS()
external foo() {}
main() => foo();
"""
          ]),

      //////////////////////////////////////////////////////////////////////////////
      // Patch errors end.
      //////////////////////////////////////////////////////////////////////////////

      MessageKind.IMPORT_EXPERIMENTAL_MIRRORS: const MessageTemplate(
          MessageKind.IMPORT_EXPERIMENTAL_MIRRORS,
          r'''

****************************************************************
* WARNING: dart:mirrors support in dart2js is experimental,
*          and not recommended.
*          This implementation of mirrors is incomplete,
*          and often greatly increases the size of the generated
*          JavaScript code.
*
* Your app imports dart:mirrors via:'''
          '''
$IMPORT_EXPERIMENTAL_MIRRORS_PADDING#{importChain}
*
* You can disable this message by using the --enable-experimental-mirrors
* command-line flag.
*
* To learn what to do next, please visit:
*    http://dartlang.org/dart2js-reflection
****************************************************************
'''),

      MessageKind.DISALLOWED_LIBRARY_IMPORT: const MessageTemplate(
          MessageKind.DISALLOWED_LIBRARY_IMPORT,
          '''
Your app imports the unsupported library '#{uri}' via:
'''
          '''
$DISALLOWED_LIBRARY_IMPORT_PADDING#{importChain}

Use the --categories option to support import of '#{uri}'.
'''),

      MessageKind.MIRRORS_LIBRARY_NOT_SUPPORT_BY_BACKEND: const MessageTemplate(
          MessageKind.MIRRORS_LIBRARY_NOT_SUPPORT_BY_BACKEND,
          """
dart:mirrors library is not supported when using this backend.

Your app imports dart:mirrors via:"""
          """
$MIRRORS_NOT_SUPPORTED_BY_BACKEND_PADDING#{importChain}"""),

      MessageKind.DIRECTLY_THROWING_NSM: const MessageTemplate(
          MessageKind.DIRECTLY_THROWING_NSM,
          "This 'noSuchMethod' implementation is guaranteed to throw an "
          "exception. The generated code will be smaller if it is "
          "rewritten.",
          howToFix: "Rewrite to "
              "'noSuchMethod(Invocation i) => super.noSuchMethod(i);'."),

      MessageKind.COMPLEX_THROWING_NSM: const MessageTemplate(
          MessageKind.COMPLEX_THROWING_NSM,
          "This 'noSuchMethod' implementation is guaranteed to throw an "
          "exception. The generated code will be smaller and the compiler "
          "will be able to perform more optimizations if it is rewritten.",
          howToFix: "Rewrite to "
              "'noSuchMethod(Invocation i) => super.noSuchMethod(i);'."),

      MessageKind.COMPLEX_RETURNING_NSM: const MessageTemplate(
          MessageKind.COMPLEX_RETURNING_NSM,
          "Overriding 'noSuchMethod' causes the compiler to generate "
          "more code and prevents the compiler from doing some optimizations.",
          howToFix: "Consider removing this 'noSuchMethod' implementation."),

      MessageKind.UNRECOGNIZED_VERSION_OF_LOOKUP_MAP: const MessageTemplate(
          MessageKind.UNRECOGNIZED_VERSION_OF_LOOKUP_MAP,
          "Unsupported version of package:lookup_map.",
          howToFix: DONT_KNOW_HOW_TO_FIX),

      MessageKind.DUPLICATE_SERIALIZED_LIBRARY: const MessageTemplate(
          MessageKind.DUPLICATE_SERIALIZED_LIBRARY,
          "Library '#{libraryUri}' found in both '#{sourceUri1}' and "
          "'#{sourceUri2}'."),
    }); // End of TEMPLATES.

  /// Padding used before and between import chains in the message for
  /// [MessageKind.IMPORT_EXPERIMENTAL_MIRRORS].
  static const String IMPORT_EXPERIMENTAL_MIRRORS_PADDING = '\n*   ';

  /// Padding used before and between import chains in the message for
  /// [MessageKind.MIRRORS_LIBRARY_NOT_SUPPORT_BY_BACKEND].
  static const String MIRRORS_NOT_SUPPORTED_BY_BACKEND_PADDING = '\n   ';

  /// Padding used before and between import chains in the message for
  /// [MessageKind.DISALLOWED_LIBRARY_IMPORT].
  static const String DISALLOWED_LIBRARY_IMPORT_PADDING = '\n  ';

  toString() => template;

  Message message([Map arguments = const {}, bool terse = false]) {
    return new Message(this, arguments, terse);
  }

  bool get hasHowToFix => howToFix != null && howToFix != DONT_KNOW_HOW_TO_FIX;
}

class Message {
  final MessageTemplate template;
  final Map arguments;
  final bool terse;
  String message;

  Message(this.template, this.arguments, this.terse) {
    assert(() {
      computeMessage();
      return true;
    });
  }

  MessageKind get kind => template.kind;

  String computeMessage() {
    if (message == null) {
      message = template.template;
      arguments.forEach((key, value) {
        message = message.replaceAll('#{${key}}', convertToString(value));
      });
      assert(
          kind == MessageKind.GENERIC ||
              !message.contains(new RegExp(r'#\{.+\}')),
          failedAt(CURRENT_ELEMENT_SPANNABLE,
              'Missing arguments in error message: "$message"'));
      if (!terse && template.hasHowToFix) {
        String howToFix = template.howToFix;
        arguments.forEach((key, value) {
          howToFix = howToFix.replaceAll('#{${key}}', convertToString(value));
        });
        message = '$message\n$howToFix';
      }
    }
    return message;
  }

  String toString() {
    return computeMessage();
  }

  bool operator ==(other) {
    if (other is! Message) return false;
    return (template == other.template) && (toString() == other.toString());
  }

  int get hashCode => throw new UnsupportedError('Message.hashCode');

  static String convertToString(value) {
    if (value is ErrorToken) {
      // Shouldn't happen.
      return value.assertionMessage;
    } else if (value is Token) {
      value = value.lexeme;
    }
    return '$value';
  }
}
