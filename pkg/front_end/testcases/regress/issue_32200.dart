// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "issue_32200.dart" as self;

class Foo {
  self.Foo self;
}

main() {
  self.Foo instance = new Foo();
  instance.self = instance;
}
