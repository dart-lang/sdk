library methods;

class A {
  int x() => 42;

  int y(int a) {
    return a;
  }

  int z([int b]) => b;

  int zz([int b = 0]) => b;

  int w(int a, {int b}) {
    return a + b;
  }

  int ww(int a, {int b: 0}) {
    return a + b;
  }

  int get a => x();

  void set b(int b) {}

  int _c = 3;

  int get c => _c;

  void set c(int c) {
    _c = c;
  }
}
