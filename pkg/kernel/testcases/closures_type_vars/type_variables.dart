// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class C<T, S> {
  foo(S s) => (T x) {
        T y = x;
        Object z = y;
        C<T, S> self = this;
        return z as T;
      };

  bar() {
    C<T, S> self = this;
  }

  baz() {
    return () => () => new C<T, S>();
  }

  factory C() {
    local() {
      C<T, S> self = new C<T, S>.internal();
      return self;
    }

    return local();
  }
  C.internal();
}

fn<A>(A x) {
  var fn2 = (A x2) {
    var l = <A>[];
    l.add(x2);
    return l;
  };
  return fn2(x);
}

main(arguments) {
  print(new C<String, String>().foo(null)(arguments.first));
  dynamic c = new C<int, int>().baz()()();
  if (c is! C<int, int>) throw "$c fails type test 'is C<int, int>'";
  if (c is C<String, String>) {
    throw "$c passes type test 'is C<String, String>'";
  }
  print(c);
  print(fn<int>(3));
}
