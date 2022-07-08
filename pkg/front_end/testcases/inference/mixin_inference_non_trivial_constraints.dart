// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I<X> {}

class M0<T> extends I<List<T>> {}

class M1<T> extends I<List<T>> {}

class M2<T> extends M1<Map<T, T>> {}

// M0 is inferred as M0<Map<int, int>>
class A extends M2<int> with M0 {}

main() {}
