// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1() => (0, $0: 0); // Error.
test2() => ($0: 0); // Ok.
test3() => (0, $1: 1); // Ok.
(int, {String $0}) test4() => throw 0; // Error.
({bool $0}) test5() => throw 0; // Ok.
(num, {double $1}) test6() => throw 0; // Ok.
(num, {double $00}) test7() => throw 0; // Ok.
(num, {double $0x0}) test8() => throw 0; // Ok.
(num, bool, {double $01}) test9() => throw 0; // Ok.
({String $0, bool $00, int $0x0}) test10() => throw 0; // Ok.
test11() => (10, 11, 12, $2: 13); // Error.
(int, double, num, {String $2}) test12() => throw 0; // Error.

main() {}
