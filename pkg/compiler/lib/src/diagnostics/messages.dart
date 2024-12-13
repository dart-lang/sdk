// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The messages in this file should follow the [Guide for Writing
/// Diagnostics](../../../../front_end/lib/src/base/diagnostics.md).
///
/// Other things to keep in mind:
///
/// An INFO message should always be preceded by a non-INFO message, and the
/// INFO messages are additional details about the preceding non-INFO
/// message. For example, consider duplicated elements. First report a WARNING
/// or ERROR about the duplicated element, and then report an INFO about the
/// location of the existing element.
library;

import '../commandline_options.dart';
import '../options.dart';
import 'invariant.dart' show failedAt;
import 'spannable.dart' show currentElementSpannable;

/// Keys for the [MessageTemplate]s.
enum MessageKind {
  compilerCrashed,
  complexReturningNsm,
  complexThrowingNsm,
  directlyThrowingNsm,
  generic,
  hiddenHints,
  hiddenWarnings,
  hiddenWarningsHints,
  invalidMetadata,
  invalidMetadataGeneric,
  jsPlaceholderCapture,
  nativeNonInstanceInNonNativeClass,
  nonNativeExternal,
  pleaseReportTheCrash,
  preamble,
  runtimeTypeToString,
  stringExpected,
  wrongArgumentForJS,
  wrongArgumentForJSFirst,
  wrongArgumentForJSSecond,
  wrongArgumentForJSInterceptorConstant,
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
  final String? howToFix;

  ///  Examples will be checked by
  ///  pkg/compiler/test/message_kind_test.dart.
  ///
  ///  An example is a String containing the example source code.
  final List<String>? examples;

  /// Additional options needed for the examples to work.
  final List<String> options;

  const MessageTemplate(this.kind, this.template,
      {this.howToFix, this.examples, this.options = const <String>[]});

