// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler can handle missing files used in imports, exports,
// part tags or as the main source file.

library dart2js.test.malformed_uri;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import '../memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
  'main.dart': '''
import '../../Udyn[mic ils/expect.dart';

main () { print("Hi"); }
''',
};

testMalformedUri() {
  asyncTest(() async {
    var collector = new DiagnosticCollector();
    await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES, diagnosticHandler: collector);
    Expect.equals(1, collector.errors.length);
  });
}

void main() {
  testMalformedUri();
}
