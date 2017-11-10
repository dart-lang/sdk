// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N library_prefixes`

import 'dart:async' as _async; //OK
import 'dart:collection' as $collection; //OK
import 'dart:convert' as _1; //LINT
import 'dart:core' as _i1; //OK
import 'dart:math' as dartMath; //LINT [23:8]

main() {
  _i1.print(dartMath.PI);
  _i1.print(_async.Timer);
}
