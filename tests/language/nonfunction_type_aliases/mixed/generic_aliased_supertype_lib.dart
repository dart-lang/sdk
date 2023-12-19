// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {}

typedef A1<Y> = A<Y>;
typedef A2<U, Z> = A1<A<Z>>;
typedef A3<W> = A2<int, A<W>>;
