// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Unresolved symbols should be reported as an error.

library Prefix13NegativeTest.dart;

import "library12.dart" as lib12;

class myClass extends lib12.Library13 {
  myClass(int this.fld) : super(0);
  int fld;
}

main() {
  new myClass(1);
}
