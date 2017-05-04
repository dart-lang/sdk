// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch (e) {
    return true;
  }
}

int returnString1() => 's';
void returnNull() => null;
void returnString2() => 's';

main() {
  if (isCheckedMode()) {
    Expect.throws(returnString1, (e) => e is TypeError);
    returnString2();
    returnNull();
  } else {
    returnString1();
    returnNull();
    returnString2();
  }
}
