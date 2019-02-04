// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/util/yaml_test.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CrossPackageHintCodeTest);
  });
}

final metaLibraryStub = r'''
library meta;

const _AlwaysThrows alwaysThrows = const _AlwaysThrows();
const _Factory factory = const _Factory();
const Immutable immutable = const Immutable();
const _Literal literal = const _Literal();
const _MustCallSuper mustCallSuper = const _MustCallSuper();
const _Protected protected = const _Protected();
const Required required = const Required();
const _Sealed sealed = const _Sealed();
const _VisibleForTesting visibleForTesting = const _VisibleForTesting();

class Immutable {
  final String reason;
  const Immutable([this.reason]);
}
class _AlwaysThrows {
  const _AlwaysThrows();
}
class _Factory {
  const _Factory();
}
class _Literal {
  const _Literal();
}
class _MustCallSuper {
  const _MustCallSuper();
}
class _Protected {
  const _Protected();
}
class Required {
  final String reason;
  const Required([this.reason]);
}
class _Sealed {
  const _Sealed();
}
class _VisibleForTesting {
  const _VisibleForTesting();
}
''';

@reflectiveTest
class CrossPackageHintCodeTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  test_subtypeOfSealedClass_extending() async {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
      [
        'foo',
        r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
'''
      ]
    ]);

    _newPubPackageRoot('/pkg1');
    Source source = addNamedSource('/pkg1/lib/lib1.dart', r'''
                    import 'package:foo/foo.dart';
                    class Bar extends Foo {}
                    ''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.SUBTYPE_OF_SEALED_CLASS]);
    verify([source]);
  }

  test_subtypeOfSealedClass_implementing() async {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
      [
        'foo',
        r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
'''
      ]
    ]);

    _newPubPackageRoot('/pkg1');
    Source source = addNamedSource('/pkg1/lib/lib1.dart', r'''
                    import 'package:foo/foo.dart';
                    class Bar implements Foo {}
                    ''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.SUBTYPE_OF_SEALED_CLASS]);
    verify([source]);
  }

  test_subtypeOfSealedClass_mixinApplication() async {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
      [
        'foo',
        r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
'''
      ]
    ]);

    _newPubPackageRoot('/pkg1');
    Source source = addNamedSource('/pkg1/lib/lib1.dart', r'''
                    import 'package:foo/foo.dart';
                    class Bar1 {}
                    class Bar2 = Bar1 with Foo;
                    ''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.SUBTYPE_OF_SEALED_CLASS]);
    verify([source]);
  }

  test_subtypeOfSealedClass_mixinImplements() async {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
      [
        'foo',
        r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
'''
      ]
    ]);

    _newPubPackageRoot('/pkg1');
    Source source = addNamedSource('/pkg1/lib/lib1.dart', r'''
                    import 'package:foo/foo.dart';
                    mixin Bar implements Foo {}
                    ''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.SUBTYPE_OF_SEALED_CLASS]);
    verify([source]);
  }

  test_subtypeOfSealedClass_mixinOn() async {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
      [
        'foo',
        r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
'''
      ]
    ]);

    _newPubPackageRoot('/pkg1');
    Source source = addNamedSource('/pkg1/lib/lib1.dart', r'''
                    import 'package:foo/foo.dart';
                    mixin Bar on Foo {}
                    ''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MIXIN_ON_SEALED_CLASS]);
    verify([source]);
  }

  test_subtypeOfSealedClass_with() async {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
      [
        'foo',
        r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
'''
      ]
    ]);

    _newPubPackageRoot('/pkg1');
    Source source = addNamedSource('/pkg1/lib/lib1.dart', r'''
                    import 'package:foo/foo.dart';
                    class Bar extends Object with Foo {}
                    ''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.SUBTYPE_OF_SEALED_CLASS]);
    verify([source]);
  }

  test_subtypeOfSealedClass_withinLibrary_OK() async {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
    ]);

    _newPubPackageRoot('/pkg1');
    Source source = addNamedSource('/pkg1/lib/lib1.dart', r'''
                    import 'package:meta/meta.dart';
                    @sealed class Foo {}

                    class Bar1 extends Foo {}
                    class Bar2 implements Foo {}
                    class Bar4 = Bar1 with Foo;
                    mixin Bar5 on Foo {}
                    mixin Bar6 implements Foo {}
                    ''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_subtypeOfSealedClass_withinPackageLibDirectory_OK() async {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
    ]);

    _newPubPackageRoot('/pkg1');
    Source source1 = addNamedSource('/pkg1/lib/lib1.dart', r'''
                     import 'package:meta/meta.dart';
                     @sealed class Foo {}
                     ''');
    Source source2 = addNamedSource('/pkg1/lib/src/lib2.dart', r'''
                     import '../lib1.dart';
                     class Bar1 extends Foo {}
                     class Bar2 implements Foo {}
                     class Bar4 = Bar1 with Foo;
                     mixin Bar5 on Foo {}
                     mixin Bar6 implements Foo {}
                     ''');
    await computeAnalysisResult(source1);
    await computeAnalysisResult(source2);
    assertNoErrors(source1);
    assertNoErrors(source2);
    verify([source1, source2]);
  }

  test_subtypeOfSealedClass_withinPackageTestDirectory_OK() async {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
    ]);

    newFolder('/pkg1');
    _newPubPackageRoot('/pkg1');

    Source source1 = addNamedSource('/pkg1/lib/lib1.dart', r'''
                     import 'package:meta/meta.dart';
                     @sealed class Foo {}
                     ''');
    Source source2 = addNamedSource('/pkg1/test/test.dart', r'''
                     import '../lib/lib1.dart';
                     class Bar1 extends Foo {}
                     class Bar2 implements Foo {}
                     class Bar4 = Bar1 with Foo;
                     mixin Bar5 on Foo {}
                     mixin Bar6 implements Foo {}
                     ''');
    await computeAnalysisResult(source1);
    await computeAnalysisResult(source2);
    assertNoErrors(source1);
    assertNoErrors(source2);
    verify([source1, source2]);
  }

  test_subtypeOfSealedClass_withinPart_OK() async {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
    ]);

    _newPubPackageRoot('/pkg1');
    Source source1 = addNamedSource('/pkg1/lib/lib1.dart', r'''
                     import 'package:meta/meta.dart';
                     part 'part1.dart';
                     @sealed class Foo {}
                     ''');
    addNamedSource('/pkg1/lib/part1.dart', r'''
                     part of 'lib1.dart';
                     class Bar1 extends Foo {}
                     class Bar2 implements Foo {}
                     class Bar4 = Bar1 with Foo;
                     mixin Bar5 on Foo {}
                     mixin Bar6 implements Foo {}
                     ''');
    await computeAnalysisResult(source1);
    assertNoErrors(source1);
    verify([source1]);
  }

  test_subtypeOfSealedMixin_mixinApplication() async {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
      [
        'foo',
        r'''
import 'package:meta/meta.dart';
@sealed mixin Foo {}
'''
      ]
    ]);

    _newPubPackageRoot('/pkg1');
    Source source = addNamedSource('/pkg1/lib/lib1.dart', r'''
                    import 'package:foo/foo.dart';
                    class Bar1 {}
                    class Bar2 = Bar1 with Foo;
                    ''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.SUBTYPE_OF_SEALED_CLASS]);
    verify([source]);
  }

  test_subtypeOfSealedMixin_with() async {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
      [
        'foo',
        r'''
import 'package:meta/meta.dart';
@sealed mixin Foo {}
'''
      ]
    ]);

    _newPubPackageRoot('/pkg1');
    Source source = addNamedSource('/pkg1/lib/lib1.dart', r'''
                    import 'package:foo/foo.dart';
                    class Bar extends Object with Foo {}
                    ''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.SUBTYPE_OF_SEALED_CLASS]);
    verify([source]);
  }

  /// Write a pubspec file at [root], so that BestPracticesVerifier can see
  /// that [root] is the root of a PubWorkspace, and a PubWorkspacePackage.
  void _newPubPackageRoot(String root) {
    newFile('$root/pubspec.yaml');
  }
}

@reflectiveTest
class HintCodeTest extends ResolverTestCase {
  @override
  void reset() {
    super.resetWith(packages: [
      ['meta', metaLibraryStub],
      [
        'js',
        r'''
library js;
class JS {
  const JS([String js]);
}
'''
      ],
      [
        'angular_meta',
        r'''
library angular.meta;

const _VisibleForTemplate visibleForTemplate = const _VisibleForTemplate();

class _VisibleForTemplate {
  const _VisibleForTemplate();
}
'''
      ],
    ]);
  }

  test_deadCode_deadBlock_conditionalElse() async {
    Source source = addSource(r'''
f() {
  true ? 1 : 2;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadBlock_conditionalElse_nested() async {
    // test that a dead else-statement can't generate additional violations
    Source source = addSource(r'''
f() {
  true ? true : false && false;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadBlock_conditionalIf() async {
    Source source = addSource(r'''
f() {
  false ? 1 : 2;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadBlock_conditionalIf_nested() async {
    // test that a dead then-statement can't generate additional violations
    Source source = addSource(r'''
f() {
  false ? false && false : true;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadBlock_else() async {
    Source source = addSource(r'''
f() {
  if(true) {} else {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadBlock_else_nested() async {
    // test that a dead else-statement can't generate additional violations
    Source source = addSource(r'''
f() {
  if(true) {} else {if (false) {}}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadBlock_if() async {
    Source source = addSource(r'''
f() {
  if(false) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadBlock_if_nested() async {
    // test that a dead then-statement can't generate additional violations
    Source source = addSource(r'''
f() {
  if(false) {if(false) {}}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadBlock_while() async {
    Source source = addSource(r'''
f() {
  while(false) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadBlock_while_nested() async {
    // test that a dead while body can't generate additional violations
    Source source = addSource(r'''
f() {
  while(false) {if(false) {}}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadCatch_catchFollowingCatch() async {
    Source source = addSource(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
    verify([source]);
  }

  test_deadCode_deadCatch_catchFollowingCatch_nested() async {
    // test that a dead catch clause can't generate additional violations
    Source source = addSource(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {if(false) {}}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
    verify([source]);
  }

  test_deadCode_deadCatch_catchFollowingCatch_object() async {
    Source source = addSource(r'''
f() {
  try {} on Object catch (e) {} catch (e) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
    verify([source]);
  }

  test_deadCode_deadCatch_catchFollowingCatch_object_nested() async {
    // test that a dead catch clause can't generate additional violations
    Source source = addSource(r'''
f() {
  try {} on Object catch (e) {} catch (e) {if(false) {}}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
    verify([source]);
  }

  test_deadCode_deadCatch_onCatchSubtype() async {
    Source source = addSource(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE_ON_CATCH_SUBTYPE]);
    verify([source]);
  }

  test_deadCode_deadCatch_onCatchSubtype_nested() async {
    // test that a dead catch clause can't generate additional violations
    Source source = addSource(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {if(false) {}}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE_ON_CATCH_SUBTYPE]);
    verify([source]);
  }

  test_deadCode_deadFinalReturnInCase() async {
    Source source = addSource(r'''
f() {
  switch (true) {
  case true:
    try {
      int a = 1;
    } finally {
      return;
    }
    return;
  default:
    break;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadFinalStatementInCase() async {
    Source source = addSource(r'''
f() {
  switch (true) {
  case true:
    try {
      int a = 1;
    } finally {
      return;
    }
    int b = 1;
  default:
    break;
  }
}''');
    // A single dead statement at the end of a switch case that is not a
    // terminating statement will yield two errors.
    await computeAnalysisResult(source);
    assertErrors(source,
        [HintCode.DEAD_CODE, StaticWarningCode.CASE_BLOCK_NOT_TERMINATED]);
    verify([source]);
  }

  test_deadCode_deadOperandLHS_and() async {
    Source source = addSource(r'''
f() {
  bool b = false && false;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadOperandLHS_and_nested() async {
    Source source = addSource(r'''
f() {
  bool b = false && (false && false);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadOperandLHS_or() async {
    Source source = addSource(r'''
f() {
  bool b = true || true;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_deadOperandLHS_or_nested() async {
    Source source = addSource(r'''
f() {
  bool b = true || (false && false);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterAlwaysThrowsFunction() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

@alwaysThrows
void a() {
  throw 'msg';
}

f() {
  var one = 1;
  a();
  var two = 2;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  @failingTest
  test_deadCode_statementAfterAlwaysThrowsGetter() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  @alwaysThrows
  int get a {
    throw 'msg';
  }
}

f() {
  var one = 1;
  new C().a;
  var two = 2;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterAlwaysThrowsMethod() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  @alwaysThrows
  void a() {
    throw 'msg';
  }
}

f() {
  var one = 1;
  new C().a();
  var two = 2;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterBreak_inDefaultCase() async {
    Source source = addSource(r'''
f(v) {
  switch(v) {
    case 1:
    default:
      break;
      var a;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterBreak_inForEachStatement() async {
    Source source = addSource(r'''
f() {
  var list;
  for(var l in list) {
    break;
    var a;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterBreak_inForStatement() async {
    Source source = addSource(r'''
f() {
  for(;;) {
    break;
    var a;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterBreak_inSwitchCase() async {
    Source source = addSource(r'''
f(v) {
  switch(v) {
    case 1:
      break;
      var a;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterBreak_inWhileStatement() async {
    Source source = addSource(r'''
f(v) {
  while(v) {
    break;
    var a;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterContinue_inForEachStatement() async {
    Source source = addSource(r'''
f() {
  var list;
  for(var l in list) {
    continue;
    var a;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterContinue_inForStatement() async {
    Source source = addSource(r'''
f() {
  for(;;) {
    continue;
    var a;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterContinue_inWhileStatement() async {
    Source source = addSource(r'''
f(v) {
  while(v) {
    continue;
    var a;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterExitingIf_returns() async {
    Source source = addSource(r'''
f() {
  if (1 > 2) {
    return;
  } else {
    return;
  }
  var one = 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterRethrow() async {
    Source source = addSource(r'''
f() {
  try {
    var one = 1;
  } catch (e) {
    rethrow;
    var two = 2;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterReturn_function() async {
    Source source = addSource(r'''
f() {
  var one = 1;
  return;
  var two = 2;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterReturn_ifStatement() async {
    Source source = addSource(r'''
f(bool b) {
  if(b) {
    var one = 1;
    return;
    var two = 2;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterReturn_method() async {
    Source source = addSource(r'''
class A {
  m() {
    var one = 1;
    return;
    var two = 2;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterReturn_nested() async {
    Source source = addSource(r'''
f() {
  var one = 1;
  return;
  if(false) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterReturn_twoReturns() async {
    Source source = addSource(r'''
f() {
  var one = 1;
  return;
  var two = 2;
  return;
  var three = 3;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deadCode_statementAfterThrow() async {
    Source source = addSource(r'''
f() {
  var one = 1;
  throw 'Stop here';
  var two = 2;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_deprecatedFunction_class() async {
    Source source = addSource(r'''
class Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION]);
    verify([source]);
  }

  test_deprecatedFunction_extends() async {
    Source source = addSource(r'''
class A extends Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEPRECATED_EXTENDS_FUNCTION]);
    verify([source]);
  }

  test_deprecatedFunction_extends2() async {
    Source source = addSource(r'''
class Function {}
class A extends Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION,
      HintCode.DEPRECATED_EXTENDS_FUNCTION
    ]);
    verify([source]);
  }

  test_deprecatedFunction_mixin() async {
    Source source = addSource(r'''
class A extends Object with Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEPRECATED_MIXIN_FUNCTION]);
    verify([source]);
  }

  test_deprecatedFunction_mixin2() async {
    Source source = addSource(r'''
class Function {}
class A extends Object with Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION,
      HintCode.DEPRECATED_MIXIN_FUNCTION
    ]);
    verify([source]);
  }

  test_duplicateImport() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
A a;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DUPLICATE_IMPORT]);
    verify([source]);
  }

  test_duplicateImport2() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
import 'lib1.dart';
A a;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [HintCode.DUPLICATE_IMPORT, HintCode.DUPLICATE_IMPORT]);
    verify([source]);
  }

  test_duplicateImport3() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' as M show A hide B;
import 'lib1.dart' as M show A hide B;
M.A a;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DUPLICATE_IMPORT]);
    verify([source]);
  }

  test_duplicateShownHiddenName_hidden() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart' hide A, B, A;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DUPLICATE_HIDDEN_NAME]);
    verify([source]);
  }

  test_duplicateShownHiddenName_shown() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart' show A, B, A;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DUPLICATE_SHOWN_NAME]);
    verify([source]);
  }

  test_factory__expr_return_null_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  State createState() => null;
}

class State { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_abstract_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

abstract class Stateful {
  @factory
  State createState();
}

class State { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_bad_return() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  State _s = new State();

  @factory
  State createState() => _s;
}

class State { }
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.INVALID_FACTORY_METHOD_IMPL]);
    verify([source]);
  }

  test_factory_block_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  State createState() {
    return new State();
  }
}

class State { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_block_return_null_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  State createState() {
    return null;
  }
}

class State { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_expr_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  State createState() => new State();
}

class State { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_misplaced_annotation() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

@factory
class X {
  @factory
  int x;
}

@factory
main() { }
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      HintCode.INVALID_FACTORY_ANNOTATION,
      HintCode.INVALID_FACTORY_ANNOTATION,
      HintCode.INVALID_FACTORY_ANNOTATION
    ]);
    verify([source]);
  }

  test_factory_no_return_type_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  createState() {
    return new Stateful();
  }
}
''');
    // Null return types will get flagged elsewhere, no need to pile-on here.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_subclass_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

abstract class Stateful {
  @factory
  State createState();
}

class MyThing extends Stateful {
  @override
  State createState() {
    print('my state');
    return new MyState();
  }
}

class State { }
class MyState extends State { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_void_return() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  void createState() {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.INVALID_FACTORY_METHOD_DECL]);
    verify([source]);
  }

  test_importDeferredLibraryWithLoadFunction() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
loadLibrary() {}
f() {}''',
      r'''
library root;
import 'lib1.dart' deferred as lib1;
main() { lib1.f(); }'''
    ], <ErrorCode>[
      HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION
    ]);
  }

  test_invalidImmutableAnnotation_method() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @immutable
  void m() {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.INVALID_IMMUTABLE_ANNOTATION]);
    verify([source]);
  }

  test_invalidLiteralAnnotation_nonConstConstructor() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  A() {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.INVALID_LITERAL_ANNOTATION]);
    verify([source]);
  }

  test_nonConstCallToLiteralConstructor_nonConstContext() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
void main() {
  var a = A();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR]);
    verify([source]);
  }

  test_nonConstCallToLiteralConstructor_usingNew() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
void main() {
  var a = new A();
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [HintCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW]);
    verify([source]);
  }

  test_nonConstCallToLiteralConstructor_namedConstructor() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A.named();
}
void main() {
  var a = A.named();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR]);
    verify([source]);
  }

  test_invalidLiteralAnnotation_nonConstructor() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  void m() {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.INVALID_LITERAL_ANNOTATION]);
    verify([source]);
  }

  test_invalidSealedAnnotation_onClass() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';

@sealed class A {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidSealedAnnotation_onMixin() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';

@sealed mixin M {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.INVALID_SEALED_ANNOTATION]);
    verify([source]);
  }

  test_invalidSealedAnnotation_onMixinApplication() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';

abstract class A {}

abstract class B {}

@sealed abstract class M = A with B;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidSealedAnnotation_onNonClass() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';

@sealed m({a = 1}) => null;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.INVALID_SEALED_ANNOTATION]);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_closure() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';

class A {
  @protected
  int a() => 42;
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  var leak = new A().a;
  print(leak);
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_field() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a;
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

abstract class B {
  int b() => new A().a;
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_field_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a;
}
abstract class B implements A {
  int b() => a;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_fromSuperclassConstraint() async {
    Source sourceA = addNamedSource('/a.dart', r'''
import 'package:meta/meta.dart';

abstract class A {
  @protected
  void foo() {}
}
''');
    Source sourceM = addNamedSource('/m.dart', r'''
import 'a.dart';

mixin M on A {
  @override
  void foo() {
    super.foo();
  }
}
''');

    await computeAnalysisResult(sourceA);
    await computeAnalysisResult(sourceM);
    assertNoErrors(sourceA);
    assertNoErrors(sourceM);
    verify([sourceA, sourceM]);
  }

  test_invalidUseOfProtectedMember_function() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

main() {
  new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_function_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a() => 0;
}

abstract class B implements A {
  int b() => a();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_function_OK2() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
main() {
  new A().a();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_getter() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B {
  A a;
  int b() => a.a;
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_getter_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
abstract class B implements A {
  int b() => a;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_in_docs_OK() async {
    addNamedSource('/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @protected
  int c = 0;

  @protected
  int get b => 0;

  @protected
  int a() => 0;
}
''');
    Source source = addSource(r'''
import 'a.dart';

/// OK: [A.a], [A.b], [A.c].
f() {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_message() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_method_1() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');

    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_method_OK() async {
    // https://github.com/dart-lang/linter/issues/257
    Source source = addSource(r'''
import 'package:meta/meta.dart';

typedef void VoidCallback();

class State<E> {
  @protected
  void setState(VoidCallback fn) {}
}

class Button extends State<Object> {
  void handleSomething() {
    setState(() {});
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_1() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
class B extends A {
  void b() => a();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_2() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
class B extends Object with A {
  void b() => a();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_3() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected m1() {}
}
class B extends A {
  static m2(A a) => a.m1();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_4() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
class B extends A {
  void a() => a();
}
main() {
  new B().a();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_field() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a = 42;
}
class B extends A {
  int b() => a;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_getter() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
class B extends A {
  int b() => a;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_setter() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
class B extends A {
  void b(int i) {
    a = i;
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_setter_2() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  int _a;
  @protected
  void set a(int a) { _a = a; }
  A(int a) {
    this.a = a;
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_setter() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B{
  A a;
  b(int i) {
    a.a = i;
  }
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_setter_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
abstract class B implements A {
  b(int i) {
    a = i;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_topLevelVariable() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
@protected
int x = 0;
main() {
  print(x);
}''');
    // TODO(brianwilkerson) This should produce a hint because the annotation is
    // being applied to the wrong kind of declaration.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfVisibleForTemplateMember_constructor() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  int _x;

  @visibleForTemplate
  A.forTemplate(this._x);
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  new A.forTemplate(0);
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(
        source2, [HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTemplateMember_export_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int fn0() => 1;
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
export 'lib1.dart' show fn0;
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTemplateMember_method() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  @visibleForTemplate
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(
        source2, [HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTemplateMember_method_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  @visibleForTemplate
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib1.template.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTemplateMember_propertyAccess() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  @visibleForTemplate
  int get a => 7;

  @visibleForTemplate
  set b(_) => 7;
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  new A().a;
  new A().b = 6;
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [
      HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER,
      HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER
    ]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTemplateMember_topLevelFunction() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int fn0() => 1;
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  fn0();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(
        source2, [HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTestingMember_constructor() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  int _x;

  @visibleForTesting
  A.forTesting(this._x);
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  new A.forTesting(0);
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTestingMember_export_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
int fn0() => 1;
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
export 'lib1.dart' show fn0;
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTestingMember_method() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTestingMember_method_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    Source source2 = addNamedSource('/test/test1.dart', r'''
import '../lib1.dart';

class B {
  void b() => new A().a();
}
''');
    Source source3 = addNamedSource('/testing/lib1.dart', r'''
import '../lib1.dart';

class C {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    await computeAnalysisResult(source3);
    assertNoErrors(source2);
    assertNoErrors(source3);
    verify([source, source2, source3]);
  }

  test_invalidUseOfVisibleForTestingMember_propertyAccess() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  int get a => 7;

  @visibleForTesting
  set b(_) => 7;
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  new A().a;
  new A().b = 6;
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [
      HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER,
      HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER
    ]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTestingMember_topLevelFunction() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
int fn0() => 1;
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  fn0();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseProtectedAndForTemplate_asProtected_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTemplate
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_invalidUseProtectedAndForTemplate_asTemplate_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTemplate
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib1.template.dart', r'''
import 'lib1.dart';

void main() {
  new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_invalidUseProtectedAndForTesting_asProtected_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTesting
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_invalidUseProtectedAndForTesting_asTesting_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTesting
  void a(){ }
}
''');
    Source source2 = addNamedSource('/test/test1.dart', r'''
import '../lib1.dart';

void main() {
  new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_isDouble() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.dart2jsHint = true;
    resetWith(options: options);
    Source source = addSource("var v = 1 is double;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.IS_DOUBLE]);
    verify([source]);
  }

  @failingTest
  test_isInt() async {
    Source source = addSource("var v = 1 is int;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.IS_INT]);
    verify([source]);
  }

  test_isNotDouble() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.dart2jsHint = true;
    resetWith(options: options);
    Source source = addSource("var v = 1 is! double;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.IS_NOT_DOUBLE]);
    verify([source]);
  }

  @failingTest
  test_isNotInt() async {
    Source source = addSource("var v = 1 is! int;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.IS_NOT_INT]);
    verify([source]);
  }

  test_js_lib_OK() async {
    Source source = addSource(r'''
@JS()
library foo;

import 'package:js/js.dart';

@JS()
class A { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_missingJsLibAnnotation_class() async {
    Source source = addSource(r'''
library foo;

import 'package:js/js.dart';

@JS()
class A { }
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingJsLibAnnotation_externalField() async {
    // https://github.com/dart-lang/sdk/issues/26987
    Source source = addSource(r'''
import 'package:js/js.dart';

@JS()
external dynamic exports;
''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [ParserErrorCode.EXTERNAL_FIELD, HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingJsLibAnnotation_function() async {
    Source source = addSource(r'''
library foo;

import 'package:js/js.dart';

@JS('acxZIndex')
set _currentZIndex(int value) { }
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingJsLibAnnotation_method() async {
    Source source = addSource(r'''
library foo;

import 'package:js/js.dart';

class A {
  @JS()
  void a() { }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingJsLibAnnotation_variable() async {
    Source source = addSource(r'''
import 'package:js/js.dart';

@JS()
dynamic variable;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingReturn_async() async {
    Source source = addSource('''
import 'dart:async';
Future<int> f() async {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_RETURN]);
    verify([source]);
  }

  test_missingReturn_factory() async {
    Source source = addSource(r'''
class A {
  factory A() {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_RETURN]);
    verify([source]);
  }

  test_missingReturn_function() async {
    Source source = addSource("int f() {}");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_RETURN]);
    verify([source]);
  }

  test_missingReturn_method() async {
    Source source = addSource(r'''
class A {
  int m() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_RETURN]);
    verify([source]);
  }

  test_missingReturn_method_inferred() async {
    Source source = addSource(r'''
abstract class A {
  int m();
}
class B extends A {
  m() {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_RETURN]);
    verify([source]);
  }

  test_mustBeImmutable_direct() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  int x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MUST_BE_IMMUTABLE]);
    verify([source]);
  }

  test_mustBeImmutable_directMixin() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
@immutable
mixin A {
  int x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MUST_BE_IMMUTABLE]);
    verify([source]);
  }

  test_mustBeImmutable_extends() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
@immutable
class A {}
class B extends A {
  int x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MUST_BE_IMMUTABLE]);
    verify([source]);
  }

  test_mustBeImmutable_fromMixin() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
@immutable
class A {}
class B {
  int x;
}
class C extends A with B {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MUST_BE_IMMUTABLE]);
    verify([source]);
  }

  test_mustBeImmutable_instance() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  static int x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
    verify([source]);
  }

  test_mustBeImmutable_mixinApplication() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
@immutable
class A {}
class B {
  int x;
}
class C = A with B;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MUST_BE_IMMUTABLE]);
    verify([source]);
  }

  test_mustBeImmutable_mixinApplicationBase() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  int x;
}
class B {}
@immutable
class C = A with B;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MUST_BE_IMMUTABLE]);
    verify([source]);
  }

  test_mustCallSuper() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class B extends A {
  @override
  void a()
  {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MUST_CALL_SUPER]);
    verify([source]);
  }

  test_mustCallSuper_fromInterface() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class C implements A {
  @override
  void a() {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
    verify([source]);
  }

  test_mustCallSuper_indirect() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class C extends A {
  @override
  void a() {
    super.a();
  }
}
class D extends C {
  @override
  void a() {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MUST_CALL_SUPER]);
    verify([source]);
  }

  test_mustCallSuper_overridden() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class C extends A {
  @override
  void a() {
    super.a(); //OK
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
    verify([source]);
  }

  test_mustCallSuper_overridden_w_future() async {
    //https://github.com/flutter/flutter/issues/11646
    Source source = addSource(r'''
import 'dart:async';
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  Future<Null> bar() => new Future<Null>.value();
}
class C extends A {
  @override
  Future<Null> bar() {
    final value = super.bar();
    return value.then((Null _) {
      return null;
    });
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
    verify([source]);
  }

  test_mustCallSuper_overridden_w_future2() async {
    //https://github.com/flutter/flutter/issues/11646
    Source source = addSource(r'''
import 'dart:async';
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  Future<Null> bar() => new Future<Null>.value();
}
class C extends A {
  @override
  Future<Null> bar() {
    return super.bar().then((Null _) {
      return null;
    });
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, []);
    verify([source]);
  }

  test_no_missingReturn_async_futureOrVoid() async {
    Source source = addSource('''
import 'dart:async';
FutureOr<void> f(Future f) async {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_no_missingReturn_async_futureVoid() async {
    Source source = addSource('''
import 'dart:async';
Future<void> f() async {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareBeforeOperator_minus() async {
    Source source = addSource(r'''
m(x) {
  x?.a - '';
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_BEFORE_OPERATOR]);
    verify([source]);
  }

  test_nullAwareBeforeOperator_ok_assignment() async {
    Source source = addSource(r'''
m(x) {
  x?.a = '';
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareBeforeOperator_ok_equal_equal() async {
    Source source = addSource(r'''
m(x) {
  x?.a == '';
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareBeforeOperator_ok_is() async {
    Source source = addSource(r'''
m(x) {
  x?.a is String;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareBeforeOperator_ok_is_not() async {
    Source source = addSource(r'''
m(x) {
  x?.a is! String;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareBeforeOperator_ok_not_equal() async {
    Source source = addSource(r'''
m(x) {
  x?.a != '';
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareBeforeOperator_ok_question_question() async {
    Source source = addSource(r'''
m(x) {
  x?.a ?? true;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareInCondition_assert() async {
    Source source = addSource(r'''
m(x) {
  assert (x?.a);
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInCondition_conditionalExpression() async {
    Source source = addSource(r'''
m(x) {
  return x?.a ? 0 : 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInCondition_do() async {
    Source source = addSource(r'''
m(x) {
  do {} while (x?.a);
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInCondition_for() async {
    Source source = addSource(r'''
m(x) {
  for (var v = x; v?.a; v = v.next) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInCondition_if() async {
    Source source = addSource(r'''
m(x) {
  if (x?.a) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInCondition_if_parenthesized() async {
    Source source = addSource(r'''
m(x) {
  if ((x?.a)) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInCondition_while() async {
    Source source = addSource(r'''
m(x) {
  while (x?.a) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_conditionalAnd_first() async {
    Source source = addSource(r'''
m(x) {
  x?.a && x.b;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_conditionalAnd_second() async {
    Source source = addSource(r'''
m(x) {
  x.a && x?.b;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_conditionalAnd_third() async {
    Source source = addSource(r'''
m(x) {
  x.a && x.b && x?.c;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_conditionalOr_first() async {
    Source source = addSource(r'''
m(x) {
  x?.a || x.b;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_conditionalOr_second() async {
    Source source = addSource(r'''
m(x) {
  x.a || x?.b;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_conditionalOr_third() async {
    Source source = addSource(r'''
m(x) {
  x.a || x.b || x?.c;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_not() async {
    Source source = addSource(r'''
m(x) {
  !x?.a;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  @failingTest
  test_overrideEqualsButNotHashCode() async {
    Source source = addSource(r'''
class A {
  bool operator ==(x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.OVERRIDE_EQUALS_BUT_NOT_HASH_CODE]);
    verify([source]);
  }

  test_overrideOnNonOverridingField_invalid() async {
    Source source = addSource(r'''
class A {
}
class B extends A {
  @override
  final int m = 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD]);
    verify([source]);
  }

  test_overrideOnNonOverridingGetter_invalid() async {
    Source source = addSource(r'''
class A {
}
class B extends A {
  @override
  int get m => 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER]);
    verify([source]);
  }

  test_overrideOnNonOverridingMethod_invalid() async {
    Source source = addSource(r'''
class A {
}
class B extends A {
  @override
  int m() => 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD]);
    verify([source]);
  }

  test_overrideOnNonOverridingSetter_invalid() async {
    Source source = addSource(r'''
class A {
}
class B extends A {
  @override
  set m(int x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER]);
    verify([source]);
  }

  test_required_constructor_param() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required('must specify an `a`') int a}) {}
}

main() {
  new C();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  test_required_constructor_param_no_reason() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int a}) {}
}

main() {
  new C();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM]);
    verify([source]);
  }

  test_required_constructor_param_null_reason() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required(null) int a}) {}
}

main() {
  new C();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM]);
    verify([source]);
  }

  test_required_constructor_param_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int a}) {}
}

main() {
  new C(a: 2);
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_required_constructor_param_redirecting_cons_call() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int x});
  C.named() : this();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM]);
    verify([source]);
  }

  test_required_constructor_param_super_call() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required('must specify an `a`') int a}) {}
}

class D extends C {
  D() : super();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  test_required_function_param() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

void f({@Required('must specify an `a`') int a}) {}

main() {
  f();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  test_required_method_param() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  void m({@Required('must specify an `a`') int a}) {}
}
f() {
  new A().m();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  test_required_method_param_in_other_lib() async {
    addNamedSource('/a_lib.dart', r'''
library a_lib;
import 'package:meta/meta.dart';
class A {
  void m({@Required('must specify an `a`') int a}) {}
}
''');

    Source source = addSource(r'''
import "a_lib.dart";
f() {
  new A().m();
}
''');

    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  test_required_typedef_function_param() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

String test(C c) => c.m()();

typedef String F({@required String x});

class C {
  F m() => ({@required String x}) => null;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM]);
    verify([source]);
  }

  test_strongMode_downCastCompositeHint() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongModeHints = true;
    resetWith(options: options);
    Source source = addSource(r'''
main() {
  List dynamicList = [ ];
  List<int> list = dynamicList;
  print(list);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.DOWN_CAST_COMPOSITE]);
    verify([source]);
  }

  test_strongMode_downCastCompositeNoHint() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongModeHints = false;
    resetWith(options: options);
    Source source = addSource(r'''
main() {
  List dynamicList = [ ];
  List<int> list = dynamicList;
  print(list);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_downCastCompositeWarn() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    applyToAnalysisOptions(
        options,
        wrap({
          AnalyzerOptions.analyzer: {
            AnalyzerOptions.errors: {
              StrongModeCode.DOWN_CAST_COMPOSITE.name: 'warning'
            },
          }
        }));
    options.strongModeHints = false;
    resetWith(options: options);
    Source source = addSource(r'''
main() {
  List dynamicList = [ ];
  List<int> list = dynamicList;
  print(list);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.DOWN_CAST_COMPOSITE]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter() async {
    Source source = addSource('''
class A {
  int get g => 0;
}
var b = new A().g;
''');
    var analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    TopLevelVariableDeclaration b = analysisResult.unit.declarations[1];
    expect(b.variables.variables[0].declaredElement.type.toString(), 'int');
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_call() async {
    Source source = addSource('''
class A {
  int Function() get g => () => 0;
}
var a = new A();
var b = a.g();
''');
    var analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    TopLevelVariableDeclaration b = analysisResult.unit.declarations[2];
    expect(b.variables.variables[0].declaredElement.type.toString(), 'int');
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_field() async {
    Source source = addSource('''
class A {
  int g;
}
var b = new A().g;
''');
    var analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    TopLevelVariableDeclaration b = analysisResult.unit.declarations[1];
    expect(b.variables.variables[0].declaredElement.type.toString(), 'int');
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_field_call() async {
    Source source = addSource('''
class A {
  int Function() g;
}
var a = new A();
var b = a.g();
''');
    var analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    TopLevelVariableDeclaration b = analysisResult.unit.declarations[2];
    expect(b.variables.variables[0].declaredElement.type.toString(), 'int');
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_field_prefixedIdentifier() async {
    Source source = addSource('''
class A {
  int g;
}
var a = new A();
var b = a.g;
''');
    var analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    TopLevelVariableDeclaration b = analysisResult.unit.declarations[2];
    expect(b.variables.variables[0].declaredElement.type.toString(), 'int');
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped() async {
    Source source = addSource('''
class A {
  get g => 0;
}
var b = new A().g;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_call() async {
    Source source = addSource('''
class A {
  get g => () => 0;
}
var a = new A();
var b = a.g();
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_field() async {
    Source source = addSource('''
class A {
  var g = 0;
}
var b = new A().g;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_field_call() async {
    Source source = addSource('''
class A {
  var g = () => 0;
}
var a = new A();
var b = a.g();
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_field_prefixedIdentifier() async {
    Source source = addSource('''
class A {
  var g = 0;
}
var a = new A();
var b = a.g;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_fn() async {
    Source source = addSource('''
class A {
  var x = 0;
}
int f<T>(x) => 0;
var a = new A();
var b = f(a.x);
''');
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because f is
    // generic, so the type of a.x might affect the type of b.
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_fn_explicit_type_params() async {
    Source source = addSource('''
class A {
  var x = 0;
}
int f<T>(x) => 0;
var a = new A();
var b = f<int>(a.x);
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_fn_not_generic() async {
    Source source = addSource('''
class A {
  var x = 0;
}
int f(x) => 0;
var a = new A();
var b = f(a.x);
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_indexExpression() async {
    Source source = addSource('''
class A {
  var x = 0;
  int operator[](int value) => 0;
}
var a = new A();
var b = a[a.x];
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_invoke() async {
    Source source = addSource('''
class A {
  var x = 0;
}
var a = new A();
var b = (<T>(y) => 0)(a.x);
''');
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because the
    // closure is generic, so the type of a.x might affect the type of b.
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_invoke_explicit_type_params() async {
    Source source = addSource('''
class A {
  var x = 0;
}
var a = new A();
var b = (<T>(y) => 0)<int>(a.x);
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_invoke_not_generic() async {
    Source source = addSource('''
class A {
  var x = 0;
}
var a = new A();
var b = ((y) => 0)(a.x);
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_method() async {
    Source source = addSource('''
class A {
  var x = 0;
  int f<T>(int x) => 0;
}
var a = new A();
var b = a.f(a.x);
''');
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because f is
    // generic, so the type of a.x might affect the type of b.
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_method_explicit_type_params() async {
    Source source = addSource('''
class A {
  var x = 0;
  int f<T>(x) => 0;
}
var a = new A();
var b = a.f<int>(a.x);
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_method_not_generic() async {
    Source source = addSource('''
class A {
  var x = 0;
  int f(x) => 0;
}
var a = new A();
var b = a.f(a.x);
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_new() async {
    Source source = addSource('''
class A {
  var x = 0;
}
class B<T> {
  B(x);
}
var a = new A();
var b = new B(a.x);
''');
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because B is
    // generic, so the type of a.x might affect the type of b.
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_explicit_type_params() async {
    Source source = addSource('''
class A {
  var x = 0;
}
class B<T> {
  B(x);
}
var a = new A();
var b = new B<int>(a.x);
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_explicit_type_params_named() async {
    Source source = addSource('''
class A {
  var x = 0;
}
class B<T> {
  B.named(x);
}
var a = new A();
var b = new B<int>.named(a.x);
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_explicit_type_params_prefixed() async {
    addNamedSource('/lib1.dart', '''
class B<T> {
  B(x);
}
''');
    Source source = addSource('''
import 'lib1.dart' as foo;
class A {
  var x = 0;
}
var a = new A();
var b = new foo.B<int>(a.x);
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_named() async {
    Source source = addSource('''
class A {
  var x = 0;
}
class B<T> {
  B.named(x);
}
var a = new A();
var b = new B.named(a.x);
''');
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because B is
    // generic, so the type of a.x might affect the type of b.
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_not_generic() async {
    Source source = addSource('''
class A {
  var x = 0;
}
class B {
  B(x);
}
var a = new A();
var b = new B(a.x);
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_not_generic_named() async {
    Source source = addSource('''
class A {
  var x = 0;
}
class B {
  B.named(x);
}
var a = new A();
var b = new B.named(a.x);
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_not_generic_prefixed() async {
    addNamedSource('/lib1.dart', '''
class B {
  B(x);
}
''');
    Source source = addSource('''
import 'lib1.dart' as foo;
class A {
  var x = 0;
}
var a = new A();
var b = new foo.B(a.x);
''');
    // The reference to a.x does not trigger TOP_LEVEL_INSTANCE_GETTER because
    // it can't possibly affect the type of b.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_prefixed() async {
    addNamedSource('/lib1.dart', '''
class B<T> {
  B(x);
}
''');
    Source source = addSource('''
import 'lib1.dart' as foo;
class A {
  var x = 0;
}
var a = new A();
var b = new foo.B(a.x);
''');
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because B is
    // generic, so the type of a.x might affect the type of b.
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_prefixedIdentifier() async {
    Source source = addSource('''
class A {
  get g => 0;
}
var a = new A();
var b = a.g;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_implicitlyTyped_propertyAccessLhs() async {
    Source source = addSource('''
class A {
  var x = new B();
  int operator[](int value) => 0;
}
class B {
  int y;
}
var a = new A();
var b = (a.x).y;
''');
    // The reference to a.x triggers TOP_LEVEL_INSTANCE_GETTER because the type
    // of a.x affects the lookup of y, which in turn affects the type of b.
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_GETTER]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceGetter_prefixedIdentifier() async {
    Source source = addSource('''
class A {
  int get g => 0;
}
var a = new A();
var b = a.g;
''');
    var analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    TopLevelVariableDeclaration b = analysisResult.unit.declarations[2];
    expect(b.variables.variables[0].declaredElement.type.toString(), 'int');
    verify([source]);
  }

  test_strongMode_topLevelInstanceMethod() async {
    Source source = addSource('''
class A {
  f() => 0;
}
var x = new A().f();
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_METHOD]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceMethod_parameter() async {
    Source source = addSource('''
class A {
  int f(v) => 0;
}
var x = new A().f(0);
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceMethod_parameter_generic() async {
    Source source = addSource('''
class A {
  int f<T>(v) => 0;
}
var x = new A().f(0);
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_METHOD]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceMethod_parameter_generic_explicit() async {
    Source source = addSource('''
class A {
  int f<T>(v) => 0;
}
var x = new A().f<int>(0);
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceMethod_static() async {
    Source source = addSource('''
class A {
  static f() => 0;
}
var x = A.f();
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_topLevelInstanceMethod_tearoff() async {
    Source source = addSource('''
class A {
  f() => 0;
}
var x = new A().f;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_METHOD]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceMethod_tearoff_parameter() async {
    Source source = addSource('''
class A {
  int f(v) => 0;
}
var x = new A().f;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.TOP_LEVEL_INSTANCE_METHOD]);
    verify([source]);
  }

  test_strongMode_topLevelInstanceMethod_tearoff_static() async {
    Source source = addSource('''
class A {
  static f() => 0;
}
var x = A.f;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeCheck_type_is_Null() async {
    Source source = addSource(r'''
m(i) {
  bool b = i is Null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.TYPE_CHECK_IS_NULL]);
    verify([source]);
  }

  test_typeCheck_type_not_Null() async {
    Source source = addSource(r'''
m(i) {
  bool b = i is! Null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.TYPE_CHECK_IS_NOT_NULL]);
    verify([source]);
  }

  test_undefinedGetter() async {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    return a.m;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  test_undefinedIdentifier_exportHide() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart' hide a;''');
    addNamedSource("/lib1.dart", "library lib1;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNDEFINED_HIDDEN_NAME]);
    verify([source]);
  }

  test_undefinedIdentifier_exportShow() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart' show a;''');
    addNamedSource("/lib1.dart", "library lib1;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNDEFINED_SHOWN_NAME]);
    verify([source]);
  }

  test_undefinedIdentifier_importHide() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' hide a;''');
    addNamedSource("/lib1.dart", "library lib1;");
    await computeAnalysisResult(source);
    assertErrors(
        source, [HintCode.UNUSED_IMPORT, HintCode.UNDEFINED_HIDDEN_NAME]);
    verify([source]);
  }

  test_undefinedIdentifier_importShow() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' show a;''');
    addNamedSource("/lib1.dart", "library lib1;");
    await computeAnalysisResult(source);
    assertErrors(
        source, [HintCode.UNUSED_IMPORT, HintCode.UNDEFINED_SHOWN_NAME]);
    verify([source]);
  }

  test_undefinedOperator_binaryExpression() async {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a + 1;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_undefinedOperator_indexBoth() async {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a[0]++;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      StaticTypeWarningCode.UNDEFINED_OPERATOR,
      StaticTypeWarningCode.UNDEFINED_OPERATOR,
    ]);
  }

  test_undefinedOperator_indexGetter() async {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a[0];
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_undefinedOperator_indexSetter() async {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a[0] = 1;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_undefinedOperator_postfixExpression() async {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a++;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedOperator_prefixExpression() async {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    ++a;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_undefinedSetter() async {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a.m = 0;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_SETTER]);
  }

  test_unnecessaryNoSuchMethod_blockBody() async {
    Source source = addSource(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) {
    return super.noSuchMethod(y);
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNNECESSARY_NO_SUCH_METHOD]);
    verify([source]);
  }

  test_unnecessaryNoSuchMethod_expressionBody() async {
    Source source = addSource(r'''
class A {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B extends A {
  mmm();
  noSuchMethod(y) => super.noSuchMethod(y);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNNECESSARY_NO_SUCH_METHOD]);
    verify([source]);
  }

  test_unnecessaryTypeCheck_null_is_Null() async {
    Source source = addSource("bool b = null is Null;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_TRUE]);
    verify([source]);
  }

  test_unnecessaryTypeCheck_null_not_Null() async {
    Source source = addSource("bool b = null is! Null;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_FALSE]);
    verify([source]);
  }

  test_unnecessaryTypeCheck_type_is_dynamic() async {
    Source source = addSource(r'''
m(i) {
  bool b = i is dynamic;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_TRUE]);
    verify([source]);
  }

  test_unnecessaryTypeCheck_type_is_object() async {
    Source source = addSource(r'''
m(i) {
  bool b = i is Object;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_TRUE]);
    verify([source]);
  }

  test_unnecessaryTypeCheck_type_not_dynamic() async {
    Source source = addSource(r'''
m(i) {
  bool b = i is! dynamic;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_FALSE]);
    verify([source]);
  }

  test_unnecessaryTypeCheck_type_not_object() async {
    Source source = addSource(r'''
m(i) {
  bool b = i is! Object;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_FALSE]);
    verify([source]);
  }

  test_unusedElement_class_isUsed_extends() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
class B extends _A {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_class_isUsed_fieldDeclaration() async {
    enableUnusedElement = true;
    var src = r'''
class Foo {
  _Bar x;
}

class _Bar {
}
''';
    Source source = addSource(src);
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_class_isUsed_implements() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
class B implements _A {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_class_isUsed_instanceCreation() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main() {
  new _A();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_class_isUsed_staticFieldAccess() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {
  static const F = 42;
}
main() {
  _A.F;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_class_isUsed_staticMethodInvocation() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {
  static m() {}
}
main() {
  _A.m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_class_isUsed_typeArgument() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main() {
  var v = new List<_A>();
  print(v);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_class_notUsed_inClassMember() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {
  static staticMethod() {
    new _A();
  }
  instanceMethod() {
    new _A();
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_class_notUsed_inConstructorName() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {
  _A() {}
  _A.named() {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_class_notUsed_isExpression() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main(p) {
  if (p is _A) {
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_class_notUsed_noReference() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_class_notUsed_variableDeclaration() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main() {
  _A v;
  print(v);
}
print(x) {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_enum_isUsed_fieldReference() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
enum _MyEnum {A, B, C}
main() {
  print(_MyEnum.B);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_enum_notUsed_noReference() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
enum _MyEnum {A, B, C}
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_functionLocal_isUsed_closure() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  print(() {});
}
print(x) {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_functionLocal_isUsed_invocation() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  f() {}
  f();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_functionLocal_isUsed_reference() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  f() {}
  print(f);
}
print(x) {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_functionLocal_notUsed_noReference() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  f() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_functionLocal_notUsed_referenceFromItself() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  _f(int p) {
    _f(p - 1);
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_functionTop_isUsed_invocation() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
_f() {}
main() {
  _f();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_functionTop_isUsed_reference() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
_f() {}
main() {
  print(_f);
}
print(x) {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_functionTop_notUsed_noReference() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
_f() {}
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_functionTop_notUsed_referenceFromItself() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
_f(int p) {
  _f(p - 1);
}
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_functionTypeAlias_isUsed_isExpression() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
typedef _F(a, b);
main(f) {
  if (f is _F) {
    print('F');
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_functionTypeAlias_isUsed_reference() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
typedef _F(a, b);
main(_F f) {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_functionTypeAlias_isUsed_typeArgument() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
typedef _F(a, b);
main() {
  var v = new List<_F>();
  print(v);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_functionTypeAlias_isUsed_variableDeclaration() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
typedef _F(a, b);
class A {
  _F f;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_functionTypeAlias_notUsed_noReference() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
typedef _F(a, b);
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_getter_isUsed_invocation_implicitThis() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g => null;
  useGetter() {
    var v = _g;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_getter_isUsed_invocation_PrefixedIdentifier() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g => null;
}
main(A a) {
  var v = a._g;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_getter_isUsed_invocation_PropertyAccess() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g => null;
}
main() {
  var v = new A()._g;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_getter_notUsed_noReference() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_getter_notUsed_referenceFromItself() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g {
    return _g;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_method_isUsed_hasReference_implicitThis() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
  useMethod() {
    print(_m);
  }
}
print(x) {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_method_isUsed_hasReference_implicitThis_subclass() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
  useMethod() {
    print(_m);
  }
}
class B extends A {
  _m() {}
}
print(x) {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_method_isUsed_hasReference_PrefixedIdentifier() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
main(A a) {
  a._m;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_method_isUsed_hasReference_PropertyAccess() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
main() {
  new A()._m;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_method_isUsed_invocation_implicitThis() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
  useMethod() {
    _m();
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_method_isUsed_invocation_implicitThis_subclass() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
  useMethod() {
    _m();
  }
}
class B extends A {
  _m() {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_method_isUsed_invocation_MemberElement() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A<T> {
  _m(T t) {}
}
main(A<int> a) {
  a._m(0);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_method_isUsed_invocation_propagated() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
main() {
  var a = new A();
  a._m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_method_isUsed_invocation_static() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
main() {
  A a = new A();
  a._m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_method_isUsed_invocation_subclass() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
class B extends A {
  _m() {}
}
main(A a) {
  a._m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_method_isUsed_notPrivate() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  m() {}
}
main() {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_method_isUsed_staticInvocation() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  static _m() {}
}
main() {
  A._m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_method_notUsed_noReference() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  static _m() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_method_notUsed_referenceFromItself() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  static _m(int p) {
    _m(p - 1);
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_setter_isUsed_invocation_implicitThis() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(x) {}
  useSetter() {
    _s = 42;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_setter_isUsed_invocation_PrefixedIdentifier() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(x) {}
}
main(A a) {
  a._s = 42;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_setter_isUsed_invocation_PropertyAccess() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(x) {}
}
main() {
  new A()._s = 42;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_setter_notUsed_noReference() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_setter_notUsed_referenceFromItself() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(int x) {
    if (x > 5) {
      _s = x - 1;
    }
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedElement_topLevelVariable_isUsed() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
int _a = 1;
main() {
  _a;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_topLevelVariable_isUsed_plusPlus() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
int _a = 0;
main() {
  var b = _a++;
  b;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedElement_topLevelVariable_notUsed() async {
    enableUnusedElement = true;
    Source source = addSource(r'''
int _a = 1;
main() {
  _a = 2;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  test_unusedLocalVariable_inCatch_exception() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } on String catch (exception) {
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_CATCH_CLAUSE]);
    verify([source]);
  }

  test_unusedLocalVariable_inCatch_exception_hasStack() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } catch (exception, stack) {
    print(stack);
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedLocalVariable_inCatch_exception_noOnClause() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } catch (exception) {
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedLocalVariable_inCatch_stackTrace() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } catch (exception, stackTrace) {
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_CATCH_STACK]);
    verify([source]);
  }

  test_unusedLocalVariable_inCatch_stackTrace_used() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } catch (exception, stackTrace) {
    print('exception at $stackTrace');
  }
}
print(x) {}''');
    await computeAnalysisResult(source);
    assertErrors(source);
    verify([source]);
  }

  test_unusedLocalVariable_inFor_underscore_ignored() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  for (var _ in [1,2,3]) {
    for (var __ in [4,5,6]) {
      // do something
    }
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source);
    verify([source]);
  }

  test_unusedLocalVariable_inFunction() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  v = 2;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  test_unusedLocalVariable_inMethod() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
class A {
  foo() {
    var v = 1;
    v = 2;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  test_unusedLocalVariable_isInvoked() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
typedef Foo();
main() {
  Foo foo;
  foo();
}''');
    await computeAnalysisResult(source);
    assertErrors(source);
    verify([source]);
  }

  test_unusedLocalVariable_isNullAssigned() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
typedef Foo();
main() {
  var v;
  v ??= doSomething();
}
doSomething() => 42;
''');
    await computeAnalysisResult(source);
    assertErrors(source);
    verify([source]);
  }

  test_unusedLocalVariable_isRead_notUsed_compoundAssign() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  v += 2;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  test_unusedLocalVariable_isRead_notUsed_postfixExpr() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  v++;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  test_unusedLocalVariable_isRead_notUsed_prefixExpr() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  ++v;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  test_unusedLocalVariable_isRead_usedArgument() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  print(++v);
}
print(x) {}''');
    await computeAnalysisResult(source);
    assertErrors(source);
    verify([source]);
  }

  test_unusedLocalVariable_isRead_usedInvocationTarget() async {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
class A {
  foo() {}
}
main() {
  var a = new A();
  a.foo();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source);
    verify([source]);
  }
}
