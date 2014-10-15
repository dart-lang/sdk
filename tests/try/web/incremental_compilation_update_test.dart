// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.incremental_compilation_update_test;

import 'dart:html';

import 'dart:async' show
    Future;

import 'package:async_helper/async_helper.dart' show
    asyncTest;

import 'sandbox.dart' show
    appendIFrame,
    listener;

import 'web_compiler_test_case.dart' show
    WebCompilerTestCase,
    WebInputProvider;

import 'program_result.dart';

const List<List<ProgramResult>> tests = const <List<ProgramResult>>[
    // Basic hello-world test.
    const <ProgramResult>[
        const ProgramResult(
            "main() { print('Hello, World!'); }",
            const <String> ['Hello, World!']),
        const ProgramResult(
            "main() { print('Hello, Brave New World!'); }",
            const <String> ['Hello, Brave New World!']),
    ],

    // Test that the test framework handles more than one update.
    const <ProgramResult>[
        const ProgramResult(
            "main() { print('Hello darkness, my old friend'); }",
            const <String> ['Hello darkness, my old friend']),
        const ProgramResult(
            "main() { print('I\\'ve come to talk with you again'); }",
            const <String> ['I\'ve come to talk with you again']),
        const ProgramResult(
            "main() { print('Because a vision softly creeping'); }",
            const <String> ['Because a vision softly creeping']),
    ],

    // Test that that isolate support works.
    const <ProgramResult>[
        const ProgramResult(
            "main(arguments) { print('Hello, Isolated World!'); }",
            const <String> ['Hello, Isolated World!']),
        const ProgramResult(
            "main(arguments) { print(arguments); }",
            const <String> ['[]']),
    ],

    // Test that a stored closure changes behavior when updated.
    const <ProgramResult>[
        const ProgramResult(
            r"""
var closure;

foo(a, [b = 'b']) {
  print('$a $b');
}

main() {
  if (closure == null) {
    print('[closure] is null.');
    closure = foo;
  }
  closure('a');
  closure('a', 'c');
}
""",
            const <String> ['[closure] is null.', 'a b', 'a c']),
        const ProgramResult(
            r"""
var closure;

foo(a, [b = 'b']) {
  print('$b $a');
}

main() {
  if (closure == null) {
    print('[closure] is null.');
    closure = foo;
  }
  closure('a');
  closure('a', 'c');
}
""",
            const <String> ['b a', 'c a']),
    ],
];


void main() {
  listener.start();

  return asyncTest(() => Future.forEach(tests, compileAndRun));
}

Future compileAndRun(List<ProgramResult> programs) {
  var status = new DivElement();
  document.body.append(status);

  IFrameElement iframe =
      appendIFrame(
          '/root_dart/tests/try/web/incremental_compilation_update.html',
          document.body)
          ..style.width = '100%'
          ..style.height = '600px';

  return listener.expect('iframe-ready').then((_) {
    ProgramResult program = programs.first;
    status.append(new PreElement()..appendText(program.code));
    status.style.color = 'orange';
    WebCompilerTestCase test = new WebCompilerTestCase(program.code);
    return test.run().then((String jsCode) {
      status.style.color = 'red';
      var objectUrl =
          Url.createObjectUrl(new Blob([jsCode], 'application/javascript'));

      iframe.contentWindow.postMessage(['add-script', objectUrl], '*');
      Future future =
          listener.expect(program.messagesWith('iframe-dart-main-done'));
      return future.then((_) {
        int version = 2;
        return Future.forEach(programs.skip(1), (ProgramResult program) {

          status.append(new PreElement()..appendText(program.code));

          WebInputProvider inputProvider =
              test.incrementalCompiler.inputProvider;
          Uri uri = test.scriptUri.resolve('?v${version++}');
          inputProvider.cachedSources[uri] = new Future.value(program.code);
          Future future = test.incrementalCompiler.compileUpdates(
              {test.scriptUri: uri});
          return future.then((String update) {
            iframe.contentWindow.postMessage(['apply-update', update], '*');

            return listener.expect(
                program.messagesWith('iframe-dart-updated-main-done'));
          });
        });
      });
    });
  }).then((_) {
    status.style.color = 'limegreen';

    // Remove the iframe to work around a bug in test.dart.
    iframe.remove();
  });
}
