// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.16

// ignore_for_file: unused_local_variable

import 'dart:ffi';

class Foo implements Finalizable {}

void main() {
  late Foo foo;
  if (DateTime.now().millisecond % 2 == 0) {
    foo = Foo();
  }

  for (int i = 0; i < 3; i++) late Foo foo2;

  for (final i in [1, 2, 3]) late Foo foo3;

  if (DateTime.now().millisecond % 2 == 0) late Foo foo4;

  try {
    late Foo foo5;
  } catch (e) {
    late Foo foo6;
  } finally {
    late Foo foo7;
  }

  switch (DateTime.now().millisecond) {
    case 1:
      late Foo foo8;
      break;
    default:
      late Foo foo9;
  }

  final x = () {
    late Foo foo10;
  };

  // ignore: unused_element
  bar() {
    late Foo foo11;
  }
}
