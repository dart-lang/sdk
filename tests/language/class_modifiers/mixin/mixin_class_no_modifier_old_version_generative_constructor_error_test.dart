// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when mixing in a regular class from a library older than 3.0 where the
// class is outside and that class declares a generative constructor

import 'mixin_class_no_modifier_old_version_lib.dart';

class ClassMixingCtorClass with GenerativeConstructorClass {}
//    ^
// [cfe] Can't use 'GenerativeConstructorClass' as a mixin because it has constructors.
//                              ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR

abstract class AbstractClassMixingCtorClass with GenerativeConstructorClass {}
//             ^
// [cfe] Can't use 'GenerativeConstructorClass' as a mixin because it has constructors.
//                                               ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
