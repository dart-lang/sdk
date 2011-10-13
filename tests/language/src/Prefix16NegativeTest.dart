// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Unresolved symbols should be reported as an error.

#library("Prefix16NegativeTest.dart");
#import("library12.dart", prefix:"lib12");

typedef lib12.Library13 myFunc(lib12.Library13 param);

main() {
  myFunc i = 0;
}
