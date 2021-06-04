// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "lib1.dart" deferred as lib1;
import "lib2.dart" deferred as lib2;
import "package:expect/expect.dart";

// Compiling lib_shared will result in a single part file which only uses
// the static state holder.
void main() {
  lib1.loadLibrary().then((_) {
    lib1.update();
    Expect.equals(lib1.value(), 'lib1');
  });
  lib2.loadLibrary().then((_) {
    lib2.update();
    Expect.equals(lib2.value(), 'lib2');
  });
}
