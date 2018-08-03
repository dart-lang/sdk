@JS()
library js_typed_interop_type2_test;

import 'dart:html';
import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
@anonymous
class C {
  final foo;

  external factory C({foo});
}

@JS()
@anonymous
class D {
  final foo;

  external factory D({foo});
}

class F {
  final foo;

  F(this.foo);
}

@NoInline()
testC(C o) {
  return o.foo;
}

@NoInline()
testF(F o) {
  return o.foo;
}

main() {
  dynamic d = new D(foo: 4);
  var f = new F(6);
  Expect.equals(testC(d), 4);
  Expect.equals(testF(f), 6); //# 01: ok
}
