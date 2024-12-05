// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface {}

mixin Mixin0<X> {}

mixin Mixin1<X extends Interface> {}

mixin Mixin2<X extends Interface> {}

abstract class C<X, Y, Z extends Interface> with Mixin0<Y>, Mixin1, Mixin2<Z> {}
