import "b.dart";

var x = A.b().c().d;

class A {
  static B b() {
    return new B();
  }
}