  /// All templates used by the compiler.
  ///
  /// The map is complete mapping from [MessageKind] to their corresponding
  /// [MessageTemplate].
  static const Map<MessageKind, MessageTemplate> templates = {
    /// Do not use this. It is here for legacy and debugging. It violates item
    /// 4 of the guide lines for error messages in the beginning of the file.
    MessageKind.generic: MessageTemplate(MessageKind.generic, '#{text}'),

    MessageKind.stringExpected: MessageTemplate(MessageKind.stringExpected,
        "Expected a 'String', but got an instance of '#{type}'."),

    MessageKind.jsPlaceholderCapture: MessageTemplate(
        MessageKind.jsPlaceholderCapture,
        "JS code must not use '#' placeholders inside functions.",
        howToFix: "Use an immediately called JavaScript function to capture the"
            " the placeholder values as JavaScript function parameters."),

    MessageKind.wrongArgumentForJS: MessageTemplate(
        MessageKind.wrongArgumentForJS,
        "JS expression must take two or more arguments."),

    MessageKind.wrongArgumentForJSFirst: MessageTemplate(
        MessageKind.wrongArgumentForJSFirst,
        "JS expression must take two or more arguments."),

    MessageKind.wrongArgumentForJSSecond: MessageTemplate(
        MessageKind.wrongArgumentForJSSecond,
        "JS second argument must be a string literal."),

    MessageKind.wrongArgumentForJSInterceptorConstant: MessageTemplate(
        MessageKind.wrongArgumentForJSInterceptorConstant,
        "Argument for 'JS_INTERCEPTOR_CONSTANT' must be a type constant."),

    MessageKind.invalidMetadata: MessageTemplate(
        MessageKind.invalidMetadata,
        "A metadata annotation must be either a reference to a compile-time "
        "constant variable or a call to a constant constructor.",
        howToFix:
            "Try using a different constant value or referencing it through a "
            "constant variable.",
        examples: ['@Object main() {}', '@print main() {}']),

    MessageKind.invalidMetadataGeneric: MessageTemplate(
        MessageKind.invalidMetadataGeneric,
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

    MessageKind.compilerCrashed: MessageTemplate(MessageKind.compilerCrashed,
        "The compiler crashed when compiling this element."),

    MessageKind.pleaseReportTheCrash:
        MessageTemplate(MessageKind.pleaseReportTheCrash, '''
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

    MessageKind.hiddenWarningsHints: MessageTemplate(
        MessageKind.hiddenWarningsHints,
        "#{warnings} warning(s) and #{hints} hint(s) suppressed in #{uri}."),

    MessageKind.hiddenWarnings: MessageTemplate(MessageKind.hiddenWarnings,
        "#{warnings} warning(s) suppressed in #{uri}."),

    MessageKind.hiddenHints: MessageTemplate(
        MessageKind.hiddenHints, "#{hints} hint(s) suppressed in #{uri}."),

    MessageKind.preamble: MessageTemplate(
        MessageKind.preamble,
        "When run on the command-line, the compiled output might"
        " require a preamble file located in:\n"
        "  <sdk>/lib/_internal/js_runtime/lib/preambles."),

    MessageKind.directlyThrowingNsm: MessageTemplate(
        MessageKind.directlyThrowingNsm,
        "This 'noSuchMethod' implementation is guaranteed to throw an "
        "exception. The generated code will be smaller if it is "
        "rewritten.",
        howToFix: "Rewrite to "
            "'noSuchMethod(Invocation i) => super.noSuchMethod(i);'."),

    MessageKind.complexThrowingNsm: MessageTemplate(
        MessageKind.complexThrowingNsm,
        "This 'noSuchMethod' implementation is guaranteed to throw an "
        "exception. The generated code will be smaller and the compiler "
        "will be able to perform more optimizations if it is rewritten.",
        howToFix: "Rewrite to "
            "'noSuchMethod(Invocation i) => super.noSuchMethod(i);'."),

    MessageKind.complexReturningNsm: MessageTemplate(
        MessageKind.complexReturningNsm,
        "Overriding 'noSuchMethod' causes the compiler to generate "
        "more code and prevents the compiler from doing some optimizations.",
        howToFix: "Consider removing this 'noSuchMethod' implementation."),

    MessageKind.runtimeTypeToString: MessageTemplate(
        MessageKind.runtimeTypeToString,
        "Using '.runtimeType.toString()' causes the compiler to generate "
        "more code because it needs to preserve type arguments on "
        "generic classes, even if they are not necessary elsewhere.",
        howToFix: "If used only for debugging, consider using option "
            "${Flags.laxRuntimeTypeToString} to reduce the code size "
            "impact."),

    MessageKind.nonNativeExternal: MessageTemplate(
        MessageKind.nonNativeExternal,
        "Non-native external members must be js-interop.",
        howToFix: "Try removing the 'external' keyword, making it 'native', or "
            "annotating the function as a js-interop function."),

    MessageKind.nativeNonInstanceInNonNativeClass: MessageTemplate(
        MessageKind.nativeNonInstanceInNonNativeClass,
        "Native non-instance members are only allowed in native classes."),
  }; // End of TEMPLATES.

  @override
  String toString() => template;

  Message message(Map<String, String> arguments, DiagnosticOptions? options) {
    // [options] is nullable for testing.
    // TODO(sra): Provide a testing version of [DiagnosticOptions] to allow
    // [options] to be non-nullable, and use composition in [CompilerOptions]
    // rather than inheritance.
    return Message(this, arguments, options?.terseDiagnostics ?? false);
  }

  bool get hasHowToFix => howToFix != null;
}

class Message {
  final MessageTemplate template;
  final Map<String, String> arguments;
  final bool terse;
  late String message = _computeMessage();

  Message(this.template, this.arguments, this.terse) {
    assert(message != ''); // Force message formating in 'dart2js_developer'.
  }

  MessageKind get kind => template.kind;

  String _computeMessage() {
    message = template.template;
    arguments.forEach((String key, String value) {
      message = message.replaceAll('#{$key}', value);
    });
    assert(
        kind == MessageKind.generic || !message.contains(RegExp(r'#\{.+\}')),
        failedAt(currentElementSpannable,
            'Missing arguments in error message: "$message"'));
    if (!terse && template.hasHowToFix) {
      String howToFix = template.howToFix!;
      arguments.forEach((String key, String value) {
        howToFix = howToFix.replaceAll('#{$key}', value);
      });
      message = '$message\n$howToFix';
    }
    return message;
  }

  @override
  String toString() => message;

  @override
  bool operator ==(other) {
    if (other is! Message) return false;
    return (template == other.template) && (toString() == other.toString());
  }

  @override
  int get hashCode => throw UnsupportedError('Message.hashCode');
}
