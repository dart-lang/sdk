// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/verifier.dart';
import 'package:test/test.dart';
import 'package:vm/modular/target/vm.dart' show VmTarget;
import 'package:vm/transformations/unreachable_code_elimination.dart'
    show transformComponent;
import 'package:vm/transformations/vm_constant_evaluator.dart';

import '../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../..').toFilePath();

runTestCase(Uri source) async {
  // Do not perform constant evaluation for a specific target operating system.
  final targetOS = null;
  final enableAsserts = false;

  final target = new VmTarget(new TargetFlags());
  Component component = await compileTestCaseToKernelProgram(source,
      target: target,
      environmentDefines: {
        'test.define.isTrue': 'true',
        'test.define.isFalse': 'false'
      });
  final evaluator = VMConstantEvaluator.create(target, component, targetOS,
      enableAsserts: enableAsserts);
  component = transformComponent(target, component, evaluator, enableAsserts);
  verifyComponent(
      target, VerificationStage.afterGlobalTransformations, component);

  final actual = kernelLibraryToString(component.mainMethod!.enclosingLibrary);

  compareResultWithExpectationsFile(source, actual);
}

main() {
  group('unreachable-code-elimination', () {
    final testCasesDir = new Directory(
        pkgVmDir + '/testcases/transformations/unreachable_code_elimination');

    for (var entry in testCasesDir
        .listSync(recursive: true, followLinks: false)
        .reversed) {
      if (entry.path.endsWith(".dart")) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });
}
