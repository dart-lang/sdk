// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/target/targets.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:test/test.dart';

import 'common_test_utils.dart';

final String testRootDir = Platform.script.resolve('.').toFilePath();

runTestCase(
    Uri source, List<String> experimentalFlags, bool enableNullSafety) async {
  final target =
      TestingDart2jsTarget(TargetFlags(enableNullSafety: enableNullSafety));
  Component component = await compileTestCaseToKernelProgram(source,
      target: target, experimentalFlags: experimentalFlags);

  String actual = kernelLibraryToString(component.mainMethod.enclosingLibrary);

  compareResultWithExpectationsFile(source, actual);
}

main() {
  group('goldens', () {
    final testCasesDir = new Directory(testRootDir + '/data');

    for (var entry
        in testCasesDir.listSync(recursive: true, followLinks: false)) {
      final path = entry.path;
      if (path.endsWith('.dart')) {
        final bool enableNullSafety = path.endsWith('_nnbd_strong.dart');
        final bool enableNNBD = enableNullSafety || path.endsWith('_nnbd.dart');
        final List<String> experimentalFlags = [
          if (enableNNBD) 'non-nullable',
        ];
        test(path,
            () => runTestCase(entry.uri, experimentalFlags, enableNullSafety));
      }
    }
  }, timeout: Timeout.none);
}
