class A {}

class B extends A {}

main() {
  A a = A();
  var b = B();
  print(a is A);
  print(b is B);
  print(b is A);
  print(a is B);
}