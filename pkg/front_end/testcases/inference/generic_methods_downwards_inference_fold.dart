// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

void test(List<int> o) {
  int y = o.fold(0, (x, y) => x + y);
  var z = o.fold(0, (x, y) => /*info:DYNAMIC_INVOKE*/ x + y);
  y = /*info:DYNAMIC_CAST*/ z;
}

void functionExpressionInvocation(List<int> o) {
  int y = (o.fold)(0, (x, y) => x + y);
  var z = (o.fold)(0, (x, y) => /*info:DYNAMIC_INVOKE*/ x + y);
  y = /*info:DYNAMIC_CAST*/ z;
}

main() {}
