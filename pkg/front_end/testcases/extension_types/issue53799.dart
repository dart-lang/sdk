// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {}
class B<X> extends A<X> {}
class C extends A<String> {}
extension type E<X>(X it) {}

extension type E1(A<Never> it) implements A<String>, A<int> {} // Error.

extension type E2(B<Never> it) implements B<String>, A<double> {} // Error.

extension type E3(C it) implements C, A<num> {} // Error.

extension type E41(A<Never> it) implements A<String> {}
extension type E42(A<Never> it) implements E41, A<int> {} // Error.

extension type E5(E<Never> it) implements E<String>, E<bool> {} // Error.

extension type E61(E<Never> it) implements E<num> {}
extension type E62(E<Never> it) implements E61, E<String> {} // Error.

extension type E71(E<Never> it) implements E<double> {}
extension type E72(E<Never> it) implements E<bool> {}
extension type E73(E<Never> it) implements E71, E72 {} // Error.
