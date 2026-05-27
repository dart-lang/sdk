// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentLanguageVersionOverrideTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InconsistentLanguageVersionOverrideTest extends PubPackageResolutionTest {
  test_0_00_000_AAA() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.10
part 'b.dart';
''',
      b: r'''
// @dart = 3.10
part of 'a.dart';
part 'c.dart';
''',
      c: r'''
// @dart = 3.10
part of 'b.dart';
''',
    });
  }

  test_0_00_000_AAB() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.10
part 'b.dart';
''',
      b: r'''
// @dart = 3.10
part of 'a.dart';
part 'c.dart';
//   ^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      c: r'''
// @dart = 3.11
part of 'b.dart';
''',
    });
  }

  test_0_00_000_AAN() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.10
part 'b.dart';
''',
      b: r'''
// @dart = 3.10
part of 'a.dart';
part 'c.dart';
//   ^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      c: r'''
part of 'b.dart';
''',
    });
  }

  test_0_00_000_ABB() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.10
part 'b.dart';
//   ^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      b: r'''
// @dart = 3.11
part of 'a.dart';
part 'c.dart';
''',
      c: r'''
// @dart = 3.11
part of 'b.dart';
''',
    });
  }

  test_0_00_000_NAA() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
//   ^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      b: r'''
// @dart = 3.10
part of 'a.dart';
part 'c.dart';
''',
      c: r'''
// @dart = 3.10
part of 'b.dart';
''',
    });
  }

  test_0_00_AA() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.2
part 'b.dart';
''',
      b: r'''
// @dart = 3.2
part of 'a.dart';
''',
    });
  }

  test_0_00_AB() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
// @dart = 3.1
part 'b.dart';
//   ^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      b: r'''
// @dart = 3.2
part of 'a.dart';
''',
    });
  }

  test_0_00_NA() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
//   ^^^^^^^^
// [diag.inconsistentLanguageVersionOverride] Parts must have exactly the same language version override as the library.
''',
      b: r'''
// @dart = 3.1
part of 'a.dart';
''',
    });
  }

  test_0_00_NN() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
''',
    });
  }
}
