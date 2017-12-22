// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import '../libs/deferred_constant2_lib.dart' deferred as lib;

/*element: main:OutputUnit(main, {})*/
main() {
  asyncStart();
  lib.loadLibrary().then((_) {
    Expect.equals(499, lib.C1.value);
    asyncEnd();
  });
}
