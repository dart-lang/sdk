// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.ignored_parser_errors;

import 'package:_fe_analyzer_shared/src/parser/parser.dart' show optional;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;

import 'fasta_codes.dart' show Code, codeNonPartOfDirectiveInPart;

bool isIgnoredParserError(Code<Object> code, Token token) {
  if (code == codeNonPartOfDirectiveInPart) {
    // Ignored. This error is handled in the outline phase (part resolution).
    return optional("part", token);
  } else {
    return false;
  }
}
