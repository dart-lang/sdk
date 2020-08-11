// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains benign use of NNBD features that shouldn't result in
// compile-time errors.

import 'opt_out_lib.dart';

class A<T> {
  late int field = 42;
}

class B extends A<String?> {}

typedef F = void Function()?;

List<String?> l = [];
String? s = null;
var t = s!;

late int field = 42;

void method(void f()?, {required int a}) {}

main() {}

noErrors() {
  late int local = 42;
  String? s = null;
  dynamic c;
  c?..f;
  c?[0];
}
