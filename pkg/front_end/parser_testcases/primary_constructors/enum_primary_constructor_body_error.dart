enum const E1() {
  this() {}
}

enum const E2() {
  this(int x) : assert(1 > 2) {}
}

enum const E3() {
  this();
}

enum const E4() {
  this(int x) : assert(1 > 2);
}

enum const E5() { // missing constants
  this : assert(1 > 2);
}

enum const E6() { // missing constants
  this {}
}
