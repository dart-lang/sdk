f() {
  var a, b;

  a?.call<Foo>(b);
  a?<Foo>(b);
}