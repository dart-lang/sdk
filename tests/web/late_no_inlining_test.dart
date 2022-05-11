// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--disable-inlining

import 'package:expect/expect.dart';

// Tests to ensure that narrowing type information does not discard late
// sentinel values unintentionally.

class Foo {
  late int bar = 42;
  late final int baz = 1729;
}

void main() {
  final foo = Foo();
  Expect.equals(42, foo.bar);
  Expect.equals(1729, foo.baz);
}
