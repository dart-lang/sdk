// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test should fail to load because we are importing two libraries
// which define the same top level name. In this case libraryE.dart is
// importing libraryC.dart and libraryF.dart which both define variable
// "fooC".

#library("Library3NegativeTest.dart");
#import("libraryA.dart");
#import("libraryB.dart");
#import("libraryD.dart");
#import("libraryE.dart");

main() {
  Expect.equals(0, fooE);
}
