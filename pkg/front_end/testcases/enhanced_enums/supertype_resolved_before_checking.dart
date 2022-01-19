// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks an execution path where _Enum as supertype was checked before
// being resolved.

mixin GM<T> on Enum {}

mixin M on Object {}

abstract class I {}

abstract class GI<T> {}

enum E<S extends num, T extends num>
    with GM<T>, M
    implements I, GI<S> { element }

main() {}
