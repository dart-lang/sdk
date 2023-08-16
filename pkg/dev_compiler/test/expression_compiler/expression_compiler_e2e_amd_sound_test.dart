// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:test/test.dart';

import 'expression_compiler_e2e_shared.dart';
import 'expression_compiler_e2e_suite.dart';
import 'setup_compiler_options.dart';

void main(List<String> args) async {
  // Set to `true` for debug output.
  final debug = false;
  var driver = await TestDriver.init();

  group('(Sound null safety)', () {
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
      setup.options.verbose = debug;
      runNullSafeSharedTests(setup, driver);
    });
  });
}
