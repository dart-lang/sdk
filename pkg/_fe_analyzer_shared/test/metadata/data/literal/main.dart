// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const String variable = '';

@Helper(0)
/*member: literal1:
IntegerLiteral(0)*/
void literal1() {}

@Helper(42.5)
/*member: literal2:
DoubleLiteral(42.5)*/
void literal2() {}

@Helper(0x42)
/*member: literal3:
IntegerLiteral(0x42)*/
void literal3() {}

@Helper(true)
/*member: literal4:
BooleanLiteral(true)*/
void literal4() {}

@Helper(false)
/*member: literal5:
BooleanLiteral(false)*/
void literal5() {}

@Helper(null)
/*member: literal6:
NullLiteral()*/
void literal6() {}

@Helper('a')
/*member: literal7:
StringLiteral('a')*/
void literal7() {}

@Helper('-$variable-')
/*member: literal8:
StringLiteral('-${StaticGet(variable)}-')*/
void literal8() {}

@Helper('a${0}b')
/*member: literal9:
StringLiteral('a${IntegerLiteral(0)}b')*/
void literal9() {}

@Helper('a' 'b')
/*member: literal10:
StringJuxtaposition(
    StringLiteral('a')
    StringLiteral('b'))*/
void literal10() {}

@Helper('a' 'b' 'c')
/*member: literal11:
StringJuxtaposition(
    StringLiteral('a')
    StringLiteral('b')
    StringLiteral('c'))*/
void literal11() {}

@Helper('\t\n\f\r\b\u00A0')
/*member: literal12:
StringLiteral('\u0009\n\u000c\u000d\u0008\u00a0')*/
void literal12() {}

@Helper(r'$\')
/*member: literal13:
StringLiteral('\$\\')*/
void literal13() {}

@Helper('''

more lines

''')
/*member: literal14:
StringLiteral('\nmore lines\n\n')*/
void literal14() {}

@Helper(#a)
/*member: literal15:
SymbolLiteral(a)*/
void literal15() {}
