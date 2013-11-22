// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is a helper for run.sh. We try to run all of the Dart code in one
 * instance of the Dart VM to reduce warm-up time.
 */
library run_impl;

import 'package:unittest/compact_vm_config.dart';
import 'testing.dart';

import 'big_1_test.dart' as big_1_test;
import 'compiler_test.dart' as compiler_test;
import 'declaration_test.dart' as declaration_test;
import 'debug_test.dart' as debug_test;
import 'error_test.dart' as error_test;
import 'extend_test.dart' as extend_test;
import 'mixin_test.dart' as mixin_test;
import 'nested_test.dart' as nested_test;
import 'selector_test.dart' as selector_test;
import 'var_test.dart' as var_test;
import 'visitor_test.dart' as visitor_test;

void main(List<String> arguments) {
  var pattern = new RegExp(arguments.length > 0 ? arguments[0] : '.');

  useCompactVMConfiguration();
  useMockMessages();

  if (pattern.hasMatch('debug_test.dart')) debug_test.main();
  if (pattern.hasMatch('compiler_test.dart')) compiler_test.main();
  if (pattern.hasMatch('declaration_test.dart')) declaration_test.main();
  if (pattern.hasMatch('var_test.dart')) var_test.main();
  if (pattern.hasMatch('nested_test.dart')) nested_test.main();
  if (pattern.hasMatch('selector_test.dart')) selector_test.main();
  if (pattern.hasMatch('mixin_test.dart')) mixin_test.main();
  if (pattern.hasMatch('extend_test.dart')) extend_test.main();
  if (pattern.hasMatch('big_1_test.dart')) big_1_test.main();
  if (pattern.hasMatch('visitor_test.dart')) visitor_test.main();
  if (pattern.hasMatch('error_test.dart')) error_test.main();
}
