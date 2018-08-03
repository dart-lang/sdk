// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that metaTargets can be reached via the mirrorSystem.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import "deferred_mirrors_metatarget_lib.dart" deferred as lib;

void main() {
  asyncStart();
  lib.loadLibrary().then((_) {
    Expect.equals("A", lib.foo());
    asyncEnd();
  });
}
