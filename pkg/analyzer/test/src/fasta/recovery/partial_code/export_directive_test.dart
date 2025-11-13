// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

import 'partial_code_support.dart';

main() {
  ExportDirectivesTest().buildAll();
}

class ExportDirectivesTest extends PartialCodeTest {
  buildAll() {
    buildTests('export_directive', [
      TestDescriptor('keyword', 'export', [
        // TODO(danrubel): Consider an improved error message
        // ParserErrorCode.MISSING_URI,
        diag.expectedStringLiteral,
        diag.expectedToken,
      ], "export '';"),
      TestDescriptor('emptyUri', "export ''", [
        diag.expectedToken,
      ], "export '';"),
      TestDescriptor('uri', "export 'a.dart'", [
        diag.expectedToken,
      ], "export 'a.dart';"),
      TestDescriptor(
        'hide',
        "export 'a.dart' hide",
        [diag.missingIdentifier, diag.expectedToken],
        "export 'a.dart' hide _s_;",
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor('hideName', "export 'a.dart' hide A", [
        diag.expectedToken,
      ], "export 'a.dart' hide A;"),
      TestDescriptor(
        'hideComma',
        "export 'a.dart' hide A,",
        [diag.missingIdentifier, diag.expectedToken],
        "export 'a.dart' hide A, _s_;",
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor('hideCommaName', "export 'a.dart' hide A, B", [
        diag.expectedToken,
      ], "export 'a.dart' hide A, B;"),
      TestDescriptor(
        'hideShow',
        "export 'a.dart' hide A show",
        [diag.missingIdentifier, diag.expectedToken],
        "export 'a.dart' hide A show _s_;",
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor(
        'show',
        "export 'a.dart' show",
        [diag.missingIdentifier, diag.expectedToken],
        "export 'a.dart' show _s_;",
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor('showName', "export 'a.dart' show A", [
        diag.expectedToken,
      ], "export 'a.dart' show A;"),
      TestDescriptor(
        'showComma',
        "export 'a.dart' show A,",
        [diag.missingIdentifier, diag.expectedToken],
        "export 'a.dart' show A, _s_;",
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor('showCommaName', "export 'a.dart' show A, B", [
        diag.expectedToken,
      ], "export 'a.dart' show A, B;"),
      TestDescriptor(
        'showHide',
        "export 'a.dart' show A hide",
        [diag.missingIdentifier, diag.expectedToken],
        "export 'a.dart' show A hide _s_;",
        failing: ['functionNonVoid', 'getter'],
      ),
    ], PartialCodeTest.prePartSuffixes);
  }
}
