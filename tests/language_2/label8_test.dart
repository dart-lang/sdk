// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  int i;
  // Grammar doesn't allow label on block for switch statement.
  switch(i)
    L: //# 01: compile-time error
  {
    case 111:
      while (false) {
        break L; //# 01: continued
      }
      i++;
  }
}
