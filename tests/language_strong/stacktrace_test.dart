// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a stack trace is properly terminated (issue 8850).

import "package:expect/expect.dart";

void main() {
  var ex = new Exception("fail");
  try {
    throw ex;
  } on Exception catch (e, st) {
    Expect.equals(ex, e);
    Expect.isTrue(st.toString().endsWith("\n"));
  }
}
