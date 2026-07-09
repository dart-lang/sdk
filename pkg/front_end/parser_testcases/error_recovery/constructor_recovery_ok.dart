class Foo {
  Foo() {
    // OK.
  }
  Foo() : initializer = true {
    // OK.
  }
  Foo.x() {
    // OK.
  }
  Foo.x() : initializer = true {
    // OK.
  }
}