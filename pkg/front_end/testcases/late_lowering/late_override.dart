// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Interface {
  late int implementedLateFieldDeclaredGetterSetter;
}

class Class implements Interface {
  int get implementedLateFieldDeclaredGetterSetter => 0;

  void set implementedLateFieldDeclaredGetterSetter(int value) {}
}

main() {}
