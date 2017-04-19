// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

main() {
  switch (1) {
    case 1:
    {
      "No fall-through error needed.";
      break;
      ; // Empty statement.
    }
    case 2:
    {
      "Fall-through error needed.";
      if (true) {
        break;
      }
    }
    case 3:
      try {
        "No fall-through error needed.";
      } finally {
        break;
      }
    case 4:
      try {
        "No fall-through error needed.";
        break;
      } finally {
      }
    case 5:
      try {
        "Fall-through error needed.";
      } finally {
      }
    case 10000:
      "Should be last. No fall-through error, falling through allowed here.";
  }
}
