// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class SealedClass {}
class A with SealedClass {}

sealed mixin SealedMixin {}
class B with SealedClass, SealedMixin {}

class Class {}
class C with Class, SealedClass {}
class D with Class, SealedMixin {}

mixin Mixin {}
class E with Mixin, SealedClass {}
class F with Mixin, SealedMixin {}

// TODO(kallentu): Move this to a more generic test.
class G with Class, Mixin {}
