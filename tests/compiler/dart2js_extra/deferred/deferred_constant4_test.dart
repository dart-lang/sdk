// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'deferred_class_library2.dart' deferred as lib;

main() {
  asyncStart();
  lib.loadLibrary().then((_) {
    // Only Gee2.n888 to make sure no other constant pulls in its super.
    Expect.equals(888, new lib.Gee2.n888().value);
    asyncEnd();
  });
}
