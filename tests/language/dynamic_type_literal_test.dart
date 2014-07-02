// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test generation of 'dynamic' type literals.

import "package:expect/expect.dart";

void main() {
  Expect.isTrue(dynamic is Type);
  Expect.isFalse(dynamic == Type);
}
