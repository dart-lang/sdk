// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion takes effect when the thing being promoted is a
// scrutinee of an if-case construct.

// SharedOptions=--enable-experiment=inference-update-2

import '../static_type_helper.dart';

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

void mapPattern(C c) {
  if (c._o case {0: _}) {
    c._o.expectStaticType<Exactly<Map<Object?, Object?>>>();
  }
}

void nullAssertPattern(C c) {
  if (c._o case _!) {
    c._o.expectStaticType<Exactly<Object>>();
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
  mapPattern(C({}));
  nullAssertPattern(C(0));
  nullCheckPattern(C(0));
  objectPattern(C(0));
  recordPattern(C(()));
  variablePattern(C(0));
  wildcardPattern(C(0));
}
