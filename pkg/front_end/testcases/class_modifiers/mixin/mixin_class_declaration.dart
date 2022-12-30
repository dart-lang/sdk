// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin class A {}

abstract mixin class B {}

mixin M {}
mixin class C = Object with M;

class AWith with A {}

class BWith with B {}

class CWith with C {}

class MultipleWithMixin with A, M {}

class MultipleWithAnotherClass with A, B {}
