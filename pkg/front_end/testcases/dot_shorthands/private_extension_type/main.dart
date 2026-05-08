// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

void test() {
  var x = one;
  x = .new(1); // Error.
  x = .new; // Error.
  x = .getter; // Error.
  x = .method(); // Error.
  x = .named(1); // Error.
  x = Public_E(1); // But this is OK.

  var constX = constOne;
  constX = const .new(1); // Error.
  constX = const .named(1); // Error.
  constX = const Public_EConst(1); // But this is OK.
}
