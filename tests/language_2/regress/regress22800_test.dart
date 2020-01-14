// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check proper exception handler finalization, even for unreachable handlers.

void main() {
  try {
    print("Starting here");
    throw 0;
    try {} catch (e) {}
  } catch (e) {
    print("Caught in here: $e");
  }
  try {} catch (e) {}
}
