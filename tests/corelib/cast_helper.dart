// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final elements = <C?>[c, d, e, f, null];

class C {}

class D extends C {}

class E extends C {}

class F implements D, E {}

final c = C();
final d = D();
final e = E();
final f = F();
