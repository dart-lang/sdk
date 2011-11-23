#library("test");
#import("QualifiedReturnTypeA.dart", prefix : "pref");

class A {
  pref.A foo() {
    return new pref.A();
  }
}
