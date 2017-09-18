// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'source_constant_lib.dart';

class ClassWithoutConstConstructor {
  static const int staticConstField = 42;
  static final int staticFinalField = 42;
  static int staticField = 42;
  final int instanceFinalField = 42;
  int instanceField = 42;

  ClassWithoutConstConstructor([int p = 42]);
}

class ClassWithConstConstructor {
  static const int staticConstField = 42;
  static final int staticFinalField = 42;
  static int staticField = 42;
  final int instanceFinalField = 42;

  const ClassWithConstConstructor([int a = 42, b = libConst1]);
}

const int constField = 42;
final int finalField = 42;
int regularField = 42;
