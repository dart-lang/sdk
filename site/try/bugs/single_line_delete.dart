// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var greeting = "Hello, World!";

void main() {
  // Put cursor at end of previous line. Hit backspace.
  // 1. Ensure this triggers a single-line change.
  // 2. Ensure the cursor position is correct.
  // Then restore the file and place the cursor at the end of the file. Delete
  // each character in the file by holding down backspace. Verify that there
  // are no exceptions and that the entire buffer is deleted.
  // Then restore the file and place the cursor before the semicolon on the
  // first line. Hit delete and verify that a character is deleted.
  print(greeting);
}
