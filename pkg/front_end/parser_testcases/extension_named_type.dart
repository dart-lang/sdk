class A {}

extension type on A {
  method() {}
}

test(A a) => type(new A()).method();
