// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion logic properly joins promoted properties when the
// two control flow paths being joined assign different values to the containing
// variable.
//
// See https://github.com/dart-lang/sdk/issues/53146 for further details.

// SharedOptions=--enable-experiment=inference-update-2

import '../static_type_helper.dart';

class C {
  final int? _i;
  C(this._i);
}

class D {
  final C _c;
  D(this._c);
}

void direct(bool b, C c1, C c2) {
  C c3;
  if (b) {
    c3 = c1;
    if (c3._i == null) return;
  } else {
    c3 = c2;
    if (c3._i == null) return;
  }
  c3._i.expectStaticType<Exactly<int>>();
}

void nested(bool b, D d1, D d2) {
  D d3;
  if (b) {
    d3 = d1;
    if (d3._c._i == null) return;
  } else {
    d3 = d2;
    if (d3._c._i == null) return;
  }
  d3._c._i.expectStaticType<Exactly<int>>();
}

main() {
  var c1 = C(1);
  var c2 = C(2);
  direct(false, c1, c2);
  direct(true, c1, c2);
  var d1 = D(c1);
  var d2 = D(c2);
  nested(false, d1, d2);
  nested(true, d1, d2);
}
