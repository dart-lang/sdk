// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class SuperA<T> {
  method() => null;
}

class SuperB<T> extends SuperA<T> {
  method() => T;
}

mixin Mixin<T> on SuperA<T> {
  method() => super.method();
}

class Class<T> extends SuperB<T> with Mixin<T> {}

main() {
  var c1 = new Class<String>();
  var c2 = new Class<int>();
  Expect.equals(String, c1.method());
  Expect.equals(int, c2.method());
}
