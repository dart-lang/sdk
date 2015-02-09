class A {
  var x;
}

void test_closure_with_mutate() {
  var a = new A();
  a.x = () {
    print("hi");
    a = null;
  };
  a
    ..x()
    ..x();
  print(a);
}

void test_closure_without_mutate() {
  var a = new A();
  a.x = () {
    print(a);
  };
  a
    ..x()
    ..x();
  print(a);
}

void test_mutate_inside_cascade() {
  var a;
  a = new A()
    ..x = (a = null)
    ..x = (a = null);
  print(a);
}

void test_mutate_outside_cascade() {
  var a, b;
  a = new A()
    ..x = (b = null)
    ..x = (b = null);
  a = null;
  print(a);
}

void test_VariableDeclaration_single() {
  var a = []
    ..length = 2
    ..add(42);
  print(a);
}

void test_VariableDeclaration_last() {
  var a = 42,
      b = []
        ..length = 2
        ..add(a);
  print(b);
}

void test_VariableDeclaration_first() {
  var a = []
    ..length = 2
    ..add(3),
      b = 2;
  print(a);
}
