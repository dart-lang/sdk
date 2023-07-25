// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {}

extension type B<T>(A<T> it) implements A<T> {}

extension type C<T>(A<T> it) implements C<T> {}

extension type D(A<Never> it) implements A<int>, B<String> {}

extension type E(A<Never> it) implements B<int>, C<String> {}
