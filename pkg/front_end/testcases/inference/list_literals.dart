// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

test1() {
  var x = [1, 2, 3];
  x.add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 'hi');
  x.add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 4.0);
  x.add(4);
  List<num> y = x;
}

test2() {
  var x = [1, 2.0, 3];
  x.add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 'hi');
  x.add(4.0);
  List<int> y = /*info:ASSIGNMENT_CAST*/ x;
}

main() {}
