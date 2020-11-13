// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I<X> {}

class M0<X, Y extends void Function({String name})> extends I<X> {}

class M1 implements I<int> {}

// M0 is inferred as M0<int, void Function({String name})>
class A extends M1 with M0 {}

main() {}
