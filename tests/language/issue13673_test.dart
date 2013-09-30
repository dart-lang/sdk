// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Bar {
  Type field;
  Bar(this.field);
  foo() => field;
}

var topLevel = new Bar(String).foo();

main() {
  Expect.isTrue(topLevel is Type);
}
