// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "deferred_overlapping_lib1.dart" deferred as lib1;
import "deferred_overlapping_lib2.dart" deferred as lib2;

// lib1.C1 and lib2.C2 has a shared base class It will go in its own hunk.
// If lib1 or lib2s hunks are loaded before the common hunk, the program
// will fail because the base class does not exist.
void main() {
  lib1.loadLibrary().then((_) {
    var a = new lib1.C1();
    lib2.loadLibrary().then((_) {
      var b = new lib2.C2();
    });
  });
}
