// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:test/test.dart';

import 'expression_compiler_e2e_shared.dart';
import 'expression_compiler_e2e_suite.dart';

void main() async {
  var driver = await TestDriver.init();

  group('(Unsound null safety) (Agnostic code shard 1)', () {
    tearDownAll(() async {
      await driver.finish();
    });

    group('(DDC module system)', () {
      var setup = SetupCompilerOptions(
          soundNullSafety: false,
          legacyCode: false,
          moduleFormat: ModuleFormat.ddc);
      runAgnosticSharedTestsShard1(setup, driver);
    });
  });
}
