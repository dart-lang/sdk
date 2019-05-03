// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_double_quotes`

import 'dart:collection'; // LINT
import "dart:async"; // OK

main() {
  String string1 = 'no quote'; // LINT
  String string2 = "uses double"; // OK
  String string3 = 'has double quote "'; // OK

  String rawString1 = r'no double quote'; // LINT
  String rawString2 = r"uses double"; // OK
  String rawString3 = r'has double quote "'; // OK

  String multilineString1 = r'''no double quote'''; // LINT
  String multilineString2 = r"""uses double"""; // OK
  String multilineString3 = r'''has double quote "'''; // OK

  String x = "x";

  String interpString1 = 'no double quote $x'; // LINT
  String interpString2 = "uses double $x"; // OK
  String interpString3 = 'has double quote " $x'; // OK

  String interpString4 = 'no double quote $x has double quote " $x no double quote'; // OK
  String interpString5 = 'no double quote $x no double quote $x no double quote'; // LINT

  String stringWithinStringDoubleFirst = "foo ${x == 'x'} bar"; // OK
  String stringWithinStringSingleFirst = 'foo ${x == "x"} bar'; // OK
}
