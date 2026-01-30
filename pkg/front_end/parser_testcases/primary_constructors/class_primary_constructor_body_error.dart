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

class C5() {
  const this;
}

class C6() {
  covariant this;
}

class C7() {
  external this;
}

class C8() {
  final this;
}

class C9() {
  late this;
}

class C10() {
  static this;
}

class C11() {
  var this;
}
