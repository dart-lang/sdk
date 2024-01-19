// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E1(num it) {}
extension type E2(E1 it) implements E1 {} // Ok.
extension type E3(int it) implements E1 {} // Ok.
extension type E4(E3 it) implements E1 {} // Ok.
extension type E5(E3 it) implements E2 {} // Ok.
extension type E6(E2 it) implements E3 {} // Error.
extension type E7(String it) implements E1 {} // Error.
