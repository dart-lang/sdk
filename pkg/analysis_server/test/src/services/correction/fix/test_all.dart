// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'extend_class_for_mixin_test.dart' as extend_class_for_mixin;

main() {
  defineReflectiveSuite(() {
    extend_class_for_mixin.main();
  }, name: 'fix');
}
