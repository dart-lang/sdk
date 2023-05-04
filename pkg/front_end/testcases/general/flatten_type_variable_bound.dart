// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

Future<void>
    bar<T extends Future<num>, S, U extends num, V extends FutureOr<num>>(
        T t, S s, U u, V v) async {
  var x = await t;
  if (s is Future<num>) {
    var y = await s;
  }
  var z = await u;
  var w = await v;
}
