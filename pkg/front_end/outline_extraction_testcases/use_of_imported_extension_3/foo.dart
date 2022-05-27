enum Foo {
  a,
  b,
  c,
  d,
  e,
}

extension FooExtension on Foo {
  Function(int) get foobar => (int value) => 42;
}

// The below doesn't have to be included.

extension BarExtension on Bar {
  Function(int) get foobar => (int value) => 42;
}

class Bar {}
