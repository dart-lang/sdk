// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LoadLibraryTakesNoArgumentsTest);
  });
}

@reflectiveTest
class LoadLibraryTakesNoArgumentsTest extends DriverResolutionTest {
  test_noArguments() {
    newFile('/test/lib/foo.dart', content: '''
class C {}
''');
    assertNoErrorsInCode('''
import 'foo.dart' deferred as foo;

void f() {
  foo.loadLibrary();
}
''');
  }

  test_oneArgument() {
    newFile('/test/lib/foo.dart', content: '''
class C {}
''');
    assertErrorsInCode('''
import 'foo.dart' deferred as foo;

void f() {
  foo.loadLibrary(10);
}
''', [
      error(CompileTimeErrorCode.LOAD_LIBRARY_TAKES_NO_ARGUMENTS, 53, 11),
    ]);
  }
}
