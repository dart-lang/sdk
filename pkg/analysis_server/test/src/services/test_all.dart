// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'correction/test_all.dart' as correction_all;
import 'flutter/test_all.dart' as flutter_all;

void main() {
  defineReflectiveSuite(() {
    correction_all.main();
    flutter_all.main();
  }, name: 'services');
}
