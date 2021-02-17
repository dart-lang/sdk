// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int? methodAndField1() {}
  int? methodAndField1;

  int? methodAndField2;
  int? methodAndField2() {}

  int? methodAndFinalField1() {}
  final int? methodAndFinalField1 = 0;

  final int? methodAndFinalField2 = 0;
  int? methodAndFinalField2() {}

  int? methodAndFieldAndSetter1() {}
  int? methodAndFieldAndSetter1;
  void set methodAndFieldAndSetter1(int? value) {}

  int? methodAndFieldAndSetter2;
  int? methodAndFieldAndSetter2() {}
  void set methodAndFieldAndSetter2(int? value) {}

  void set methodAndFieldAndSetter3(int? value) {}
  int? methodAndFieldAndSetter3() {}
  int? methodAndFieldAndSetter3;

  void set methodAndFieldAndSetter4(int? value) {}
  int? methodAndFieldAndSetter4;
  int? methodAndFieldAndSetter4() {}

  int? methodAndFinalFieldAndSetter1() {}
  final int? methodAndFinalFieldAndSetter1 = 0;
  void set methodAndFinalFieldAndSetter1(int? value) {}

  final int? methodAndFinalFieldAndSetter2 = 0;
  int? methodAndFinalFieldAndSetter2() {}
  void set methodAndFinalFieldAndSetter2(int? value) {}

  void set methodAndFinalFieldAndSetter3(int? value) {}
  int? methodAndFinalFieldAndSetter3() {}
  final int? methodAndFinalFieldAndSetter3 = 0;

  void set methodAndFinalFieldAndSetter4(int? value) {}
  final int? methodAndFinalFieldAndSetter4 = 0;
  int? methodAndFinalFieldAndSetter4() {}

  int? methodAndSetter1() {}
  void set methodAndSetter1(int? value) {}

  void methodAndSetter2(int? value) {}
  int? set methodAndSetter2() {}

  int? fieldAndSetter1;
  void set fieldAndSetter1(int? value) {}

  int? fieldAndSetter2;
  void set fieldAndSetter2(int? value) {}

  int? fieldAndFinalFieldAndSetter1;
  final int? fieldAndFinalFieldAndSetter1 = 0;
  void set fieldAndFinalFieldAndSetter1(int? value) {}

  final int? fieldAndFinalFieldAndSetter2 = 0;
  int? fieldAndFinalFieldAndSetter2;
  void set fieldAndFinalFieldAndSetter2(int? value) {}

  void set fieldAndFinalFieldAndSetter3(int? value) {}
  int? fieldAndFinalFieldAndSetter3;
  final int? fieldAndFinalFieldAndSetter3 = 0;

  void set fieldAndFinalFieldAndSetter4(int? value) {}
  final int? fieldAndFinalFieldAndSetter4 = 0;
  int? fieldAndFinalFieldAndSetter4;
}

test(Class c) {
  c.methodAndField1 = c.methodAndField1;
  c.methodAndField2 = c.methodAndField2;
  c.methodAndFinalField1;
  c.methodAndFinalField2;
  c.methodAndFieldAndSetter1 = c.methodAndFieldAndSetter1;
  c.methodAndFieldAndSetter2 = c.methodAndFieldAndSetter2;
  c.methodAndFieldAndSetter3 = c.methodAndFieldAndSetter3;
  c.methodAndFieldAndSetter4 = c.methodAndFieldAndSetter4;
  c.methodAndFinalFieldAndSetter1 = c.methodAndFinalFieldAndSetter1;
  c.methodAndFinalFieldAndSetter2 = c.methodAndFinalFieldAndSetter2;
  c.methodAndFinalFieldAndSetter3 = c.methodAndFinalFieldAndSetter3;
  c.methodAndFinalFieldAndSetter4 = c.methodAndFinalFieldAndSetter4;
  c.methodAndSetter1 = c.methodAndSetter1;
  c.methodAndSetter2 = c.methodAndSetter2;
  c.fieldAndSetter1 = c.fieldAndSetter1;
  c.fieldAndSetter2 = c.fieldAndSetter2;
  c.fieldAndFinalFieldAndSetter1 = c.fieldAndFinalFieldAndSetter1;
  c.fieldAndFinalFieldAndSetter2 = c.fieldAndFinalFieldAndSetter2;
  c.fieldAndFinalFieldAndSetter3 = c.fieldAndFinalFieldAndSetter3;
  c.fieldAndFinalFieldAndSetter4 = c.fieldAndFinalFieldAndSetter4;
}

main() {}
