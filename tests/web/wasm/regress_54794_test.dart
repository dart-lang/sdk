// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  final dynamic object = int.parse('1') == 1 ? Sub<int, String>() : 1;

  Expect.isTrue(isBase<dynamic>(object));
  Expect.isTrue(isBase<Object>(object));
  Expect.isTrue(isBase<(dynamic, dynamic)>(object));
  Expect.isTrue(isBase<(int, dynamic)>(object));
  Expect.isTrue(isBase<(dynamic, String)>(object));
  Expect.isTrue(isBase<(int, String)>(object));

  Expect.isFalse(isBase<(String, dynamic)>(object));
  Expect.isFalse(isBase<(dynamic, int)>(object));
}

bool isBase<T>(dynamic o) => o is Base<T>;

class Base<T> {}

class Sub<A, B> implements Base<(A, B)> {}
