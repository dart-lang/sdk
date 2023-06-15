// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Other-library declarations used by 
// base_class_typedef_outside_of_library_test.dart

import 'base_class_typedef_outside_of_library_lib2.dart';

base class BaseClass {
  int foo = 0;
}

base class A extends ATypeDef {}

base class B implements ATypeDef {
  int foo = 1;
}
