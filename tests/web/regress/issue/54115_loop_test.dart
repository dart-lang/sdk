// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var canSelect = false;
// Use late binding so the compiler doesn't inline and optimize out the bug.
late bool Function() select = () => true;

void doWhileLoop() {
  bool shouldRepeat;
  do {
    shouldRepeat = false;
    if (canSelect) {
      final isApproved = select();
      if (!isApproved) {
        shouldRepeat = true;
        continue;
      }
    }
  } while (shouldRepeat);
}

void main() {
  canSelect = true;
  doWhileLoop();

  canSelect = false;
  doWhileLoop();
}
