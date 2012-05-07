// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('test3.dart');

#source('test3a.dart');

int test3() {
  var result = test3a();
  Expect.equals(3, result);
  return result;
}
