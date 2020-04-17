// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_type1_test;

import 'dart:html';
import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
class A {
  external get foo;

  external A(var foo);
}

class F {
  final foo;

  F(this.foo);
}

@pragma('dart2js:noInline')
testA(A o) {
  return o.foo;
}

@pragma('dart2js:noInline')
testF(F o) {
  return o.foo;
}

_injectJs() {
  document.body!.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
function A(foo) {
  this.foo = foo;
}
""");
}

main() {
  _injectJs();

  var a = new A(1);
  var f = new F(6);

  Expect.equals(testA(a), 1);
  Expect.equals(testF(f), 6);
}
