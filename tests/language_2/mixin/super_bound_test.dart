// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class M<U extends V, V> {}

class N<U, V extends U> {}

class S<T> {}

class MNA<U, V extends U, W> extends S<List<U>>
    with M<V, U>, N<List<W>, List<W>> {}

class MNA2<U, V extends U, W> = S<List<U>> with M<V, U>, N<List<W>, List<W>>;

main() {
  new MNA<num, int, bool>();
  new MNA2<num, int, bool>();

  // Type parameter U of M must extend type parameter V, but
  // type argument num is not a subtype of int.
  new MNA<int, num, bool>();
  //  ^
  // [cfe] Type argument 'num' doesn't conform to the bound 'U' of the type variable 'V' on 'MNA'.
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

  // Type parameter U of M must extend type parameter V, but
  // type argument num is not a subtype of int.
  new MNA2<int, num, bool>();
  //  ^
  // [cfe] Type argument 'num' doesn't conform to the bound 'U' of the type variable 'V' on 'MNA2'.
  //            ^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}
