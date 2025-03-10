// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B implements A {
  /*member: B.foo:[exact=B|powerset=0]*/
  B.foo([int? /*[null|powerset=1]*/ x]);
}

class A {
  /*member: A._#foo#tearOff:[exact=B|powerset=0]*/
  factory A.foo([int /*[null|powerset=1]*/ x]) = B.foo;
}

/*member: main:[null|powerset=1]*/
void main() {
  final f = A.foo;
  f();
}
