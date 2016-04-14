// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test/util/solo_test.dart await_no_future`

import 'dart:async';

bad() async {
  print(await 23); // LINT
}

good() async {
  print(await new Future.value(23));
}

Future awaitWrapper(dynamic future) async {
  return await future; // OK
}
