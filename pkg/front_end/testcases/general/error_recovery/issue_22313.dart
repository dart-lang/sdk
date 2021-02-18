class A { }
// @dart=2.9
class B { }

class Foo extends A, B {
  Foo() { }
}

class Bar extend A, B {
  Bar() { }
}

class Baz on A, B {
  Baz() { }
}

main() {}