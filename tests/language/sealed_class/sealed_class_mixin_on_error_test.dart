// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'sealed_class_mixin_on_lib.dart';

// It is an error to declare a mixin with an `on` type which is a sealed class
// from another library.
mixin MA on SealedClass {}
//          ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.

// It is not an error to declare a mixin with an `on` type which is a subtype of
// a sealed class from another library if the subclass is not otherwise
// restricted.
mixin MB on A {}

// It is an error to apply a mixin with an `on` type which is sealed to the
// sealed class which is its `on` type outside of the library which declares the
// `on` type.
class ConcreteA extends SealedClass with M {}
//                      ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'SealedClass' can't be extended, implemented, or mixed in outside of its library because it's a sealed class.

// It is not an error to apply a mixin with an `on` type which is sealed to a
// subtype of the sealed class.
class ConcreteB extends A with M {}

// It is not an error to apply a mixin with an `on` type which is a subtype of a
// sealed class from another library to a subtype of the sealed class.
class ConcreteC extends A with MB {}
