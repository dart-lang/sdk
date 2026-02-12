// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type E1(var foo) {} // Error.
extension type E2(final foo) {} // Ok.
extension type E3(final String foo) {} // Ok.
extension type E4(covariant num foo) {} // Error.
extension type E5(const bool foo) {} // Error.
extension type E6(covariant final double foo) {} // Error.
extension type E7(const var foo) {} // Error.
extension type E8() {} // Error.
extension type E9(int foo, String bar) {} // Error.
extension type E10(num foo, bool bar, double baz) {} // Error.
// TODO(johnniwinther): Stop reporting error on trailing comma?
extension type E11(bool foo,) {} // Error.
extension type E12(bool foo = false,) {} // Error.
extension type E13([int? foo]) {} // Ok.
extension type E14({String? foo}) {} // Ok.
extension type E15({required double foo}) {} // Ok.
extension type E16(bool foo, [dynamic bar]) {} // Error.
extension type E17(Object foo, {num? bar, String? baz}) {} // Error.
extension type E18(double foo, {required int bar}) {} // Error.
