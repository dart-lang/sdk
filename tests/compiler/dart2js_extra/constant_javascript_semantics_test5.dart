// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

// Make sure we can assert(const Foo() != null) in const initializers.
class Color {
  const Color(this.value);
  final int value;
}

class ColorHaver {
  const ColorHaver({this.color = const Color(0xFF000000)})
      : assert(color != null);
  final Color color;
}

const c = const ColorHaver(color: const Color(0xFF00FF00));

enum Enum {
  a,
  b,
}

class EnumHaver {
  const EnumHaver({this.myEnum: Enum.a}) : assert(myEnum != null);
  final Enum myEnum;
}

const e = const EnumHaver(myEnum: Enum.b);

main() {
  Expect.equals(c.value, 0xFF00FF00);
  Expect.equals(e.myEnum, Enum.b);
}
