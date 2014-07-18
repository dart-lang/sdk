// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import "dart:_js_helper";
import "package:expect/expect.dart";

@Native("B")
class B {
  // Having this field in a native class will generate accessors with
  // the interceptor calling convention.
  var f;
}

class A {
  int f;
}

const symF = const Symbol('f');

main() {
  var a = new A();

  InstanceMirror mirror = reflect(a);
  mirror.setField(symF, 42);
  Expect.equals(42, a.f);

  mirror = mirror.getField(symF);
  Expect.equals(42, mirror.reflectee);
}
