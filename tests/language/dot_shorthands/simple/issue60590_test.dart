// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Additional test cases in enums, initializer lists, initializers, top-level
// fields from https://github.com/dart-lang/sdk/issues/60590.

import 'package:expect/expect.dart';

import '../dot_shorthand_helper.dart';

class PositionalParameter {
  Color c;
  PositionalParameter([this.c = .red]);
}

class NamedParameter {
  final Color c;
  const NamedParameter({this.c = .red});
  const NamedParameter.cast({Object? o}) : this(c: o as Color);
  const factory NamedParameter.fwd({Color o}) = NamedParameter.cast;
}

class InitializerList {
  Color c;
  InitializerList(): c = .red;
}

class Initializer {
  Color c = .red;
  static Color staticC = .red;
}

Color topLevelRed = .red;

enum NestedEnum {
  red(.red),
  blue(.blue);

  const NestedEnum(this.color);
  final Color color;
}

Color get getterArrow => .red;
Color get getterBody { return .red; }

class Getters {
  static Color get getterArrowStatic => .red;
  static Color get getterBodyStatic { return .red; }
  Color get getterArrow => .red;
  Color get getterBody { return .red; }
}

Color Function() anonymousFunctionArrow = () => .red;
Color Function() anonymousFunctionBody = () { return .red; };

class E {
  static const e1 = E(null);
  static const e2 = E.forward1();
  static const e3 = E.forward2(E.e1);
  final Object? id;
  const E([this.id]);
  const E.e([E? this.id]);
  const E.forward1() : this.e(E.e1);
  const factory E.forward2([E? id]) = E;
}

void main() {
  Expect.equals(Color.red, PositionalParameter().c);
  Expect.equals(Color.blue, PositionalParameter(Color.blue).c);
  Expect.equals(Color.red, const NamedParameter().c);
  Expect.equals(Color.red, NamedParameter().c);
  Expect.equals(Color.blue, NamedParameter(c: Color.blue).c);
  Expect.equals(Color.blue, NamedParameter.fwd(o: Color.blue).c);
  Expect.equals(Color.blue, const NamedParameter.fwd(o: Color.blue).c);
  Expect.equals(Color.red, InitializerList().c);
  Expect.equals(Color.red, Initializer().c);
  Expect.equals(Color.red, Initializer.staticC);
  Expect.equals(Color.red, topLevelRed);
  Expect.equals(Color.red, NestedEnum.red.color);
  Expect.equals(Color.blue, NestedEnum.blue.color);
  Expect.equals(Color.red, getterArrow);
  Expect.equals(Color.red, getterBody);
  Expect.equals(Color.red, Getters.getterArrowStatic);
  Expect.equals(Color.red, Getters.getterBodyStatic);
  Expect.equals(Color.red, Getters().getterArrow);
  Expect.equals(Color.red, Getters().getterBody);
  Expect.equals(Color.red, anonymousFunctionArrow());
  Expect.equals(Color.red, anonymousFunctionBody());
  Expect.identical(E.e2, E.e3);
}
