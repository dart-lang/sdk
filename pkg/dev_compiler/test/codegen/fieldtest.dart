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

int compute() => 123;
int y = compute() + 444;

String get q => 'life, ' + 'the universe ' + 'and everything';
int get z => 42;
int set z(value) {
  y = value;
}

void main() {
  var a = new A();
  foo(a);
  bar(a);
  print(baz(a));
}
