List<Foo> bootstrap() {
  return <Foo>[new Foo()];
}

typedef B A2B<A, B>(A x);

A2B<Foo, Foo> id(A2B<Foo, Foo> f) => f;

class Foo {
}

void main() {
  print(bootstrap()[0]);
}
