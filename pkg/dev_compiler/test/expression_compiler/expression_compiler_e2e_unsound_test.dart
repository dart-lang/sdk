// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

library dev_compiler.test.expression_compiler;

import 'package:test/test.dart';
import 'expression_compiler_e2e_shared.dart';
import 'expression_compiler_e2e_suite.dart';

void main() async {
  var driver = await TestDriver.init();
  var setup = SetupCompilerOptions(soundNullSafety: false);

  group('(Unsound null safety)', () {
    tearDownAll(() {
      driver.finish();
    });

    runSharedTests(setup, driver);
  });
}
