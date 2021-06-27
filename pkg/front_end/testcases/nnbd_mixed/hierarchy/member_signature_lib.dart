// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Super {
  void extendedConcreteMethod(int i) {}

  void extendedAbstractMethod(int i);

  void extendedConcreteImplementedMethod(int i) {}

  void extendedAbstractImplementedMethod(int i);
}

abstract class Interface1 {
  void extendedConcreteImplementedMethod(int i) {}

  void extendedAbstractImplementedMethod(int i) {}

  void implementedMethod(int i) {}

  void implementedMultipleMethod(int i) {}
}

abstract class Interface2 {
  void implementedMultipleMethod(int i) {}
}
