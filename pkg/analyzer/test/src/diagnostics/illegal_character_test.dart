// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalCharacterTest);
  });
}

@reflectiveTest
class IllegalCharacterTest extends PubPackageResolutionTest {
  test_asciiControlCharacter() async {
    await resolveTestCodeWithDiagnostics('''
\f
// [diag.illegalCharacter][column 1][length 1] Illegal character '12'.
''');
  }

  test_nonAsciiIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
piskefløde() {}
//     ^
// [diag.illegalCharacter] Illegal character '248'.
''');
  }

  test_nonAsciiWhitespace() async {
    await resolveTestCodeWithDiagnostics('''
\u00a0
// [diag.illegalCharacter][column 1][length 1] Illegal character '160'.
''');
  }
}
