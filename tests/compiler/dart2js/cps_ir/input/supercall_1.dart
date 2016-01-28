class Base {
  m(x) {
    print(x+1);
  }
}
class Sub extends Base {
  m(x) => super.m(x+10);
}
main() {
  new Sub().m(100);
}
