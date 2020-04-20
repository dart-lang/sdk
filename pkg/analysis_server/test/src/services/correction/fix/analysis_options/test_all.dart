// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'remove_setting_test.dart' as remove_setting;

void main() {
  defineReflectiveSuite(() {
    remove_setting.main();
  });
}
