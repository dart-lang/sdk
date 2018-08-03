// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// User-facing regression test: ensure we correctly record when a closure needs
/// runtime type information for a type parameter that may be used or
/// .runtimeType.
class A<T> {
  final f;
  A() : f = (() => new C<T>());
}

class C<T> {}

main() => print(new A<int>().f().runtimeType);
