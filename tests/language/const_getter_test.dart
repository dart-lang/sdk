// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that const getters are not allowed.

import 'package:expect/expect.dart';

class C {
  const C();

  const //# 01: syntax error
  get x => 1;
}

const //# 02: syntax error
get y => 2;

main() {
  Expect.equals(1, const C().x);
  Expect.equals(2, y);
}
