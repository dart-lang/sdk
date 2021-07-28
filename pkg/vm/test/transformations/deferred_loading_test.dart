// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/deferred_loading.dart'
    show transformComponent;

import '../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../..').toFilePath();

runTestCase(Uri source) async {
  final target = new TestingVmTarget(new TargetFlags());
  Component component =
      await compileTestCaseToKernelProgram(source, target: target);

  // Disrupt the import order as a way of simulating issue 42985.
  final reversed = component.libraries.reversed.toList();
  component.libraries.setAll(0, reversed);

  component = transformComponent(component);

  // Remove core libraries so the expected output isn't enormous and broken by
  // core libraries changes.
  component.libraries.removeWhere((lib) => lib.importUri.scheme == "dart");

  String actual = kernelComponentToString(component);

  // Remove absolute library URIs.
  actual = actual.replaceAll(new Uri.file(pkgVmDir).toString(), '#pkg/vm');

  compareResultWithExpectationsFile(source, actual);
}

main() {
  group('deferred-loading', () {
    final testCasesDir =
        new Directory(pkgVmDir + '/testcases/transformations/deferred_loading');

    for (var entry in testCasesDir
        .listSync(recursive: true, followLinks: false)
        .reversed) {
      if (entry.path.endsWith("main.dart")) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });
}
