// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type A(int it) implements B {}

extension type B(int it) implements A {}

extension type C(int it) implements D {}

extension type D(int it) implements E {}

extension type E(int it) implements F {}

extension type F(int it) implements D {}
