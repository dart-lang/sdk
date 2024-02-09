// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}
extension type E(Object? it) {}
typedef TA = A;
typedef TE = E;

extension type E1(A it) implements A, A {} // Error.

extension type E2(E it) implements E, E {} // Error.

extension type E3(A it) implements A, TA, A, TA {} // Error.

extension type E4(E it) implements E, TE, E, TE {} // Error.
