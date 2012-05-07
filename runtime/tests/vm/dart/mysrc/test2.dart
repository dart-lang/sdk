// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('test2.dart');

#source('../$SRC/test2a.dart');

int test2() {
  var result = test2a();
  Expect.equals(2, result);
  return result;
}
