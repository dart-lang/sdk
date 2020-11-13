// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  num field;
}

class B {
  covariant num field;
}

class C extends A implements B {
  num field;
}

main() {}
