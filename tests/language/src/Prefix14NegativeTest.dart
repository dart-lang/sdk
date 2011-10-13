// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Unresolved symbols should be reported as an error.

#library("Prefix14NegativeTest.dart");
#import("library12.dart", prefix:"lib12");

class myClass {
  myClass(lib12.Library13 this.fld);
  lib12.Library13 fld;
}

main() {
}
