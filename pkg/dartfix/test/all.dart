// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'src/client_version_test.dart' as client_version_test;
import 'src/driver_exclude_test.dart' as driver_exclude_test;
import 'src/driver_help_test.dart' as driver_list_test;
import 'src/driver_include_test.dart' as driver_include_test;
import 'src/driver_required_test.dart' as driver_required_test;
import 'src/driver_test.dart' as driver_test;
import 'src/options_test.dart' as options_test;

main() {
  client_version_test.main();
  group('driver', driver_exclude_test.main);
  group('driver', driver_include_test.main);
  group('driver', driver_list_test.main);
  group('driver', driver_required_test.main);
  group('driver', driver_test.main);
  group('options', options_test.main);
}
