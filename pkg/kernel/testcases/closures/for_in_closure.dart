// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

const numbers = const <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

main() {
  var closures = [];
  var captured_outside = 0;
  for (int i in numbers) {
    closures.add(() => i + captured_outside);
  }
  int sum = 0;
  for (Function f in closures) {
    sum += f();
  }
  // This formula is credited to Gauss. Search for "Gauss adding 1 to 100".
  int expectedSum = (numbers.length - 1) * numbers.length ~/ 2;
  if (expectedSum != sum) {
    throw new Exception("Unexpected sum = $sum != $expectedSum");
  }
}
