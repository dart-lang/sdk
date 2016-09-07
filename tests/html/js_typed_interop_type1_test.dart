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

@NoInline()
testA(A o) {
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

void expectValueOrTypeError(f(), value) {
  try {
    var i = 0;
    String s = i; // Test for checked mode.
    Expect.equals(f(), value);
  } on TypeError catch (error) {
    Expect.throws(f, (ex) => ex is TypeError);
  }
}

main() {
  _injectJs();

  var a = new A(1);
  var f = new F(6);

  Expect.equals(testA(a), 1);
  Expect.equals(testF(f), 6); /// 01: ok
}


