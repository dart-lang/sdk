// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test((int, String, {double d, void Function() f, Class c})? record,
      List<(int, String, {double d, void Function() f, Class c})>? list) {
  record.$1; // Error
  record.$2; // Error
  record.d; // Error
  record.f; // Error
  record.c; // Error
  record.$1(); // Error
  record.$2(); // Error
  record.d(); // Error
  record.f(); // Error
  record.c(); // Error

  record?.$1; // Ok
  record?.$2; // Ok
  record?.d; // Ok
  record?.f; // Ok
  record?.c; // Ok
  record?.$1(); // Ok
  record?.$2(); // Ok
  record?.d(); // Ok
  record?.f(); // Ok
  record?.c(); // Ok

  record?.$1.isEven; // Ok
  record?.$2.length; // Ok
  record?.d.isNaN; // Ok
  record?.f.call; // Ok
  record?.c.call; // Ok

  list?.first.$1; // Ok
  list?.first.$2; // Ok
  list?.first.d; // Ok
  list?.first.f; // Ok
  list?.first.c; // Ok
  list?.first.$1(); // Ok
  list?.first.$2(); // Ok
  list?.first.d(); // Ok
  list?.first.f(); // Ok
  list?.first.c(); // Ok

  list?.first.$1.isEven; // Ok
  list?.first.$2.length; // Ok
  list?.first.d.isNaN; // Ok
  list?.first.f.call; // Ok
  list?.first.c.call; // Ok
}

extension on int {
  void call() {}
}

extension on String {
  void call() {}
}

extension on double {
  void call() {}
}

class Class {
  void call() {}
}