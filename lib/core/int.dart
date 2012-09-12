// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

interface int extends num {
  // Bit-operations.
  int operator &(int other);
  int operator |(int other);
  int operator ^(int other);
  int operator ~();
  int operator <<(int shiftAmount);
  int operator >>(int shiftAmount);

  // Testers.
  bool isEven();
  bool isOdd();

  // Specializations of super-interface.
  int operator -();
  int abs();
  int round();
  int floor();
  int ceil();
  int truncate();
}
