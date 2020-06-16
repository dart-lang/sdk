// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as Math;
import 'package:expect/expect.dart';
import 'regress21998_lib1.dart' as lib1;
import 'regress21998_lib2.dart';
import 'regress21998_lib3.dart';

main() {
  Expect.equals(4, new C().m());
}

class C {
  max(a) => a;

  m() {
    return max(Math.max<num>(
        lib3_max(0, lib2_max(1, 2)), lib1.max('a', 'b', 'cd').length));
  }
}
