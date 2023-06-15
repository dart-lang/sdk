// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Other-library declarations used by 
// final_class_typedef_subtype_error_test.dart and
// final_class_typedef_test.dart.

final class FinalClass {
  int foo = 0;
}

typedef FinalClassTypeDef = FinalClass;

final class A extends FinalClassTypeDef {}

final class B implements FinalClassTypeDef {
  int foo = 1;
}
