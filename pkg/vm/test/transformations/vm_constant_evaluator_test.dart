// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/base/nnbd_mode.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/verifier.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:vm/target_os.dart';
import 'package:vm/target/vm.dart' show VmTarget;
import 'package:vm/transformations/unreachable_code_elimination.dart'
    show transformComponent;
import 'package:vm/transformations/vm_constant_evaluator.dart';

import '../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../..').toFilePath();

runTestCase(Uri source, TargetOS os) async {
  final target = new VmTarget(new TargetFlags());
  Component component = await compileTestCaseToKernelProgram(source,
      target: target,
      environmentDefines: {
        'test.define.isTrue': 'true',
        'test.define.isFalse': 'false'
      });

  final evaluator =
      VMConstantEvaluator.create(target, component, os, NnbdMode.Strong);
  final enableAsserts = false;
  component = transformComponent(component, enableAsserts, evaluator);
  verifyComponent(
      target, VerificationStage.afterGlobalTransformations, component);

  final actual = kernelLibraryToString(component.mainMethod!.enclosingLibrary);
  final postfix = '.${os.name}';
  compareResultWithExpectationsFile(source, actual, expectFilePostfix: postfix);
}

main() {
  group('platform-use-transformation', () {
    final testCasesPath = path.join(
        pkgVmDir, 'testcases', 'transformations', 'vm_constant_evaluator');

    for (var entry in Directory(testCasesPath)
        .listSync(recursive: true, followLinks: false)
        .reversed) {
      if (entry.path.endsWith(".dart")) {
        for (final os in TargetOS.values) {
          test('${entry.path}.${os.name}', () => runTestCase(entry.uri, os));
        }
      }
    }
  });
}
