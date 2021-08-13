import 'a.dart' deferred as alib;

class B {
  const B();
}

void f() {
  var a = alib.A(); // OK
  var b = B(); // LINT
}
