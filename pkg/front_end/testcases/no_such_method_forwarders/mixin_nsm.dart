// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface {
  void method1(num n);
}

class Super {
  void method2(num n) {}
  void method3(num n) {}
}

mixin class Mixin {
  dynamic noSuchMethod(_) => null;
  void method1(int i);
  void method2(covariant int i);
  void method3(num n);
}

class Class = Super with Mixin implements Interface;
