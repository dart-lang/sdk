// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Copied from pkg/vm/testcases/bytecode/type_ops.dart

class A<T> {}

class B extends A<String> {}

class C<T1, T2, T3> extends B {}

foo1(x) {
  if (x is B) {
    print('11');
  }
  if (x is C<int, Object, dynamic>) {
    print('12');
  }
  return x as A<int>;
}

class D<P, Q> extends C<int, Q, P> {
  Map<P, Q> foo;

  D(tt) : foo = tt;

  foo2(y) {
    if (y is A<P>) {
      print('21');
    }
    if (y is C<dynamic, Q, List<P>>) {
      print('22');
    }
    foo = y;
  }

  foo3<T1, T2>(z) {
    if (z is A<T1>) {
      print('31');
    }
    if (z is C<Map<T1, P>, List<T2>, Q>) {
      print('32');
    }
    return (z as Map<T2, Q>).values;
  }

  Map<P, Q> foo4(w) {
    List<Map<P, Q>> list = [w];
    return w;
  }
}

List<Iterable> globalVar;

void foo5(x) {
  globalVar = x;
}

class E<P extends String> {
  factory E() => null;
  void foo6<T extends P, U extends List<T>>(Map<T, U> map) {}
}

abstract class F<T> {
  void foo7<Q extends T>(Q a, covariant num b, T c);
  void foo8<Q extends T>(Q a, covariant num b, T c);
}

class G<T> {
  void foo7<Q extends T>(Q a, int b, T c) {}
}

class H<T> extends G<T> implements F<T> {
  void foo8<Q extends T>(Q a, int b, T c) {}
}

main() {}
