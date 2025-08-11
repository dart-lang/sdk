// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int instanceMethod() => 1;
  int instanceMethod() => 2;

  int get instanceGetter => 1;
  int get instanceGetter => 2;

  void set instanceSetter(value) {}

  void set instanceSetter(value) {}

  int instanceField = 1;
  int instanceField = 2;

  int instanceFieldAndSetter1 = 1;
  void set instanceFieldAndSetter1(int value) {}

  void set instanceFieldAndSetter2(int value) {}

  int instanceFieldAndSetter2 = 1;

  late final int instanceLateFinalFieldAndSetter1;
  void set instanceLateFinalFieldAndSetter1(int value) {}

  void set instanceLateFinalFieldAndSetter2(int value) {}

  late final int instanceLateFinalFieldAndSetter2;

  final int instanceDuplicateFieldAndSetter = 1;
  final int instanceDuplicateFieldAndSetter = 2;
  void set instanceDuplicateFieldAndSetter(int value) {}

  final int instanceFieldAndDuplicateSetter = 1;
  void set instanceFieldAndDuplicateSetter(int value) {}

  void set instanceFieldAndDuplicateSetter(int value) {}

  final int instanceDuplicateFieldAndDuplicateSetter = 1;
  final int instanceDuplicateFieldAndDuplicateSetter = 2;
  void set instanceDuplicateFieldAndDuplicateSetter(int value) {}

  void set instanceDuplicateFieldAndDuplicateSetter(int value) {}

  int instanceMethodAndSetter1() => 1;
  void set instanceMethodAndSetter1(int value) {}

  void set instanceMethodAndSetter2(int value) {}

  int instanceMethodAndSetter2() => 1;
}

test() {
  Class c = new Class();
  c.instanceMethod();
  (c.instanceMethod)();
  c.instanceGetter;
  c.instanceSetter = 0;
  c.instanceField;
  c.instanceField = 0;
  c.instanceFieldAndSetter1;
  c.instanceFieldAndSetter1 = 0;
  c.instanceFieldAndSetter2;
  c.instanceFieldAndSetter2 = 0;
  c.instanceDuplicateFieldAndSetter;
  c.instanceDuplicateFieldAndSetter = 0;
  c.instanceFieldAndDuplicateSetter;
  c.instanceFieldAndDuplicateSetter = 0;
  c.instanceDuplicateFieldAndDuplicateSetter;
  c.instanceDuplicateFieldAndDuplicateSetter = 0;
  c.instanceLateFinalFieldAndSetter1;
  c.instanceLateFinalFieldAndSetter1 = 0;
  c.instanceLateFinalFieldAndSetter2;
  c.instanceLateFinalFieldAndSetter2 = 0;
  c.instanceMethodAndSetter1();
  c.instanceMethodAndSetter1 = 0;
  c.instanceMethodAndSetter2();
  c.instanceMethodAndSetter2 = 0;
}
