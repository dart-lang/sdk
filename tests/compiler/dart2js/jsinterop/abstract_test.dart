// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsinterop.abstract_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import '../memory_compiler.dart';

void main() {
  asyncTest(() async {
    DiagnosticCollector collector = new DiagnosticCollector();
    await runCompiler(diagnosticHandler: collector, memorySourceFiles: const {
      'main.dart': '''
import 'package:js/js.dart';

@JS()
class A {
  get foo;
}

main() => new A();
'''
    });
    Expect.equals(0, collector.errors.length, 'Unexpected error count.');
    Expect.equals(1, collector.warnings.length, 'Unexpected warning count.');
    Expect.equals(MessageKind.ABSTRACT_GETTER,
        collector.warnings.first.messageKind, 'Unexpected warning.');
  });
}
