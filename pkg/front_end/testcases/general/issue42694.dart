// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  void set setter(int value);
}

class B implements A {
  get setter => throw '';
  void set setter(value) {}
}

main() {}
