// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/target/targets.dart';
import 'package:kernel/verifier.dart';
import 'package:test/test.dart';
import 'package:vm/modular/target/vm.dart' show VmTarget;
import 'package:vm/transformations/mixin_deduplication.dart'
    show transformComponent;

import '../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../..').toFilePath();

runTestCase(Uri source) async {
  final target = VmTarget(new TargetFlags());
  final component = await compileTestCaseToKernelProgram(
    source,
    target: target,
  );
  transformComponent(component, CoreTypes(component), target);
  verifyComponent(
    target,
    VerificationStage.afterGlobalTransformations,
    component,
  );

  final actual = component.libraries
      .where(
        (l) =>
            l.importUri.path.contains('testcases') ||
            (l.importUri.scheme == 'dart' &&
                l.importUri.path.startsWith('mixin_deduplication')),
      )
      .map(kernelLibraryToString)
      .join('\n\n')
      .replaceAll(pkgVmDir.toString(), 'file:pkg/vm/');
  compareResultWithExpectationsFile(source, actual);
}

main() {
  group('mixin-deduplication', () {
    final testCasesDir = Directory(
      pkgVmDir + '/testcases/transformations/mixin_deduplication',
    );

    for (var entry
        in testCasesDir
            .listSync(recursive: true, followLinks: false)
            .reversed) {
      if (entry.path.endsWith(".dart") && !entry.path.contains('helper')) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });
}
