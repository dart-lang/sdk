// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Square {
  final void Function(String s)? logFunction;
  final double length;

  const Square(this.length, [this.logFunction = null]);

  void _log(String toLog) {
    void Function(String s)? _l = logFunction;
    if (_l != null) {
      _l(toLog);
    }
  }

  double get area {
    _log("Square.area");
    return length * length;
  }
}

String log = "";

void logger(String s) {
  log += s;
}

main() {
  var Square(area: _) = Square(2, logger);
  expect("Square.area", log);
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}