// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib1.dart' deferred as lib1;
import 'lib2.dart' deferred as lib2;

// lib1.C1 and lib2.C2 has a shared base class. It will go in its own hunk.
/*member: main:OutputUnit(main, {})*/
void main() {
  lib1.loadLibrary().then(/*OutputUnit(main, {})*/ (_) {
    new lib1.C1();
    lib2.loadLibrary().then(/*OutputUnit(main, {})*/ (_) {
      new lib2.C2();
    });
  });
}
