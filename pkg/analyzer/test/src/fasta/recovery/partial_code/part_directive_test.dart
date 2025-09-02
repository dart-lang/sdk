// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  PartDirectivesTest().buildAll();
}

class PartDirectivesTest extends PartialCodeTest {
  buildAll() {
    buildTests('part_directive', [
      TestDescriptor('keyword', 'part', [
        // TODO(danrubel): Consider an improved error message
        // ParserErrorCode.MISSING_URI,
        ParserErrorCode.expectedStringLiteral,
        ParserErrorCode.expectedToken,
      ], "part '';"),
      TestDescriptor('emptyUri', "part ''", [
        ParserErrorCode.expectedToken,
      ], "part '';"),
      TestDescriptor('uri', "part 'a.dart'", [
        ParserErrorCode.expectedToken,
      ], "part 'a.dart';"),
    ], PartialCodeTest.postPartSuffixes);
  }
}
