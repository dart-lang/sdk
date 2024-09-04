// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

main() {
  final List<A<Object>> l = [A<int>(), A<String>()];

  final aInt = l[int.parse('0')];
  Expect.isNull(aInt.value);
  aInt.value = 10;
  Expect.equals(10, aInt.value);

  final aString = l[int.parse('1')];
  Expect.isNull(aString.value);
  if (checkedParameters) {
    Expect.throws(() => aString.value = 1);
    Expect.isNull(aString.value);
  }
}

class A<T> {
  T? value;
}
