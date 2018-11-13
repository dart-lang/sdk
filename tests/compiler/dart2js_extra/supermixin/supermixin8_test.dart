// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class SuperA<T, S> {
  method() => T;
}

class SuperB<T, S> extends SuperA<T, S> {
  method() => S;
}

mixin Mixin<T, S> on SuperA<T, S> {
  method() => super.method();
}

class Class<T, S> extends SuperB<T, S> with Mixin<T, S> {}

main() {
  var c1 = new Class<int, String>();
  var c2 = new Class<String, int>();
  Expect.equals(String, c1.method());
  Expect.equals(int, c2.method());
}
