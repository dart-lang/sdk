// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Square {
  Unit get size;
}

class Unit {
  final double value;
  const Unit(this.value);
}

String test(Map map) {
  return switch (map) {
    {13: Square(size: Unit(1))} => "object",
    _ => "default"
  };
}
