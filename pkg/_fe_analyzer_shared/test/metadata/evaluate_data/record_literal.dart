// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

@Helper((
  "a"
      "b",
  c:
      "c"
      "d",
))
/*member: recordLiteral1:
resolved=RecordLiteral(AdjacentStringLiterals(
    StringLiteral('a')
    StringLiteral('b')), c: AdjacentStringLiterals(
    StringLiteral('c')
    StringLiteral('d')))
evaluate=RecordLiteral(StringLiteral('ab'), c: StringLiteral('cd'))*/
void recordLiteral1() {}

@Helper((
  "a"
      "b",
  c: (
    d:
        "c"
        "d",
  ),
))
/*member: recordLiteral2:
resolved=RecordLiteral(AdjacentStringLiterals(
    StringLiteral('a')
    StringLiteral('b')), c: RecordLiteral(d: AdjacentStringLiterals(
    StringLiteral('c')
    StringLiteral('d'))))
evaluate=RecordLiteral(StringLiteral('ab'), c: RecordLiteral(d: StringLiteral('cd')))*/
void recordLiteral2() {}
