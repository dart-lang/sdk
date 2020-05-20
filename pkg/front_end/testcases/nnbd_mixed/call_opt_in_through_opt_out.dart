// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'call_opt_in_through_opt_out_lib.dart';

test() {
  applyTakesNever(takesNever);
  applyTakesNever(takesNull);
  applyTakesNull(takesNever);
  applyTakesNull(takesNull);
  applyTakesNeverNamed(f: takesNever);
  applyTakesNeverNamed(f: takesNull);
  applyTakesNullNamed(f: takesNever);
  applyTakesNullNamed(f: takesNull);

  applyTakesNonNullable(takesNonNullable);
  applyTakesNonNullable(takesNullable);
  applyTakesNullable(takesNonNullable);
  applyTakesNullable(takesNullable);
  applyTakesNonNullableNamed(f: takesNonNullable);
  applyTakesNonNullableNamed(f: takesNullable);
  applyTakesNullableNamed(f: takesNonNullable);
  applyTakesNullableNamed(f: takesNullable);
}

main() {}
