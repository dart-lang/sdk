// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const String variable = '';

@Helper(0)
/*member: literal1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (IntegerLiteral(0))))
resolved=IntegerLiteral(0)*/
void literal1() {}

@Helper(42.5)
/*member: literal2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (DoubleLiteral(42.5))))
resolved=DoubleLiteral(42.5)*/
void literal2() {}

@Helper(0x42)
/*member: literal3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (IntegerLiteral(0x42))))
resolved=IntegerLiteral(0x42)*/
void literal3() {}

@Helper(true)
/*member: literal4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BooleanLiteral(true))))
resolved=BooleanLiteral(true)*/
void literal4() {}

@Helper(false)
/*member: literal5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BooleanLiteral(false))))
resolved=BooleanLiteral(false)*/
void literal5() {}

@Helper(null)
/*member: literal6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (NullLiteral())))
resolved=NullLiteral()*/
void literal6() {}

@Helper('a')
/*member: literal7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (StringLiteral('a'))))
resolved=StringLiteral('a')*/
void literal7() {}

@Helper('-$variable-')
/*member: literal8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (StringLiteral('-${UnresolvedExpression(UnresolvedIdentifier(variable))}-'))))
resolved=StringLiteral('-${StaticGet(variable)}-')*/
void literal8() {}

@Helper('a${0}b')
/*member: literal9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (StringLiteral('a${IntegerLiteral(0)}b'))))
resolved=StringLiteral('a${IntegerLiteral(0)}b')*/
void literal9() {}

@Helper(
  'a'
  'b',
)
/*member: literal10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (AdjacentStringLiterals(
      StringLiteral('a')
      StringLiteral('b')))))
resolved=AdjacentStringLiterals(
    StringLiteral('a')
    StringLiteral('b'))*/
void literal10() {}

@Helper(
  'a'
  'b'
  'c',
)
/*member: literal11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (AdjacentStringLiterals(
      StringLiteral('a')
      StringLiteral('b')
      StringLiteral('c')))))
resolved=AdjacentStringLiterals(
    StringLiteral('a')
    StringLiteral('b')
    StringLiteral('c'))*/
void literal11() {}

@Helper('\t\n\f\r\b\u00A0')
/*member: literal12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (StringLiteral('\u0009\n\u000c\u000d\u0008\u00a0'))))
resolved=StringLiteral('\u0009\n\u000c\u000d\u0008\u00a0')*/
void literal12() {}

@Helper(r'$\')
/*member: literal13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (StringLiteral('\$\\'))))
resolved=StringLiteral('\$\\')*/
void literal13() {}

@Helper('''

more lines

''')
/*member: literal14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (StringLiteral('\nmore lines\n\n'))))
resolved=StringLiteral('\nmore lines\n\n')*/
void literal14() {}

@Helper(#a)
/*member: literal15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SymbolLiteral(a))))
resolved=SymbolLiteral(a)*/
void literal15() {}
