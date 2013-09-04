// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

main() {
  int i = 0;
  try {
    i = 1;
  } catch (exception) {
    i = 2;
  }
  // Since there is a generic 'catch all' statement preceding this
  // we expect to get a dead code error/warning over here.
  on Exception catch (exception) { i = 3; }  /// 01: compile-time error
}
