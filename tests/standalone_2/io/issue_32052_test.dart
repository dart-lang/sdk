// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:cli';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

main() {
  asyncStart();
  Completer<Null> c = new Completer<Null>();
  Timer.run(() {
    c.complete(null);
    asyncEnd();
  });
  Null result = waitFor<Null>(c.future);
  Expect.isNull(result);
}
