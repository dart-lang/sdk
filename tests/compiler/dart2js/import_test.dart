// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler can handle missing files used in imports, exports,
// part tags or as the main source file.

library dart2js.test.import;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
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

testMissingImports() async {
  var collector = new DiagnosticCollector();
  await runCompiler(
      memorySourceFiles: MEMORY_SOURCE_FILES,
      diagnosticHandler: collector);
  Expect.equals(4, collector.errors.length);
  Expect.equals(1, collector.warnings.length);
}

testMissingMain() async {
  var collector = new DiagnosticCollector();
  await runCompiler(
      entryPoint: Uri.parse('memory:missing.dart'),
      diagnosticHandler: collector);
  Expect.equals(1, collector.errors.length);
  Expect.equals(0, collector.warnings.length);
}

void main() {
  asyncTest(() async {
    await testMissingImports();
    await testMissingMain();
  });
}
