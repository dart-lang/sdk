// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/dart/micro/cider_byte_store.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dart/micro/utils.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'file_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileResolver_changeFile_Test);
    defineReflectiveTests(FileResolverTest);
  });
}

@reflectiveTest
class FileResolver_changeFile_Test extends FileResolutionTest {
  test_changeFile_refreshedFiles() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
class B {}
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
import 'a.dart';
import 'b.dart';
''');

    // First time we refresh everything.
    await resolveFile(c.path);

    const state_1 = r'''
files
  /sdk/lib/_internal/internal.dart
    current
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /sdk/lib/async/async.dart
    current
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /sdk/lib/async/stream.dart
    current
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
  /sdk/lib/core/core.dart
    current
      unlinkedKey: k03
    unlinkedGet: []
    unlinkedPut: [k03]
  /sdk/lib/math/math.dart
    current
      unlinkedKey: k04
    unlinkedGet: []
    unlinkedPut: [k04]
  /workspace/dart/test/lib/a.dart
    current
      unlinkedKey: k05
    unlinkedGet: []
    unlinkedPut: [k05]
  /workspace/dart/test/lib/b.dart
    current
      unlinkedKey: k06
    unlinkedGet: []
    unlinkedPut: [k06]
  /workspace/dart/test/lib/c.dart
    current
      unlinkedKey: k07
    unlinkedGet: []
    unlinkedPut: [k07]
libraryCycles
  /sdk/lib/_internal/internal.dart /sdk/lib/async/async.dart /sdk/lib/core/core.dart /sdk/lib/math/math.dart
    get: []
    put: [k08]
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k09]
  /workspace/dart/test/lib/b.dart
    get: []
    put: [k10]
  /workspace/dart/test/lib/c.dart
    get: []
    put: [k11]
elementFactory
  hasElement
    dart:_internal
    dart:async
    dart:core
    dart:math
    package:dart.test/a.dart
    package:dart.test/b.dart
    package:dart.test/c.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09, k10, k11]
''';
    assertStateString(state_1);

    // Without changes we refresh nothing.
    await resolveFile(c.path);
    assertStateString(state_1);

    // We already know a.dart, refresh nothing.
    await resolveFile(a.path);
    assertStateString(state_1);

    // Change a.dart, discard data for a.dart and c.dart, but not b.dart
    fileResolver.changeFile(a.path);
    fileResolver.releaseAndClearRemovedIds();
    assertStateString(r'''
files
  /sdk/lib/_internal/internal.dart
    current
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /sdk/lib/async/async.dart
    current
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /sdk/lib/async/stream.dart
    current
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
  /sdk/lib/core/core.dart
    current
      unlinkedKey: k03
    unlinkedGet: []
    unlinkedPut: [k03]
  /sdk/lib/math/math.dart
    current
      unlinkedKey: k04
    unlinkedGet: []
    unlinkedPut: [k04]
  /workspace/dart/test/lib/a.dart
    unlinkedGet: []
    unlinkedPut: [k05]
  /workspace/dart/test/lib/b.dart
    current
      unlinkedKey: k06
    unlinkedGet: []
    unlinkedPut: [k06]
  /workspace/dart/test/lib/c.dart
    unlinkedGet: []
    unlinkedPut: [k07]
libraryCycles
  /sdk/lib/_internal/internal.dart /sdk/lib/async/async.dart /sdk/lib/core/core.dart /sdk/lib/math/math.dart
    get: []
    put: [k08]
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k09]
  /workspace/dart/test/lib/b.dart
    get: []
    put: [k10]
  /workspace/dart/test/lib/c.dart
    get: []
    put: [k11]
elementFactory
  hasElement
    dart:_internal
    dart:async
    dart:core
    dart:math
    package:dart.test/b.dart
byteStore
  1: [k00, k01, k02, k03, k04, k06, k08, k10]
''');

    // Resolve, read again a.dart and c.dart
    await resolveFile(c.path);
    assertStateString(r'''
files
  /sdk/lib/_internal/internal.dart
    current
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /sdk/lib/async/async.dart
    current
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /sdk/lib/async/stream.dart
    current
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
  /sdk/lib/core/core.dart
    current
      unlinkedKey: k03
    unlinkedGet: []
    unlinkedPut: [k03]
  /sdk/lib/math/math.dart
    current
      unlinkedKey: k04
    unlinkedGet: []
    unlinkedPut: [k04]
  /workspace/dart/test/lib/a.dart
    current
      unlinkedKey: k05
    unlinkedGet: []
    unlinkedPut: [k05, k05]
  /workspace/dart/test/lib/b.dart
    current
      unlinkedKey: k06
    unlinkedGet: []
    unlinkedPut: [k06]
  /workspace/dart/test/lib/c.dart
    current
      unlinkedKey: k07
    unlinkedGet: []
    unlinkedPut: [k07, k07]
