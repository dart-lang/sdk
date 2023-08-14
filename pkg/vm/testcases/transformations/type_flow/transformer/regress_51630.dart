// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/51630.

import 'dart:math' show Random;

/// Naive [List] equality implementation.
bool listEquals<E>(List<E> list1, List<E> list2) {
  if (identical(list1, list2)) {
    return true;
  }

  if (list1.length != list2.length) {
    return false;
  }

  for (var i = 0; i < list1.length; i += 1) {
    if (list1[i] != list2[i]) {
      return false;
    }
  }

  return true;
}

void main() {
  var random = Random();

  const n = 100 * 1000 * 1000;
  var list1 = [for (var i = 0; i < n; i += 1) random.nextInt(256)];
  var list2 = list1.toList();

  var stopwatch = Stopwatch()..start();
  var result = listEquals(list1, list2);
  print('$result ${stopwatch.elapsed}');

  var list3 = List<int>.of(list1);
  print(list3[0]);
}
