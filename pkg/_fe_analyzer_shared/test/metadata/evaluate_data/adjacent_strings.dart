// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

@Helper(
  "a"
  "b",
)
/*member: adjacentStrings1:
resolved=AdjacentStringLiterals(
    StringLiteral('a')
    StringLiteral('b'))
evaluate=StringLiteral('ab')*/
void adjacentStrings1() {}

@Helper(
  "a"
  "b"
  "c",
)
/*member: adjacentStrings2:
resolved=AdjacentStringLiterals(
    StringLiteral('a')
    StringLiteral('b')
    StringLiteral('c'))
evaluate=StringLiteral('abc')*/
void adjacentStrings2() {}
