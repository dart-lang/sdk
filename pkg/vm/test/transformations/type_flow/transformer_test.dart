// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/pragma.dart'
    show ConstantPragmaAnnotationParser;
import 'package:vm/transformations/type_flow/transformer.dart'
    show transformComponent;

import '../../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../../..').toFilePath();

runTestCase(Uri source, List<String> experimentalFlags) async {
  final target = new TestingVmTarget(new TargetFlags());
  Component component = await compileTestCaseToKernelProgram(source,
      target: target, experimentalFlags: experimentalFlags);

  final coreTypes = new CoreTypes(component);

  component = transformComponent(target, coreTypes, component,
      new ConstantPragmaAnnotationParser(coreTypes));

  final actual = kernelLibraryToString(component.mainMethod.enclosingLibrary);

  compareResultWithExpectationsFile(source, actual);

  ensureKernelCanBeSerializedToBinary(component);
}

main() {
  group('transform-component', () {
    final testCasesDir = new Directory(
        pkgVmDir + '/testcases/transformations/type_flow/transformer');

    for (var entry in testCasesDir
        .listSync(recursive: true, followLinks: false)
        .reversed) {
      if (entry.path.endsWith(".dart")) {
        final List<String> experimentalFlags = [
          if (entry.path.endsWith("_nnbd.dart")) 'non-nullable',
        ];
        test(entry.path, () => runTestCase(entry.uri, experimentalFlags));
      }
    }
  });
}
