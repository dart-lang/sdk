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
    Uri source, List<String> experimentalFlags, bool soundNullSafety) async {
  final target =
      TestingDart2jsTarget(TargetFlags(enableNullSafety: soundNullSafety));
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
        final bool unsoundNullSafety = path.endsWith('_unsound.dart');
        test(
            path,
            () => runTestCase(
                entry.uri, const ['non-nullable'], !unsoundNullSafety));
      }
    }
  }, timeout: Timeout.none);
}
