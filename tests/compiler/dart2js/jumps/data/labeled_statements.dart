// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  breakFromIf(true);
  breakFromBlock(true);
}

breakFromIf(c) {
  label:
  /*0@break*/ if (c) {
    /*target=0*/ break label;
  }
}

breakFromBlock(c) {
  label:
  /*0@break*/
  {
    if (c) {
      /*target=0*/ break label;
    }
    print('1');
  }
}
