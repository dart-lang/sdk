// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library declaring a getter `_f2`, to check that it doesn't prevent promotion
// of a field named `_f2` in `field_promotion_and_no_such_method_test.dart`.

class C {
  int? get _f2 => 0;
}
