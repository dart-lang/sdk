// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract //# 01: static type warning
class Abstract {
  Abstract(_);
}

void main() {
  Expect.throws(() => new Abstract(throw "argument"), (e) => e == "argument");
}
