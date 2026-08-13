// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Other-library declarations used by
// mixin_class_no_modifier_outside_library_error_test.dart.

class Class {
  int foo = 0;
}

mixin Mixin {
  int foo = 0;
}

abstract class AbstractClass {}

class NamedMixinClassApplication = Object with Mixin;
