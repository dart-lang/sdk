// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartdocDirectiveInfoTest);
  });
}

@reflectiveTest
class DartdocDirectiveInfoTest {
  DartdocDirectiveInfo info = new DartdocDirectiveInfo();

  test_processDartdoc_macro_defined() {
    info.extractTemplate('''
/**
 * {@template foo}
 * Body of the
 * template.
 * {@endtemplate}
 */''');
    String result = info.processDartdoc('''
/**
 * Before macro.
 * {@macro foo}
 * After macro.
 */''');
    expect(result, '''
Before macro.
Body of the
template.
After macro.''');
  }

  test_processDartdoc_macro_undefined() {
    String result = info.processDartdoc('''
/**
 * {@macro foo}
 */''');
    expect(result, '''
{@macro foo}''');
  }

  test_processDartdoc_multiple() {
    info.extractTemplate('''
/**
 * {@template foo}
 * First template.
 * {@endtemplate}
 */''');
    info.extractTemplate('''
/// {@template bar}
/// Second template.
/// {@endtemplate}''');
    String result = info.processDartdoc('''
/**
 * Before macro.
 * {@macro foo}
 * Between macros.
 * {@macro bar}
 * After macro.
 */''');
    expect(result, '''
Before macro.
First template.
Between macros.
Second template.
After macro.''');
  }

  test_processDartdoc_noMacro() {
    String result = info.processDartdoc('''
/**
 * Comment without a macro.
 */''');
    expect(result, '''
Comment without a macro.''');
  }
}
