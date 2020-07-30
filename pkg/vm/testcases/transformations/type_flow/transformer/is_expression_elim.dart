class A {}

class B extends A {}

class C with A {}

A a = A();
var b = B();
A c = C();

main() {
  print(a is A);
  print(b is B);
  print(b is A);
  print(a is B);
  print(c is A);
  print(c is B);
  print(c is C);
}