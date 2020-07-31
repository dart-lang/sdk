// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test: stack trace could be null when using async-await.
import 'dart:async';

import 'package:expect/expect.dart';

main() async {
  C value = await test();
  Expect.identical(StackTrace.empty, value._s);
}

Future<C> test() async {
  try {
    await throwInFuture();
    return C(StackTrace.fromString("no-throw"));
  } on MyException catch (e, s) {
    return C(s); // Note: s is *no longer* null
  }
}

Future<int> throwInFuture() {
  var completer = new Completer<int>();
  var future = completer.future;
  new Future(() {}).then((_) {
    StackTrace.fromString("hi");
    completer.completeError(new MyException());
  });
  return future;
}

class MyException {}

class C {
  final StackTrace _s; // Global inference used to infer this field as non-null
  C(this._s);

  @override
  String toString() => '[[$_s]]';
}
