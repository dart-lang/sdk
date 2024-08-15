// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;

import '../shared_test_options.dart';
import 'assertions_enabled_common.dart';
import 'expression_compiler_e2e_suite.dart';

void main(List<String> args) async {
  final debug = false;
  final driver = await ExpressionEvaluationTestDriver.init();
  runTests(
      driver,
      SetupCompilerOptions(moduleFormat: ModuleFormat.amd, args: args)
        ..options.verbose = debug);
}
