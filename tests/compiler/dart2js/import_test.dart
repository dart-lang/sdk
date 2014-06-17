// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler can handle missing files used in imports, exports,
// part tags or as the main source file.

library dart2js.test.import;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''

library main;

import 'dart:thisLibraryShouldNotExist';
import 'package:thisPackageShouldNotExist/thisPackageShouldNotExist.dart';
export 'foo.dart';

part 'bar.dart';

main() {
  int i = "";
}
''',
};

testMissingImports() {
  var collector = new DiagnosticCollector();
  var compiler = compilerFor(MEMORY_SOURCE_FILES, diagnosticHandler: collector);
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    Expect.equals(4, collector.errors.length);
    // TODO(johnniwinther): Expect 1 warning when analysis of programs with load
    // failures is reenabled.
    Expect.equals(0, collector.warnings.length);
  }));
}

testMissingMain() {
  var collector = new DiagnosticCollector();
  var compiler = compilerFor({}, diagnosticHandler: collector);
  asyncTest(() => compiler.run(Uri.parse('memory:missing.dart')).then((_) {
    Expect.equals(1, collector.errors.length);
    Expect.equals(0, collector.warnings.length);
  }));
}

void main() {
  testMissingImports();
  testMissingMain();
}
