library fieldtest;

class A {
  int x = 42;
}

void foo(A a) {
  print(a.x);
}

void bar(a) {
  print(a.x);
}

void main() {
  A a = new A();
  foo(a);
  bar(a);
}

