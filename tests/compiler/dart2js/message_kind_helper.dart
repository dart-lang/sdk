// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.message_kind_helper;

import 'package:expect/expect.dart';
import 'dart:async';

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/diagnostics/messages.dart'
    show MessageKind, MessageTemplate;
import 'package:compiler/compiler_new.dart' show Diagnostic;

import 'memory_compiler.dart';

const String ESCAPE_REGEXP = r'[[\]{}()*+?.\\^$|]';

/// Most examples generate a single diagnostic.
/// Add an exception here if a single diagnostic cannot be produced.
/// However, consider that a single concise diagnostic is easier to understand,
/// so try to change error reporting logic before adding an exception.
final Set<MessageKind> kindsWithExtraMessages = new Set<MessageKind>.from([
  // See http://dartbug.com/18361:
  MessageKind.CANNOT_EXTEND_MALFORMED,
  MessageKind.CANNOT_IMPLEMENT_MALFORMED,
  MessageKind.CANNOT_MIXIN,
  MessageKind.CANNOT_MIXIN_MALFORMED,
  MessageKind.CANNOT_INSTANTIATE_ENUM,
  MessageKind.CYCLIC_TYPEDEF_ONE,
  MessageKind.DUPLICATE_DEFINITION,
  MessageKind.EQUAL_MAP_ENTRY_KEY,
  MessageKind.FINAL_FUNCTION_TYPE_PARAMETER,
  MessageKind.FORMAL_DECLARED_CONST,
  MessageKind.FORMAL_DECLARED_STATIC,
  MessageKind.FUNCTION_TYPE_FORMAL_WITH_DEFAULT,
  MessageKind.HIDDEN_IMPLICIT_IMPORT,
  MessageKind.HIDDEN_IMPORT,
  MessageKind.INHERIT_GETTER_AND_METHOD,
  MessageKind.UNIMPLEMENTED_METHOD,
  MessageKind.UNIMPLEMENTED_METHOD_ONE,
  MessageKind.VAR_FUNCTION_TYPE_PARAMETER,
  MessageKind.UNMATCHED_TOKEN,
]);

/// Most messages can be tested without causing a fatal error. Add an exception
/// here if a fatal error is unavoidable and leads to pending classes.
/// Try to avoid adding exceptions here; a fatal error causes the compiler to
/// stop before analyzing all input, and it isn't safe to reuse it.
final Set<MessageKind> kindsWithPendingClasses = new Set<MessageKind>.from([
  // If you add something here, please file a *new* bug report.
]);

Future<Compiler> check(MessageTemplate template, Compiler cachedCompiler) {
  Expect.isFalse(template.examples.isEmpty);

  return Future.forEach(template.examples, (example) {
    if (example is String) {
      example = {'main.dart': example};
    } else {
      Expect.isTrue(
          example is Map, "Example must be either a String or a Map.");
      Expect.isTrue(example.containsKey('main.dart'),
          "Example map must contain a 'main.dart' entry.");
    }
    DiagnosticCollector collector = new DiagnosticCollector();

    Compiler compiler = compilerFor(
        memorySourceFiles: example,
        diagnosticHandler: collector,
        options: [Flags.analyzeOnly, Flags.enableExperimentalMirrors]
          ..addAll(template.options),
        cachedCompiler: cachedCompiler);

    return compiler.run(Uri.parse('memory:main.dart')).then((_) {
      Iterable<CollectedMessage> messages = collector.filterMessagesByKinds([
        Diagnostic.ERROR,
        Diagnostic.WARNING,
        Diagnostic.HINT,
        Diagnostic.CRASH
      ]);

      Expect.isFalse(messages.isEmpty, 'No messages in """$example"""');

      String expectedText = !template.hasHowToFix
          ? template.template
          : '${template.template}\n${template.howToFix}';
      String pattern = expectedText.replaceAllMapped(
          new RegExp(ESCAPE_REGEXP), (m) => '\\${m[0]}');
      pattern = pattern.replaceAll(new RegExp(r'#\\\{[^}]*\\\}'), '.*');

      bool checkMessage(CollectedMessage message) {
        if (message.message.kind != MessageKind.GENERIC) {
          return message.message.kind == template.kind;
        } else {
          return new RegExp('^$pattern\$').hasMatch(message.text);
        }
      }

      // TODO(johnniwinther): Extend MessageKind to contain information on
      // where info messages are expected.
      bool messageFound = false;
      List unexpectedMessages = [];
      for (CollectedMessage message in messages) {
        if (!messageFound && checkMessage(message)) {
          messageFound = true;
        } else {
          unexpectedMessages.add(message);
        }
      }
      Expect.isTrue(
          messageFound,
          '${template.kind}} does not match any in\n '
          '${messages.join('\n ')}');
      dynamic reporter = compiler.reporter;
      Expect.isFalse(reporter.hasCrashed);
      if (!unexpectedMessages.isEmpty) {
        for (CollectedMessage message in unexpectedMessages) {
          print("Unexpected message: $message");
        }
        if (!kindsWithExtraMessages.contains(template.kind)) {
          // Try changing the error reporting logic before adding an exception
          // to [kindsWithExtraMessages].
          throw 'Unexpected messages found.';
        }
      }

      bool pendingStuff = false;
      for (var e in compiler.resolver.pendingClassesToBePostProcessed) {
        pendingStuff = true;
        compiler.reporter.reportInfo(e, MessageKind.GENERIC,
            {'text': 'Pending class to be post-processed.'});
      }
      for (var e in compiler.resolver.pendingClassesToBeResolved) {
        pendingStuff = true;
        compiler.reporter.reportInfo(
            e, MessageKind.GENERIC, {'text': 'Pending class to be resolved.'});
      }
      Expect
          .isTrue(!pendingStuff || kindsWithPendingClasses.contains(template));

      if (!pendingStuff) {
        // If there is pending stuff, or the compiler was cancelled, we
        // shouldn't reuse the compiler.
        cachedCompiler = compiler;
      }
    });
  }).then((_) => cachedCompiler);
}
