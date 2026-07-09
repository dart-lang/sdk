// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin M on Object {
  void mixinMethod() {}
}

class B {}

class C with M {}

class D = Object with M;
