// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

bool inCheckedMode() {
  try {
    var i = 42;
    String s = i;
  } on TypeError catch (e) {
    return true;
  }
  return false;
}

class M<U extends V, V> {}

class N<U, V extends U> {}

class S<T> {}

class MNA<U, V, W> extends S<List<U>> with M<V, U>, N<List<W>, List<W>> {}

class MNA2<U, V, W> = S<List<U>> with M<V, U>, N<List<W>, List<W>>;

main() {
  new MNA<num, int, bool>();
  new MNA2<num, int, bool>();
  if (inCheckedMode()) {
    // Type parameter U of M must extend type parameter V, but
    // type argument num is not a subtype of int.
    Expect.throws(() => new MNA<int, num, bool>(), (e) => e is TypeError);
    // Type parameter U of M must extend type parameter V, but
    // type argument num is not a subtype of int.
    Expect.throws(() => new MNA2<int, num, bool>(), (e) => e is TypeError);
  } else {
    new MNA<int, num, bool>();
    new MNA2<int, num, bool>();
  }
}
