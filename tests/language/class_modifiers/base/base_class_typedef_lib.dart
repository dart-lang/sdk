// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Other-library declarations used by
// base_class_typedef_implement_error_test.dart.

base class BaseClass {
  int foo = 0;
}

typedef BaseClassTypeDef = BaseClass;

base class A extends BaseClassTypeDef {}

base class B implements BaseClassTypeDef {
  int foo = 1;
}
