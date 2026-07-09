class A {
  A(int x);
  A.y(int x);
}

class B extends A {
  B(int x) : assert(x > 0), super(x);
}

class B2 extends A {
  B2(int x) : assert(x > 0), super.y(x);
}

class B3 extends A {
  B3(int x) : assert(x > 0), this.y(x);
  B3.y(int x);
}

class C extends A {
  int y;
  C(int x) : assert(x > 0), y = 2*21;
}

class D extends A {
  D(int x) : assert(x > 0), assert(x - 1 > 0);
}

class E extends A {
  final int y;
  E(int x) : assert(x > 0), this.y = x*2;
}
