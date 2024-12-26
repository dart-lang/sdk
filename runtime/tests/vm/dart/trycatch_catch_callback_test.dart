// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test getting values correctly into the catch block.

import 'package:async_helper/async_helper.dart' show asyncEnd, asyncStart;
import 'package:expect/expect.dart';

import 'dart:async';

_completeWithErrorCallback(result, e, s) {
  Expect.isTrue(result is Future<int>);
  Expect.equals("kuka", e);
  Expect.isTrue(s is StackTrace);
  result.then((v) {
    Expect.equals(42, v);
    asyncEnd();
  });
}

dotry(compute) {
  Future<int> result = Future<int>.value(42);
  new Timer(Duration(milliseconds: 50), () {
    try {
      compute();
    } catch (e, s) {
      print('Caught exception $e');
      _completeWithErrorCallback(result, e, s);
    }
  });
  print(result);
}

main() {
  asyncStart();
  dotry(() {
    throw 'kuka';
  });
}
