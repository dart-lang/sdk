// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'src/driver_test.dart' as driver_test;
import 'src/options_test.dart' as options_test;

main() {
  group('driver', driver_test.main);
  group('options', options_test.main);
}
