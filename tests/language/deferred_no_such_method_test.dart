// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

@l import "deferred_no_such_method_lib.dart" as lib;

const l = const DeferredLibrary('lib');

void main() {
  asyncStart();
  l.load().then((_) {
    Expect.equals(42, new lib.C().nonExisting());
    asyncEnd();
  });
}