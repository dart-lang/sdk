main() {
  dynamic foo = new X();
  var bar = foo.late;
  late();
  bar();
  new X().late();
  new Y().late;
  
  // And now the late modifiers
  late int foo;
  foo = 42;
}

late() {
  print("hello");
}

class X {
  late() {
    print("hello");
  }
}

class Y {
  int late = 42;
}
