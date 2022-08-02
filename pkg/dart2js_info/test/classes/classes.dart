import 'package:expect/expect.dart';

class Super<T> {
  void method(T t) {
    print(t.runtimeType);
  }
}

class Mixin {
  void method(int t) {
    print(t + 1);
  }
}

class Clazz = Super<int> with Mixin;

class Subclass extends Clazz {
  void test() {
    void Function(int) f = super.method;
    f(42);
    print(f);
  }
}

class Subsub1 extends Subclass {
  void a(dynamic x) {
    print(x);
  }
}

class Subsub2 extends Subclass {
  void a(dynamic x) {
    print(x);
    print(x);
  }
}

void main() {
  Super<Object> s = Subclass()..test();
  Expect.throws(() => s.method(''));
  dynamic x = Subsub1();
  x.a(x);
  x = Subsub2();
  x.a(x);
}
