// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MultipleCombinatorsDeprecatedExportTest);
    defineReflectiveTests(MultipleCombinatorsDeprecatedImportTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MultipleCombinatorsDeprecatedExportTest extends PubPackageResolutionTest {
  Future<void> test_hide() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
export 'dart:async' hide Future, Stream;
''');
  }

  Future<void> test_hide_hide() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
export 'dart:async' hide Future, Stream hide Stream;
//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.multipleCombinatorsDeprecated] Using multiple 'hide' or 'show' combinators is never necessary and often produces surprising results.
''');
  }

  Future<void> test_hide_show() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
export 'dart:async' hide Future, Stream show Stream;
//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.multipleCombinatorsDeprecated] Using multiple 'hide' or 'show' combinators is never necessary and often produces surprising results.
''');
  }

  Future<void> test_no_combinators() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
export 'dart:async';
''');
  }

  Future<void> test_show() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
export 'dart:async' show Future, Stream;
''');
  }

  Future<void> test_show_hide() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
export 'dart:async' show Future, Stream hide Stream;
//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.multipleCombinatorsDeprecated] Using multiple 'hide' or 'show' combinators is never necessary and often produces surprising results.
''');
  }

  Future<void> test_show_show() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
export 'dart:async' show Future, Stream show Stream;
//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.multipleCombinatorsDeprecated] Using multiple 'hide' or 'show' combinators is never necessary and often produces surprising results.
''');
  }
}

@reflectiveTest
class MultipleCombinatorsDeprecatedImportTest extends PubPackageResolutionTest {
  Future<void> test_hide() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
// ignore: unused_import
import 'dart:async' hide Future, Stream;
''');
  }

  Future<void> test_hide_hide() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
// ignore: unused_import
import 'dart:async' hide Future, Stream hide Stream;
//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.multipleCombinatorsDeprecated] Using multiple 'hide' or 'show' combinators is never necessary and often produces surprising results.
''');
  }

  Future<void> test_hide_show() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
// ignore: unused_import
import 'dart:async' hide Future, Stream show Stream;
//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.multipleCombinatorsDeprecated] Using multiple 'hide' or 'show' combinators is never necessary and often produces surprising results.
''');
  }

  Future<void> test_no_combinators() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
// ignore: unused_import
import 'dart:async';
''');
  }

  Future<void> test_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
// ignore: unused_import
import 'dart:async' as async hide Future, Stream show Stream;
//                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.multipleCombinatorsDeprecated] Using multiple 'hide' or 'show' combinators is never necessary and often produces surprising results.
''');
  }

  Future<void> test_show() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
// ignore: unused_import
import 'dart:async' show Future, Stream;
''');
  }

  Future<void> test_show_hide() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
// ignore: unused_import
import 'dart:async' show Future, Stream hide Stream;
//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.multipleCombinatorsDeprecated] Using multiple 'hide' or 'show' combinators is never necessary and often produces surprising results.
''');
  }

  Future<void> test_show_show() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: single-combinators
// ignore: unused_import
import 'dart:async' show Future, Stream show Stream;
//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.multipleCombinatorsDeprecated] Using multiple 'hide' or 'show' combinators is never necessary and often produces surprising results.
''');
  }
}
