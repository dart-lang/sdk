// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

const int max = 100;

main() {
  var closures = [];
  var closures2 = [];
  var last;
  for (int i = 0; i < max; i++) {
    closures.add(() => last = i);
    closures2.add(() {
      if (last != max - 1) throw "last: $last != ${max - 1}";
    });
  }
  int sum = 0;
  for (Function f in closures) {
    sum += f();
  }
  for (Function f in closures2) {
    f();
  }
  // This formula is credited to Gauss. Search for "Gauss adding 1 to 100".
  int expectedSum = (max - 1) * max ~/ 2;
  if (expectedSum != sum) {
    throw new Exception("Unexpected sum = $sum != $expectedSum");
  }
}
