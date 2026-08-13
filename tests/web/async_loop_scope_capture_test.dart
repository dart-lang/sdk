// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

int global = -1;

Future<void> staticAsyncLoopFunction(String value) async {
  Function? f;
  for (var i in [1, 2, 3]) {
    print(value);
    final myLocal = await 'my local value';
    f ??= () {
      // This should capture the value from the first loop iteration.
      global = i;
      return myLocal;
    };
  }
  f!();
}

void main() async {
  asyncStart();
  await staticAsyncLoopFunction('foo');
  Expect.equals(global, 1);
  asyncEnd();
}
