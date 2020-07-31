// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_type2_test;

import 'dart:html';
import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
@anonymous
class C {
  external get foo;

  external factory C({required foo});
}

@JS()
@anonymous
class D {
  external get foo;

  external factory D({required foo});
}

class F {
  final foo;

  F(this.foo);
}

@pragma('dart2js:noInline')
testC(C o) {
  return o.foo;
}

@pragma('dart2js:noInline')
testF(F o) {
  return o.foo;
}

main() {
  dynamic d = new D(foo: 4);
  var f = new F(6);
  Expect.equals(testC(d), 4);
  Expect.equals(testF(f), 6);
}
