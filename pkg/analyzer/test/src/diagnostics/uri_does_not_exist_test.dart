// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriDoesNotExistTest);
  });
}

@reflectiveTest
class UriDoesNotExistTest extends DriverResolutionTest {
  test_deferredImportWithInvalidUri() async {
    await assertErrorsInCode(r'''
import '[invalid uri]' deferred as p;
main() {
  p.loadLibrary();
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 15),
    ]);
  }

  test_export() async {
    await assertErrorsInCode('''
export 'unknown.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
  }

  test_import() async {
    await assertErrorsInCode('''
import 'unknown.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
  }

  test_import_appears_after_deleting_target() async {
    String filePath = newFile('/test/lib/target.dart').path;

    await assertErrorsInCode('''
import 'target.dart';
''', [
      error(HintCode.UNUSED_IMPORT, 7, 13),
    ]);

    // Remove the overlay in the same way as AnalysisServer.
    deleteFile(filePath);
    driver.removeFile(filePath);

    await resolveTestFile();
    GatheringErrorListener errorListener = GatheringErrorListener();
    errorListener.addAll(result.errors);
    errorListener.assertErrors([
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 13),
    ]);
  }

  @failingTest
  test_import_disappears_when_fixed() async {
    await assertErrorsInCode('''
import 'target.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 13),
    ]);

    newFile('/test/lib/target.dart');

    // Make sure the error goes away.
    // TODO(brianwilkerson) The error does not go away, possibly because the
    //  file is not being reanalyzed.
    await resolveTestFile();
    GatheringErrorListener errorListener = GatheringErrorListener();
    errorListener.addAll(result.errors);
    errorListener.assertErrors([
      error(HintCode.UNUSED_IMPORT, 0, 0),
    ]);
  }

  test_part() async {
    await assertErrorsInCode(r'''
library lib;
part 'unknown.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 18, 14),
    ]);
  }

  test_valid_dll() async {
    newFile("/test/lib/lib.dll");
    await assertNoErrorsInCode('''
import 'dart-ext:lib';
''');
  }

  test_valid_dylib() async {
    newFile("/test/lib/lib.dylib");
    await assertNoErrorsInCode('''
import 'dart-ext:lib';
''');
  }

  test_valid_so() async {
    newFile("/test/lib/lib.so");
    await assertNoErrorsInCode('''
import 'dart-ext:lib';
''');
  }
}
