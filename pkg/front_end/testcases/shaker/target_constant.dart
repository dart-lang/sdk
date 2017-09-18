// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'target_constant_lib.dart';

class RefStaticConstFields {
  static const int staticConstField_from_staticConst = A1.staticConstField1;
  static int staticConstField_from_static = A1.staticConstField2;
  static final int staticConstField_from_staticFinal = A1.staticConstField3;
  final int staticConstField_from_final = A1.staticConstField4;
  int staticConstField_from_regular = A1.staticConstField5;
}

class RefNotConstStaticFields {
  static int ref_staticFinalField = A2.staticFinalField1;
  static int ref_staticField = A2.staticField1;
}

class RefNotConstInstanceFields {
  static int ref_instanceFinalField = new A3().instanceFinalField1;
  static int ref_instanceField = new A3().instanceField1;
}

const b = const B();
