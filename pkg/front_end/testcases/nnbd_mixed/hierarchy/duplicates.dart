// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  void superDuplicate1() {}
  int get superDuplicate1 => 42;

  int get superDuplicate2 => 42;
  void superDuplicate2() {}

  void extendedDuplicate1() {}
  void extendedDuplicate2() {}
}

class Mixin {
  //void mixinDuplicate1() {}
  //int get mixinDuplicate1 => 42;

  //int get mixinDuplicate2 => 42;
  //void mixinDuplicate2() {}

  void mixedInDuplicate1() {}
  void mixedInDuplicate2() {}
}

class Interface {
  void interfaceDuplicate1() {}
  int get interfaceDuplicate1 => 42;

  int get interfaceDuplicate2 => 42;
  void interfaceDuplicate2() {}

  void implementedDuplicate1() {}
  void implementedDuplicate2() {}
}

abstract class Class extends Super with Mixin implements Interface {
  void superDuplicate1() {}
  void superDuplicate2() {}

  void extendedDuplicate1() {}
  int get extendedDuplicate1 => 42;

  int get extendedDuplicate2 => 42;
  void extendedDuplicate2() {}

  //void mixinDuplicate1() {}
  //void mixinDuplicate2() {}

  void mixedInDuplicate1() {}
  int get mixedInDuplicate1 => 42;

  int get mixedInDuplicate2 => 42;
  void mixedInDuplicate2() {}

  void interfaceDuplicate1() {}
  void interfaceDuplicate2() {}

  void implementedDuplicate1() {}
  int get implementedDuplicate1 => 42;

  int get implementedDuplicate2 => 42;
  void implementedDuplicate2() {}
}

main() {}
