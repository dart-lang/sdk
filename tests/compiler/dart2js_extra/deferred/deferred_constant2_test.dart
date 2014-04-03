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
    Expect.equals(499, lib.C1.value);
    asyncEnd();
  });
}
