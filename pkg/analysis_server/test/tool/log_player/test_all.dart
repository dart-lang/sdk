// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'message_equality_test.dart' as message_equality_test;

void main() {
  defineReflectiveSuite(() {
    message_equality_test.main();
  }, name: 'log_player');
}
