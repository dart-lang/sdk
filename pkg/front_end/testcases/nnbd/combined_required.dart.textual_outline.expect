class A {
  void method1({required int a}) {}
  void method2({int? a, required int b}) {}
}

class B {
  void method1({required covariant int a}) {}
  void method2({covariant int? a, required int b}) {}
}

class C extends A implements B {}

class D extends C {
  void method1({required covariant int a}) {}
  void method2({covariant int? a, required int b}) {}
}

main() {}
