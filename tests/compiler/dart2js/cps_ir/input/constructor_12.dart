class Foo {
  factory Foo.make(x) {
    print('Foo');
    return new Foo.create(x);
  }
  var x;
  Foo.create(this.x);
}
main() {
  print(new Foo.make(5));
}
