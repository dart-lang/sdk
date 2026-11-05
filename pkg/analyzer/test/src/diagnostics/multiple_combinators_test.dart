// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MultipleCombinatorsExportTest);
    defineReflectiveTests(MultipleCombinatorsImportTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MultipleCombinatorsExportTest extends PubPackageResolutionTest {
  Future<void> test_hide() async {
    await resolveTestCodeWithDiagnostics(r'''
export 'dart:async' hide Future, Stream;
''');
  }

  Future<void> test_hide_hide() async {
    await resolveTestCodeWithDiagnostics(r'''
export 'dart:async' hide Future, Stream hide Stream;
//                                      ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
  }

  Future<void> test_hide_show() async {
    await resolveTestCodeWithDiagnostics(r'''
export 'dart:async' hide Future, Stream show Stream;
//                                      ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
  }

  Future<void> test_no_combinators() async {
    await resolveTestCodeWithDiagnostics(r'''
export 'dart:async';
''');
  }

  Future<void> test_show() async {
    await resolveTestCodeWithDiagnostics(r'''
export 'dart:async' show Future, Stream;
''');
  }

  Future<void> test_show_hide() async {
    await resolveTestCodeWithDiagnostics(r'''
export 'dart:async' show Future, Stream hide Stream;
//                                      ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
  }

  Future<void> test_show_hide_show() async {
    await resolveTestCodeWithDiagnostics(r'''
export 'dart:async' show Future hide Stream show Stream;
//                              ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
//                                          ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
  }

  Future<void> test_show_show() async {
    await resolveTestCodeWithDiagnostics(r'''
export 'dart:async' show Future, Stream show Stream;
//                                      ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
  }
}

@reflectiveTest
class MultipleCombinatorsImportTest extends PubPackageResolutionTest {
  Future<void> test_hide() async {
    await resolveTestCodeWithDiagnostics(r'''
//ignore: unused_import
import 'dart:async' hide Future, Stream;
''');
  }

  Future<void> test_hide_hide() async {
    await resolveTestCodeWithDiagnostics(r'''
//ignore: unused_import
import 'dart:async' hide Future, Stream hide Stream;
//                                      ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
  }

  Future<void> test_hide_show() async {
    await resolveTestCodeWithDiagnostics(r'''
//ignore: unused_import
import 'dart:async' hide Future, Stream show Stream;
//                                      ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
  }

  Future<void> test_no_combinators() async {
    await resolveTestCodeWithDiagnostics(r'''
//ignore: unused_import
import 'dart:async';
''');
  }

  Future<void> test_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
//ignore: unused_import
import 'dart:async' as async hide Future, Stream show Stream;
//                                               ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
  }

  Future<void> test_show() async {
    await resolveTestCodeWithDiagnostics(r'''
//ignore: unused_import
import 'dart:async' show Future, Stream;
''');
  }

  Future<void> test_show_hide() async {
    await resolveTestCodeWithDiagnostics(r'''
//ignore: unused_import
import 'dart:async' show Future, Stream hide Stream;
//                                      ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
  }

  Future<void> test_show_hide_show() async {
    await resolveTestCodeWithDiagnostics(r'''
//ignore: unused_import
import 'dart:async' show Future hide Stream show Stream;
//                              ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
//                                          ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
  }

  Future<void> test_show_show() async {
    await resolveTestCodeWithDiagnostics(r'''
//ignore: unused_import
import 'dart:async' show Future, Stream show Stream;
//                                      ^^^^
// [diag.multipleCombinators] At most one 'show' or 'hide' combinator can be used on an import or export directive.
''');
  }
}
