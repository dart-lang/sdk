// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:test/test.dart';
import 'package:vm/modular/target/vm.dart' show VmTarget;
import 'package:vm/transformations/dynamic_interface_annotator.dart'
    show annotateComponent;

import '../common_test_utils.dart';

final Uri pkgVmDir = Platform.script.resolve('../..');

runTestCase(Uri testCaseDir) async {
  final mainDart = testCaseDir.resolve('main.dart');
  final dynamicInterface = testCaseDir.resolve('dynamic_interface.yaml');
  final dynamicInterfaceYaml =
      File.fromUri(dynamicInterface).readAsStringSync();

  final target = VmTarget(TargetFlags());
  Component component =
      await compileTestCaseToKernelProgram(mainDart, target: target);
  final coreTypes = CoreTypes(component);
  annotateComponent(
      dynamicInterfaceYaml, dynamicInterface, component, coreTypes);

  for (final lib in component.libraries) {
    if (!lib.importUri.isScheme('dart')) {
      print(lib.fileUri);
      final actual = kernelLibraryToString(lib)
          .replaceAll(pkgVmDir.toString(), 'file:pkg/vm/');
      compareResultWithExpectationsFile(lib.fileUri, actual);
    }
  }
}

main() {
  test('dynamic-interface-annotator', () async {
    final testCaseDir = pkgVmDir
        .resolve('testcases/transformations/dynamic_interface_annotator/');
    await runTestCase(testCaseDir);
  });
}
