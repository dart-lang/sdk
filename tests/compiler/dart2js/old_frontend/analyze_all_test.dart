// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:expect/expect.dart';
import '../memory_compiler.dart';

const String SOURCE = """
class Foo {
  // Deliberately not const to ensure compile error.
  Foo(_);
}

@Bar()
class Bar {
  const Bar();
}

@Foo('x')
typedef void VoidFunction();

@Foo('y')
class MyClass {}

main() {
}
""";

Future<DiagnosticCollector> run(String source,
    {bool analyzeAll, bool expectSuccess}) async {
  DiagnosticCollector collector = new DiagnosticCollector();

  List<String> options = [];
  if (analyzeAll) {
    options.add(Flags.analyzeAll);
  } else {
    options.add(Flags.analyzeOnly);
  }
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': source},
      diagnosticHandler: collector,
      options: options);
  Expect.equals(expectSuccess, result.isSuccess);
  return collector;
}

test1() async {
  DiagnosticCollector collector =
      await run(SOURCE, analyzeAll: false, expectSuccess: true);
  Expect.isTrue(
      collector.warnings.isEmpty, 'Unexpected warnings: ${collector.warnings}');
  Expect.isTrue(
      collector.errors.isEmpty, 'Unexpected errors: ${collector.errors}');
}

test2() async {
  DiagnosticCollector collector =
      await run(SOURCE, analyzeAll: true, expectSuccess: false);

  Expect.isTrue(
      collector.warnings.isEmpty, 'unexpected warnings: ${collector.warnings}');
  Expect.equals(2, collector.errors.length,
      'expected exactly two errors, but got ${collector.errors}');

  CollectedMessage first = collector.errors.first;
  Expect.equals(MessageKind.CONSTRUCTOR_IS_NOT_CONST, first.message.kind);
  Expect.equals("Foo", SOURCE.substring(first.begin, first.end));

  CollectedMessage second = collector.errors.elementAt(1);
  Expect.equals(MessageKind.CONSTRUCTOR_IS_NOT_CONST, second.message.kind);
  Expect.equals("Foo", SOURCE.substring(second.begin, second.end));
}

// This is a regression test, testing that we can handle annotations on
// malformed elements. Depending on the order of analysis, annotations on such
// elements might not be resolved which caused a crash when trying to detect
// a `@NoInline()` annotation.
test3() async {
  String source = '''
import 'package:expect/expect.dart';

class A {
  @NoInline
  m() {
    => print(0);
  }
}

@NoInline()
main() => new A().m();
''';

  DiagnosticCollector collector =
      await run(source, analyzeAll: true, expectSuccess: false);

  Expect.isTrue(
      collector.warnings.isEmpty, 'unexpected warnings: ${collector.warnings}');
  Expect.equals(1, collector.errors.length,
      'expected exactly one error, but got ${collector.errors}');
}

main() {
  asyncTest(() async {
    await test1();
    await test2();
    await test3();
  });
}
