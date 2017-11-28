// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib1;

import 'library_same_name_used_lib2.dart' as lib2;

abstract class X {}

X makeX() {
  return new lib2.X();
}
