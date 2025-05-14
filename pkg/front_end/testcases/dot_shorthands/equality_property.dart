// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Color {
  final int x;
  static Color get red => Color(1);
  static Color get blue => Color(2);
  Color(this.x);
}

void main() {
  Color c = .red;
  bool b = c == .blue;
}