libraryCycles
  /sdk/lib/_internal/internal.dart /sdk/lib/async/async.dart /sdk/lib/core/core.dart /sdk/lib/math/math.dart
    get: []
    put: [k08]
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k09, k09]
  /workspace/dart/test/lib/b.dart
    get: []
    put: [k10]
  /workspace/dart/test/lib/c.dart
    get: []
    put: [k11, k11]
elementFactory
  hasElement
    dart:_internal
    dart:async
    dart:core
    dart:math
    package:dart.test/a.dart
    package:dart.test/b.dart
    package:dart.test/c.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09, k10, k11]
''');
  }

  test_changeFile_resolution() async {
    final a = newFile('/workspace/dart/test/lib/a.dart', r'''
class A {}
''');

    final b = newFile('/workspace/dart/test/lib/b.dart', r'''
import 'a.dart';
void f(A a, B b) {}
''');

    result = await resolveFile(b.path);
    assertErrorsInResolvedUnit(result, [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 29, 1),
    ]);

    newFile(a.path, r'''
class A {}
class B {}
''');
    fileResolver.changeFile(a.path);

    result = await resolveFile(b.path);
    assertErrorsInResolvedUnit(result, []);
  }

  test_changeFile_resolution_flushInheritanceManager() async {
    final a = newFile('/workspace/dart/test/lib/a.dart', r'''
class A {
  final int foo = 0;
}
''');

    final b = newFile('/workspace/dart/test/lib/b.dart', r'''
import 'a.dart';

void f(A a) {
  a.foo = 1;
}
''');

    result = await resolveFile(b.path);
    assertErrorsInResolvedUnit(result, [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 36, 3),
    ]);

    newFile(a.path, r'''
class A {
  int foo = 0;
}
''');
    fileResolver.changeFile(a.path);

    result = await resolveFile(b.path);
    assertErrorsInResolvedUnit(result, []);
  }

  test_changeFile_resolution_missingChangeFileForPart() async {
    final a = newFile('/workspace/dart/test/lib/a.dart', r'''
part 'b.dart';

var b = B(0);
''');

    result = await resolveFile(a.path);
    assertErrorsInResolvedUnit(result, [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 8),
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 24, 1),
    ]);

    // Update a.dart, and notify the resolver. We need this to have at least
    // one change, so that we decided to rebuild the library summary.
    newFile(a.path, r'''
part 'b.dart';

var b = B(1);
''');
    fileResolver.changeFile(a.path);

    // Update b.dart, but do not notify the resolver.
    // If we try to read it now, it will throw.
    final b = newFile('/workspace/dart/test/lib/b.dart', r'''
part of 'a.dart';

class B {
  B(int _);
}
''');

    expect(() async {
      await resolveFile(a.path);
    }, throwsStateError);

    // Notify the resolver about b.dart, it is OK now.
    fileResolver.changeFile(b.path);
    result = await resolveFile(a.path);
    assertErrorsInResolvedUnit(result, []);
  }

  test_changePartFile_refreshedFiles() async {
    newFile('/workspace/dart/test/lib/a.dart', r'''
part 'b.dart';

class A {}
''');

    final b = newFile('/workspace/dart/test/lib/b.dart', r'''
part of 'a.dart';

class B extends A {}
''');

    // First time we refresh everything.
    await resolveFile(b.path);
    assertStateString(r'''
files
  /sdk/lib/_internal/internal.dart
    current
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /sdk/lib/async/async.dart
    current
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /sdk/lib/async/stream.dart
    current
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
  /sdk/lib/core/core.dart
    current
      unlinkedKey: k03
    unlinkedGet: []
    unlinkedPut: [k03]
  /sdk/lib/math/math.dart
    current
      unlinkedKey: k04
    unlinkedGet: []
    unlinkedPut: [k04]
  /workspace/dart/test/lib/a.dart
    current
      unlinkedKey: k05
    unlinkedGet: []
    unlinkedPut: [k05]
  /workspace/dart/test/lib/b.dart
    current
      unlinkedKey: k06
    unlinkedGet: []
    unlinkedPut: [k06]
libraryCycles
  /sdk/lib/_internal/internal.dart /sdk/lib/async/async.dart /sdk/lib/core/core.dart /sdk/lib/math/math.dart
    get: []
    put: [k07]
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k08]
elementFactory
  hasElement
    dart:_internal
    dart:async
    dart:core
    dart:math
    package:dart.test/a.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08]
''');

    // Change b.dart, discard both b.dart and a.dart
    fileResolver.changeFile(b.path);
    fileResolver.releaseAndClearRemovedIds();
    assertStateString(r'''
files
  /sdk/lib/_internal/internal.dart
    current
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /sdk/lib/async/async.dart
    current
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /sdk/lib/async/stream.dart
    current
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
  /sdk/lib/core/core.dart
    current
      unlinkedKey: k03
    unlinkedGet: []
    unlinkedPut: [k03]
  /sdk/lib/math/math.dart
    current
      unlinkedKey: k04
    unlinkedGet: []
    unlinkedPut: [k04]
  /workspace/dart/test/lib/a.dart
    unlinkedGet: []
    unlinkedPut: [k05]
  /workspace/dart/test/lib/b.dart
    unlinkedGet: []
    unlinkedPut: [k06]
