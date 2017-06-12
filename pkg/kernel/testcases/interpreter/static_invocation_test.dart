// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library static_invocation_test;

/// Simple program containing static invocations.
///
/// The log of this test is used to verify the order of execution and evaluation
/// of function body, arguments and static invocation expression.
void main() {
  a();
  b(1, 9);
  print(b(1, 9));
  var retD = d();
  print(c(37));
  print(retD);
}

void a() {}

void b(int n, int m) {
  print(n);
  print(m);
  print(n + m);
}

String c(int n) {
  print('c:$n');
  return "d:${d()}";
}

int d() {
  a();
  return 37;
}
