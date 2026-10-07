// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion takes effect when the thing being promoted is a
// scrutinee of an if-case construct.

import 'package:expect/static_type_helper.dart';

class C {
  final Object? _o;
  C(this._o);
}

void castPattern(C c) {
  if (c._o case _ as int) {
    c._o.expectStaticType<Exactly<int>>();
  }
}

void listPattern(C c) {
  if (c._o case []) {
    c._o.expectStaticType<Exactly<List<Object?>>>();
  }
}

void listPatternWithSubpattern(C c) {
  if (c._o case [int()]) {
    // The type test is performed on the list element, not on `c._o`, so `c._o`
    // is promoted to `List<Object?>` and no further.
    c._o.expectStaticType<Exactly<List<Object?>>>();
  }
}

void mapPattern(C c) {
  if (c._o case {0: _}) {
    c._o.expectStaticType<Exactly<Map<Object?, Object?>>>();
  }
}

void mapPatternWithSubpattern(C c) {
  if (c._o case {0: int()}) {
    // The type test is performed on the map value, not on `c._o`, so `c._o` is
    // promoted to `Map<Object?, Object?>` and no further.
    c._o.expectStaticType<Exactly<Map<Object?, Object?>>>();
  }
}

void nullAssertPattern(C c) {
  if (c._o case _!) {
    c._o.expectStaticType<Exactly<Object>>();
  }
}

void nullAssertPatternInSubpattern(C c) {
  if (c._o case [_!]) {
    // The null assert is performed on the list element, not on `c._o`, so
    // `c._o` is promoted to `List<Object?>` and no further.
    c._o.expectStaticType<Exactly<List<Object?>>>();
  }
}

void nullCheckPattern(C c) {
  if (c._o case _?) {
    c._o.expectStaticType<Exactly<Object>>();
  }
}

void objectPattern(C c) {
  if (c._o case int()) {
    c._o.expectStaticType<Exactly<int>>();
  }
}

void recordPattern(C c) {
  if (c._o case ()) {
    c._o.expectStaticType<Exactly<()>>();
  }
}

void recordPatternWithSubpattern(C c) {
  if (c._o case (int(),)) {
    // The type test is performed on the record field, not on `c._o`; `c._o` is
    // promoted to the record pattern's demonstrated type.
    c._o.expectStaticType<Exactly<(int,)>>();
  }
}

void variablePattern(C c) {
  if (c._o case int x) {
    c._o.expectStaticType<Exactly<int>>();
  }
}

void wildcardPattern(C c) {
  if (c._o case int _) {
    c._o.expectStaticType<Exactly<int>>();
  }
}

main() {
  castPattern(C(0));
  listPattern(C([]));
  listPatternWithSubpattern(C([0]));
  mapPattern(C({}));
  mapPatternWithSubpattern(C({0: 0}));
  nullAssertPattern(C(0));
  nullAssertPatternInSubpattern(C([0]));
  nullCheckPattern(C(0));
  objectPattern(C(0));
  recordPattern(C(()));
  recordPatternWithSubpattern(C((0,)));
  variablePattern(C(0));
  wildcardPattern(C(0));
}
