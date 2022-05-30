// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "issue_32182.dart" as self;

class A<T> {}

class M {
  m() => 42;
}

class C extends A<self.A> with M {}

main() {
  new C().m() + 1;
}
