// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'helper_lib.dart' as async;

class A {
  async.async get x => async.async();
}

class B {
  int get async => 0;
}

async.async topLevel() => async.async();

main() {
  var a = new A();
  var b = a.x;
  var c = topLevel();
  var d = new B();
  var e = d.async;
}
