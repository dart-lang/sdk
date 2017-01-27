// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:typed_data';

import 'package:expect/expect.dart';

var list = [1, 2, 3];

class Foo {
  final value;
  Foo(this.value) {}

  factory Foo.fac(value) {
    return new Foo(value);
  }
}

main() {
  Expect.isTrue(new Uint8List.fromList(list)[1] == 2);
  Expect.isTrue(new Foo.fac(10).value == 10);
}
