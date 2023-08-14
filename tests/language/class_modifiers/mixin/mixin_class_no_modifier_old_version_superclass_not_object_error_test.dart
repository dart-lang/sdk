// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when mixing in a regular class from a library older than 3.0 where the
// class is outside and it has a superclass that's not Object

import 'mixin_class_no_modifier_old_version_lib.dart';

class SubclassNotObject with NonObjectSuperclassClass {
//                           ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_INHERITS_FROM_NOT_OBJECT
// [cfe] The class 'NonObjectSuperclassClass' can't be used as a mixin because it extends a class other than 'Object'.
  int foo = 1;
}

abstract class AbstractMixinClass with NonObjectSuperclassClass {}
//                                     ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_INHERITS_FROM_NOT_OBJECT
// [cfe] The class 'NonObjectSuperclassClass' can't be used as a mixin because it extends a class other than 'Object'.
