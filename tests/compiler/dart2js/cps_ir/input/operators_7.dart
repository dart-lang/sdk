class Foo {
  operator[]=(index, value) {
    print(value);
  }
}
main() {
  var foo = new Foo();
  foo[5] = 6;
}
