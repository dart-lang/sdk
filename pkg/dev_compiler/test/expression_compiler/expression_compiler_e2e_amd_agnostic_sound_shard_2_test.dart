// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'expression_compiler_e2e_shared.dart';
import 'expression_compiler_e2e_suite.dart';

void main(List<String> args) async {
  var driver = await ExpressionEvaluationTestDriver.init();

  group('(Sound null safety) (Agnostic code shard 2)', () {
    tearDownAll(() async {
      await driver.finish();
    });

    group('(AMD module system)', () {
      var setup = SetupCompilerOptions(
        soundNullSafety: true,
        legacyCode: false,
        moduleFormat: ModuleFormat.amd,
        args: args,
      );
      runAgnosticSharedTestsShard2(setup, driver);
    });
  });
}
