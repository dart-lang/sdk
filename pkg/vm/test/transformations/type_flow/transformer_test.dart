// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/type_flow/transformer.dart'
    show transformProgram;

import 'common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../../..').toFilePath();

runTestCase(Uri source) async {
  Program program = await compileTestCaseToKernelProgram(source);

  // Make sure the library name is the same and does not depend on the order
  // of test cases.
  program.mainMethod.enclosingLibrary.name = '#lib';

  final coreTypes = new CoreTypes(program);

  final entryPoints = [
    pkgVmDir + '/lib/transformations/type_flow/entry_points.json',
    pkgVmDir + '/lib/transformations/type_flow/entry_points_extra.json',
  ];

  program = transformProgram(coreTypes, program, entryPoints);

  final StringBuffer buffer = new StringBuffer();
  new Printer(buffer, showExternal: false, showMetadata: true)
      .writeLibraryFile(program.mainMethod.enclosingLibrary);
  final actual = buffer.toString();

  compareResultWithExpectationsFile(source, actual);
}

main() {
  group('transform-program', () {
    final testCasesDir = new Directory(
        pkgVmDir + '/testcases/transformations/type_flow/transformer');

    for (var entry
        in testCasesDir.listSync(recursive: true, followLinks: false)) {
      if (entry.path.endsWith(".dart")) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });
}
