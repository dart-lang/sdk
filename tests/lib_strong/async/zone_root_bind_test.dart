// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

main() {
  Expect.identical(Zone.ROOT, Zone.current);
  Zone forked = Zone.current.fork();
  var f = Zone.current.bindCallback(() {
    Expect.identical(Zone.ROOT, Zone.current);
  }, runGuarded: false);
  forked.run(() {
    f();
  });
}
