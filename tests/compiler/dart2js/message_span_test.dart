// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show JSON, UTF8;
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';
import 'memory_source_file_helper.dart';

const List<Test> TESTS = const <Test>[
  const Test('''
class A { A(b); }
class B extends A {
  a() {}

  lot() {}

  of() {}

  var members;
}
main() => new B();''', const {
    MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT: '''
class B extends A {
^^^^^^^^^^^^^^^^^'''
  }),
  const Test('''
class I {}
class A { A(b); }
class B extends A implements I {
  a() {}

  lot() {}

  of() {}

  var members;
}
main() => new B();''', const {
    MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT: '''
class B extends A implements I {
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'''
  }),
  const Test('''
class M<T> {}
class A { A(b); }
class B extends A with M<int> {
  a() {}

  lot() {}

  of() {}

  var members;
}
main() => new B();''', const {
    MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT: '''
class B extends A with M<int> {
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'''
  }),
  const Test('''
class A { A(b); }
class B
    extends A {
  a() {}

  lot() {}

  of() {}

  var members;
}
main() => new B();''', const {
    MessageKind.NO_MATCHING_CONSTRUCTOR_FOR_IMPLICIT: '''
class B
    extends A {
'''
  }),
  const Test('''
void foo(int a) {
  // a
  // non-empty
  // body
}
main() => foo('');''', const {
    MessageKind.THIS_IS_THE_METHOD: '''
void foo(int a) {
^^^^^^^^^^^^^^^'''
  }),
  const Test('''
void foo(int a,
         int b) {
  // a
  // non-empty
  // body
}
main() => foo('', 0);''', const {
    MessageKind.THIS_IS_THE_METHOD: '''
void foo(int a,
         int b) {
'''
  }),
  const Test('''
class A {
  int foo() {
    // a
    // non-empty
    // body
  }
}
class B extends A {
  int get foo {
    // a
    // non-empty
    // body
    return 0;
  }
}
main() => new B();''', const {
    MessageKind.CANNOT_OVERRIDE_METHOD_WITH_GETTER: '''
  int get foo {
  ^^^^^^^^^^^''',
    MessageKind.CANNOT_OVERRIDE_METHOD_WITH_GETTER_CONT: '''
  int foo() {
  ^^^^^^^^^'''
  }),
];

class Test {
  final String code;
  final Map<MessageKind, String> kindToSpan;

  const Test(this.code, this.kindToSpan);
}

const String MARKER = '---marker---';

main() {
  asyncTest(() async {
    var cachedCompiler;
    for (Test test in TESTS) {
      DiagnosticCollector collector = new DiagnosticCollector();
      CompilationResult result = await runCompiler(
          memorySourceFiles: {'main.dart': test.code},
          options: [Flags.analyzeOnly],
          diagnosticHandler: collector,
          cachedCompiler: cachedCompiler);
      cachedCompiler = result.compiler;
      MemorySourceFileProvider provider = cachedCompiler.provider;
      Map<MessageKind, String> kindToSpan =
          new Map<MessageKind, String>.from(test.kindToSpan);
      for (CollectedMessage message in collector.messages) {
        String expectedSpanText = kindToSpan[message.messageKind];
        if (expectedSpanText != null) {
          SourceFile sourceFile = provider.getSourceFile(message.uri);
          String locationMessage =
              sourceFile.getLocationMessage(MARKER, message.begin, message.end);
          // Remove `filename:line:column:` and message.
          String strippedLocationMessage = locationMessage
              .substring(locationMessage.indexOf(MARKER) + MARKER.length + 1);
          // Using JSON.encode to add string quotes and backslashes.
          String expected = JSON.encode(
              UTF8.decode(expectedSpanText.codeUnits, allowMalformed: true));
          String actual = JSON.encode(UTF8
              .decode(strippedLocationMessage.codeUnits, allowMalformed: true));
          Expect.equals(
              expectedSpanText,
              strippedLocationMessage,
              "Unexpected span for ${message.messageKind} in\n${test.code}"
              "\nExpected: $expected"
              "\nActual  : $actual");
          kindToSpan.remove(message.messageKind);
        }
      }
      kindToSpan.forEach((MessageKind kind, _) {
        Expect.fail("Missing message kin $kind in\n${test.code}");
      });
    }
  });
}
