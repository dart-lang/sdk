// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void constantFoldInt() {
  var x = 100;
  var y = 24;
  print(x + y);
  print(x - y);
  print(x * y);
  print(x ~/ y);
  print(x % y);
  print(x.remainder(y));
  print(x / y);
  print(x | y);
  print(x & y);
  print(x ^ y);
  print(x == y);
  print(x > y);
  print(x >= y);
  print(x < y);
  print(x <= y);
  print(x << y);
  print(x >> y);
  print((-x) >>> y);
  print(-x);
  print(~x);
  print(x.toDouble());
  print((-x).abs());
  print(x.sign);
}

void constantFoldDouble() {
  var x = 4.0;
  var y = 0.5;
  var z = double.nan;
  print(x + y);
  print(x + z);
  print(x - y);
  print(x * y);
  print(x ~/ y);
  print(x % y);
  print(x.remainder(y));
  print(x / y);
  print(x == y);
  print(x == z);
  print(x > y);
  print(x > z);
  print(x >= y);
  print(x < y);
  print(x <= y);
  print(-x);
  print(x.ceil());
  print(y.ceilToDouble());
  print(y.round());
  print(x.roundToDouble());
  print((-x).truncate());
  print((-y).truncateToDouble());
}

void moveConstantToRight(int x, double y, Object? obj) {
  print(2 + x);
  print(3 * x);
  print(4 == x);
  print(5 > x);
  print(6 >= x);
  print(7 < x);
  print(8 <= x);
  print(2 + y);
  print(3 * y);
  print(4 == y);
  print(5 > y);
  print(6 >= y);
  print(7 < y);
  print(8 <= y);
  print(null == obj);
}

void arithmeticPatterns(int x, double y) {
  print(0 + x);
  print(0 - x);
  print(1 * x);
  print(x * 0);
  print(x * 16);
  print(x ~/ 32);
  print(x * (-1));
  print(x << 65);
  print(x >> 65);
  print(x >>> 65);
  print(x | 0);
  print(x | (-1));
  print(x | x);
  print(x & 0);
  print(x & (-1));
  print(x & x);
  print(x ^ 0);
  print(x ^ (-1));
  print(x ^ x);
  print(y * 1.0);
  print(y * y);
}

void redundantPhi(int x) {
  if (x > 0) {
    x = x + 0;
  }
  print(x);
}

void main() {}
