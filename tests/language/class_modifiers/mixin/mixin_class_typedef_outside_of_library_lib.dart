// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Other-library declarations used by
// mixin_class_typedef_outside_of_library_test.dart.

import 'mixin_class_typedef_outside_of_library_lib2.dart';

mixin class MixinClass {
  int foo = 0;
}

class A with ATypeDef {}

abstract class B with ATypeDef {}
