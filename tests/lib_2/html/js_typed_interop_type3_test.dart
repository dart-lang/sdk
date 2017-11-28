@JS()
library js_typed_interop_type3_test;

import 'dart:html';
import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
class A {
  external get foo;

  external A(var foo);
}

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
testA(A o) {
  return o.foo;
}

@NoInline()
testC(C o) {
  return o.foo;
}

@NoInline()
testD(D o) {
  return o.foo;
}

@NoInline()
testF(F o) {
  return o.foo;
}

_injectJs() {
  document.body.append(new ScriptElement()
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
  dynamic d = new D(foo: 4);

  Expect.equals(testA(a), 1); //# 01: ok
  Expect.equals(testA(a), 1); //# 02: ok
  Expect.equals(testA(d), 4);
  Expect.equals(testD(d), 4); //# 02: continued
}
