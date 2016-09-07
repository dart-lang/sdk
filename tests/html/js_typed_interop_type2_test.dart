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

void expectValueOrTypeError(f(), value) {
  try {
    var i = 0;
    String s = i; // Test for checked mode.
  } on TypeError catch (error) {
    Expect.throws(f, (ex) => ex is TypeError);
  }
}

main() {
  var d = new D(foo: 4);
  var f = new F(6);
  Expect.equals(testC(d), 4);
  Expect.equals(testF(f), 6); /// 01: ok
}


