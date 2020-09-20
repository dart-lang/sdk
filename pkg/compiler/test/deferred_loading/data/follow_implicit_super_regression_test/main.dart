// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "lib.dart" deferred as lib;

/*member: main:OutputUnit(main, {})*/
void main() {
  lib.loadLibrary().then(/*OutputUnit(main, {})*/ (_) {
    new lib.A2();
    new lib.B2();
    new lib.C3();
    new lib.D3(10);
    new lib.G();
  });
}
