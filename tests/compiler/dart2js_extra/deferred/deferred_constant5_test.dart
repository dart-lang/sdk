// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'dart:async';

@lazy import 'deferred_class_library2.dart' as lib;

const lazy = const DeferredLibrary('deferred_class_library2');

main() {
  asyncStart();
  lazy.load().then((bool didLoad) {
    Expect.isTrue(didLoad);
    Expect.equals(321, const lib.Gee.n321().value);
    Expect.equals(246, const lib.Gee.n246().value);
    Expect.equals(888, const lib.Gee.n888().value);
    Expect.equals(321, const lib.Gee2.n321().value);
    Expect.equals(151, const lib.Gee2.n151().value);
    Expect.equals(888, const lib.Gee2.n888().value);
    asyncEnd();
  });
}
