// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo {
  late final bool x;

  Foo() {
    build();
  }

  void build() {
    x = true;
  }
}

void main() {
  final foo = Foo();
  Expect.isTrue(foo.x);
}
