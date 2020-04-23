// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

class MyFuture<T> implements Future<T> {
  Future<S> then<S>(FutureOr<S> valueHandler(T x), {Function? onError}) {
    scheduleMicrotask(() {
      valueHandler(null as T);
    });
    return Future.value(null as S);
  }

  catchError(_, {test}) => Future.value(null as T);
  whenComplete(_) => Future.value(null as T);
  asStream() => Stream.value(null as T);
  timeout(Duration timeLimit, {void onTimeout()?}) => Future.value(null as T);
}

main() {
  asyncStart();
  Completer completer = new Completer();
  completer.complete(new MyFuture());
  Expect.isTrue(completer.isCompleted);
  Expect.throws(() => completer.complete(42));
  completer.future.then((_) => asyncEnd());
}
