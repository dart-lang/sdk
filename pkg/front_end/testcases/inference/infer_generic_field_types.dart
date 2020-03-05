// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  X field;
}

abstract class B<Y> implements A<Y> {
  get field;
  set field(value);
}

abstract class C implements A<int> {
  get field;
  set field(value);
}

main() {}
