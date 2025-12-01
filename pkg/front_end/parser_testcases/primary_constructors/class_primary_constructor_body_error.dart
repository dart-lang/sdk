class C1() {
  this() {}
}

class C2() {
  this(int x) : assert(1 > 2) {}
}

class C3() {
  this();
}

class C4() {
  this(int x) : assert(1 > 2);
}
