// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'dart:async';

@lazy import 'deferred_class_library2.dart';

const lazy = const DeferredLibrary('deferred_class_library2');

main() {
  asyncStart();
  lazy.load().then((bool didLoad) {
    Expect.isTrue(didLoad);
    Expect.equals(499, C1.value);
    Expect.equals(99, C2[0].value);
    Expect.equals(42, foo().value);
    Expect.equals(777, bar().value);
    Expect.equals(111, new Gee().value);
    Expect.equals(321, new Gee.n321().value);
    Expect.equals(135, new Gee.n135().value);
    Expect.equals(246, new Gee.n246().value);
    Expect.equals(888, new Gee.n888().value);
    Expect.equals(979, new Gee2().value);
    Expect.equals(321, new Gee2.n321().value);
    Expect.equals(151, new Gee2.n151().value);
    Expect.equals(888, new Gee2.n888().value);
    asyncEnd();
  });
}
