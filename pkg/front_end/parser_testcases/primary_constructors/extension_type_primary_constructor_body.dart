extension type E1(int x) {
  this {}
}

extension type E2(int x) {
  this : assert(1 > 2) {}
}

extension type E3(int x) {
  this;
}

extension type E4(int x) {
  this : assert(1 > 2);
}
