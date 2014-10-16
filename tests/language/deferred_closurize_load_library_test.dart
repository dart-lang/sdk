// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

import "deferred_closurize_load_library_lib.dart" deferred as lib;

void main() {
  var x = lib.loadLibrary;
  asyncStart();
  x().then((_) {
    Expect.isTrue(lib.trueVar);
    asyncEnd();
  });
}
