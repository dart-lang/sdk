// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B implements A {
  /*member: B.foo:[exact=B]*/
  B.foo([int? /*[null]*/ x]);
}

class A {
  /*member: A._#foo#tearOff:[exact=B]*/
  factory A.foo([int /*[null]*/ x]) = B.foo;
}

/*member: main:[null]*/
void main() {
  final f = A.foo;
  f();
}
