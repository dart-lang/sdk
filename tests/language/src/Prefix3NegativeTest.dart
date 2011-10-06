// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

// Using the same prefix name while importing two different libraries is
// an error.
#library("Prefix3NegativeTest.dart");
#import("library1.dart", prefix: "lib2");
#import("library2.dart", prefix: "lib2");

class Prefix3NegativeTest {
  static Main() {
  }
}

main() {
  Prefix3NegativeTest.Main();
}
