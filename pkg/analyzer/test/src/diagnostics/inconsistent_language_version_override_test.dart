// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:meta/meta.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentLanguageVersionOverrideTest);
  });
}

@reflectiveTest
class InconsistentLanguageVersionOverrideTest extends DriverResolutionTest {
  CompileTimeErrorCode get _errorCode =>
      CompileTimeErrorCode.INCONSISTENT_LANGUAGE_VERSION_OVERRIDE;

  test_both_different() async {
    await _checkLibraryAndPart(
      libraryContent: r'''
// @dart = 2.5
part 'b.dart';
''',
      partContent: r'''
// @dart = 2.6
part of 'a.dart';
''',
      partErrors: [
        error(_errorCode, 0, 14),
      ],
    );
  }

  test_both_same() async {
    await _checkLibraryAndPart(
      libraryContent: r'''
// @dart = 2.5
part 'b.dart';
''',
      partContent: r'''
// @dart = 2.5
part of 'a.dart';
''',
      partErrors: [],
    );
  }

  test_none() async {
    await _checkLibraryAndPart(
      libraryContent: r'''
part 'b.dart';
''',
      partContent: r'''
part of 'a.dart';
''',
      partErrors: [],
    );
  }

  test_onlyLibrary() async {
    await _checkLibraryAndPart(
      libraryContent: r'''
// @dart = 2.5
part 'b.dart';
''',
      partContent: r'''
part of 'a.dart';
''',
      partErrors: [
        error(_errorCode, 0, 7),
      ],
    );
  }

  test_onlyPart() async {
    await _checkLibraryAndPart(
      libraryContent: r'''
part 'b.dart';
''',
      partContent: r'''
// @dart = 2.5
part of 'a.dart';
''',
      partErrors: [
        error(_errorCode, 0, 14),
      ],
    );
  }

  Future<void> _checkLibraryAndPart({
    @required String libraryContent,
    @required String partContent,
    @required List<ExpectedError> partErrors,
  }) async {
    var libraryPath = convertPath('/test/lib/a.dart');
    var partPath = convertPath('/test/lib/b.dart');

    newFile(libraryPath, content: libraryContent);

    newFile(partPath, content: partContent);

    await resolveFile(libraryPath);

    await assertErrorsInFile2(partPath, partErrors);
  }
}
