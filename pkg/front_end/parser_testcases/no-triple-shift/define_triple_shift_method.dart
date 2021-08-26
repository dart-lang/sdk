class Foo {
  Foo operator >>>(_) => this;
}

main() {
  Foo foo = new Foo();
  foo >>> 42;
  print(foo >>> 42);
  print(foo >>>= 42);
  if ((foo >>>= 42) == foo) {
    print("same");
  }
}
