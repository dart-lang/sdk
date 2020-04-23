// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist/test_all.dart' as assist_all;
import 'fix/test_all.dart' as fix_all;

void main() {
  defineReflectiveSuite(() {
    assist_all.main();
    fix_all.main();
  }, name: 'correction');
}
