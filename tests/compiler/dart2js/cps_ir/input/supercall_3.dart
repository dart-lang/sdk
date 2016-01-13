class Base {
  var field = 123;
}
class Sub extends Base {
  m(x) => x + super.field;
}
main() {
  print(new Sub().m(10));
}
