// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

import 'partial_code_support.dart';

main() {
  LibraryDirectivesTest().buildAll();
}

class LibraryDirectivesTest extends PartialCodeTest {
  buildAll() {
    buildTests('library_directive', [
      TestDescriptor(
        'keyword',
        'library',
        [diag.missingIdentifier, diag.expectedToken],
        'library _s_;',
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor('name', 'library lib', [
        diag.expectedToken,
      ], 'library lib;'),
      TestDescriptor(
        'nameDot',
        'library lib.',
        [diag.missingIdentifier, diag.expectedToken],
        'library lib._s_;',
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor('nameDotName', 'library lib.a', [
        diag.expectedToken,
      ], 'library lib.a;'),
    ], PartialCodeTest.prePartSuffixes);
  }
}
