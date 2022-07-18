// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I<X, Y> {}

class M0<T> implements I<T, int> {}

class M1<T> implements I<String, T> {}

// M0 inferred as M0<String>
// M1 inferred as M1<int>
class A extends Object with M0, M1 {}

main() {}
