// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Other-library declarations used by sealed_class_mixin_on_error_test.dart.

sealed class SealedClass {}

abstract class A extends SealedClass {}

class B extends SealedClass {}

// It is legal to declare a mixin whose `on` type is a sealed type from the
// same library.
mixin M on SealedClass {}

class C extends SealedClass with M {}
