// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'dart:async';

import 'deferred_class_library2.dart' deferred as lib;

main() {
  asyncStart();
  lib.loadLibrary().then((_) {
    Expect.equals(499, lib.C1.value);
    Expect.equals(99, lib.C2[0].value);
    Expect.equals(42, lib.foo().value);
    Expect.equals(777, lib.bar().value);
    Expect.equals(111, new lib.Gee().value);
    Expect.equals(321, new lib.Gee.n321().value);
    Expect.equals(135, new lib.Gee.n135().value);
    Expect.equals(246, new lib.Gee.n246().value);
    Expect.equals(888, new lib.Gee.n888().value);
    Expect.equals(979, new lib.Gee2().value);
    Expect.equals(321, new lib.Gee2.n321().value);
    Expect.equals(151, new lib.Gee2.n151().value);
    Expect.equals(888, new lib.Gee2.n888().value);
    asyncEnd();
  });
}
