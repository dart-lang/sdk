// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B1<T> {}

mixin M1 {}

class SC1<A extends B, B extends List<A>> extends B1<A> with M1 {}

class SC2<A extends B, B extends List<A>> extends B1<A> with M1 {}

class SC3<A extends B, B extends List<A?>> extends B1<A> with M1 {}

class SC4<A extends B, B extends List<A>?> extends B1<A> with M1 {}

main() {}
