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

import 'generated/shared_messages.dart' as shared_messages;
import '../commandline_options.dart';
import '../options.dart';
import 'invariant.dart' show failedAt;
import 'spannable.dart' show CURRENT_ELEMENT_SPANNABLE;

const DONT_KNOW_HOW_TO_FIX = "Computer says no!";

/// Keys for the [MessageTemplate]s.
enum MessageKind {
  ABSTRACT_GETTER,
  CANNOT_RESOLVE,
  COMPILER_CRASHED,
  COMPLEX_RETURNING_NSM,
  COMPLEX_THROWING_NSM,
  CONST_CONSTRUCTOR_WITH_BODY,
  CONST_FACTORY,
  CONSTRUCTOR_WITH_RETURN_TYPE,
  CYCLIC_COMPILE_TIME_CONSTANTS,
  DIRECTLY_THROWING_NSM,
  EQUAL_MAP_ENTRY_KEY,
  EQUAL_SET_ENTRY,
  EXTRANEOUS_MODIFIER,
  EXTRANEOUS_MODIFIER_REPLACE,
  FORIN_NOT_ASSIGNABLE,
  GENERIC,
  HIDDEN_HINTS,
  HIDDEN_WARNINGS,
  HIDDEN_WARNINGS_HINTS,
  IMPLICIT_JS_INTEROP_FIELD_NOT_SUPPORTED,
  INVALID_ASSERT_VALUE,
  INVALID_ASSERT_VALUE_MESSAGE,
  INVALID_BOOL_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE,
  INVALID_CONSTANT_CAST,
  INVALID_CONSTANT_ADD_TYPES,
  INVALID_CONSTANT_BINARY_INT_TYPE,
  INVALID_CONSTANT_BINARY_NUM_TYPE,
  INVALID_CONSTANT_BINARY_PRIMITIVE_TYPE,
  INVALID_CONSTANT_COMPLEMENT_TYPE,
  INVALID_CONSTANT_CONDITIONAL_TYPE,
  INVALID_CONSTANT_CONSTRUCTOR,
  INVALID_CONSTANT_DIV,
  INVALID_CONSTANT_INDEX,
  INVALID_CONSTANT_INTERPOLATION_TYPE,
  INVALID_CONSTANT_NEGATE_TYPE,
  INVALID_CONSTANT_NOT_TYPE,
  INVALID_CONSTANT_STRING_ADD_TYPE,
  INVALID_CONSTANT_NUM_ADD_TYPE,
  INVALID_CONSTANT_STRING_LENGTH_TYPE,
  INVALID_CONSTANT_SHIFT,
  INVALID_FROM_ENVIRONMENT_NAME_TYPE,
  INVALID_INT_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE,
  INVALID_LOGICAL_AND_OPERAND_TYPE,
  INVALID_LOGICAL_OR_OPERAND_TYPE,
  INVALID_METADATA,
  INVALID_METADATA_GENERIC,
  INVALID_PACKAGE_CONFIG,
  INVALID_PACKAGE_URI,
  INVALID_STRING_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE,
  JS_INTEROP_FIELD_NOT_SUPPORTED,
  JS_INTEROP_NON_EXTERNAL_MEMBER,
  JS_OBJECT_LITERAL_CONSTRUCTOR_WITH_POSITIONAL_ARGUMENTS,
  JS_PLACEHOLDER_CAPTURE,
  LIBRARY_NOT_FOUND,
  MIRRORS_LIBRARY_NOT_SUPPORT_WITH_CFE,
  MISSING_EXPRESSION_IN_THROW,
  NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS,
  NO_SUCH_SUPER_MEMBER,
  NON_NATIVE_EXTERNAL,
  NOT_A_COMPILE_TIME_CONSTANT,
  NOT_ASSIGNABLE,
  PLEASE_REPORT_THE_CRASH,
  PREAMBLE,
  RETHROW_OUTSIDE_CATCH,
  RETURN_IN_GENERATIVE_CONSTRUCTOR,
  RETURN_IN_GENERATOR,
  RUNTIME_TYPE_TO_STRING,
  STRING_EXPECTED,
  UNDEFINED_GETTER,
  UNDEFINED_INSTANCE_GETTER_BUT_SETTER,
  UNDEFINED_METHOD,
  UNDEFINED_OPERATOR,
  UNDEFINED_SETTER,
  UNDEFINED_STATIC_GETTER_BUT_SETTER,
  UNDEFINED_STATIC_SETTER_BUT_GETTER,
  UNDEFINED_SUPER_SETTER,
  WRONG_ARGUMENT_FOR_JS,
  WRONG_ARGUMENT_FOR_JS_FIRST,
  WRONG_ARGUMENT_FOR_JS_SECOND,
  WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT,
  // TODO(32557): Remove these when issue 32557 is fixed.
  SWITCH_CASE_FORBIDDEN,
  SWITCH_CASE_VALUE_OVERRIDES_EQUALS,
  SWITCH_CASE_TYPES_NOT_EQUAL,
  SWITCH_CASE_TYPES_NOT_EQUAL_CASE,
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

