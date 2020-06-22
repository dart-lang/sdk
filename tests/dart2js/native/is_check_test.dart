// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

@Native("A")
class A {}

main() {
  JS('A', '(null)'); // Class 'A' appears to be created.
  Expect.isFalse(confuse(new Object()) is A);
}
