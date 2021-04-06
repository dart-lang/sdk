// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

library dev_compiler.test.expression_compiler;

import 'package:dev_compiler/dev_compiler.dart' show ModuleFormat;
import 'package:test/test.dart';
import 'expression_compiler_e2e_shared.dart';
import 'expression_compiler_e2e_suite.dart';

void main() async {
  var driver = await TestDriver.init();

  group('(Unsound null safety)', () {
    tearDownAll(() {
      driver.finish();
    });

    group('(AMD module system)', () {
      var setup = SetupCompilerOptions(
          soundNullSafety: false, moduleFormat: ModuleFormat.amd);
      runSharedTests(setup, driver);
    });

    group('(DDC module system)', () {
      var setup = SetupCompilerOptions(
          soundNullSafety: false, moduleFormat: ModuleFormat.ddc);
      runSharedTests(setup, driver);
    });
  });
}
