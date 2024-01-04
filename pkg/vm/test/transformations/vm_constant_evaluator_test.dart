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

class TestCase {
  final TargetOS os;
  final bool debug;
  final bool enableAsserts;

  const TestCase(this.os, {required this.debug, required this.enableAsserts});

  String postfix() {
    String result = '.${os.name}';
    if (debug) {
      result += '.debug';
    }
    if (enableAsserts) {
      result += '.withAsserts';
    }
    return result;
  }
}

runTestCase(Uri source, TestCase testCase) async {
  final soundNullSafety = true;
  final nnbdMode = NnbdMode.Strong;
  final target =
      new VmTarget(new TargetFlags(soundNullSafety: soundNullSafety));
  Component component = await compileTestCaseToKernelProgram(source,
      target: target,
      environmentDefines: {
        'test.define.debug': testCase.debug ? 'true' : 'false',
        'test.define.enableAsserts': testCase.enableAsserts ? 'true' : 'false',
      });

  final evaluator = VMConstantEvaluator.create(
      target, component, testCase.os, nnbdMode,
      enableAsserts: testCase.enableAsserts);
  component =
      transformComponent(target, component, evaluator, testCase.enableAsserts);
  verifyComponent(
      target, VerificationStage.afterGlobalTransformations, component);

  final actual = kernelLibraryToString(component.mainMethod!.enclosingLibrary);
  compareResultWithExpectationsFile(source, actual,
      expectFilePostfix: testCase.postfix());
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
          for (final enableAsserts in [true, false]) {
            for (final debug in [true, false]) {
              final testCase =
                  TestCase(os, debug: debug, enableAsserts: enableAsserts);
              test('${entry.path}${testCase.postfix()}',
                  () => runTestCase(entry.uri, testCase));
            }
          }
        }
      }
    }
  });
}
