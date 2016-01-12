class Foo {
  factory Foo.make(x) = Foo.create;
  var x;
  Foo.create(this.x);
}
main() {
  print(new Foo.make(5));
}
