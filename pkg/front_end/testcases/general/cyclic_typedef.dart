// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F1<X> = List<G1<X>>;
typedef G1<Y> = F1<Y>;

typedef F2 = void Function<X extends F2>();

typedef F3 = F3;

typedef F4 = List<F4>;

typedef F5<X extends F5<Never>> = Object;
