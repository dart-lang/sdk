// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library classes `B` and `E`, used by
// `field_promotion_and_no_such_method_library_cycle_test.dart`.

import 'field_promotion_and_no_such_method_library_cycle_test.dart';

class B extends C {
  B(super.f1);

  // This class has an `_f1` getter in its interface, inherited from `C`. It
  // also inherits an implementation of `_f1` from `C`. Therefore, even though
  // there is a non-default `noSuchMethod` method, this class _doesn't_
  // introduce a `noSuchMethod`-forwarding `_f1` getter implementation.
  //
  // Hence, the presence of this `noSuchMethod` method doesn't prevent `_f1`
  // from undergoing type promotion in the other library.
  noSuchMethod(_) => 0;
}

abstract class E implements F {}
