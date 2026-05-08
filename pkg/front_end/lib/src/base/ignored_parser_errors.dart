// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show TokenIsAExtension, Keyword, Token;
import 'package:front_end/src/codes/diagnostic.dart' as diag;

import '../codes/cfe_codes.dart' show Code;

bool isIgnoredParserError(Code code, Token token) {
  if (code == diag.nonPartOfDirectiveInPart) {
    // Ignored. This error is handled in the outline phase (part resolution).
    return token.isA(Keyword.PART);
  } else {
    return false;
  }
}
