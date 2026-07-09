// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const int constInt = 42;

@Helper(0!)
/*member: nullCheck1:
resolved=NullCheck(IntegerLiteral(0))
evaluate=IntegerLiteral(0)*/
void nullCheck1() {}

@Helper(null!)
/*member: nullCheck2:
resolved=NullCheck(NullLiteral())
evaluate=NullCheck(NullLiteral())*/
void nullCheck2() {}

@Helper(constInt!)
/*member: nullCheck3:
resolved=NullCheck(StaticGet(constInt))
evaluate=IntegerLiteral(42)
constInt=IntegerLiteral(42)*/
void nullCheck3() {}
