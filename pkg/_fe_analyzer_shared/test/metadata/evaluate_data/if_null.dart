// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const int? constNullableInt = 42;

@Helper(0 ?? 1)
/*member: ifNull1:
resolved=IfNull(
  IntegerLiteral(0)
   ?? 
  IntegerLiteral(1)
)
evaluate=IntegerLiteral(0)*/
void ifNull1() {}

@Helper(null ?? 1)
/*member: ifNull2:
resolved=IfNull(
  NullLiteral()
   ?? 
  IntegerLiteral(1)
)
evaluate=IntegerLiteral(1)*/
void ifNull2() {}

@Helper(1 ?? null)
/*member: ifNull3:
resolved=IfNull(
  IntegerLiteral(1)
   ?? 
  NullLiteral()
)
evaluate=IntegerLiteral(1)*/
void ifNull3() {}

@Helper(null ?? null)
/*member: ifNull4:
resolved=IfNull(
  NullLiteral()
   ?? 
  NullLiteral()
)
evaluate=NullLiteral()*/
void ifNull4() {}

@Helper(constNullableInt ?? 0)
/*member: ifNull5:
resolved=IfNull(
  StaticGet(constNullableInt)
   ?? 
  IntegerLiteral(0)
)
evaluate=IntegerLiteral(42)
constNullableInt=IntegerLiteral(42)*/
void ifNull5() {}
