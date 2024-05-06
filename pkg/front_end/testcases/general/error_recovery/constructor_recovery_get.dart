class Foo {
  // Not OK.
  get Foo() { }
  // Not OK.
  get Foo() : initializer = true { }
  // Not OK.
  get Foo.x() { }
  // Not OK.
  get Foo.x() : initializer = true { }
}