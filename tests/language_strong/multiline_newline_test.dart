// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'multiline_newline_cr.dart' as cr;
import 'multiline_newline_crlf.dart' as crlf;
import 'multiline_newline_lf.dart' as lf;

main() {
  Expect.equals(4, cr.constantMultilineString.length);
  Expect.equals(4, crlf.constantMultilineString.length);
  Expect.equals(4, lf.constantMultilineString.length);
  Expect.equals(cr.constantMultilineString, crlf.constantMultilineString);
  Expect.equals(crlf.constantMultilineString, lf.constantMultilineString);
  Expect.equals(lf.constantMultilineString, cr.constantMultilineString);

  Expect.equals(4, cr.nonConstantMultilineString.length);
  Expect.equals(4, crlf.nonConstantMultilineString.length);
  Expect.equals(4, lf.nonConstantMultilineString.length);
  Expect.equals(cr.nonConstantMultilineString, crlf.nonConstantMultilineString);
  Expect.equals(crlf.nonConstantMultilineString, lf.nonConstantMultilineString);
  Expect.equals(lf.nonConstantMultilineString, cr.nonConstantMultilineString);

  const c1 =
      cr.constantMultilineString == crlf.constantMultilineString ? true : null;
  const c2 =
      crlf.constantMultilineString == lf.constantMultilineString ? true : null;
  const c3 =
      lf.constantMultilineString == cr.constantMultilineString ? true : null;
  Expect.isTrue(c1);
  Expect.isTrue(c2);
  Expect.isTrue(c3);

  const c4 = c1 ? 1 : 2; // //# 01: ok
  Expect.equals(1, c4); //  //# 01: continued

  const c5 = c2 ? 2 : 3; // //# 02: ok
  Expect.equals(2, c5); //  //# 02: continued

  const c6 = c3 ? 3 : 4; // //# 03: ok
  Expect.equals(3, c6); //  //# 03: continued

  const c7 =
      cr.constantMultilineString != crlf.constantMultilineString ? true : null;
  const c8 =
      crlf.constantMultilineString != lf.constantMultilineString ? true : null;
  const c9 =
      lf.constantMultilineString != cr.constantMultilineString ? true : null;
  Expect.isNull(c7);
  Expect.isNull(c8);
  Expect.isNull(c9);

  const c10 = c7 ? 1 : 2; // //# 04: compile-time error
  const c11 = c8 ? 2 : 3; // //# 05: compile-time error
  const c12 = c9 ? 3 : 4; // //# 06: compile-time error
}
