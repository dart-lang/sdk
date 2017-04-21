// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

main() {
  for (var x, y in []) {}
  L: { continue L; }
  L: if (true) { continue L; }
  L: switch (1) {
    case 1:
      continue L;
    case 2:
      break L;
  }
  try {
  } on NoSuchMethodError {
  }
}
