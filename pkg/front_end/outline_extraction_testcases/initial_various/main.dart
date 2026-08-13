import "main.dart" as self;
import "test3.dart";

class Foo<E> extends Bar<int> with Qux1<int> implements Baz<Bar<int>> {
  Foo<E>? parent;

  Foo() {}
  Foo.bar() {}
  F? fooMethod1<F>() {
    print(foo);
    print(F);
    print(x.A);
  }

  E? fooMethod2() {
    print(E);
    print(x.A);
  }

  self.Foo? fooMethod3() {
    print(E);
    print(x.A);
  }

  x fooMethod4() {
    return x.A;
  }
}
