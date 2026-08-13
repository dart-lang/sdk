// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

main() async {
  FutureOr<Object> future1 = Future<Object?>.value();
  var x = await future1; // Check against `Future<Object>`.

  Object o = Future<Object?>.value();
  var y = await o; // Check against `Future<Object>`.

  Future<Object?> future2 = Future<Object?>.value();
  var z = await future2; // No check.
}
