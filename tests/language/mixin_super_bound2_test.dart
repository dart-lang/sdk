// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--supermixin

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

class MS<U, V extends U> { }

class M<U extends V, V> extends MS<V, U> { }

class NS<U extends V, V> { }

class N<U, V extends U> extends NS<V, U> { }

class S<T> { }

class MNA<U, V, W> extends S<List<U>>
    with M<List<V>, List<U>>, N<List<W>, List<W>> { }

class MNA2<U, V, W> = S<List<U>>
    with M<List<W>, List<W>>, N<List<U>, List<V>>;

class MNA3<U, V, W> extends S<List<U>>
    with MNA<U, V, W>, MNA2<List<U>, List<V>, List<W>> { }

class MNA4<U, V, W> = S<List<U>>
    with MNA<U, V, W>, MNA2<List<U>, List<V>, List<W>>;

main() {
  new MNA<num, int, bool>();
  new MNA2<num, int, bool>();
  new MNA3<num, int, bool>();
  new MNA4<num, int, bool>();
  if (inCheckedMode()) {
    // Type parameter U of M must extend type parameter V, but
    // type argument List<num> is not a subtype of List<int>.
    Expect.throws(() => new MNA<int, num, bool>(), (e) => e is TypeError);
    // Type parameter V of N must extend type parameter U, but
    // type argument List<num> is not a subtype of List<int>.
    Expect.throws(() => new MNA2<int, num, bool>(), (e) => e is TypeError);
    // Type parameter V of N must extend type parameter U, but
    // type argument List<List<num>> is not a subtype of List<List<int>>.
    Expect.throws(() => new MNA3<int, num, bool>(), (e) => e is TypeError);
    // Type parameter V of N must extend type parameter U, but
    // type argument List<List<num>> is not a subtype of List<List<int>>.
    Expect.throws(() => new MNA4<int, num, bool>(), (e) => e is TypeError);
  } else {
    new MNA<int, num, bool>();
    new MNA2<int, num, bool>();
    new MNA3<int, num, bool>();
    new MNA4<int, num, bool>();
  }
}

