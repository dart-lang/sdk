// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

@Helper((1 + 2) as int)
/*member: as1:
resolved=AsExpression(ParenthesizedExpression(BinaryExpression(IntegerLiteral(1) + IntegerLiteral(2))) as int)
evaluate=AsExpression(IntegerLiteral(value=3) as int)*/
void as1() {}

@Helper((1 + 2) is int)
/*member: is1:
resolved=IsTest(ParenthesizedExpression(BinaryExpression(IntegerLiteral(1) + IntegerLiteral(2))) is int)
evaluate=IsTest(IntegerLiteral(value=3) is int)*/
void is1() {}
