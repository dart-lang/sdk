// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that const getters are not allowed.

import 'package:expect/expect.dart';

class C {
  const C();


  get x => 1;
}


get y => 2;

main() {
  const C().x;
  y;
}
