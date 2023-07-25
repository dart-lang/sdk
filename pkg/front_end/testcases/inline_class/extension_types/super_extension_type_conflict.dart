// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type A<T>(int it) {}

extension type B<T>(int it) implements A<T> {}

extension type C<T>(int it) implements A<T> {}

extension type D(int it) implements A<int>, B<String> {}

extension type E(int it) implements B<int>, C<String> {}
