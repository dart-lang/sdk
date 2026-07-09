void foo1({required int x1}) {
  print(x);
}

void foo2({required x2}) {
  print(x);
}

void foo3({required required x3}) {
  print(x);
}

class Foo {
  void foo4({required covariant int x4}) {
    print(x);
  }
}