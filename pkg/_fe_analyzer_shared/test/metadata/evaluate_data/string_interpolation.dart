// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const bool constBool = true;

@Helper("a ${"b"} c")
/*member: stringInterpolation1:
resolved=StringLiteral('a ${StringLiteral('b')} c')
evaluate=StringLiteral('a b c')*/
void stringInterpolation1() {}

@Helper("a ${null} c")
/*member: stringInterpolation2:
resolved=StringLiteral('a ${NullLiteral()} c')
evaluate=StringLiteral('a null c')*/
void stringInterpolation2() {}

@Helper("a ${true} c")
/*member: stringInterpolation3:
resolved=StringLiteral('a ${BooleanLiteral(true)} c')
evaluate=StringLiteral('a true c')*/
void stringInterpolation3() {}

@Helper("a ${false} c")
/*member: stringInterpolation4:
resolved=StringLiteral('a ${BooleanLiteral(false)} c')
evaluate=StringLiteral('a false c')*/
void stringInterpolation4() {}

@Helper("a ${0} c")
/*member: stringInterpolation5:
resolved=StringLiteral('a ${IntegerLiteral(0)} c')
evaluate=StringLiteral('a 0 c')*/
void stringInterpolation5() {}

@Helper("a ${0.5} c")
/*member: stringInterpolation6:
resolved=StringLiteral('a ${DoubleLiteral(0.5)} c')
evaluate=StringLiteral('a 0.5 c')*/
void stringInterpolation6() {}

@Helper("a ${"b ${"c"} d"} e")
/*member: stringInterpolation7:
resolved=StringLiteral('a ${StringLiteral('b ${StringLiteral('c')} d')} e')
evaluate=StringLiteral('a b c d e')*/
void stringInterpolation7() {}

@Helper("a ${" b ${constBool}"} c")
/*member: stringInterpolation8:
resolved=StringLiteral('a ${StringLiteral(' b ${StaticGet(constBool)}')} c')
evaluate=StringLiteral('a  b true c')
constBool=BooleanLiteral(true)*/
void stringInterpolation8() {}
