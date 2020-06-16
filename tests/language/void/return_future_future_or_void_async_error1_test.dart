// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

void main() {
  test();
}

// Can only have `return;` if future value type is `void`, `dynamic` or `Null`.
// Here it's `FutureOr<void>` which is equivalent to `void`, but is not `void`.
Future<FutureOr<void>> test() async {
  return; //# none: compile-time error
}
