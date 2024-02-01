// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  const Chk((Ex(1),), eq: (1,));
  const Chk((1,), eq: (1,));
  const Chk((Ex(1),), eq: (Ex(1),));
  const Chk((Ex(1),), eq: (1,));
  const Chk(((1 as Ex),), eq: (1,));
  const Chk((Ex(1) as int,), eq: (1,));
  const Chk((Ex(1),) as (int,), eq: (1,));
  const Chk((1,) as (Ex,), eq: (1,));
  const Chk(Ex((1,)), eq: (1,));
  const Chk(Ex((Ex(1),)), eq: (1,));
}
class Chk {
  const Chk(Object? v, {required Object? eq}) :
    assert(v == eq, "Not equal ${(v, eq: eq)}");
}

extension type const Ex(Object? value) {}
