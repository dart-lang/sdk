// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  abstract int instanceField; // ok

  abstract final int finalInstanceField; // ok

  abstract covariant num covariantInstanceField; // ok
}

mixin B {
  abstract int instanceField; // ok

  abstract final int finalInstanceField; // ok

  abstract covariant num covariantInstanceField; // ok
}

main() {}
