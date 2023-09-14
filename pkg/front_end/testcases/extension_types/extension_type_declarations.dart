// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ExtensionType1(int it) {}
extension type ExtensionType2(int it) implements ExtensionType1, int {}
extension type ExtensionType3<T extends num>(T it) {}
extension type ExtensionType4(int it) {
  const ExtensionType4.constructor(this.it);
  const ExtensionType4.redirect(int it) : this(it);
  factory ExtensionType4.fact(int it) => ExtensionType4(it);
  factory ExtensionType4.redirectingFactory(int it) = ExtensionType4;

  final int field = 42;
  int get getter => it;
  void set setter(int value) {}
  int method() => it;
  int operator[](int index) => it;
  void operator[]=(int index, int value) {}

  static int staticField = 42;
  static int get staticGetter => 42;
  static void set staticSetter(int value) {}
  static int staticMethod() => 42;
}
extension type ExtensionType5.new(int it) {}
extension type ExtensionType6.id(int it) {}
extension type ExtensionType7<T extends num>.id(int it) {}