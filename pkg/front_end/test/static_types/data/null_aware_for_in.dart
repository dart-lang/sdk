// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {}

main() {
  var o;
  /*current: dynamic*/
  /*as: Class!*/
  for (
      // ignore: UNUSED_LOCAL_VARIABLE
      Class c in
      /*as: Iterable<dynamic>!*/
      /*dynamic|dynamic*/ o?. /*dynamic*/ iterable) {}
}
