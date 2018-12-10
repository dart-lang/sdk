// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_sample_extension;

import 'sample_asynchronous_extension.dart';

void check(bool condition, String message) {
  if (!condition) {
    throw new StateError(message);
  }
}

void main() {
  RandomArray r = new RandomArray();
  r.randomArray(17, 100).then((list_100) {
    r.randomArray(17, 200).then((list_200) {
      for (var i = 0; i < 100; ++i) {
        check(list_100[i] == list_200[i], "list_100[i] == list_200[i]");
      }
    });
  });

  // Gets a list of 256000 random uint8 values, using seed 19, and
  // runs checkNormal on that list.
  r.randomArray(19, 256000).then(checkNormal);
}

void checkNormal(List l) {
  // Count how many times each byte value occurs.  Assert that the counts
  // are all within a reasonable (six-sigma) range.
  List counts = new List<int>.filled(256, 0);
  for (var e in l) {
    counts[e]++;
  }
  new RandomArray().randomArray(18, 256000).then(checkCorrelation(counts));
}

Function checkCorrelation(List counts) {
  return (List l) {
    List counts_2 = new List<int>.filled(256, 0);
    for (var e in l) {
      counts_2[e]++;
    }
    var product = 0;
    for (var i = 0; i < 256; ++i) {
      check(counts[i] < 1200, "counts[i] < 1200");
      check(counts_2[i] < 1200, "counts_2[i] < 1200");
      check(counts[i] > 800, "counts[i] > 800");
      check(counts[i] > 800, "counts[i] > 800");

      product += counts[i] * counts_2[i];
    }
    check(product < 256000000 * 1.001, "product < 256000000 * 1.001");
    check(product > 256000000 * 0.999, "product > 256000000 * 0.999");
  };
}
