// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

void test() {
  var w = v;
  w = .new(); // Error.
  w = .new; // Error.
  w = .getter; // Error.
  w = .method(); // Error.
  w = .named(); // Error.
  w = Public_C(); // But this is OK.

  var constW = constV;
  constW = const .new(); // Error.
  constW = const .named(); // Error.
  constW = const Public_Const(); // But this is OK.
}
