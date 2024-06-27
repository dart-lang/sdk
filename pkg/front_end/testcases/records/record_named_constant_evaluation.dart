// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Mostly copied from issue54491.dart.

void main() {
  const Chk((Ex(1), foo: Ex(2)), eq: (1, foo: 2));
  const Chk((1, foo: 2), eq: (1, foo: 2));
  const Chk((Ex(1), foo: Ex(2)), eq: (Ex(1), foo: Ex(2)));
  const Chk((Ex(1), foo: Ex(2)), eq: (1, foo: 2));
  const Chk(((1 as Ex), foo: (2 as Ex)), eq: (1, foo: 2));
  const Chk((Ex(1) as int, foo: Ex(2) as int), eq: (1, foo: 2));
  const Chk((Ex(1), foo: Ex(2)) as (int, {int foo}), eq: (1, foo: 2));
  const Chk((1, foo: 2) as (Ex, {int foo}), eq: (1, foo: 2));
  const Chk(Ex((1, foo: 2)), eq: (1, foo: 2));
  const Chk(Ex((Ex(1), foo: Ex(2))), eq: (1, foo: 2));
}
class Chk {
  const Chk(Object? v, {required Object? eq}) :
    assert(v == eq, "Not equal ${(v, eq: eq)}");
}

extension type const Ex(Object? value) {}
