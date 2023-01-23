// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Callable {
  void call() {}
}

T id<T>(T x) => x;

foo() {
  // No static error.
  // Inferred type of the record is (int, double, int Function(int), void Function()).
  var c = Callable();
  dynamic d = 3;
  (num, double, int Function(int), void Function()) r = (d, 3, id, c);
  ({num x, double y, int Function(int) f, void Function() g}) r2 = (x: d, y: 3, f: id, g: c);
  (num, double, {int Function(int) f, void Function() g}) r3 = (d, 3, f: id, g: c);
}

main() {}
