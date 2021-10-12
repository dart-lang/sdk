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

import '../commandline_options.dart';
import '../options.dart';
import 'invariant.dart' show failedAt;
import 'spannable.dart' show CURRENT_ELEMENT_SPANNABLE;

const DONT_KNOW_HOW_TO_FIX = "Computer says no!";

/// Keys for the [MessageTemplate]s.
enum MessageKind {
  COMPILER_CRASHED,
  COMPLEX_RETURNING_NSM,
  COMPLEX_THROWING_NSM,
  DIRECTLY_THROWING_NSM,
  GENERIC,
  HIDDEN_HINTS,
  HIDDEN_WARNINGS,
  HIDDEN_WARNINGS_HINTS,
  INVALID_METADATA,
  INVALID_METADATA_GENERIC,
  JS_PLACEHOLDER_CAPTURE,
  NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS,
  NON_NATIVE_EXTERNAL,
  PLEASE_REPORT_THE_CRASH,
  PREAMBLE,
  RUNTIME_TYPE_TO_STRING,
  STRING_EXPECTED,
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
      {this.howToFix, this.examples, this.options = const <String>[]});

  /// All templates used by the compiler.
  ///
  /// The map is complete mapping from [MessageKind] to their corresponding
  /// [MessageTemplate].
  static const Map<MessageKind, MessageTemplate> TEMPLATES = {
    /// Do not use this. It is here for legacy and debugging. It violates item
    /// 4 of the guide lines for error messages in the beginning of the file.
    MessageKind.GENERIC: MessageTemplate(MessageKind.GENERIC, '#{text}'),

    MessageKind.STRING_EXPECTED: MessageTemplate(MessageKind.STRING_EXPECTED,
        "Expected a 'String', but got an instance of '#{type}'."),

    MessageKind.JS_PLACEHOLDER_CAPTURE: MessageTemplate(
        MessageKind.JS_PLACEHOLDER_CAPTURE,
        "JS code must not use '#' placeholders inside functions.",
        howToFix: "Use an immediately called JavaScript function to capture the"
            " the placeholder values as JavaScript function parameters."),

    MessageKind.WRONG_ARGUMENT_FOR_JS: MessageTemplate(
        MessageKind.WRONG_ARGUMENT_FOR_JS,
        "JS expression must take two or more arguments."),

    MessageKind.WRONG_ARGUMENT_FOR_JS_FIRST: MessageTemplate(
        MessageKind.WRONG_ARGUMENT_FOR_JS_FIRST,
        "JS expression must take two or more arguments."),

    MessageKind.WRONG_ARGUMENT_FOR_JS_SECOND: MessageTemplate(
        MessageKind.WRONG_ARGUMENT_FOR_JS_SECOND,
        "JS second argument must be a string literal."),

    MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT: MessageTemplate(
        MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT,
        "Argument for 'JS_INTERCEPTOR_CONSTANT' must be a type constant."),

    MessageKind.INVALID_METADATA: MessageTemplate(
        MessageKind.INVALID_METADATA,
        "A metadata annotation must be either a reference to a compile-time "
        "constant variable or a call to a constant constructor.",
        howToFix:
            "Try using a different constant value or referencing it through a "
            "constant variable.",
        examples: ['@Object main() {}', '@print main() {}']),

    MessageKind.INVALID_METADATA_GENERIC: MessageTemplate(
        MessageKind.INVALID_METADATA_GENERIC,
        "A metadata annotation using a constant constructor cannot use type "
        "arguments.",
        howToFix: "Try removing the type arguments or referencing the constant "
            "through a constant variable.",
        examples: [
          '''
class C<T> {
  const C();
}
@C<int>() main() {}
'''
        ]),

    MessageKind.COMPILER_CRASHED: MessageTemplate(MessageKind.COMPILER_CRASHED,
        "The compiler crashed when compiling this element."),

    MessageKind.PLEASE_REPORT_THE_CRASH:
        MessageTemplate(MessageKind.PLEASE_REPORT_THE_CRASH, '''
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

    MessageKind.HIDDEN_WARNINGS_HINTS: MessageTemplate(
        MessageKind.HIDDEN_WARNINGS_HINTS,
        "#{warnings} warning(s) and #{hints} hint(s) suppressed in #{uri}."),

    MessageKind.HIDDEN_WARNINGS: MessageTemplate(MessageKind.HIDDEN_WARNINGS,
        "#{warnings} warning(s) suppressed in #{uri}."),

    MessageKind.HIDDEN_HINTS: MessageTemplate(
        MessageKind.HIDDEN_HINTS, "#{hints} hint(s) suppressed in #{uri}."),

    MessageKind.PREAMBLE: MessageTemplate(
        MessageKind.PREAMBLE,
        "When run on the command-line, the compiled output might"
        " require a preamble file located in:\n"
        "  <sdk>/lib/_internal/js_runtime/lib/preambles."),

    MessageKind.DIRECTLY_THROWING_NSM: MessageTemplate(
        MessageKind.DIRECTLY_THROWING_NSM,
        "This 'noSuchMethod' implementation is guaranteed to throw an "
        "exception. The generated code will be smaller if it is "
        "rewritten.",
        howToFix: "Rewrite to "
            "'noSuchMethod(Invocation i) => super.noSuchMethod(i);'."),

    MessageKind.COMPLEX_THROWING_NSM: MessageTemplate(
        MessageKind.COMPLEX_THROWING_NSM,
        "This 'noSuchMethod' implementation is guaranteed to throw an "
        "exception. The generated code will be smaller and the compiler "
        "will be able to perform more optimizations if it is rewritten.",
        howToFix: "Rewrite to "
            "'noSuchMethod(Invocation i) => super.noSuchMethod(i);'."),

    MessageKind.COMPLEX_RETURNING_NSM: MessageTemplate(
        MessageKind.COMPLEX_RETURNING_NSM,
        "Overriding 'noSuchMethod' causes the compiler to generate "
        "more code and prevents the compiler from doing some optimizations.",
        howToFix: "Consider removing this 'noSuchMethod' implementation."),

    MessageKind.RUNTIME_TYPE_TO_STRING: MessageTemplate(
        MessageKind.RUNTIME_TYPE_TO_STRING,
        "Using '.runtimeType.toString()' causes the compiler to generate "
        "more code because it needs to preserve type arguments on "
        "generic classes, even if they are not necessary elsewhere.",
        howToFix: "If used only for debugging, consider using option "
            "${Flags.laxRuntimeTypeToString} to reduce the code size "
            "impact."),

    MessageKind.NON_NATIVE_EXTERNAL: MessageTemplate(
        MessageKind.NON_NATIVE_EXTERNAL,
        "Non-native external members must be js-interop.",
        howToFix: "Try removing the 'external' keyword, making it 'native', or "
            "annotating the function as a js-interop function."),

    MessageKind.NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS: MessageTemplate(
        MessageKind.NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS,
        "Native non-instance members are only allowed in native classes."),

    // TODO(32557): Remove these when issue 32557 is fixed.
    MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS: MessageTemplate(
        MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS,
        "'case' expression type '#{type}' overrides 'operator =='."),
    MessageKind.SWITCH_CASE_FORBIDDEN: MessageTemplate(
        MessageKind.SWITCH_CASE_FORBIDDEN,
        "'case' expression may not be of type '#{type}'."),
    MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL: MessageTemplate(
        MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL,
        "'case' expressions do not all have type '#{type}'."),
    MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL_CASE: MessageTemplate(
        MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL_CASE,
        "'case' expression of type '#{type}'."),
  }; // End of TEMPLATES.

  @override
  String toString() => template;

  Message message(Map<String, String> arguments, CompilerOptions options) {
    return Message(this, arguments, options);
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
          kind == MessageKind.GENERIC || !message.contains(RegExp(r'#\{.+\}')),
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
  int get hashCode => throw UnsupportedError('Message.hashCode');
}
