// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A<X> {}

mixin M1<Y> on A<void Function<Z>(void Function(Z, Y))> {}
class B1 extends A<void Function<Z>(void Function(Z, int))> with M1 {} // Ok.
