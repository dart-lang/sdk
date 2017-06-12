// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

// This library contains a member loadLibrary.
// Check that we shadow this member.
import "deferred_shadow_load_library_lib.dart" deferred as lib;

void main() {
  var x = lib.loadLibrary();
  Expect.isTrue(x is Future);
  asyncStart();
  x.then((_) {
    Expect.isTrue(lib.trueVar);
    // Check that shadowing still is in place after loading the library.
    Expect.isTrue(lib.loadLibrary() is Future);
    asyncEnd();
  });
}
