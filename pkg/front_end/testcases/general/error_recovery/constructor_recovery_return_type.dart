class Foo {
  void Foo() {
    // Not OK.
  }
  void Foo() : initializer = true {
    // Not OK.
  }
  void Foo.x() {
    // Not OK.
  }
  void Foo.x() : initializer = true {
    // Not OK.
  }
}
