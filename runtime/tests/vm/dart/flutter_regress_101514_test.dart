// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/expect.dart';

late StreamSubscription sub;

main() async {
  sub = foo().listen((_) => throw 'unexpected item');
}

Stream<int> foo() async* {
  // While the generator (i.e. this funtion) runs, we cancel the consumer and
  // try to yield more.
  sub.cancel();
  yield* Stream.fromIterable([1, 2, 3]);
  throw 'should not run';
}
