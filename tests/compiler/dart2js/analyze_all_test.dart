// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "compiler_helper.dart";
import "package:async_helper/async_helper.dart";

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

main() {
  Uri uri = Uri.parse('test:code');
  var compiler1 = compilerFor(SOURCE, uri, analyzeAll: false);
  asyncTest(() => compiler1.run(uri).then((compilationSucceded) {
    DiagnosticCollector collector = compiler1.diagnosticCollector;
    Expect.isTrue(compilationSucceded);
    print(collector.warnings);
    Expect.isTrue(collector.warnings.isEmpty, 'unexpected warnings');
    Expect.isTrue(collector.errors.isEmpty, 'unexpected errors');
  }));

  var compiler2 = compilerFor(SOURCE, uri, analyzeAll: true);
  asyncTest(() => compiler2.run(uri).then((compilationSucceded) {
    DiagnosticCollector collector = compiler2.diagnosticCollector;
    Expect.isFalse(compilationSucceded);
    Expect.isTrue(collector.warnings.isEmpty,
                  'unexpected warnings: ${collector.warnings}');
    Expect.equals(2, collector.errors.length,
                  'expected exactly two errors, but got ${collector.errors}');

    CollectedMessage first = collector.errors.first;
    Expect.equals(MessageKind.CONSTRUCTOR_IS_NOT_CONST, first.message.kind);
    Expect.equals("Foo", SOURCE.substring(first.begin, first.end));

    CollectedMessage second = collector.errors.elementAt(1);
    Expect.equals(MessageKind.CONSTRUCTOR_IS_NOT_CONST, second.message.kind);
    Expect.equals("Foo", SOURCE.substring(second.begin, second.end));
  }));
}
