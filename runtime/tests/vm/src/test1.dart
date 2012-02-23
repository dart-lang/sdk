// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--import_map=GOOGLE,. --import_map=SRC,mysrc --import_map=DART,.
//
// Dart test program for checking implementation of string
// interapolation feature in import statements.

#library('test1.dart');

#import('${GOOGLE}/$SRC/test2.dart');
#import('$SRC/test3.dart');

int test1() {
  return 1;
}

main() {
  var result = test1() + test2() + test3();
  Expect.equals(6, result);
}
