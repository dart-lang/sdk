class Base {
  m(x) {
    try { print(x+1); } finally { }
  }
}
class Sub extends Base {
  m(x) => super.m(x+10);
}
main() {
  new Sub().m(100);
}
