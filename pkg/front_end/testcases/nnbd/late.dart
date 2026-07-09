// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

late int lateTopLevelField;
late final int lateFinalTopLevelField;
late final int lateFinalTopLevelFieldWithInit = 0;

class Class {
  late int lateInstanceField;
  late final int lateFinalInstanceField1;
  late final int lateFinalInstanceField2;
  late final int lateFinalInstanceFieldWithInit = 0;

  late Class lateInstanceFieldThis = this;
  late final Class lateFinalInstanceFieldThis = this;

  static late int lateStaticField;
  static late final int lateFinalStaticField1;
  static late final int lateFinalStaticField2;
  static late final int lateFinalStaticFieldWithInit = 0;

  method() {
    late int lateVariable;
    late final int lateFinalVariable;
    late final int lateFinalVariableWithInit = 0;

    lateVariable = 0;
    lateFinalVariable = 0;

    lateInstanceField = 0;
    lateFinalInstanceField1 = 0;

    lateStaticField = 0;
    lateFinalStaticField1 = 0;
  }

  methodWithErrors() {
    late final int lateFinalVariableWithInit = 0;
    lateFinalVariableWithInit = 0;

    lateFinalInstanceFieldWithInit = 0;

    lateFinalStaticFieldWithInit = 0;
  }
}

main() {}

noErrors() {
  lateTopLevelField = 0;
  lateFinalTopLevelField = 0;
  var c1 = new Class();
  c1.method();
  var c2 = new Class();
  c2.lateInstanceField = 0;
  c2.lateFinalInstanceField2 = 0;
  Class.lateStaticField = 0;
  Class.lateFinalStaticField2 = 0;
}

errors() {
  lateFinalTopLevelFieldWithInit = 0;
  var c = new Class();
  c.lateFinalInstanceFieldWithInit = 0;
  c.methodWithErrors();
  Class.lateFinalStaticFieldWithInit = 0;
}