  ///  Examples will be checked by
  ///  pkg/compiler/test/message_kind_test.dart.
  ///
  ///  An example is either a String containing the example source code or a Map
  ///  from filenames to source code. In the latter case, the filename for the
  ///  main library code must be 'main.dart'.
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

      MessageKind.CANNOT_RESOLVE: const MessageTemplate(
          MessageKind.CANNOT_RESOLVE, "Cannot resolve '#{name}'."),

      MessageKind.NOT_A_COMPILE_TIME_CONSTANT: const MessageTemplate(
          MessageKind.NOT_A_COMPILE_TIME_CONSTANT,
          "Not a compile-time constant."),

      MessageKind.CYCLIC_COMPILE_TIME_CONSTANTS: const MessageTemplate(
          MessageKind.CYCLIC_COMPILE_TIME_CONSTANTS,
          "Cycle in the compile-time constant computation."),

      MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER: const MessageTemplate(
          MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER,
          "Cannot resolve setter."),

      MessageKind.STRING_EXPECTED: const MessageTemplate(
          MessageKind.STRING_EXPECTED,
          "Expected a 'String', but got an instance of '#{type}'."),

      MessageKind.JS_INTEROP_NON_EXTERNAL_MEMBER: const MessageTemplate(
          MessageKind.JS_INTEROP_NON_EXTERNAL_MEMBER,
          "Js-interop members must be 'external'."),

      MessageKind.IMPLICIT_JS_INTEROP_FIELD_NOT_SUPPORTED:
          const MessageTemplate(
              MessageKind.IMPLICIT_JS_INTEROP_FIELD_NOT_SUPPORTED,
              "Fields in js-interop classes are not supported.",
              howToFix: "Try replacing the field with an "
                  "external getter and/or setter."),
      MessageKind.JS_INTEROP_FIELD_NOT_SUPPORTED: const MessageTemplate(
          MessageKind.JS_INTEROP_FIELD_NOT_SUPPORTED,
          "Field can't be marked as js-interop.",
          howToFix: "Try replacing the field with an "
              "external getter and/or setter."),

      MessageKind.LIBRARY_NOT_FOUND: const MessageTemplate(
          MessageKind.LIBRARY_NOT_FOUND, "Library not found '#{resolvedUri}'."),

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

      MessageKind.EQUAL_SET_ENTRY: const MessageTemplate(
          MessageKind.EQUAL_SET_ENTRY, "An entry appears twice in the set.",
          howToFix: "Try removing one of the entries.",
          examples: const [
            """
main() {
  var m = const {'foo', 'bar', 'foo'};
}"""
          ]),

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

