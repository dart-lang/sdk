extension type E1(int x) {
  this(this.x) {}
}

extension type E2(int x) {
  this(this.x)  : assert(1 > 2) {}
}

extension type E3(int x) {
  this(this.x) ;
}

extension type E4(int x) {
  this(this.x)  : assert(1 > 2);
}
