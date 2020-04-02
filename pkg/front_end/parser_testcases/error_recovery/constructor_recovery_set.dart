class Foo {
  set Foo() {
    // Not OK.
  }
  set Foo() : initializer = true {
    // Not OK.
  }
  set Foo.x() {
    // Not OK.
  }
  set Foo.x() : initializer = true {
    // Not OK.
  }
}