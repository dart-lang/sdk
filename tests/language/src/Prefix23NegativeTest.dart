// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Unresolved symbols should be reported as an static type warnings.
// In this variant of test we turn warnings into errors.
// VMOptions=--enable_type_checks

#library("Prefix22NegativeTest.dart");
#import("library12.dart", prefix:"lib12");

class myClass {
  lib12.Library13 fld; /// static type error
}

main() {
}
