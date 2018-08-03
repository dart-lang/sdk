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

  Expect.equals(6, cr.constantRawMultilineString.length);
  Expect.equals(6, crlf.constantRawMultilineString.length);
  Expect.equals(6, lf.constantRawMultilineString.length);

  Expect.equals(cr.constantMultilineString, crlf.constantMultilineString);
  Expect.equals(crlf.constantMultilineString, lf.constantMultilineString);
  Expect.equals(lf.constantMultilineString, cr.constantMultilineString);

  Expect.equals(cr.constantRawMultilineString, crlf.constantRawMultilineString);
  Expect.equals(crlf.constantRawMultilineString, lf.constantRawMultilineString);
  Expect.equals(lf.constantRawMultilineString, cr.constantRawMultilineString);

  Expect.equals(4, cr.nonConstantMultilineString.length);
  Expect.equals(4, crlf.nonConstantMultilineString.length);
  Expect.equals(4, lf.nonConstantMultilineString.length);

  Expect.equals(6, cr.nonConstantRawMultilineString.length);
  Expect.equals(6, crlf.nonConstantRawMultilineString.length);
  Expect.equals(6, lf.nonConstantRawMultilineString.length);

  Expect.equals(cr.nonConstantMultilineString, crlf.nonConstantMultilineString);
  Expect.equals(crlf.nonConstantMultilineString, lf.nonConstantMultilineString);
  Expect.equals(lf.nonConstantMultilineString, cr.nonConstantMultilineString);

  Expect.equals(
      cr.nonConstantRawMultilineString, crlf.nonConstantRawMultilineString);
  Expect.equals(
      crlf.nonConstantRawMultilineString, lf.nonConstantRawMultilineString);
  Expect.equals(
      lf.nonConstantRawMultilineString, cr.nonConstantRawMultilineString);

  const c1 =
  cr.constantMultilineString == crlf.constantMultilineString ? true : null;
  const c2 =
  crlf.constantMultilineString == lf.constantMultilineString ? true : null;
  const c3 =
  lf.constantMultilineString == cr.constantMultilineString ? true : null;
  Expect.isTrue(c1);
  Expect.isTrue(c2);
  Expect.isTrue(c3);

  const c1r = cr.constantRawMultilineString == crlf.constantRawMultilineString
      ? true
      : null;
  const c2r = crlf.constantRawMultilineString == lf.constantRawMultilineString
      ? true
      : null;
  const c3r = lf.constantRawMultilineString == cr.constantRawMultilineString
      ? true
      : null;
  Expect.isTrue(c1r);
  Expect.isTrue(c2r);
  Expect.isTrue(c3r);

  const c4 = c1 ? 1 : 2; //# 01: ok
  Expect.equals(1, c4); //# 01: continued

  const c5 = c2 ? 2 : 3; //# 02: ok
  Expect.equals(2, c5); //# 02: continued

  const c6 = c3 ? 3 : 4; //# 03: ok
  Expect.equals(3, c6); //# 03: continued

  const c4r = c1r ? 1 : 2; //# 01r: ok
  Expect.equals(1, c4r); //# 01r: continued

  const c5r = c2r ? 2 : 3; //# 02r: ok
  Expect.equals(2, c5r); //# 02r: continued

  const c6r = c3r ? 3 : 4; //# 03r: ok
  Expect.equals(3, c6r); //# 03r: continued

  const c7 =
  cr.constantMultilineString != crlf.constantMultilineString ? true : null;
  const c8 =
  crlf.constantMultilineString != lf.constantMultilineString ? true : null;
  const c9 =
  lf.constantMultilineString != cr.constantMultilineString ? true : null;
  Expect.isNull(c7);
  Expect.isNull(c8);
  Expect.isNull(c9);

  const c7r = cr.constantRawMultilineString != crlf.constantRawMultilineString
      ? true
      : null;
  const c8r = crlf.constantRawMultilineString != lf.constantRawMultilineString
      ? true
      : null;
  const c9r = lf.constantRawMultilineString != cr.constantRawMultilineString
      ? true
      : null;
  Expect.isNull(c7r);
  Expect.isNull(c8r);
  Expect.isNull(c9r);

  // What's the deal with the compile-time errors below? This is to validate
  // that constants are evaluated correctly at compile-time (or analysis
  // time). For example, only if [c7] is evaluated correctly does it become
  // null which leads to a compile-time error (as it isn't a boolean). For
  // tools like dart2js, this ensures that the compile-time evaluation of
  // constants is similar to the runtime evaluation tested above. For tools
  // like the analyzer, this ensures that evaluation is tested (there's no
  // runtime evaluation).
  const c10 = c7 ? 1 : 2; //# 04: compile-time error
  const c11 = c8 ? 2 : 3; //# 05: compile-time error
  const c12 = c9 ? 3 : 4; //# 06: compile-time error

  const c10r = c7r ? 1 : 2; //# 04r: compile-time error
  const c11r = c8r ? 2 : 3; //# 05r: compile-time error
  const c12r = c9r ? 3 : 4; //# 06r: compile-time error
}
