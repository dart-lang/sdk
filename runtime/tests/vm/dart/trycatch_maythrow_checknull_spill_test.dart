// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test handling of MayThrow instructions in try-catch block.

import 'package:expect/expect.dart';

int foo(int? y, int z) {
  int x = z + z;
  int sum = 42;
  try {
    print('13: x: $x sum: $sum');
    sum += y!; // Here "MayThrow" should result in x included into live-out,
    // since it is live-in for enclosing catch block.
  } catch (e) {
    sum += x;
    print('18: x: $x sum: $sum');
  }
  print('20: sum: $sum');
  return sum;
}

main(List<String> args) {
  Expect.equals(42, foo(args.length, args.length + 1));
  Expect.equals(44, foo(null, 1));
}
