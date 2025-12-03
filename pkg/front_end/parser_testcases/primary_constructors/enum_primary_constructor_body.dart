enum const E1() {
  e;
  this {}
}

enum const E2() {
  e;
  this : assert(1 > 2) {}
}

enum const E3() {
  e;
  this;
}

enum const E4() {
  e;
  this : assert(1 > 2);
}