libraryCycles
  /sdk/lib/_internal/internal.dart /sdk/lib/async/async.dart /sdk/lib/core/core.dart /sdk/lib/math/math.dart
    get: []
    put: [k07]
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k08]
elementFactory
  hasElement
    dart:_internal
    dart:async
    dart:core
    dart:math
byteStore
  1: [k00, k01, k02, k03, k04, k07]
''');

    // Resolve, read a.dart and b.dart
    await resolveFile(b.path);
    assertStateString(r'''
files
  /sdk/lib/_internal/internal.dart
    current
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /sdk/lib/async/async.dart
    current
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /sdk/lib/async/stream.dart
    current
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
  /sdk/lib/core/core.dart
    current
      unlinkedKey: k03
    unlinkedGet: []
    unlinkedPut: [k03]
  /sdk/lib/math/math.dart
    current
      unlinkedKey: k04
    unlinkedGet: []
    unlinkedPut: [k04]
  /workspace/dart/test/lib/a.dart
    current
      unlinkedKey: k05
    unlinkedGet: []
    unlinkedPut: [k05, k05]
  /workspace/dart/test/lib/b.dart
    current
      unlinkedKey: k06
    unlinkedGet: []
    unlinkedPut: [k06, k06]
libraryCycles
  /sdk/lib/_internal/internal.dart /sdk/lib/async/async.dart /sdk/lib/core/core.dart /sdk/lib/math/math.dart
    get: []
    put: [k07]
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k08, k08]
elementFactory
  hasElement
    dart:_internal
    dart:async
    dart:core
    dart:math
    package:dart.test/a.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08]
''');
  }

  test_changePartFile_refreshedFiles_transitive() async {
    newFile('/workspace/dart/test/lib/a.dart', r'''
part 'b.dart';

class A {}
''');

    final b = newFile('/workspace/dart/test/lib/b.dart', r'''
part of 'a.dart';

class B extends A {}
''');

    final c = newFile('/workspace/dart/test/lib/c.dart', r'''
import 'a.dart';
''');

    await resolveFile(c.path);
    assertStateString(r'''
files
  /sdk/lib/_internal/internal.dart
    current
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /sdk/lib/async/async.dart
    current
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /sdk/lib/async/stream.dart
    current
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
  /sdk/lib/core/core.dart
    current
      unlinkedKey: k03
    unlinkedGet: []
    unlinkedPut: [k03]
  /sdk/lib/math/math.dart
    current
      unlinkedKey: k04
    unlinkedGet: []
    unlinkedPut: [k04]
  /workspace/dart/test/lib/a.dart
    current
      unlinkedKey: k05
    unlinkedGet: []
    unlinkedPut: [k05]
  /workspace/dart/test/lib/b.dart
    current
      unlinkedKey: k06
    unlinkedGet: []
    unlinkedPut: [k06]
  /workspace/dart/test/lib/c.dart
    current
      unlinkedKey: k07
    unlinkedGet: []
    unlinkedPut: [k07]
libraryCycles
  /sdk/lib/_internal/internal.dart /sdk/lib/async/async.dart /sdk/lib/core/core.dart /sdk/lib/math/math.dart
    get: []
    put: [k08]
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k09]
  /workspace/dart/test/lib/c.dart
    get: []
    put: [k10]
elementFactory
  hasElement
    dart:_internal
    dart:async
    dart:core
    dart:math
    package:dart.test/a.dart
    package:dart.test/c.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09, k10]
''');

    // Should invalidate a.dart, b.dart, c.dart
    fileResolver.changeFile(b.path);
    fileResolver.releaseAndClearRemovedIds();
    assertStateString(r'''
files
  /sdk/lib/_internal/internal.dart
    current
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /sdk/lib/async/async.dart
    current
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /sdk/lib/async/stream.dart
    current
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
  /sdk/lib/core/core.dart
    current
      unlinkedKey: k03
    unlinkedGet: []
    unlinkedPut: [k03]
  /sdk/lib/math/math.dart
    current
      unlinkedKey: k04
    unlinkedGet: []
    unlinkedPut: [k04]
  /workspace/dart/test/lib/a.dart
    unlinkedGet: []
    unlinkedPut: [k05]
  /workspace/dart/test/lib/b.dart
    unlinkedGet: []
    unlinkedPut: [k06]
  /workspace/dart/test/lib/c.dart
    unlinkedGet: []
    unlinkedPut: [k07]
libraryCycles
  /sdk/lib/_internal/internal.dart /sdk/lib/async/async.dart /sdk/lib/core/core.dart /sdk/lib/math/math.dart
    get: []
    put: [k08]
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k09]
  /workspace/dart/test/lib/c.dart
    get: []
    put: [k10]
