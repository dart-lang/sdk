// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

enum Color { red, blue, green }

class E {
  final int x;
  static E y(int x) => E(x);
  E(this.x);
}

void main() {
  FutureOr<Color> color = .blue;
  FutureOr<FutureOr<Color>> recursiveColor = .blue;
  const FutureOr<Color> constColor = .blue;
  switch (color) {
    case .blue:
      print('blue');
    case .red:
      print('red');
    case .green:
      print('green');
    case Future<Color>():
      print('Future in switch');
  }

  var colorList = <FutureOr<Color>>[.blue, .green, .red];

  FutureOr<E> e = .y(1);
  FutureOr<FutureOr<E>> recursiveE = .y(1);
}
