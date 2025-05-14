// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Color {
  final int x;
  static Color red() => Color(1);
  Color(this.x);
}

class C<T> {
  static C<X> foo<X>(X x) => new C<X>();

  C<U> cast<U>() => new C<U>();
}

void main() {
  Color color = .red();
  C<bool> c = .foo("String").cast();
}
