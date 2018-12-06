// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_single_quotes`

import "dart:collection"; // LINT
import 'dart:async'; // OK

main() {
  String string1 = "no quote"; // LINT
  String string2 = 'uses single'; // OK
  String string3 = "has quote '"; // OK

  String rawString1 = r"no quote"; // LINT
  String rawString2 = r'uses single'; // OK
  String rawString3 = r"has quote '"; // OK

  String multilineString1 = r"""no quote"""; // LINT
  String multilineString2 = r'''uses single'''; // OK
  String multilineString3 = r"""has quote '"""; // OK

  String x = 'x';

  String interpString1 = "no quote $x"; // LINT
  String interpString2 = 'uses single $x'; // OK
  String interpString3 = "has quote ' $x"; // OK

  String interpString4 = "no quote $x has quote ' $x no quote"; // OK
  String interpString5 = "no quote $x no quote $x no quote"; // LINT

  String stringWithinStringDoubleFirst = "foo ${x == 'x'} bar"; // OK
  String stringWithinStringSingleFirst = 'foo ${x == "x"} bar'; // OK
}
