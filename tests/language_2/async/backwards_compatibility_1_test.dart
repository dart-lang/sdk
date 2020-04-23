// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'helper_lib.dart' as async;

class A {
  async.async get x => null;
}

class B {
  int get async => null;
}

async.async topLevel() => null;

main() {
  var a = new A();
  var b = a.x;
  var c = topLevel();
  var d = new B();
  var e = d.async;
}