elementFactory
  hasElement
    dart:_internal
    dart:async
    dart:core
    dart:math
byteStore
  1: [k00, k01, k02, k03, k04, k08]
''');

    // Read again a.dart, b.dart, c.dart
    await resolveFile(c.path);
    assertStateString(r'''
files
  /sdk/lib/_internal/internal.dart
    current
      unlinkedKey: k00
    unlinkedGet: []
    unlinkedPut: [k00]
  /sdk/lib/async/async.dart
    current
      unlinkedKey: k01
    unlinkedGet: []
    unlinkedPut: [k01]
  /sdk/lib/async/stream.dart
    current
      unlinkedKey: k02
    unlinkedGet: []
    unlinkedPut: [k02]
  /sdk/lib/core/core.dart
    current
      unlinkedKey: k03
    unlinkedGet: []
    unlinkedPut: [k03]
  /sdk/lib/math/math.dart
    current
      unlinkedKey: k04
    unlinkedGet: []
    unlinkedPut: [k04]
  /workspace/dart/test/lib/a.dart
    current
      unlinkedKey: k05
    unlinkedGet: []
    unlinkedPut: [k05, k05]
  /workspace/dart/test/lib/b.dart
    current
      unlinkedKey: k06
    unlinkedGet: []
    unlinkedPut: [k06, k06]
  /workspace/dart/test/lib/c.dart
    current
      unlinkedKey: k07
    unlinkedGet: []
    unlinkedPut: [k07, k07]
libraryCycles
  /sdk/lib/_internal/internal.dart /sdk/lib/async/async.dart /sdk/lib/core/core.dart /sdk/lib/math/math.dart
    get: []
    put: [k08]
  /workspace/dart/test/lib/a.dart
    get: []
    put: [k09, k09]
  /workspace/dart/test/lib/c.dart
    get: []
    put: [k10, k10]
elementFactory
  hasElement
    dart:_internal
    dart:async
    dart:core
    dart:math
    package:dart.test/a.dart
    package:dart.test/c.dart
byteStore
  1: [k00, k01, k02, k03, k04, k05, k06, k07, k08, k09, k10]
''');
  }
}

@reflectiveTest
class FileResolverTest extends FileResolutionTest {
  @override
  bool get isNullSafetyEnabled => true;

  test_analysisOptions_default_fromPackageUri() async {
    newFile('/workspace/dart/analysis_options/lib/default.yaml', r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    await assertErrorsInCode(r'''
num a = 0;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_file_inPackage() async {
    newAnalysisOptionsYamlFile('/workspace/dart/test', r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    await assertErrorsInCode(r'''
num a = 0;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_file_inThirdParty() async {
    newFile('/workspace/dart/analysis_options/lib/third_party.yaml', r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    newAnalysisOptionsYamlFile('/workspace/third_party/dart/aaa', r'''
analyzer:
  strong-mode:
    implicit-casts: true
''');

    var aPath = convertPath('/workspace/third_party/dart/aaa/lib/a.dart');
    await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_file_inThirdPartyDartLang() async {
    newFile('/workspace/dart/analysis_options/lib/third_party.yaml', r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    newAnalysisOptionsYamlFile('/workspace/third_party/dart_lang/aaa', r'''
analyzer:
  strong-mode:
    implicit-casts: true
''');

    var aPath = convertPath('/workspace/third_party/dart_lang/aaa/lib/a.dart');
    await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_lints() async {
    newFile('/workspace/dart/analysis_options/lib/default.yaml', r'''
linter:
  rules:
    - omit_local_variable_types
''');

    var rule = Registry.ruleRegistry.getRule('omit_local_variable_types')!;

    await assertErrorsInCode(r'''
main() {
  int a = 0;
  a;
}
''', [
      error(rule.lintCode, 11, 9),
    ]);
  }

  test_basic() async {
    await assertNoErrorsInCode(r'''
int a = 0;
var b = 1 + 2;
''');
    assertType(findElement.topVar('a').type, 'int');
    assertElement(findNode.simple('int a'), intElement);

    assertType(findElement.topVar('b').type, 'int');
  }

  test_collectSharedDataIdentifiers() async {
    var aPath = convertPath('/workspace/third_party/dart/aaa/lib/a.dart');

    newFile(aPath, r'''
class A {}
''');

    await resolveFile(aPath);
    fileResolver.collectSharedDataIdentifiers();
    expect(fileResolver.removedCacheKeys.length,
        (fileResolver.byteStore as MemoryCiderByteStore).testView!.length);
  }

  test_elements_export_dartCoreDynamic() async {
    var a_path = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(a_path, r'''
export 'dart:core' show dynamic;
''');

    // Analyze so that `dart:core` is linked.
    var a_result = await resolveFile(a_path);

    // Touch `dart:core` so that its element model is discarded.
    var dartCorePath = a_result.session.uriConverter.uriToPath(
      Uri.parse('dart:core'),
    )!;
    fileResolver.changeFile(dartCorePath);

    // Analyze, this will read the element model for `dart:core`.
    // There was a bug that `root::dart:core::dynamic` had no element set.
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;
p.dynamic f() {}
''');
  }

  test_errors_hasNullSuffix() {
    assertErrorsInCode(r'''
String f(Map<int, String> a) {
  return a[0];
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 40, 4,
          messageContains: ["'String'", 'String?']),
    ]);
  }

  test_findReferences_class() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class A {
  int foo;
}
''');

    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

void func() {
  var a = A();
  print(a.foo);
}
''');

    await resolveFile(bPath);
    var element = await _findElement(6, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath,
          [CiderSearchInfo(CharacterLocation(4, 11), 1, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_field() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class A {
  int foo = 0;

  void func(int bar) {
    foo = bar;
 }
}
''');

    await resolveFile(aPath);
    var element = await _findElement(16, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(
          aPath, [CiderSearchInfo(CharacterLocation(5, 5), 3, MatchKind.WRITE)])
    ];
    expect(result, expected);
  }

  test_findReferences_function() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
