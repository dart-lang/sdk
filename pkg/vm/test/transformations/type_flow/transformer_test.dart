// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/type_flow/transformer.dart'
    show transformComponent;
import 'annotation_matcher.dart';

import '../../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../../..').toFilePath();

runTestCase(Uri source) async {
  Component component = await compileTestCaseToKernelProgram(source);

  final coreTypes = new CoreTypes(component);

  final entryPoints = [
    pkgVmDir + '/lib/transformations/type_flow/entry_points.json',
    pkgVmDir + '/lib/transformations/type_flow/entry_points_extra.json',
  ];

  component = transformComponent(coreTypes, component, entryPoints,
      new ExpressionPragmaAnnotationParser(coreTypes));

  final actual = kernelLibraryToString(component.mainMethod.enclosingLibrary);

  compareResultWithExpectationsFile(source, actual);

  ensureKernelCanBeSerializedToBinary(component);
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
