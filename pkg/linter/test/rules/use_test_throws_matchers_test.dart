// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseTestThrowsMatchersTest);
  });
}

@reflectiveTest
class UseTestThrowsMatchersTest extends LintRuleTest {
  @override
  String get lintRule => 'use_test_throws_matchers';

  @override
  void setUp() {
    super.setUp();
    var testApiPath = '$workspaceRootPath/test_api';
    var packageConfigBuilder = PackageConfigFileBuilder();
    packageConfigBuilder.add(
      name: 'test_api',
      rootPath: testApiPath,
    );
    writeTestPackageConfig(packageConfigBuilder);
    newFile('$testApiPath/lib/src/frontend/expect.dart', r'''
void expect(dynamic actual, dynamic matcher) {}

Never fail(String message) {}
''');
    newFile('$testApiPath/lib/test_api.dart', r'''
export 'src/frontend/expect.dart';
''');
  }

  test_failInTry() async {
    await assertDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  try {
    f();
    fail('fail');
  } catch (e) {}
}
''', [
      lint(74, 13),
    ]);
  }

  test_failWithExpectInCatch() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  try {
    f();
    fail('fail');
  } catch (e) {
    expect(e, null);
  } finally {
    print('hello');
  }
}
''');
  }

  test_failWithExpectInOnCatch() async {
    await assertNoDiagnostics(r'''
import 'package:test_api/test_api.dart';

void f() {
  try {
    f();
    fail('fail');
  } on Exception catch (e) {
    expect(e, null);
  } catch (e) {
    expect(e, null);
  }
}
''');
  }

  test_noFail() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    f();
  } catch (e) {}
}
''');
  }
}
