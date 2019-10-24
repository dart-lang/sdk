main() {
  dynamic foo = new X();
  var bar = foo.late;
  late();
  bar();
  new X().late();
  new Y().late;
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
