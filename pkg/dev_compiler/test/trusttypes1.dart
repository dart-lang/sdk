import 'dart:math';

class A {
  int x = 42;
}
void bar(A a) {
  // Is this integer addition?
  print(a.x + a.x);
}

void main() {
  Map<A, Function> map = <A, Function>{
    new A(): bar,
    new B(new Point<int>(1,2)): print,
  };
  map.forEach((A a, Function f) => f(a));
}

class B extends A {
  var _x;
  B(this._x);

  get x => _x;
}
