// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  switchCaseWithContinue(null);
}

switchCaseWithContinue(e) {
  switch (e) {
    label:
    case 0:
      break;
    case 1:
      continue label;
  }
}
