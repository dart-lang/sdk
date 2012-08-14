library test;
import "QualifiedReturnTypeA.dart" as pref;

class A {
  pref.A foo() {
    return new pref.A();
  }
}
