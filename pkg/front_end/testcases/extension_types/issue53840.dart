// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class A {}

mixin M on A {}

enum En {
  element;
}

extension type E1(num it) implements Object {} // Ok.
extension type E2(E1 it) implements Object {} // Ok.
extension type E3(String? it) implements Object {} // Error.
extension type E4(E3 it) implements Object {} // Error.

extension type E5(Null it) implements void {} // Error.
extension type E6(Null it) implements dynamic {} // Error.
extension type E7(Null it) implements double? {} // Error.
extension type E8(bool it) implements FutureOr<bool> {} // Error.
extension type E9<X>(X it) implements FutureOr<X> {} // Error.
extension type E10(void Function(int) it) implements Function {} // Error.
extension type E11(String Function() it) implements String Function() {} // Error.
extension type E12((int, Object?) it) implements Record {} // Error.
extension type E13((Null, num) it) implements (Null, num) {} // Error.
extension type E14(Null it) implements Null {} // Error.
extension type E15<X>(X it) implements Never {} // Error.
extension type E16(Null it) implements Never {} // Error.

extension type E17(A a) implements A {} // Ok.
extension type E18(M m) implements M {} // Ok.
extension type E19(En en) implements En {} // Ok.
