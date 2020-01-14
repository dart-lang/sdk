// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo {
  static int x = 42;
}

class Bar extends Foo {
  static int x = 12;
}

void main() {
  Expect.equals(12, Bar.x);
}
