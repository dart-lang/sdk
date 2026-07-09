// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

@Helper((1))
/*member: parenthesized1:
resolved=ParenthesizedExpression(IntegerLiteral(1))
evaluate=IntegerLiteral(1)*/
void parenthesized1() {}
