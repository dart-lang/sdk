// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check function subtyping of type arguments. These cases use typedefs as type
// arguments, and the typedefs have type parameters that are used more than
// once.

import 'package:expect/expect.dart';

typedef A F<A>(A arg1, A arg2);
typedef B G<A, B>(B arg1, B arg2);

typedef Set<A> FS<A>(Set<A> arg1, Set<A> arg2);

@NoInline()
@AssumeDynamic()
dyn(x) => x;

class CheckEnv<X, Y> {
  test(bool intX) {
    Expect.isTrue(<F<X>>[] is List<F>);
    Expect.isTrue(<F<X>>[] is List<F<X>>);
    Expect.isTrue(<F<X>>[] is List<G<Y, X>>);

    Expect.isTrue(dyn(<F<X>>[]) is List<F>);
    Expect.isTrue(dyn(<F<X>>[]) is List<F<X>>);
    Expect.isTrue(dyn(<F<X>>[]) is List<G<Y, X>>);

    Expect.isFalse(<F<X>>[] is List<F<Y>>);
    Expect.isFalse(<F<X>>[] is List<G<X, Y>>);

    Expect.isFalse(dyn(<F<X>>[]) is List<F<Y>>);
    Expect.isFalse(dyn(<F<X>>[]) is List<G<X, Y>>);

    Expect.isFalse(dyn(<FS<X>>[]) is List<FS>);
    Expect.isFalse(dyn(<FS<X>>[]) is List<FS<Null>>);
    Expect.isTrue(dyn(<FS<X>>[]) is List<FS<X>>);
    if (intX) {
      Expect.isTrue(dyn(<FS<X>>[]) is List<FS<int>>);
      Expect.isTrue(dyn(<FS<int>>[]) is List<FS<X>>);
      Expect.isFalse(dyn(<FS<Y>>[]) is List<FS<int>>);
      Expect.isFalse(dyn(<FS<int>>[]) is List<FS<Y>>);
    }
  }
}

main() {
  Expect.isTrue(<F<int>>[] is List<F<int>>);
  Expect.isTrue(dyn(<F<int>>[]) is List<F<int>>);
  Expect.isTrue(<F<int>>[] is List<G<bool, int>>);
  Expect.isTrue(dyn(<F<int>>[]) is List<G<bool, int>>);

  new CheckEnv<int, String>().test(true);
  new CheckEnv<String, int>().test(false);
}
