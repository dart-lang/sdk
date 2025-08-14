// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MultipleCombinatorsExportTest);
    defineReflectiveTests(MultipleCombinatorsImportTest);
  });
}

@reflectiveTest
class MultipleCombinatorsExportTest extends PubPackageResolutionTest {
  Future<void> test_hide() async {
    await assertNoErrorsInCode(r'''
export 'dart:async' hide Future, Stream;
''');
  }

  Future<void> test_hide_hide() async {
    await assertErrorsInCode(
      r'''
export 'dart:async' hide Future, Stream hide Stream;
''',
      [error(WarningCode.multipleCombinators, 20, 31)],
    );
  }

  Future<void> test_hide_show() async {
    await assertErrorsInCode(
      r'''
export 'dart:async' hide Future, Stream show Stream;
''',
      [error(WarningCode.multipleCombinators, 20, 31)],
    );
  }

  Future<void> test_no_combinators() async {
    await assertNoErrorsInCode(r'''
export 'dart:async';
''');
  }

  Future<void> test_show() async {
    await assertNoErrorsInCode(r'''
export 'dart:async' show Future, Stream;
''');
  }

  Future<void> test_show_hide() async {
    await assertErrorsInCode(
      r'''
export 'dart:async' show Future, Stream hide Stream;
''',
      [error(WarningCode.multipleCombinators, 20, 31)],
    );
  }

  Future<void> test_show_show() async {
    await assertErrorsInCode(
      r'''
export 'dart:async' show Future, Stream show Stream;
''',
      [error(WarningCode.multipleCombinators, 20, 31)],
    );
  }
}

@reflectiveTest
class MultipleCombinatorsImportTest extends PubPackageResolutionTest {
  Future<void> test_hide() async {
    await assertNoErrorsInCode(r'''
//ignore: unused_import
import 'dart:async' hide Future, Stream;
''');
  }

  Future<void> test_hide_hide() async {
    await assertErrorsInCode(
      r'''
//ignore: unused_import
import 'dart:async' hide Future, Stream hide Stream;
''',
      [error(WarningCode.multipleCombinators, 44, 31)],
    );
  }

  Future<void> test_hide_show() async {
    await assertErrorsInCode(
      r'''
//ignore: unused_import
import 'dart:async' hide Future, Stream show Stream;
''',
      [error(WarningCode.multipleCombinators, 44, 31)],
    );
  }

  Future<void> test_no_combinators() async {
    await assertNoErrorsInCode(r'''
//ignore: unused_import
import 'dart:async';
''');
  }

  Future<void> test_prefixed() async {
    await assertErrorsInCode(
      r'''
//ignore: unused_import
import 'dart:async' as async hide Future, Stream show Stream;
''',
      [error(WarningCode.multipleCombinators, 53, 31)],
    );
  }

  Future<void> test_show() async {
    await assertNoErrorsInCode(r'''
//ignore: unused_import
import 'dart:async' show Future, Stream;
''');
  }

  Future<void> test_show_hide() async {
    await assertErrorsInCode(
      r'''
//ignore: unused_import
import 'dart:async' show Future, Stream hide Stream;
''',
      [error(WarningCode.multipleCombinators, 44, 31)],
    );
  }

  Future<void> test_show_show() async {
    await assertErrorsInCode(
      r'''
//ignore: unused_import
import 'dart:async' show Future, Stream show Stream;
''',
      [error(WarningCode.multipleCombinators, 44, 31)],
    );
  }
}
