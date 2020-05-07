// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'src/driver_example_test.dart' as driver_example;
import 'src/driver_exclude_test.dart' as driver_exclude;
import 'src/driver_help_test.dart' as driver_help;
import 'src/driver_include_test.dart' as driver_include;
import 'src/driver_pedantic_test.dart' as driver_pedantic;
import 'src/driver_prefer_is_empty_test.dart' as driver_prefer_is_empty;
import 'src/driver_test.dart' as driver;
import 'src/migrate_command_test.dart' as migrate_command_test;
import 'src/options_test.dart' as options_test;

void main() {
  group('driver', driver_example.main);
  group('driver', driver_exclude.main);
  group('driver', driver_help.main);
  group('driver', driver_include.main);
  group('driver', driver_pedantic.main);
  group('driver', driver_prefer_is_empty.main);
  group('driver', driver.main);
  group('migrate', migrate_command_test.main);
  group('options', options_test.main);
}
