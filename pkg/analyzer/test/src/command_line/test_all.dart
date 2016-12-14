// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.command_line.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'command_line_parser_test.dart' as command_line_parser_test;
import 'arguments_test.dart' as arguments_test;

main() {
  defineReflectiveSuite(() {
    command_line_parser_test.main();
    arguments_test.main();
  }, name: 'command_line');
}
