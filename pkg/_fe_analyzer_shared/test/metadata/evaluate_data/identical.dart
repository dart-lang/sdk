// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

@Helper(identical(true, false))
/*member: identicalCall1:
resolved=StaticInvocation(
  identical(
    BooleanLiteral(true), 
    BooleanLiteral(false)))
evaluate=StaticInvocation(
  identical(
    BooleanLiteral(true), 
    BooleanLiteral(false)))*/
void identicalCall1() {}
