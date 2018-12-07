// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for DartPad issue 881.

void main() {
  String v = null;
  print('${v.hashCode}');
  // Makes sure that [v] is not effectively final, so that we don't infer the
  // static type from the initializer.
  v = '';
}
