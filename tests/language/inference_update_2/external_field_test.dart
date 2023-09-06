// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that external private final fields are not promotable.
//
// An external field that is final is effectively just a getter whose
// implementation is in external code. As such, it shouldn't be promotable,
// because it's not guaranteed to yield the same value each time it's invoked.

// SharedOptions=--enable-experiment=inference-update-2

import '../static_type_helper.dart';

class C {
  external final int? _field;
}

void test(C c) {
  if (c._field != null) {
    c._field.expectStaticType<Exactly<int?>>(); // Not promoted
  }
}

main() {}
