// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is a compile-time error if a value class has a non-final instance variable.

import 'value_class_support_lib.dart';

@valueClass
class Animal {
  int numberOfLegs;
  //^
  // [cfe] unspecified
}
