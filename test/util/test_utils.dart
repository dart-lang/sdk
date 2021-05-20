// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

void testEach<T>(Iterable<T> values, bool Function(T s) f, Matcher m) {
  for (var s in values) {
    test('"$s"', () => expect(f(s), m));
  }
}
