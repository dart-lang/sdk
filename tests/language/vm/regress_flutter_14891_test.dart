// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test verifying that type literals hidden within other constant objects
// are correctly handled by the AOT compiler.

import "package:expect/expect.dart";

class _ClassOnlyUsedAsTypeLiteral {}

void main() {
  Expect
      .isTrue((const [_ClassOnlyUsedAsTypeLiteral]).toString().startsWith('['));
}