      MessageKind.INVALID_CONSTANT_CONDITIONAL_TYPE: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_CONDITIONAL_TYPE,
          "`#{constant}` of type '#{type}' is not a valid constant condition. "
          "Must be a value of type 'bool'."),

      MessageKind.INVALID_CONSTANT_INTERPOLATION_TYPE: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_INTERPOLATION_TYPE,
          "`#{constant}` of type '#{type}' is not valid in constant string "
          "interpolation. Must be a value of type 'bool', 'int', 'double', "
          "or 'String'."),

      MessageKind.INVALID_CONSTANT_BINARY_PRIMITIVE_TYPE: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_BINARY_PRIMITIVE_TYPE,
          "`#{constant}` of type '#{type}' is not a valid operand of a "
          "constant binary #{operator} expression. Must be a value of type "
          "'bool', 'int', 'double', 'String', or 'Null'."),

      MessageKind.INVALID_CONSTANT_STRING_ADD_TYPE: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_STRING_ADD_TYPE,
          "`#{constant}` of type '#{type}' is not a valid operand of a "
          "constant binary + expression on 'String'. Must be a value of type "
          "'String'."),

      MessageKind.INVALID_CONSTANT_STRING_LENGTH_TYPE: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_STRING_LENGTH_TYPE,
          "`#{constant}` of type '#{type}' is not a valid operand for a "
          ".length expression. Must be a value of type 'String'."),

      MessageKind.INVALID_CONSTANT_SHIFT: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_SHIFT,
          "Shift amount must be non-negative in "
          "`#{left} #{operator} #{right}`."),

      MessageKind.INVALID_CONSTANT_DIV: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_DIV,
          "Divisor must be non-zero in `#{left} #{operator} #{right}`."),

      MessageKind.INVALID_CONSTANT_NUM_ADD_TYPE: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_NUM_ADD_TYPE,
          "`#{constant}` of type '#{type}' is not a valid operand of a "
          "constant binary + expression on 'num'. Must be a value of type "
          "'int' or 'double'."),

      MessageKind.INVALID_CONSTANT_CAST: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_CAST,
          "`#{constant}` of type '#{type}' is not a subtype of #{castType}."),

      MessageKind.INVALID_CONSTANT_ADD_TYPES: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_ADD_TYPES,
          "`#{leftConstant}` of type '#{leftType}' and "
          "`#{rightConstant}` of type '#{rightType}' are not valid operands "
          "of a constant binary + expression. Must both be either of "
          "type 'String', or of types 'int' or 'double'."),

      MessageKind.INVALID_CONSTANT_BINARY_NUM_TYPE: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_BINARY_NUM_TYPE,
          "`#{constant}` of type '#{type}' is not a valid operand of a "
          "constant binary #{operator} expression. Must be a value of type "
          "'int' or 'double'."),

      MessageKind.INVALID_CONSTANT_BINARY_INT_TYPE: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_BINARY_INT_TYPE,
          "`#{constant}` of type '#{type}' is not a valid operand of a "
          "constant binary #{operator} expression. Must be a value of type "
          "'int'."),

      MessageKind.INVALID_CONSTANT_NOT_TYPE: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_NOT_TYPE,
          "`#{constant}` of type '#{type}' is not a valid operand of a "
          "constant unary #{operator} expression. Must be a value of type "
          "'bool'."),

      MessageKind.INVALID_CONSTANT_NEGATE_TYPE: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_NEGATE_TYPE,
          "`#{constant}` of type '#{type}' is not a valid operand of a "
          "constant unary #{operator} expression. Must be a value of type "
          "'int' or 'double'."),

      MessageKind.INVALID_CONSTANT_COMPLEMENT_TYPE: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_COMPLEMENT_TYPE,
          "`#{constant}` of type '#{type}' is not a valid operand of a "
          "constant unary #{operator} expression. Must be a value of type "
          "'int'."),

      MessageKind.INVALID_CONSTANT_INDEX: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_INDEX,
          "Index expressions are not allowed in constant expressions."),

      MessageKind.INVALID_FROM_ENVIRONMENT_NAME_TYPE: const MessageTemplate(
          MessageKind.INVALID_FROM_ENVIRONMENT_NAME_TYPE,
          "`#{constant}` of type '#{type}' is not a valid environment name "
          "constant. Must be a value of type 'String'."),

      MessageKind.INVALID_BOOL_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE:
          const MessageTemplate(
              MessageKind.INVALID_BOOL_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE,
              "`#{constant}` of type '#{type}' is not a valid "
              "`bool.fromEnvironment` default value constant. "
              "Must be a value of type 'bool' or `null`."),

      MessageKind.INVALID_INT_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE:
          const MessageTemplate(
              MessageKind.INVALID_INT_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE,
              "`#{constant}` of type '#{type}' is not a valid "
              "`int.fromEnvironment` default value constant. "
              "Must be a value of type 'int' or `null`."),

      MessageKind.INVALID_STRING_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE:
          const MessageTemplate(
              MessageKind.INVALID_STRING_FROM_ENVIRONMENT_DEFAULT_VALUE_TYPE,
              "`#{constant}` of type '#{type}' is not a valid "
              "`String.fromEnvironment` default value constant. "
              "Must be a value of type 'String' or `null`."),

      MessageKind.INVALID_LOGICAL_AND_OPERAND_TYPE: const MessageTemplate(
          MessageKind.INVALID_LOGICAL_AND_OPERAND_TYPE,
          "`#{constant}` of type '#{type}' is not a valid logical and operand. "
          "Must be a value of type 'bool'."),

      MessageKind.INVALID_LOGICAL_OR_OPERAND_TYPE: const MessageTemplate(
          MessageKind.INVALID_LOGICAL_OR_OPERAND_TYPE,
          "`#{constant}` of type '#{type}' is not a valid logical or operand. "
          "Must be a value of type 'bool'."),

      MessageKind.INVALID_CONSTANT_CONSTRUCTOR: const MessageTemplate(
          MessageKind.INVALID_CONSTANT_CONSTRUCTOR,
          "Constructor '#{constructorName}' is not a valid constant "
          "constructor."),

      MessageKind.INVALID_ASSERT_VALUE: const MessageTemplate(
          MessageKind.INVALID_ASSERT_VALUE, "Assertion '#{assertion}' failed."),

      MessageKind.INVALID_ASSERT_VALUE_MESSAGE: const MessageTemplate(
          MessageKind.INVALID_ASSERT_VALUE_MESSAGE,
          "Assertion failed: #{message}"),

      MessageKind.MIRRORS_LIBRARY_NOT_SUPPORT_WITH_CFE: const MessageTemplate(
          MessageKind.MIRRORS_LIBRARY_NOT_SUPPORT_WITH_CFE, """
dart2js no longer supports the dart:mirrors library.

APIs from this library will throw a runtime error at this time, but they will
become a compile-time error in the future."""),

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

      MessageKind.RUNTIME_TYPE_TO_STRING: const MessageTemplate(
          MessageKind.RUNTIME_TYPE_TO_STRING,
          "Using '.runtimeType.toString()' causes the compiler to generate "
          "more code because it needs to preserve type arguments on "
          "generic classes, even if they are not necessary elsewhere.",
          howToFix: "If used only for debugging, consider using option "
              "${Flags.laxRuntimeTypeToString} to reduce the code size "
              "impact."),

      MessageKind.NON_NATIVE_EXTERNAL: const MessageTemplate(
          MessageKind.NON_NATIVE_EXTERNAL,
          "Only external js-interop functions are supported.",
          howToFix:
              "Try removing 'external' keyword or annotating the function "
              "as a js-interop function."),

      MessageKind.NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS: const MessageTemplate(
          MessageKind.NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS,
          "Native non-instance members are only allowed in native classes."),

      // TODO(32557): Remove these when issue 32557 is fixed.
      MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS: const MessageTemplate(
          MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS,
          "'case' expression type '#{type}' overrides 'operator =='."),
      MessageKind.SWITCH_CASE_FORBIDDEN: const MessageTemplate(
          MessageKind.SWITCH_CASE_FORBIDDEN,
          "'case' expression may not be of type '#{type}'."),
      MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL: const MessageTemplate(
          MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL,
          "'case' expressions do not all have type '#{type}'."),
      MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL_CASE: const MessageTemplate(
          MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL_CASE,
          "'case' expression of type '#{type}'."),
    }); // End of TEMPLATES.

  @override
  String toString() => template;

  Message message(Map<String, String> arguments, CompilerOptions options) {
    return new Message(this, arguments, options);
  }

  bool get hasHowToFix => howToFix != null && howToFix != DONT_KNOW_HOW_TO_FIX;
}

