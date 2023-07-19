// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Disable `inference-update-2` (field promotion) feature.
// @dart=3.0

import '../../static_type_helper.dart';

// Verify that neither an `== null` nor an `is` test promotes the type of a
// property access on a variable when the field-promotion feature is not
// enabled.

class _C {
  final int? _f;

  _C(this._f);
}

void equality(_C c) {
  if (c._f == null) {
    c._f.expectStaticType<Exactly<int?>>();
  } else {
    c._f.expectStaticType<Exactly<int?>>();
  }
}

void notEquals(_C c) {
  if (c._f != null) {
    c._f.expectStaticType<Exactly<int?>>();
  } else {
    c._f.expectStaticType<Exactly<int?>>();
  }
}

void is_(_C c) {
  if (c._f is int) {
    c._f.expectStaticType<Exactly<int?>>();
  } else {
    c._f.expectStaticType<Exactly<int?>>();
  }
}

main() {
  equality(_C(1));
  notEquals(_C(1));
  is_(_C(1));
  equality(_C(null));
  notEquals(_C(null));
  is_(_C(null));
}
