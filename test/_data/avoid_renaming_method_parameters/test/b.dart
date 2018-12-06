// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:avoid_renaming_method_parameters/a.dart' show A;

abstract class C extends A {
  m1(); // OK
  m2(aa); // OK
  m3(
    Object aa, // OK
    num bb, // OK
  );
  m4([aa]); // OK
  m5(aa, [b]); // OK
  m6(aa, {b}); // OK
  m7(a, {c, b}); // OK
}