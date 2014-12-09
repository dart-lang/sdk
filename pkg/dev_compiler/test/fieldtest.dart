library fieldtest;

class A {
  int x = 42;
}

int foo(A a) {
  print(a.x);
  return a.x;
}

int bar(a) {
  print(a.x);
  return a.x;
}

baz(A a) => a.x;

void main() {
  var a = new A();
  foo(a);
  bar(a);
  print(baz(a));
}
