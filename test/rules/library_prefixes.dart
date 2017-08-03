// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N library_prefixes`

import 'dart:async' as _async; //OK
import 'dart:math' as dartMath; //LINT [23:8]

main() {
  print(dartMath.PI);
  print(_async.Timer);
}
