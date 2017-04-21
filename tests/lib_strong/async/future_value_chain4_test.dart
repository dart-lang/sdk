// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

class MyFuture implements Future {
  then(valueHandler, {onError}) {
    scheduleMicrotask(() {
      valueHandler(499);
    });
  }

  catchError(_, {test}) => null;
  whenComplete(_) => null;
  asStream() => null;
  timeout(Duration timeLimit, {void onTimeout()}) => null;
}

main() {
  asyncStart();
  Completer completer = new Completer();
  completer.complete(new MyFuture());
  Expect.isTrue(completer.isCompleted);
  Expect.throws(() => completer.complete(42));
  completer.future.then((_) => asyncEnd());
}
