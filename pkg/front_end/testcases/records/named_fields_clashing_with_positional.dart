// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1() => (0, $1: 0); // Error.
test2() => ($1: 0); // Ok.
test3() => (0, $2: 1); // Ok.
(int, {String $1}) test4() => throw 0; // Error.
({bool $1}) test5() => throw 0; // Ok.
(num, {double $2}) test6() => throw 0; // Ok.
(num, {double $01}) test7() => throw 0; // Ok.
(num, {double $0x1}) test8() => throw 0; // Ok.
(num, bool, {double $01}) test9() => throw 0; // Ok.
({String $1, bool $01, int $0x1}) test10() => throw 0; // Ok.
test11() => (10, 11, 12, $3: 13); // Error.
(int, double, num, {String $3}) test12() => throw 0; // Error.

main() {}
