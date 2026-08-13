// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Color {
  final int x;
  static Color get red => Color(1);
  Color(this.x);
}

void test() {
  Color c = .red();
  Color cc = .blue();
  var ccc = .yellow();
}
