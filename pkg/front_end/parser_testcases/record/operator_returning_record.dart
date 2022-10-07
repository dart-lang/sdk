class Foo {
  (int, int) operator [](int foo) {
    return (42, 42);
  }
}

class Bar {
  (int, int)? operator [](int bar) {
    return (42, 42);
  }
}
