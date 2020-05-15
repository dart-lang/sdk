// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that const getters are not allowed.

import 'package:expect/expect.dart';

class C {
  const C();

  const
//^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'const' here.
  get x => 1;
}

const
// [error line 19, column 1, length 5]
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'const' here.
get y => 2;

main() {
  const C().x;
  y;
}
