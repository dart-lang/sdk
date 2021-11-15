// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that type literals made from type aliases work and
// are canonicalized correctly

import "package:expect/expect.dart";

class C<T> {
  final T x;
  C(this.x);
  C.named(this.x);
}

typedef Special = C<int>; // Not generic.
typedef Direct<T> = C<T>;
typedef Bounded<T extends num> = C<T>;
typedef Wrapping<T> = C<C<T>>;
typedef Extra<T, S> = C<T>;

void main() {
  const Type co = C<Object?>;
  const Type cd = C<dynamic>;
  const Type cn = C<num>;
  const Type ci = C<int>;
  const Type cco = C<C<Object?>>;
  const Type ccd = C<C<dynamic>>;
  const Type cci = C<C<int>>;
  const Type s1 = Special;
  const Type d1 = Direct;
  const Type d2 = Direct<Object?>;
  const Type d3 = Direct<int>;
  const Type b1 = Bounded;
  const Type b2 = Bounded<num>;
  const Type b3 = Bounded<int>;
  const Type w1 = Wrapping;
  const Type w2 = Wrapping<Object?>;
  const Type w3 = Wrapping<int>;
  const Type e1 = Extra;
  const Type e2 = Extra<Object?, bool>;
  const Type e3 = Extra<int, bool>;

  Expect.identical(s1, ci);
  Expect.identical(d1, cd);
  Expect.identical(d2, co);
  Expect.identical(d3, ci);
  Expect.identical(b1, cn);
  Expect.identical(b2, cn);
  Expect.identical(b3, ci);
  Expect.identical(w1, ccd);
  Expect.identical(w2, cco);
  Expect.identical(w3, cci);
  Expect.identical(e1, cd);
  Expect.identical(e2, co);
  Expect.identical(e3, ci);

  (<T extends num>() {
    // Using a non-constant type.
    Expect.equals(Direct<T>, ci);
    Expect.equals(Bounded<T>, ci);
    Expect.equals(Wrapping<T>, cci);
    Expect.equals(Extra<T, bool>, ci);
  }<int>());
}
