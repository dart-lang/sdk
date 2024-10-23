// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

@Helper(())
/*member: recordLiterals1:
RecordLiteral()*/
void recordLiterals1() {}

@Helper((0,))
/*member: recordLiterals2:
RecordLiteral(IntegerLiteral(0))*/
void recordLiterals2() {}

@Helper((0, 1))
/*member: recordLiterals3:
RecordLiteral(IntegerLiteral(0), IntegerLiteral(1))*/
void recordLiterals3() {}

@Helper((a: 0, 1))
/*member: recordLiterals4:
RecordLiteral(a: IntegerLiteral(0), IntegerLiteral(1))*/
void recordLiterals4() {}

@Helper((0, b: 1))
/*member: recordLiterals5:
RecordLiteral(IntegerLiteral(0), b: IntegerLiteral(1))*/
void recordLiterals5() {}

@Helper(const ())
/*member: recordLiterals6:
RecordLiteral()*/
void recordLiterals6() {}

@Helper(const (0,))
/*member: recordLiterals7:
RecordLiteral(IntegerLiteral(0))*/
void recordLiterals7() {}

@Helper(const (0, 1))
/*member: recordLiterals8:
RecordLiteral(IntegerLiteral(0), IntegerLiteral(1))*/
void recordLiterals8() {}

@Helper(const (a: 0, 1))
/*member: recordLiterals9:
RecordLiteral(a: IntegerLiteral(0), IntegerLiteral(1))*/
void recordLiterals9() {}

@Helper(const (0, b: 1))
/*member: recordLiterals10:
RecordLiteral(IntegerLiteral(0), b: IntegerLiteral(1))*/
void recordLiterals10() {}
