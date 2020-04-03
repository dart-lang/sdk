// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class SuperA<T> {
  method() => T;
}

class SuperB extends SuperA<int> {
  method() => String;
}

mixin Mixin<T> on SuperA<T> {
  method() => super.method();
}

class Class extends SuperB with Mixin<int> {}

main() {
  var c = new Class();
  Expect.equals(String, c.method());
}
