library runtimetypechecktest;

class A<T> {
  T x;
  A(this.x);

  isT(t) => t is T;
}

class B extends A<int> {
  B(int x) : super(x);
}

int foo(B b) => b.x;

typedef int Foo(B b);

void main() {
  var a = new B(42);
  print(a is A);
  print(a as A);
  print(a is B);
  print(a as B);
  print(a is A<int>);
  print(a as A<int>);
  print(foo is Foo);
  print(a is dynamic);
  print(a as dynamic);
}

