// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef T0 = void;
typedef T1 = Function;
typedef T2<X> = List<X>;
typedef T3<X, Y> = Map<X, Y>;
typedef T4 = void Function();
typedef T5<X> = X Function(X, {X name});
typedef T6<X, Y> = X Function(Y, [Map<Y, Y>]);
typedef T7<X extends String, Y extends List<X>> = X Function(Y, [Map<Y, Y>]);
