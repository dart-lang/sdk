// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 35341.

import "dart:async";

void main() {
  FutureOr<int> i = 0;
  i = new Future<int>.value(0);
  print(i.runtimeType);
  // Ensure that [i] is not effectively final, so that we don't infer the
  // static type from the initializer.
  i = null;
}
