// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

throwValue(val) => throw val;

f1() {
  var a = 0;
  var b = 0;
  var c = 0;
  var d = 0;
  for (var i = 0; i < 10; i++) {
    try {
      for (var j = 0; j < 11; j++) {
        try {
          capture() => [i, j, a, b, c, d];
          throwValue(j == 10 ? "${j}" : j);
        } on num catch (e) {
          a += j;
          b -= e;
        }
      }
    } catch (e) {
      c++;
      d += int.parse(e);
    }
  }
  return [a, b, c, d];
}

f2() {
  var a = 0;
  var b = 0;
  var c = 0;
  var d = 0;
  for (var i = 0; i < 10; i++) {
    try {
      for (var j = 0; j < 11; j++) {
        try {
          capture() => [i, j, a, b, c, d];
          throwValue(j == 10 ? "${j}" : j);
        } on num catch (e) {
          a += j;
          b -= e;
        }
      }
    } catch (e) {
      capture() => e;
      c++;
      d += int.parse(e);
    }
  }
  return [a, b, c, d];
}

f3() {
  var a = 0;
  var b = 0;
  var c = 0;
  var d = 0;
  for (var i = 0; i < 10; i++) {
    try {
      for (var j = 0; j < 11; j++) {
        try {
          capture() => [i, j, a, b, c, d];
          throwValue(j == 10 ? "${j}" : j);
        } on num catch (e) {
          a += j;
          b -= e;
        }
      }
    } catch (e) {
      capture() => e;
      c++;
      d += int.parse(e);
      continue;
    }
  }
  return [a, b, c, d];
}

main() {
  Expect.listEquals([450, -450, 10, 100], f1());
  Expect.listEquals([450, -450, 10, 100], f2());
  Expect.listEquals([450, -450, 10, 100], f3());
}
