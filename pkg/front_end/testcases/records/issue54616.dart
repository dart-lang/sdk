// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  var c = (call: (int x) => x);
  var v = c(1); // Error.

  var c2 = (call: intId);
  var v2 = c2(1); // Error.

  var c3 = (call: <T>(T x) => x);
  var v3a = c3(1); // Error.
  var v3b = c3("a"); // Error.
}

int intId(int x) => x;
