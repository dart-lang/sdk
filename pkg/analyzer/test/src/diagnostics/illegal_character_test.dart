// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      '''
\f
''',
      [
        error(diag.illegalCharacter, 0, 1, messageContains: ["character '12'"]),
      ],
    );
  }

  test_nonAsciiIdentifier() async {
    await assertErrorsInCode(
      r'''
piskefløde() {}
''',
      [
        error(
          diag.illegalCharacter,
          7,
          1,
          messageContains: ["character '248'"],
        ),
      ],
    );
  }

  test_nonAsciiWhitespace() async {
    await assertErrorsInCode(
      '''
\u00a0
''',
      [
        error(
          diag.illegalCharacter,
          0,
          1,
          messageContains: ["character '160'"],
        ),
      ],
    );
  }
}
