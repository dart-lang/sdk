import "test4.dart";

class Bar<E> {}

class Baz<E> {}

class Qux1<E> {
  Qux1AndAHalf? qux1AndAHalf() {
    // nothing...
  }
}

class Qux1AndAHalf<E> {}

class Qux2<E> {
  Qux3? foo() {}
}

enum x { A, B, C }

int foo() {
  return 42;
}

int foo2 = foo() * 2, foo3 = foo() * 3;
