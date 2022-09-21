// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  void method() {
    C<(num, {String name})>.new; // Const
    C<(T, {String name})>.new; // Non-const
    C<(num, {T name})>.new; // Non-const
  }
}
