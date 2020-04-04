// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Tests VM optimizing compiler negate condition for doubles (bug 5376516).

loop() {
  for (double d = 0.0; d < 1100.0; d++) {}
  for (double d = 0.0; d <= 1100.0; d++) {}
  for (double d = 1000.0; d > 0.0; d--) {}
  for (double d = 1000.0; d >= 0.0; d--) {}
}

main() {
  loop();
  loop();
}
