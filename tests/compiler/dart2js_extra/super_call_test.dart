class A {
  foo() => "A.foo${baz()}";
  baz() => "A.baz";
  hest(String s, int i) => "$s$i";
}

class B extends A {
  foo() => "B.foo${super.foo()}";
  baz() => "B.baz";
  hest(s, i) => "B.hest${super.hest(s, i)}";
}

main() {
  B b = new B();
  Expect.equals("B.fooA.fooB.baz", b.foo());
  Expect.equals("B.hestfisk42", b.hest('fisk', 42));
}
