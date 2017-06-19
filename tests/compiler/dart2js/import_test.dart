// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler can handle missing files used in imports, exports,
// part tags or as the main source file.

library dart2js.test.import;

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/diagnostics/messages.dart';
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
  'part.dart': '''
part of lib;

main() {}
''',
  'lib.dart': '''
library lib;

import 'part.dart';

part 'part.dart';
''',
};

testEntryPointIsPart() async {
  var collector = new DiagnosticCollector();
  await runCompiler(
      entryPoint: Uri.parse('memory:part.dart'),
      memorySourceFiles: MEMORY_SOURCE_FILES,
      diagnosticHandler: collector);

  collector.checkMessages([const Expected.error(MessageKind.MAIN_HAS_PART_OF)]);
}

testImportPart() async {
  var collector = new DiagnosticCollector();
  await runCompiler(
      entryPoint: Uri.parse('memory:lib.dart'),
      memorySourceFiles: MEMORY_SOURCE_FILES,
      diagnosticHandler: collector);

  collector.checkMessages([
    const Expected.error(MessageKind.IMPORT_PART_OF),
    const Expected.info(MessageKind.IMPORT_PART_OF_HERE)
  ]);
}

testMissingImports() async {
  var collector = new DiagnosticCollector();
  await runCompiler(
      memorySourceFiles: MEMORY_SOURCE_FILES, diagnosticHandler: collector);

  collector.checkMessages([
    const Expected.error(MessageKind.READ_URI_ERROR),
    const Expected.error(MessageKind.LIBRARY_NOT_FOUND),
    const Expected.error(MessageKind.LIBRARY_NOT_FOUND),
    const Expected.error(MessageKind.READ_URI_ERROR),
    const Expected.warning(MessageKind.NOT_ASSIGNABLE)
  ]);
}

testMissingMain() async {
  var collector = new DiagnosticCollector();
  await runCompiler(
      entryPoint: Uri.parse('memory:missing.dart'),
      diagnosticHandler: collector);
  collector.checkMessages([const Expected.error(MessageKind.READ_SELF_ERROR)]);
}

void main() {
  asyncTest(() async {
    await testEntryPointIsPart();
    await testImportPart();
    await testMissingImports();
    await testMissingMain();
  });
}
