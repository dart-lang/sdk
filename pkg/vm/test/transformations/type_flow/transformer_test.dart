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
    show transformComponent;

import 'common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../../..').toFilePath();

runTestCase(Uri source) async {
  Component component = await compileTestCaseToKernelProgram(source);

  // Make sure the library name is the same and does not depend on the order
  // of test cases.
  component.mainMethod.enclosingLibrary.name = '#lib';

  final coreTypes = new CoreTypes(component);

  final entryPoints = [
    pkgVmDir + '/lib/transformations/type_flow/entry_points.json',
    pkgVmDir + '/lib/transformations/type_flow/entry_points_extra.json',
  ];

  component = transformComponent(coreTypes, component, entryPoints);

  final StringBuffer buffer = new StringBuffer();
  new Printer(buffer, showExternal: false, showMetadata: true)
      .writeLibraryFile(component.mainMethod.enclosingLibrary);
  final actual = buffer.toString();

  compareResultWithExpectationsFile(source, actual);
}

main() {
  group('transform-component', () {
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
