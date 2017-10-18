// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib2;

import 'library_same_name_used_lib1.dart' as lib1; // for abstract class X.

class X implements lib1.X {
  X();
  toString() => 'lib2.X';
}
