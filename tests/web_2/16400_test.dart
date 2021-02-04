// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  L:
  {
    var seeMe = 0;
    if (seeMe == 0) {
      ++seeMe;
      break L;
    }
    var wontSeeMe = 2;
    if (seeMe + wontSeeMe == 2) {
      return true;
    } else {
      return false;
    }
  }
}
