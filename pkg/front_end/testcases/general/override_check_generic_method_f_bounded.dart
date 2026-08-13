// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that an override of a generic method is allowed in case of
// correctly defined f-bounded type variables.

class Foo<T extends Foo<T>> {}

abstract class Bar {
  void fisk<S extends Foo<S>>();
}

class Hest implements Bar {
  @override
  void fisk<U extends Foo<U>>() {}
}

void main() {}
