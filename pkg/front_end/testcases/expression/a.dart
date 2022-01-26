import "b.dart";

main() {
  Foo foo = new Foo();
  print(foo.foo);
}

class Foo<E1> {
  E1 get foo => null;
  String get bar => "hello";
}

class Bar {}