main() {
  foo('Hello');
}

foo(String str) {}
''');

    await resolveFile(aPath);
    var element = await _findElement(11, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(aPath,
          [CiderSearchInfo(CharacterLocation(2, 3), 3, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_getter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class A {
  int get foo => 6;
}
''');
    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

main() {
  var a = A();
  var bar = a.foo;
}
''');

    await resolveFile(bPath);
    var element = await _findElement(20, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath,
          [CiderSearchInfo(CharacterLocation(5, 15), 3, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_local_variable() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class A {
  void func(int n) {
    var foo = bar+1;
    print(foo);
 }
}
''');
    await resolveFile(aPath);
    var element = await _findElement(39, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(aPath,
          [CiderSearchInfo(CharacterLocation(4, 11), 3, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_method() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class A {
  void func() {
   print('hello');
 }

 void func2() {
   func();
 }
}
''');

    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

main() {
  var a = A();
  a.func();
}
''');

    await resolveFile(bPath);
    var element = await _findElement(17, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath,
          [CiderSearchInfo(CharacterLocation(5, 5), 4, MatchKind.REFERENCE)]),
      CiderSearchMatch(aPath,
          [CiderSearchInfo(CharacterLocation(7, 4), 4, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_setter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class A {
  void set value(int m){ };
}
''');
    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

main() {
  var a = A();
  a.value = 6;
}
''');

    await resolveFile(bPath);
    var element = await _findElement(21, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(
          bPath, [CiderSearchInfo(CharacterLocation(5, 5), 5, MatchKind.WRITE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_top_level_getter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');

    newFile(aPath, r'''
int _foo;

int get foo => _foo;
''');

    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

main() {
  var bar = foo;
}
''');

    await resolveFile(bPath);
    var element = await _findElement(19, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath,
          [CiderSearchInfo(CharacterLocation(4, 13), 3, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_top_level_setter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');

    newFile(aPath, r'''
int _foo;

void set foo(int bar) { _foo = bar; }
''');

    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

main() {
  foo = 6;
}
''');

    await resolveFile(bPath);
    var element = await _findElement(20, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath,
          [CiderSearchInfo(CharacterLocation(4, 3), 3, MatchKind.WRITE)]),
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_top_level_variable() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');

    newFile(aPath, r'''
const int C = 42;

void func() {
    print(C);
}
''');

    await resolveFile(aPath);
    var element = await _findElement(10, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(
          aPath, [CiderSearchInfo(CharacterLocation(4, 11), 1, MatchKind.READ)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_findReferences_type_parameter() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
class Foo<T> {
  List<T> l;

  void bar(T t) {}
}
''');
    await resolveFile(aPath);
    var element = await _findElement(10, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(aPath, [
        CiderSearchInfo(CharacterLocation(2, 8), 1, MatchKind.REFERENCE),
        CiderSearchInfo(CharacterLocation(4, 12), 1, MatchKind.REFERENCE)
      ])
    ];
    expect(result, expected);
  }

  test_findReferences_typedef() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
typedef func = int Function(int);

''');
    var bPath = convertPath('/workspace/dart/test/lib/b.dart');
    newFile(bPath, r'''
import 'a.dart';

void f(func o) {}
''');

    await resolveFile(bPath);
    var element = await _findElement(8, aPath);
    var result = await fileResolver.findReferences2(element);
    var expected = <CiderSearchMatch>[
      CiderSearchMatch(bPath,
          [CiderSearchInfo(CharacterLocation(3, 8), 4, MatchKind.REFERENCE)])
    ];
    expect(result, unorderedEquals(expected));
  }

  test_getErrors() async {
    addTestFile(r'''
var a = b;
var foo = 0;
''');

    var result = await getTestErrors();
    expect(result.path, convertPath('/workspace/dart/test/lib/test.dart'));
    expect(result.uri.toString(), 'package:dart.test/test.dart');
    assertErrorsInList(result.errors, [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 8, 1),
    ]);
    expect(result.lineInfo.lineStarts, [0, 11, 24]);
  }

  test_getErrors_reuse() async {
    newFile(testFilePath, 'var a = b;');

    // No resolved files yet.
    _assertResolvedFiles([]);

    // No cached, will resolve once.
    expect((await getTestErrors()).errors, hasLength(1));
    _assertResolvedFiles([testFile]);

    // Has cached, will be not resolved again.
    expect((await getTestErrors()).errors, hasLength(1));
    _assertResolvedFiles([]);

    // Change the file, will be resolved again.
    newFile(testFilePath, 'var a = c;');
    fileResolver.changeFile(testFile.path);
    expect((await getTestErrors()).errors, hasLength(1));
    _assertResolvedFiles([testFile]);
  }

  test_getErrors_reuse_changeDependency() async {
    final a = newFile('/workspace/dart/test/lib/a.dart', r'''
var a = 0;
''');

    newFile(testFilePath, r'''
import 'a.dart';
var b = a.foo;
''');

    // No resolved files yet.
    _assertResolvedFiles([]);

    // No cached, will resolve once.
    expect((await getTestErrors()).errors, hasLength(1));
    _assertResolvedFiles([testFile]);

    // Has cached, will be not resolved again.
    expect((await getTestErrors()).errors, hasLength(1));
    _assertResolvedFiles([]);

    // Change the dependency.
    // The signature of the result is different.
    // The previously cached result cannot be used.
    newFile(a.path, r'''
var a = 4.2;
''');
    fileResolver.changeFile(a.path);
    expect((await getTestErrors()).errors, hasLength(1));
    _assertResolvedFiles([testFile]);
  }

  test_getFilesWithTopLevelDeclarations_cached() async {
    await assertNoErrorsInCode(r'''
int a = 0;
var b = 1 + 2;
''');

    void assertHasOneVariable() {
      var files = fileResolver.getFilesWithTopLevelDeclarations('a');
      expect(files, hasLength(1));
      var file = files.single;
      expect(file.path, result.path);
    }

    // Ask to check that it works when parsed.
    assertHasOneVariable();

    // Create a new resolved, but reuse the cache.
    createFileResolver();

    await resolveTestFile();

    // Ask again, when unlinked information is read from the cache.
    assertHasOneVariable();
  }

  test_getLibraryByUri() async {
    newFile('/workspace/dart/my/lib/a.dart', r'''
class A {}
''');

    var element = await fileResolver.getLibraryByUri2(
      uriStr: 'package:dart.my/a.dart',
    );
    expect(element.definingCompilationUnit.classes, hasLength(1));
  }

  test_getLibraryByUri_notExistingFile() async {
    var element = await fileResolver.getLibraryByUri2(
      uriStr: 'package:dart.my/a.dart',
    );
    expect(element.definingCompilationUnit.classes, isEmpty);
  }

  test_getLibraryByUri_partOf() async {
    newFile('/workspace/dart/my/lib/a.dart', r'''
part of 'b.dart';
''');

    expect(() async {
      await fileResolver.getLibraryByUri2(
        uriStr: 'package:dart.my/a.dart',
      );
    }, throwsArgumentError);
  }

  test_getLibraryByUri_unresolvedUri() async {
    expect(() async {
      await fileResolver.getLibraryByUri2(
        uriStr: 'my:unresolved',
      );
    }, throwsArgumentError);
  }

  test_hint() async {
    await assertErrorsInCode(r'''
import 'dart:math';
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);
  }

  test_hint_in_third_party() async {
    var aPath = convertPath('/workspace/third_party/dart/aaa/lib/a.dart');
    newFile(aPath, r'''
import 'dart:math';
''');
    await resolveFile(aPath);
    assertNoErrorsInResult();
  }

  test_linkLibraries_getErrors() async {
    addTestFile(r'''
var a = b;
var foo = 0;
''');

    var path = convertPath('/workspace/dart/test/lib/test.dart');
    await fileResolver.linkLibraries2(path: path);

    var result = await getTestErrors();
    expect(result.path, path);
    expect(result.uri.toString(), 'package:dart.test/test.dart');
    assertErrorsInList(result.errors, [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 8, 1),
    ]);
    expect(result.lineInfo.lineStarts, [0, 11, 24]);
  }

  test_nameOffset_class_method_fromBytes() async {
    newFile('/workspace/dart/test/lib/a.dart', r'''
class A {
  void foo() {}
}
''');

    addTestFile(r'''
import 'a.dart';

void f(A a) {
  a.foo();
}
''');

    await resolveTestFile();
    {
      var element = findNode.simple('foo();').staticElement!;
      expect(element.nameOffset, 17);
    }

    // New resolver.
    // Element models will be loaded from the cache.
    createFileResolver();
    await resolveTestFile();
    {
      var element = findNode.simple('foo();').staticElement!;
      expect(element.nameOffset, 17);
    }
  }

  test_nameOffset_unit_variable_fromBytes() async {
    newFile('/workspace/dart/test/lib/a.dart', r'''
var a = 0;
''');

    addTestFile(r'''
import 'a.dart';
var b = a;
''');

    await resolveTestFile();
    {
      var element = findNode.simple('a;').staticElement!;
      expect(element.nonSynthetic.nameOffset, 4);
    }

    // New resolver.
    // Element models will be loaded from the cache.
    createFileResolver();
    await resolveTestFile();
    {
      var element = findNode.simple('a;').staticElement!;
      expect(element.nonSynthetic.nameOffset, 4);
    }
  }

  test_nullSafety_enabled() async {
    await assertNoErrorsInCode(r'''
void f(int? a) {
  if (a != null) {
    a.isEven;
  }
}
''');

    assertType(
      findElement.parameter('a').type,
      'int?',
    );
  }

  test_nullSafety_notEnabled() async {
    newFile('/workspace/dart/test/BUILD', '');

    await assertErrorsInCode(r'''
void f(int? a) {}
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 10, 1),
    ]);

    assertType(
      findElement.parameter('a').type,
      'int*',
    );
  }

  test_part_notInLibrary_libraryDoesNotExist() async {
    // TODO(scheglov) Should report CompileTimeErrorCode.URI_DOES_NOT_EXIST
    await assertNoErrorsInCode(r'''
part of 'a.dart';
''');
  }

  test_removeFilesNotNecessaryForAnalysisOf() async {
    var aPath = convertPath('/workspace/dart/aaa/lib/a.dart');
    var bPath = convertPath('/workspace/dart/aaa/lib/b.dart');
    var cPath = convertPath('/workspace/dart/aaa/lib/c.dart');

    newFile(aPath, r'''
class A {}
''');

    newFile(bPath, r'''
import 'a.dart';
''');

    newFile(cPath, r'''
import 'a.dart';
''');

    await resolveFile(bPath);
    await resolveFile(cPath);
    fileResolver.removeFilesNotNecessaryForAnalysisOf([cPath]);
    _assertRemovedPaths(unorderedEquals([bPath]));
  }

  test_removeFilesNotNecessaryForAnalysisOf_multiple() async {
    var bPath = convertPath('/workspace/dart/aaa/lib/b.dart');
    var dPath = convertPath('/workspace/dart/aaa/lib/d.dart');
    var ePath = convertPath('/workspace/dart/aaa/lib/e.dart');
    var fPath = convertPath('/workspace/dart/aaa/lib/f.dart');

    newFile('/workspace/dart/aaa/lib/a.dart', r'''
class A {}
''');

    newFile(bPath, r'''
class B {}
''');

    newFile('/workspace/dart/aaa/lib/c.dart', r'''
class C {}
''');

    newFile(dPath, r'''
import 'a.dart';
''');

    newFile(ePath, r'''
import 'a.dart';
import 'b.dart';
''');

    newFile(fPath, r'''
import 'c.dart';
 ''');

    await resolveFile(dPath);
    await resolveFile(ePath);
    await resolveFile(fPath);
    fileResolver.removeFilesNotNecessaryForAnalysisOf([dPath, fPath]);
    _assertRemovedPaths(unorderedEquals([bPath, ePath]));
  }

  test_removeFilesNotNecessaryForAnalysisOf_unknown() async {
    var aPath = convertPath('/workspace/dart/aaa/lib/a.dart');
    var bPath = convertPath('/workspace/dart/aaa/lib/b.dart');

    newFile(aPath, r'''
class A {}
''');

    await resolveFile(aPath);

    fileResolver.removeFilesNotNecessaryForAnalysisOf([aPath, bPath]);
    _assertRemovedPaths(isEmpty);
  }

  test_resolve_libraryWithPart_noLibraryDiscovery() async {
    var partPath = '/workspace/dart/test/lib/a.dart';
    newFile(partPath, r'''
part of 'test.dart';

class A {}
''');

    await assertNoErrorsInCode(r'''
part 'a.dart';

void f(A a) {}
''');

    // We started resolution from the library, and then followed to the part.
    // So, the part knows its library, there is no need to discover it.
    _assertDiscoveredLibraryForParts([]);
  }

  test_resolve_part_of_name() async {
    newFile('/workspace/dart/test/lib/a.dart', r'''
library my.lib;

part 'test.dart';

class A {
  int m;
}
''');

    await assertNoErrorsInCode(r'''
part of my.lib;

void func() {
  var a = A();
  print(a.m);
}
''');

    _assertDiscoveredLibraryForParts([result.path]);
  }

  test_resolve_part_of_uri() async {
    newFile('/workspace/dart/test/lib/a.dart', r'''
part 'test.dart';

class A {
  int m;
}
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';

void func() {
  var a = A();
  print(a.m);
}
''');

    _assertDiscoveredLibraryForParts([result.path]);
  }

  test_resolveFile_cache() async {
    newFile(testFilePath, 'var a = 0;');

    // No resolved files yet.
    _assertResolvedFiles([]);

    await resolveFile2(testFile.path);
    var result1 = result;

    // The file was resolved.
    _assertResolvedFiles([testFile]);

    // The result is cached.
    expect(fileResolver.cachedResults, contains(testFile.path));

    // Ask again, no changes, not resolved.
    await resolveFile2(testFile.path);
    _assertResolvedFiles([]);

    // The same result was returned.
    expect(result, same(result1));

    // Change a file.
    var a_path = convertPath('/workspace/dart/test/lib/a.dart');
    fileResolver.changeFile(a_path);

    // The was a change to a file, no matter which, resolve again.
    await resolveFile2(testFile.path);
    _assertResolvedFiles([testFile]);

    // Get should get a new result.
    expect(result, isNot(same(result1)));
  }

  test_resolveFile_dontCache_whenForCompletion() async {
    final a = newFile('/workspace/dart/test/lib/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('/workspace/dart/test/lib/b.dart', r'''
part of 'a.dart';
''');

    // No resolved files yet.
    _assertResolvedFiles([]);

    await fileResolver.resolve2(
      path: b.path,
      completionLine: 0,
      completionColumn: 0,
    );

    // The library was resolved.
    _assertResolvedFiles([a]);

    // The completion location was set, so not units are resolved.
    // So, the result should not be cached.
    expect(fileResolver.cachedResults, isEmpty);
  }

  test_resolveLibrary() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, r'''
part 'test.dart';

class A {
  int m;
}
''');

    newFile('/workspace/dart/test/lib/test.dart', r'''
part of 'a.dart';

void func() {
  var a = A();
  print(a.m);
}
''');

    var result = await fileResolver.resolveLibrary2(path: aPath);
    expect(result.units.length, 2);
    expect(result.units[0].path, aPath);
    expect(result.units[0].uri, Uri.parse('package:dart.test/a.dart'));
  }

  test_reuse_compatibleOptions() async {
    newFile('/workspace/dart/aaa/BUILD', '');
    newFile('/workspace/dart/bbb/BUILD', '');

    var aPath = '/workspace/dart/aaa/lib/a.dart';
    var aResult = await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', []);

    var bPath = '/workspace/dart/bbb/lib/a.dart';
    var bResult = await assertErrorsInFile(bPath, r'''
num a = 0;
int b = a;
''', []);

    // Both files use the same (default) analysis options.
    // So, when we resolve 'bbb', we can reuse the context after 'aaa'.
    expect(
      aResult.libraryElement.context,
      same(bResult.libraryElement.context),
    );
  }

  test_reuse_incompatibleOptions_implicitCasts() async {
    newFile('/workspace/dart/aaa/BUILD', '');
    newAnalysisOptionsYamlFile('/workspace/dart/aaa', r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    newFile('/workspace/dart/bbb/BUILD', '');
    newAnalysisOptionsYamlFile('/workspace/dart/bbb', r'''
analyzer:
  strong-mode:
    implicit-casts: true
''');

    // Implicit casts are disabled in 'aaa'.
    var aPath = '/workspace/dart/aaa/lib/a.dart';
    await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);

    // Implicit casts are enabled in 'bbb'.
    var bPath = '/workspace/dart/bbb/lib/a.dart';
    await assertErrorsInFile(bPath, r'''
num a = 0;
int b = a;
''', []);

    // Implicit casts are still disabled in 'aaa'.
    await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_switchCase_implementsEquals_enum() async {
    await assertNoErrorsInCode(r'''
enum MyEnum {a, b, c}

void f(MyEnum myEnum) {
  switch (myEnum) {
    case MyEnum.a:
      break;
    default:
      break;
  }
}
''');
  }

  test_unknown_uri() async {
    await assertErrorsInCode(r'''
import 'foo:bar';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 9),
    ]);
  }

  void _assertDiscoveredLibraryForParts(List<String> expected) {
    expect(fileResolver.fsState!.testView.partsDiscoveredLibraries, expected);
  }

  void _assertRemovedPaths(Matcher matcher) {
    expect(fileResolver.fsState!.testView.removedPaths, matcher);
  }

  void _assertResolvedFiles(
    List<File> expected, {
    bool andClear = true,
  }) {
    final actual = fileResolver.testView!.resolvedLibraries;
    expect(actual, expected.map((e) => e.path).toList());
    if (andClear) {
      actual.clear();
    }
  }

  Future<Element> _findElement(int offset, String filePath) async {
    var resolvedUnit = await fileResolver.resolve2(path: filePath);
    var node = NodeLocator(offset).searchWithin(resolvedUnit.unit);
    var element = getElementOfNode(node);
    return element!;
  }
}
