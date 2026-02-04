// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

import 'partial_code_support.dart';

main() {
  TypedefTest().buildAll();
}

class TypedefTest extends PartialCodeTest {
  buildAll() {
    buildTests('typedef', [
      TestDescriptor(
        'keyword',
        'typedef',
        [
          diag.missingIdentifier,
          diag.missingTypedefParameters,
          diag.expectedToken,
        ],
        "typedef _s_();",
        failing: ['functionVoid', 'functionNonVoid', 'getter'],
      ),
      TestDescriptor(
        'name',
        'typedef T',
        [diag.missingTypedefParameters, diag.expectedToken],
        "typedef T();",
        failing: ['functionNonVoid', 'getter', 'mixin', 'setter'],
      ),
      TestDescriptor(
        'keywordEquals',
        'typedef =',
        [diag.missingIdentifier, diag.expectedTypeName, diag.expectedToken],
        "typedef _s_ = _s_;",
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor(
        'equals',
        'typedef T =',
        [diag.expectedTypeName, diag.expectedToken],
        "typedef T = _s_;",
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
    ], PartialCodeTest.declarationSuffixes);
  }
}
