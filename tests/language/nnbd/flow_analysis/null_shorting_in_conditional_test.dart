// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

class C {
  final D d;
  C(this.d);
}

class D {
  final int i;
  D(this.i);
}

test(bool b, C? c, D d) {
  (b ? c?.d : d).expectStaticType<Exactly<D?>>();
  (b ? d : c?.d).expectStaticType<Exactly<D?>>();
  (b ? c?.d.i : d.i).expectStaticType<Exactly<int?>>();
  (b ? d.i : c?.d.i).expectStaticType<Exactly<int?>>();
}

main() {
  for (var b in [false, true]) {
    for (var c in [null, C(D(0))]) {
      test(b, c, D(1));
    }
  }
}
