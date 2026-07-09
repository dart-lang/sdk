// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/co19/src/Language/Statements/Labels/scope_t05.dart

void foo() {
  try {
    switch (1) {
      Label:
      case 1:
        break;

      case 2:
        break;

      case 3:
        break;

      Label: // Error
      default:
        break;
    }
  } catch (x) {}
}
