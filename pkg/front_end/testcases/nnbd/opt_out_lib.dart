// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

// The intent of this file is to show that it's an error to use NNBD features in
// an opt-in library.

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

errors() {
  late int local = 42;
  List<String?> l = null;
  String? s = null;
  var t = s!;
  dynamic c;
  c?..f;
  c?.[0];
}
