// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test verifies that neither an `== null` nor an `is` test can promote the
// type of a property access on an arbitrary expression.  (Such accesses cannot
// be promoted soundly).

class _C {
  final int? _f;

  _C(this._f);
}

void equality(_C Function() c) {
  if (c()._f == null) {
    c()._f.expectStaticType<Exactly<int?>>();
  } else {
    c()._f.expectStaticType<Exactly<int?>>();
  }
}

void is_(_C Function() c) {
  if (c()._f is int) {
    c()._f.expectStaticType<Exactly<int?>>();
  } else {
    c()._f.expectStaticType<Exactly<int?>>();
  }
}

main() {
  equality(() => _C(1));
  is_(() => _C(1));
  equality(() => _C(null));
  is_(() => _C(null));
}
