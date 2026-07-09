// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:expect/expect.dart';

final num maxInt = 1 is double ? pow(2, 52) : 1.0e300.floor();

dynamic round(dynamic number) {
  if (number is num) {
    if (number.isInfinite) {
      return maxInt;
    }
    return number.round();
  }
  return number;
}

main() {
  Expect.equals(round(1.0), 1);
  Expect.equals(round(1), 1);
}
