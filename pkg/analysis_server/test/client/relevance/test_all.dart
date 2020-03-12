// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'type_member_relevance_test.dart' as type_member_relevance_test;

void main() {
  defineReflectiveSuite(() {
    type_member_relevance_test.main();
  });
}
