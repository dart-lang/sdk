// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:compiler/src/util/maplet.dart";

main() {
  for (int i = 1; i <= 32; i++) {
    test(i);
  }
}

test(int size) {
  var maplet = new Maplet();
  for (int i = 0; i < size; i++) {
    Expect.isTrue(maplet.isEmpty == (i == 0));
    maplet[i] = '$i';
    Expect.equals(i + 1, maplet.length);
    Expect.isFalse(maplet.isEmpty);
    for (int j = 0; j < size + size; j++) {
      Expect.isTrue(maplet[j] == ((j <= i) ? '$j' : null));
    }
    Expect.equals('$i', maplet.remove(i));
    Expect.isNull(maplet.remove(i + 1));
    maplet[i] = '$i';

    List expectedKeys = [];
    List expectedValues = [];
    for (int j = 0; j <= i; j++) {
      expectedKeys.add(j);
      expectedValues.add('$j');
    }

    List actualKeys = [];
    List actualValues = [];
    maplet.forEach((eachKey, eachValue) {
      actualKeys.add(eachKey);
      actualValues.add(eachValue);
    });
    Expect.listEquals(expectedKeys, actualKeys);
    Expect.listEquals(expectedValues, actualValues);
    Expect.listEquals(expectedKeys, maplet.keys.toList());
    Expect.listEquals(expectedValues, maplet.values.toList());
  }

  for (int i = 0; i < size; i++) {
    Expect.equals(size, maplet.length);

    // Try removing all possible ranges one by one and re-add them.
    for (int k = size; k > i; --k) {
      for (int j = i; j < k; j++) {
        Expect.equals('$j', maplet.remove(j));
        int expectedSize = size - (j - i + 1);
        Expect.equals(expectedSize, maplet.length);
        Expect.isNull(maplet.remove(j));
        Expect.isNull(maplet[j]);

        Expect.isNull(maplet[null]);
        maplet[null] = 'null';
        Expect.equals(expectedSize + 1, maplet.length);
        Expect.equals('null', maplet[null]);
        Expect.equals('null', maplet.remove(null));
        Expect.equals(expectedSize, maplet.length);
        Expect.isNull(maplet.remove(null));
      }

      for (int j = i; j < k; j++) {
        maplet[j] = '$j';
      }
    }

    Expect.equals(size, maplet.length);
    Expect.equals('$i', maplet[i]);
  }
}
