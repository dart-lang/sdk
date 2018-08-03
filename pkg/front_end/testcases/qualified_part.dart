// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of test.qualified.main;

class C<T> {
  C();
  C.a();
  factory C.b() = lib.C<T>.b;
}
