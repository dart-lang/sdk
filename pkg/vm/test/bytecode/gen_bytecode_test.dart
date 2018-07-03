// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:test/test.dart';
import 'package:vm/bytecode/gen_bytecode.dart' show generateBytecode;

import '../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../..').toFilePath();

runTestCase(Uri source) async {
  Component component = await compileTestCaseToKernelProgram(source);

  // Need to omit source positions from bytecode as they are different on
  // Linux and Windows (due to differences in newline characters).
  generateBytecode(component, strongMode: true, omitSourcePositions: true);

  final actual = kernelLibraryToString(component.mainMethod.enclosingLibrary);
  compareResultWithExpectationsFile(source, actual);
}

main() {
  group('gen-bytecode', () {
    final testCasesDir = new Directory(pkgVmDir + '/testcases/bytecode');

    for (var entry
        in testCasesDir.listSync(recursive: true, followLinks: false)) {
      if (entry.path.endsWith(".dart")) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });
}
