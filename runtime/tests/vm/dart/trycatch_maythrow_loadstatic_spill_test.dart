// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test handling of MayThrow LoadStatic instructions in try-catch block.

import 'package:expect/expect.dart';

int x = 0;
int initialize_bar() {
  if (x < 3) {
    return x++;
  } else {
    throw "x $x is too big now!";
  }
}

@pragma('vm:never-inline')
int foo(int y, int z) {
  late int bar = initialize_bar();
  int x = z + z;
  int sum = y;
  try {
    print('24: x: $x sum: $sum');
    sum += bar;
    x = 123;
  } catch (e) {
    print(e);
    sum += x;
    print('30: x: $x sum: $sum');
  }
  if (x != 123) {
    // Exception was thrown at "sum += bar"
    Expect.equals(x + y, sum);
  }
  print('36: sum: $sum');
  return sum;
}

main(List<String> args) {
  Expect.equals(args.length * 2, foo(args.length * 2, -1));
  Expect.equals(args.length * 4 + 1, foo(args.length * 4, -2));
  Expect.equals(args.length * 8 + 2, foo(args.length * 8, -3));
  Expect.equals(-4 * 2, foo(args.length * 16, -4));
}
