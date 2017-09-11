// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: These test relies on specific line endings in the source files.
// They requirs entries in the .gitattributes file.

import "dart:mirrors";
import "package:expect/expect.dart";

import "method_mirror_source_line_ending_lf.dart";
import "method_mirror_source_line_ending_cr.dart";
import "method_mirror_source_line_ending_crlf.dart";

main() {
  String sourceOf(Function f) => (reflect(f) as ClosureMirror).function.source;

  // Source does not cross line breaks.
  Expect.stringEquals('oneLineLF(x) => x;', sourceOf(oneLineLF));
  Expect.stringEquals('oneLineCR(x) => x;', sourceOf(oneLineCR));
  Expect.stringEquals('oneLineCRLF(x) => x;', sourceOf(oneLineCRLF));

  // Source includes line breaks.
  Expect.stringEquals(
      'multiLineLF(y) {\n  return y + 1;\n}', sourceOf(multiLineLF));
  Expect.stringEquals(
      'multiLineCR(y) {\r  return y + 1;\r}', sourceOf(multiLineCR));
  Expect.stringEquals(
      'multiLineCRLF(y) {\r\n  return y + 1;\r\n}', sourceOf(multiLineCRLF));

  // First and last characters separated from middle by line breaks.
  Expect.stringEquals('a\n(){\n}', sourceOf(a));
  Expect.stringEquals('b\r(){\r}', sourceOf(b));
  Expect.stringEquals('c\r\n(){\r\n}', sourceOf(c));
}
