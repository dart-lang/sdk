// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import '../../../sdk/lib/_internal/compiler/implementation/util/setlet.dart';

main() {
  for (int i = 1; i <= 32; i++) {
    test(i);
  }
}

test(int size) {
  var setlet = new Setlet();
  for (int i = 0; i < size; i++) {
    Expect.isTrue(setlet.isEmpty == (i == 0));
    setlet.add(i);
    Expect.equals(i + 1, setlet.length);
    Expect.isFalse(setlet.isEmpty);
    for (int j = 0; j < size + size; j++) {
      Expect.isTrue(setlet.contains(j) == (j <= i));
    }
    Expect.isTrue(setlet.remove(i));
    Expect.isFalse(setlet.remove(i + 1));
    setlet.add(i);

    List expectedElements = [];
    for (int j = 0; j <= i; j++) expectedElements.add(j);

    List actualElements = [];
    setlet.forEach((each) => actualElements.add(each));
    Expect.listEquals(expectedElements, actualElements);

    actualElements = [];
    for (var each in setlet) actualElements.add(each);
    Expect.listEquals(expectedElements, actualElements);
  }

  for (int i = 0; i < size; i++) {
    Expect.equals(size, setlet.length);

    // Try removing all possible ranges one by one and re-add them.
    for (int k = size; k > i; --k) {
      for (int j = i; j < k; j++) {
        Expect.isTrue(setlet.remove(j));
        int expectedSize = size - (j - i + 1);
        Expect.equals(expectedSize, setlet.length);
        Expect.isFalse(setlet.remove(j));
        Expect.isFalse(setlet.contains(j));

        Expect.isFalse(setlet.contains(null));
        setlet.add(null);
        Expect.equals(expectedSize + 1, setlet.length);
        Expect.isTrue(setlet.contains(null));
        Expect.isTrue(setlet.remove(null));
        Expect.equals(expectedSize, setlet.length);
        Expect.isFalse(setlet.remove(null));
      }

      for (int j = i; j < k; j++) {
        setlet.add(j);
      }
    }

    Expect.equals(size, setlet.length);
    Expect.isTrue(setlet.contains(i));
  }
}
