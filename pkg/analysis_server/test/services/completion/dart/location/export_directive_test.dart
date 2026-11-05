// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExportDirectiveTest);
  });
}

@reflectiveTest
class ExportDirectiveTest extends AbstractCompletionDriverTest {
  Future<void> test_afterHide_beforeSemicolon() async {
    await computeSuggestions('''
export "foo" hide a ^;
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterShow_beforeSemicolon() async {
    await computeSuggestions('''
export "foo" show a ^;
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterUri_beforeEnd() async {
    await computeSuggestions('''
export "foo" ^
''');
    assertResponse(r'''
suggestions
  hide
    kind: keyword
  show
    kind: keyword
''');
  }

  Future<void> test_afterUri_beforeEnd_partial() async {
    await computeSuggestions('''
export "foo" s^
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  show
    kind: keyword
''');
  }

  Future<void> test_afterUri_beforeHide() async {
    await computeSuggestions('''
export "foo" ^ hide foo;
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterUri_beforeSemicolon() async {
    await computeSuggestions('''
export "foo" ^;
''');
    assertResponse(r'''
suggestions
  hide
    kind: keyword
  show
    kind: keyword
''');
  }

  Future<void> test_afterUri_beforeSemicolon_partial() async {
    await computeSuggestions('''
export "foo" h^;
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  hide
    kind: keyword
  show
    kind: keyword
''');
  }

  Future<void> test_afterUri_beforeShow() async {
    await computeSuggestions('''
export "foo" ^ show foo;
''');
    assertResponse(r'''
suggestions
''');
  }
}
