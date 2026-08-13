// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Other library declarations used by
// interface_class_typedef_extend_error_test.dart.

interface class InterfaceClass {
  int foo = 0;
}

typedef InterfaceClassTypeDef = InterfaceClass;

class A extends InterfaceClassTypeDef {}

class B implements InterfaceClassTypeDef {
  int foo = 1;
}
