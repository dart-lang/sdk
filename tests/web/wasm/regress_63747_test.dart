// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

class Foo {
  final field = Uint8List(64);

  Foo(List<int> arg) {
    if (arg.length > 64) {
      arg = Uint8List(16);
    }
    field.setRange(0, arg.length, arg);
  }
}

class Bar {
  final field = Uint8List(64);
  final int initialLength;

  Bar(List<int> arg) : initialLength = (arg = Uint8List(16)).length {
    field.setRange(0, arg.length, arg);
  }
}

void main() {
  print(Foo(List<int>.filled(80, 0)).field);
  print(Bar(List<int>.filled(80, 0)).field);
}
