// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  L:
  {
    for (var i in []) {
      continue L; // Error
    }
  }
  1;

  alias:
  label:
  for (var i in []) {
    if (i == 0) {
      continue label; // Ok
    } else {
      continue alias; // Ok
    }
  }

  alias2:
  {
    label2:
    for (var i in []) {
      if (i == 0) {
        continue label2; // Ok
      } else {
        continue alias2; // Error
      }
    }
  }
}
