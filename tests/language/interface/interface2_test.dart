// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A class must implement a known interface.

class Interface2NegativeTest implements BooHoo {}
//                                      ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_NON_CLASS
// [cfe] Type 'BooHoo' not found.

main() {
  Interface2NegativeTest();
}
