// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'package:compiler/implementation/util/util.dart' show Indentation;

main() {
  Indentation ind = new Indentation();

  Expect.stringEquals("", ind.indentation);

  ind.indentMore();
  Expect.stringEquals(ind.indentationUnit, ind.indentation);

  ind.indentMore();
  Expect.stringEquals(ind.indentationUnit * 2, ind.indentation);

  ind.indentBlock(
      () => Expect.stringEquals(ind.indentationUnit * 3, ind.indentation));
  Expect.stringEquals(ind.indentationUnit * 2, ind.indentation);

  ind.indentationUnit = "x";
  Expect.stringEquals("xx", ind.indentation);

  ind.indentLess();
  Expect.stringEquals("x", ind.indentation);

  ind.indentLess();
  Expect.stringEquals("", ind.indentation);

  ind.indentMore();
  Expect.stringEquals("x", ind.indentation);
}