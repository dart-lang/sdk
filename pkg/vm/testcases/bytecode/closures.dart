// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int simpleClosure() {
  int x = 5;
  var inc = (int y) {
    x = x + y;
  };
  inc(3);
  return x;
}

class C1 {}

class C2 {}

class C3 {}

class C4 {}

class C5 {}

class C6 {}

class C7 {}

class C8 {}

class A<T1, T2> {
  void foo<T3, T4>() {
    void nested1<T5, T6>() {
      void nested2<T7, T8>() {
        var nested3 = () {
          print([T1, T2, T3, T4, T5, T6, T7, T8]);
          callWithArgs<T1, T2, T3, T4, T5, T6, T7, T8>();
        };
        nested3();
      }

      nested2<C7, C8>();
      nested2<List<C7>, List<C8>>();
    }

    nested1<C5, C6>();
    nested1<List<C5>, List<C6>>();
  }
}

void callWithArgs<T1, T2, T3, T4, T5, T6, T7, T8>() {
  print([T1, T2, T3, T4, T5, T6, T7, T8]);
}

void callA() {
  new A<C1, C2>().foo<C3, C4>();
  new A<C1, C2>().foo<List<C3>, List<C4>>();
  new A<List<C1>, List<C2>>().foo<List<C3>, List<C4>>();
}

class B {
  int foo;

  void topLevel() {
    {
      int x = 1;

      {
        int y = 2;
        int z = 3;

        var closure1 = (int y) {
          x = y + 1;

          if (x > 5) {
            int w = 4;

            void closure2() {
              z = x + 2;
              w = foo + y;
            }

            closure2();

            print(w);
          }
        };

        closure1(10);
        closure1(11);

        print(y);
        print(z);
      }

      print(x);
    }

    {
      int x = 42;

      var closure3 = () {
        foo = x;
      };

      closure3();
    }
  }
}

class C {
  void testForLoop() {
    int delta = 0;
    List<Function> getI = <Function>[];
    List<Function> setI = <Function>[];
    for (int i = 0; i < 10; i++) {
      getI.add(() => i + delta);
      setI.add((int ii) {
        i = ii + delta;
      });
    }
  }

  void testForInLoop(List<int> list) {
    for (var i in list) {
      var inc = () {
        i = i + 1;
      };
      inc();
      print(i);
    }
  }
}

typedef IntFunc(int arg);

IntFunc testPartialInstantiation() {
  void foo<T>(T t) {}
  IntFunc intFunc = foo;
  return intFunc;
}

class D<T> {
  foo(T t) {
    return () => t;
  }

  bar() {
    return () {
      inner() {}

      inner();
    };
  }
}

abstract class E {
  int Function(int x, int y) foo1;
  int Function<T>(T x, T y) get foo2;
  int evalArg1();
  int evalArg2();
  E getE();

  int testCallThroughGetter1() => foo1(evalArg1(), evalArg2());
  int testCallThroughGetter2() => foo2<int>(evalArg1(), evalArg2());
  int testCallThroughGetter3() => getE().foo2<int>(evalArg1(), evalArg2());
}

main() {}