class Message {
  final MessageTemplate template;
  final Map<String, String> arguments;
  final CompilerOptions _options;
  bool get terse => _options?.terseDiagnostics ?? false;
  String message;

  Message(this.template, this.arguments, this._options) {
    assert(() {
      computeMessage();
      return true;
    }());
  }

  MessageKind get kind => template.kind;

  String computeMessage() {
    if (message == null) {
      message = template.template;
      arguments.forEach((String key, String value) {
        message = message.replaceAll('#{$key}', value);
      });
      assert(
          kind == MessageKind.GENERIC ||
              !message.contains(new RegExp(r'#\{.+\}')),
          failedAt(CURRENT_ELEMENT_SPANNABLE,
              'Missing arguments in error message: "$message"'));
      if (!terse && template.hasHowToFix) {
        String howToFix = template.howToFix;
        arguments.forEach((String key, String value) {
          howToFix = howToFix.replaceAll('#{$key}', value);
        });
        message = '$message\n$howToFix';
      }
    }
    return message;
  }

  @override
  String toString() {
    return computeMessage();
  }

  @override
  bool operator ==(other) {
    if (other is! Message) return false;
    return (template == other.template) && (toString() == other.toString());
  }

  @override
  int get hashCode => throw new UnsupportedError('Message.hashCode');
}
