class A {
  int x = 42;
}

typedef int AA(A a);

void bar(AA aa, a) {
  // Is this integer addition?
  print(aa(a) + aa(a));
}

void main() {
  List<A> list = <A>[];
  list.add(new A());
  list.add(new B(new Point(1,2)));
  list.forEach((A a) => bar((a) => a.x, a));
}

class B extends A {
  var _x;
  B(this._x);

  get x => _x;
}

class Point {
  int x;
  int y;
  Point(this.x, this.y);
  Point operator+(Point other) {
    return new Point(this.x + other.x, this.y + other.y);
  }
  String toString() => "($x, $y)";
}
