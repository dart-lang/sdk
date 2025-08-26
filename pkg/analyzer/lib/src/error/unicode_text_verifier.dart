// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';

/// A verifier that checks for unsafe Unicode text.
/// See: https://nvd.nist.gov/vuln/detail/CVE-2021-22567
class UnicodeTextVerifier {
  final DiagnosticReporter _diagnosticReporter;
  UnicodeTextVerifier(this._diagnosticReporter);

  void verify(CompilationUnit unit, String source) {
    for (var offset = 0; offset < source.length; ++offset) {
      var codeUnit = source.codeUnitAt(offset);
      // U+202A, U+202B, U+202C, U+202D, U+202E, U+2066, U+2067, U+2068, U+2069.
      if (0x202a <= codeUnit &&
          codeUnit <= 0x2069 &&
          (codeUnit <= 0x202e || 0x2066 <= codeUnit)) {
        var node = unit.nodeCovering(offset: offset);
        // If it's not in a string literal, we assume we're in a comment.
        // This can potentially over-report on syntactically incorrect sources
        // (where Unicode is outside a string or comment).
        var errorCode =
            node is SimpleStringLiteral || node is InterpolationString
            ? WarningCode.textDirectionCodePointInLiteral
            : WarningCode.textDirectionCodePointInComment;
        var code = codeUnit.toRadixString(16).toUpperCase();
        _diagnosticReporter.atOffset(
          offset: offset,
          length: 1,
          diagnosticCode: errorCode,
          arguments: [code],
        );
      }
    }
  }
}
