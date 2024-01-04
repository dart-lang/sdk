// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E11(num it) {
  void foo() {}
}

extension type E12(num it) {
  void set foo(String value) {}
}

extension type E13(num it) implements E11, E12 {} /* Error */

extension type E21(bool it) {
  void bar() {}
}

extension type E22(bool it) {
  void bar() {}
}

extension type E23(bool it) implements E21, E22 {} /* Error */

extension type E31(String it) {
  void baz() {}
}

extension type E32(String it) implements E31 {}

extension type E33(String it) implements E31 {}

extension type E34(String it) implements E32, E33 {} /* Ok */
