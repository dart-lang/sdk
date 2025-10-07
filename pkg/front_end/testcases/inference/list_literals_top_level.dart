// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

var x1 = [1, 2, 3];
test1() {
  x1.add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 'hi');
  x1.add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 4.0);
  x1.add(4);
  List<num> y = x1;
}

var x2 = [1, 2.0, 3];
test2() {
  x2.add(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 'hi');
  x2.add(4.0);
  List<int> y = /*info:ASSIGNMENT_CAST*/ x2;
}

main() {}
