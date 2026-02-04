// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that VM correctly handles function type arguments across
// yield points.

import "package:expect/expect.dart";

void main() {
  doStuff<String>();
}

doStuff<T>() async {
  Expect.equals(String, T);
  await null;
  Expect.equals(String, T);
}
