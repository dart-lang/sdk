// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing import of only constants from a deferred library.

import 'package:expect/expect.dart';

import "deferred_only_constant_lib.dart" deferred as lib;

void main() {
  lib.loadLibrary().then((_) {
    Expect.equals(lib.constant, const ["a", "b", "c"]);
  });
}