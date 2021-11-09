// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:dev_compiler/dev_compiler.dart' show ModuleFormat;
import 'package:test/test.dart';
import 'expression_compiler_e2e_shared.dart';
import 'expression_compiler_e2e_suite.dart';

void main() async {
  var driver = await TestDriver.init();

  group('(Sound null safety)', () {
    tearDownAll(() async {
      await driver.finish();
    });

    group('(DDC module system)', () {
      var setup = SetupCompilerOptions(
          soundNullSafety: true,
          legacyCode: false,
          moduleFormat: ModuleFormat.ddc);
      runAgnosticSharedTests(setup, driver);
      runNullSafeSharedTests(setup, driver);
    });
  });
}
