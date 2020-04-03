// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'required_name_override_lib.dart';

class B {
  void test_default({int? i}) {}
  void test_nondefault({int? i = 1}) {}
}

class A extends B implements C {
  void test_default({required int? i}) {}
  void test_nondefault({required int? i}) {}
  void test_legacy({required int? i}) {}
}

main() {
  A().test_default(i: 1);
  A().test_nondefault(i: 1);
  A().test_legacy(i: 1);
}
