// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class M {}

class A extends M {}

sealed class B<T> extends M {}

class C<T> extends B<T> {}

class D<T, S> extends B<T> {}

exhaustiveOr(
        o) => /*
 checkingOrder={Object?,Object,Null},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      (B() || B()) as B /*space=()*/ => 0, // `B` is a subset.
    };

exhaustiveUnion(
        o) => /*
 checkingOrder={Object?,Object,Null},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      (A() || B()) as M /*space=()*/ => 0, // `M` is a subset.
    };

exhaustiveList(
        o) => /*
 checkingOrder={Object?,Object,Null},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      // `List` is not a subset, not an open restriction.
      [_] as List /*space=<[()]?>*/ => 0,
      // `List` is a subset, the restriction is open.
      [...] as List /*space=()*/ => 1,
    };

exhaustiveRestricted(
        o) => /*
 checkingOrder={Object?,Object,Null},
 fields={isEven:-},
 subtypes={Object,Null},
 type=Object?
*/
    switch (o) {
      // `int` not a subset, not an open restriction.
      int(isEven: true) as int /*space=int(isEven: true)|Null*/ => 0,
      // `int` is a subset, the restriction is open.
      int(:var isEven) as int /*space=()*/ => 1,
    };

nonExhaustiveAs(
        B<num>
            o) => /*
 checkingOrder={B<num>,C<num>,D<dynamic, dynamic>},
 error=non-exhaustive:D<dynamic, dynamic>(),
 subtypes={C<num>,D<dynamic, dynamic>},
 type=B<num>
*/
    switch (o) {
      (C() || D()) as B<num> /*space=C<num>|D<num, dynamic>|Null*/ => 0,
    };

nonExhaustiveCase(
        B<num>
            o) => /*
 checkingOrder={B<num>,C<num>,D<dynamic, dynamic>},
 error=non-exhaustive:D<dynamic, dynamic>(),
 subtypes={C<num>,D<dynamic, dynamic>},
 type=B<num>
*/
    switch (o) {
      C() /*space=C<num>*/ => 0,
      D() /*space=D<num, dynamic>*/ => 0,
    };
