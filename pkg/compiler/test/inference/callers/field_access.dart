// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: B.:[main]*/
class A {
  /*member: A.field:[main]*/
  var field;
}

/*member: A.:[main]*/
class B {
  /*member: B.field:[main]*/
  var field;
}

main() {
  A().field;
  B().field;
}
