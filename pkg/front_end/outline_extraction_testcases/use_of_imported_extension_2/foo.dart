enum Foo {
  a,
  b,
  c,
  d,
  e,
}

extension FooExtension on Foo {
  int get giveInt => 42;
}

// The below doesn't have to be included.

extension BarExtension on Bar {
  int get giveInt => 42;
}

class Bar {}
