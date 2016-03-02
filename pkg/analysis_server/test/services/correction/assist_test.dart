// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction.assist;

import 'dart:async';

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_single_unit.dart';
import '../../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(AssistProcessorTest);
}

@reflectiveTest
class AssistProcessorTest extends AbstractSingleUnitTest {
  int offset;
  int length;

  ServerPlugin plugin;
  Assist assist;
  SourceChange change;
  String resultCode;
  LinkedEditGroup linkedPositionGroup;

  /**
   * Asserts that there is an [Assist] of the given [kind] at [offset] which
   * produces the [expected] code when applied to [testCode].
   */
  assertHasAssist(AssistKind kind, String expected) async {
    assist = await _assertHasAssist(kind);
    change = assist.change;
    // apply to "file"
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    resultCode = SourceEdit.applySequence(testCode, change.edits[0].edits);
    // verify
    expect(resultCode, expected);
  }

  /**
   * Calls [assertHasAssist] at the offset of [offsetSearch] in [testCode].
   */
  assertHasAssistAt(
      String offsetSearch, AssistKind kind, String expected) async {
    offset = findOffset(offsetSearch);
    await assertHasAssist(kind, expected);
  }

  /**
   * Asserts that there is no [Assist] of the given [kind] at [offset].
   */
  assertNoAssist(AssistKind kind) async {
    List<Assist> assists = await computeAssists(
        plugin, context, testUnit.element.source, offset, length);
    for (Assist assist in assists) {
      if (assist.kind == kind) {
        throw fail('Unexpected assist $kind in\n${assists.join('\n')}');
      }
    }
  }

  /**
   * Calls [assertNoAssist] at the offset of [offsetSearch] in [testCode].
   */
  assertNoAssistAt(String offsetSearch, AssistKind kind) async {
    offset = findOffset(offsetSearch);
    await assertNoAssist(kind);
  }

  Position expectedPosition(String search) {
    int offset = resultCode.indexOf(search);
    return new Position(testFile, offset);
  }

  List<Position> expectedPositions(List<String> patterns) {
    List<Position> positions = <Position>[];
    patterns.forEach((String search) {
      positions.add(expectedPosition(search));
    });
    return positions;
  }

  List<LinkedEditSuggestion> expectedSuggestions(
      LinkedEditSuggestionKind kind, List<String> values) {
    return values.map((value) {
      return new LinkedEditSuggestion(value, kind);
    }).toList();
  }

  void processRequiredPlugins() {
    plugin = new ServerPlugin();

    List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);
    plugins.add(plugin);

    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);
  }

  void setUp() {
    super.setUp();
    offset = 0;
    length = 0;
  }

  test_addTypeAnnotation_BAD_privateType_closureParameter() async {
    addSource(
        '/my_lib.dart',
        '''
library my_lib;
class A {}
class _B extends A {}
foo(f(_B p)) {}
''');
    resolveTestUnit('''
import 'my_lib.dart';
main() {
  foo((test) {});
}
 ''');
    await assertNoAssistAt('test)', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_BAD_privateType_declaredIdentifier() async {
    addSource(
        '/my_lib.dart',
        '''
library my_lib;
class A {}
class _B extends A {}
List<_B> getValues() => [];
''');
    resolveTestUnit('''
import 'my_lib.dart';
class A<T> {
  main() {
    for (var item in getValues()) {
    }
  }
}
''');
    await assertNoAssistAt('var item', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_BAD_privateType_list() async {
    addSource(
        '/my_lib.dart',
        '''
library my_lib;
class A {}
class _B extends A {}
List<_B> getValues() => [];
''');
    resolveTestUnit('''
import 'my_lib.dart';
main() {
  var v = getValues();
}
''');
    await assertNoAssistAt('var ', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_BAD_privateType_variable() async {
    addSource(
        '/my_lib.dart',
        '''
library my_lib;
class A {}
class _B extends A {}
_B getValue() => new _B();
''');
    resolveTestUnit('''
import 'my_lib.dart';
main() {
  var v = getValue();
}
''');
    await assertNoAssistAt('var ', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_classField_OK_final() async {
    resolveTestUnit('''
class A {
  final f = 0;
}
''');
    await assertHasAssistAt(
        'final ',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
class A {
  final int f = 0;
}
''');
  }

  test_addTypeAnnotation_classField_OK_int() async {
    resolveTestUnit('''
class A {
  var f = 0;
}
''');
    await await assertHasAssistAt(
        'var ',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
class A {
  int f = 0;
}
''');
  }

  test_addTypeAnnotation_declaredIdentifier_BAD_hasTypeAnnotation() async {
    resolveTestUnit('''
main(List<String> items) {
  for (String item in items) {
  }
}
''');
    await assertNoAssistAt('item in', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_declaredIdentifier_BAD_inForEachBody() async {
    resolveTestUnit('''
main(List<String> items) {
  for (var item in items) {
    42;
  }
}
''');
    await assertNoAssistAt('42;', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_declaredIdentifier_BAD_unknownType() async {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
main() {
  for (var item in unknownList) {
  }
}
''');
    await assertNoAssistAt('item in', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_declaredIdentifier_generic_OK() async {
    resolveTestUnit('''
class A<T> {
  main(List<List<T>> items) {
    for (var item in items) {
    }
  }
}
''');
    await assertHasAssistAt(
        'item in',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
class A<T> {
  main(List<List<T>> items) {
    for (List<T> item in items) {
    }
  }
}
''');
  }

  test_addTypeAnnotation_declaredIdentifier_OK() async {
    resolveTestUnit('''
main(List<String> items) {
  for (var item in items) {
  }
}
''');
    // on identifier
    await assertHasAssistAt(
        'item in',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
main(List<String> items) {
  for (String item in items) {
  }
}
''');
    // on "for"
    await assertHasAssistAt(
        'for (',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
main(List<String> items) {
  for (String item in items) {
  }
}
''');
  }

  test_addTypeAnnotation_declaredIdentifier_OK_addImport_dartUri() async {
    addSource(
        '/my_lib.dart',
        r'''
import 'dart:async';
List<Future<int>> getFutures() => null;
''');
    resolveTestUnit('''
import 'my_lib.dart';
main() {
  for (var future in getFutures()) {
  }
}
''');
    await assertHasAssistAt(
        'future in',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
import 'my_lib.dart';
import 'dart:async';
main() {
  for (Future<int> future in getFutures()) {
  }
}
''');
  }

  test_addTypeAnnotation_declaredIdentifier_OK_final() async {
    resolveTestUnit('''
main(List<String> items) {
  for (final item in items) {
  }
}
''');
    await assertHasAssistAt(
        'item in',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
main(List<String> items) {
  for (final String item in items) {
  }
}
''');
  }

  test_addTypeAnnotation_local_BAD_hasTypeAnnotation() async {
    resolveTestUnit('''
main() {
  int v = 42;
}
''');
    await assertNoAssistAt(' = 42', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_local_BAD_multiple() async {
    resolveTestUnit('''
main() {
  var a = 1, b = '';
}
''');
    await assertNoAssistAt('var ', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_local_BAD_noValue() async {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
main() {
  var v;
}
''');
    await assertNoAssistAt('var ', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_local_BAD_null() async {
    resolveTestUnit('''
main() {
  var v = null;
}
''');
    await assertNoAssistAt('var ', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_local_BAD_onInitializer() async {
    resolveTestUnit('''
main() {
  var abc = 0;
}
''');
    await assertNoAssistAt('0;', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_local_BAD_unknown() async {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
main() {
  var v = unknownVar;
}
''');
    await assertNoAssistAt('var ', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_local_generic_OK_literal() async {
    resolveTestUnit('''
class A {
  main(List<int> items) {
    var v = items;
  }
}
''');
    await assertHasAssistAt(
        'v =',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
class A {
  main(List<int> items) {
    List<int> v = items;
  }
}
''');
  }

  test_addTypeAnnotation_local_generic_OK_local() async {
    resolveTestUnit('''
class A<T> {
  main(List<T> items) {
    var v = items;
  }
}
''');
    await assertHasAssistAt(
        'v =',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
class A<T> {
  main(List<T> items) {
    List<T> v = items;
  }
}
''');
  }

  test_addTypeAnnotation_local_OK_addImport_dartUri() async {
    addSource(
        '/my_lib.dart',
        r'''
import 'dart:async';
Future<int> getFutureInt() => null;
''');
    resolveTestUnit('''
import 'my_lib.dart';
main() {
  var v = getFutureInt();
}
''');
    await assertHasAssistAt(
        'v =',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
import 'my_lib.dart';
import 'dart:async';
main() {
  Future<int> v = getFutureInt();
}
''');
  }

  test_addTypeAnnotation_local_OK_addImport_notLibraryUnit() async {
    // prepare library
    addSource(
        '/my_lib.dart',
        r'''
import 'dart:async';
Future<int> getFutureInt() => null;
''');
    // prepare code
    String appCode = r'''
library my_app;
import 'my_lib.dart';
part 'test.dart';
''';
    testCode = r'''
part of my_app;
main() {
  var v = getFutureInt();
}
''';
    // add sources
    Source appSource = addSource('/app.dart', appCode);
    testSource = addSource('/test.dart', testCode);
    // resolve
    context.resolveCompilationUnit2(appSource, appSource);
    testUnit = context.resolveCompilationUnit2(testSource, appSource);
    assertNoErrorsInSource(testSource);
    testUnitElement = testUnit.element;
    testLibraryElement = testUnitElement.library;
    // prepare the assist
    offset = findOffset('v = ');
    assist = await _assertHasAssist(DartAssistKind.ADD_TYPE_ANNOTATION);
    change = assist.change;
    // verify
    {
      var testFileEdit = change.getFileEdit('/app.dart');
      var resultCode = SourceEdit.applySequence(appCode, testFileEdit.edits);
      expect(
          resultCode,
          '''
library my_app;
import 'my_lib.dart';
import 'dart:async';
part 'test.dart';
''');
    }
    {
      var testFileEdit = change.getFileEdit('/test.dart');
      var resultCode = SourceEdit.applySequence(testCode, testFileEdit.edits);
      expect(
          resultCode,
          '''
part of my_app;
main() {
  Future<int> v = getFutureInt();
}
''');
    }
  }

  test_addTypeAnnotation_local_OK_addImport_relUri() async {
    addSource(
        '/aa/bbb/lib_a.dart',
        r'''
class MyClass {}
''');
    addSource(
        '/ccc/lib_b.dart',
        r'''
import '../aa/bbb/lib_a.dart';
MyClass newMyClass() => null;
''');
    resolveTestUnit('''
import 'ccc/lib_b.dart';
main() {
  var v = newMyClass();
}
''');
    await assertHasAssistAt(
        'v =',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
import 'ccc/lib_b.dart';
import 'aa/bbb/lib_a.dart';
main() {
  MyClass v = newMyClass();
}
''');
  }

  test_addTypeAnnotation_local_OK_Function() async {
    resolveTestUnit('''
main() {
  var v = () => 1;
}
''');
    await assertHasAssistAt(
        'v =',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
main() {
  Function v = () => 1;
}
''');
  }

  test_addTypeAnnotation_local_OK_int() async {
    resolveTestUnit('''
main() {
  var v = 0;
}
''');
    await assertHasAssistAt(
        'v =',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
main() {
  int v = 0;
}
''');
  }

  test_addTypeAnnotation_local_OK_List() async {
    resolveTestUnit('''
main() {
  var v = <String>[];
}
''');
    await assertHasAssistAt(
        'v =',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
main() {
  List<String> v = <String>[];
}
''');
  }

  test_addTypeAnnotation_local_OK_localType() async {
    resolveTestUnit('''
class C {}
C f() => null;
main() {
  var x = f();
}
''');
    await assertHasAssistAt(
        'x =',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
class C {}
C f() => null;
main() {
  C x = f();
}
''');
  }

  test_addTypeAnnotation_local_OK_onName() async {
    resolveTestUnit('''
main() {
  var abc = 0;
}
''');
    await assertHasAssistAt(
        'bc',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
main() {
  int abc = 0;
}
''');
  }

  test_addTypeAnnotation_local_OK_onVar() async {
    resolveTestUnit('''
main() {
  var v = 0;
}
''');
    await assertHasAssistAt(
        'var ',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
main() {
  int v = 0;
}
''');
  }

  test_addTypeAnnotation_OK_privateType_sameLibrary() async {
    resolveTestUnit('''
class _A {}
_A getValue() => new _A();
main() {
  var v = getValue();
}
''');
    await assertHasAssistAt(
        'var ',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
class _A {}
_A getValue() => new _A();
main() {
  _A v = getValue();
}
''');
  }

  test_addTypeAnnotation_parameter_BAD_hasExplicitType() async {
    resolveTestUnit('''
foo(f(int p)) {}
main() {
  foo((num test) {});
}
''');
    await assertNoAssistAt('test', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_parameter_BAD_noPropagatedType() async {
    resolveTestUnit('''
foo(f(p)) {}
main() {
  foo((test) {});
}
''');
    await assertNoAssistAt('test', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_parameter_OK() async {
    resolveTestUnit('''
foo(f(int p)) {}
main() {
  foo((test) {});
}
''');
    await assertHasAssistAt(
        'test',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
foo(f(int p)) {}
main() {
  foo((int test) {});
}
''');
  }

  test_addTypeAnnotation_topLevelField_BAD_multiple() async {
    resolveTestUnit('''
var A = 1, V = '';
''');
    await assertNoAssistAt('var ', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_topLevelField_BAD_noValue() async {
    resolveTestUnit('''
var V;
''');
    await assertNoAssistAt('var ', DartAssistKind.ADD_TYPE_ANNOTATION);
  }

  test_addTypeAnnotation_topLevelField_OK_int() async {
    resolveTestUnit('''
var V = 0;
''');
    await assertHasAssistAt(
        'var ',
        DartAssistKind.ADD_TYPE_ANNOTATION,
        '''
int V = 0;
''');
  }

  test_assignToLocalVariable() async {
    resolveTestUnit('''
main() {
  List<int> bytes;
  readBytes();
}
List<int> readBytes() => <int>[];
''');
    await assertHasAssistAt(
        'readBytes();',
        DartAssistKind.ASSIGN_TO_LOCAL_VARIABLE,
        '''
main() {
  List<int> bytes;
  var readBytes = readBytes();
}
List<int> readBytes() => <int>[];
''');
    _assertLinkedGroup(
        change.linkedEditGroups[0],
        ['readBytes = '],
        expectedSuggestions(LinkedEditSuggestionKind.VARIABLE,
            ['list', 'bytes2', 'readBytes']));
  }

  test_assignToLocalVariable_alreadyAssignment() async {
    resolveTestUnit('''
main() {
  var vvv;
  vvv = 42;
}
''');
    await assertNoAssistAt('vvv =', DartAssistKind.ASSIGN_TO_LOCAL_VARIABLE);
  }

  test_assignToLocalVariable_inClosure() async {
    resolveTestUnit(r'''
main() {
  print(() {
    12345;
  });
}
''');
    await assertHasAssistAt(
        '345',
        DartAssistKind.ASSIGN_TO_LOCAL_VARIABLE,
        '''
main() {
  print(() {
    var i = 12345;
  });
}
''');
  }

  test_assignToLocalVariable_invocationArgument() async {
    resolveTestUnit(r'''
main() {
  f(12345);
}
int f(p) {}
''');
    await assertNoAssistAt('345', DartAssistKind.ASSIGN_TO_LOCAL_VARIABLE);
  }

  test_assignToLocalVariable_throw() async {
    resolveTestUnit('''
main() {
  throw 42;
}
''');
    await assertNoAssistAt('throw ', DartAssistKind.ASSIGN_TO_LOCAL_VARIABLE);
  }

  test_assignToLocalVariable_void() async {
    resolveTestUnit('''
main() {
  f();
}
void f() {}
''');
    await assertNoAssistAt('f();', DartAssistKind.ASSIGN_TO_LOCAL_VARIABLE);
  }

  test_convertDocumentationIntoBlock_BAD_alreadyBlock() async {
    resolveTestUnit('''
/**
 * AAAAAAA
 */
class A {}
''');
    await assertNoAssistAt(
        'AAA', DartAssistKind.CONVERT_DOCUMENTATION_INTO_BLOCK);
  }

  test_convertDocumentationIntoBlock_BAD_notDocumentation() async {
    resolveTestUnit('''
// AAAA
class A {}
''');
    await assertNoAssistAt(
        'AAA', DartAssistKind.CONVERT_DOCUMENTATION_INTO_BLOCK);
  }

  test_convertDocumentationIntoBlock_OK_noSpaceBeforeText() async {
    resolveTestUnit('''
class A {
  /// AAAAA
  ///BBBBB
  ///
  /// CCCCC
  mmm() {}
}
''');
    await assertHasAssistAt(
        'AAAAA',
        DartAssistKind.CONVERT_DOCUMENTATION_INTO_BLOCK,
        '''
class A {
  /**
   * AAAAA
   *BBBBB
   *
   * CCCCC
   */
  mmm() {}
}
''');
  }

  test_convertDocumentationIntoBlock_OK_onReference() async {
    resolveTestUnit('''
/// AAAAAAA [int] AAAAAAA
class A {}
''');
    await assertHasAssistAt(
        'nt]',
        DartAssistKind.CONVERT_DOCUMENTATION_INTO_BLOCK,
        '''
/**
 * AAAAAAA [int] AAAAAAA
 */
class A {}
''');
  }

  test_convertDocumentationIntoBlock_OK_onText() async {
    resolveTestUnit('''
class A {
  /// AAAAAAA [int] AAAAAAA
  /// BBBBBBBB BBBB BBBB
  /// CCC [A] CCCCCCCCCCC
  mmm() {}
}
''');
    await assertHasAssistAt(
        'AAA [',
        DartAssistKind.CONVERT_DOCUMENTATION_INTO_BLOCK,
        '''
class A {
  /**
   * AAAAAAA [int] AAAAAAA
   * BBBBBBBB BBBB BBBB
   * CCC [A] CCCCCCCCCCC
   */
  mmm() {}
}
''');
  }

  test_convertDocumentationIntoLine_BAD_alreadyLine() async {
    resolveTestUnit('''
/// AAAAAAA
class A {}
''');
    await assertNoAssistAt(
        'AAA', DartAssistKind.CONVERT_DOCUMENTATION_INTO_LINE);
  }

  test_convertDocumentationIntoLine_BAD_notDocumentation() async {
    resolveTestUnit('''
/* AAAA */
class A {}
''');
    await assertNoAssistAt(
        'AAA', DartAssistKind.CONVERT_DOCUMENTATION_INTO_LINE);
  }

  test_convertDocumentationIntoLine_OK_onReference() async {
    resolveTestUnit('''
/**
 * AAAAAAA [int] AAAAAAA
 */
class A {}
''');
    await assertHasAssistAt(
        'nt]',
        DartAssistKind.CONVERT_DOCUMENTATION_INTO_LINE,
        '''
/// AAAAAAA [int] AAAAAAA
class A {}
''');
  }

  test_convertDocumentationIntoLine_OK_onText() async {
    resolveTestUnit('''
class A {
  /**
   * AAAAAAA [int] AAAAAAA
   * BBBBBBBB BBBB BBBB
   * CCC [A] CCCCCCCCCCC
   */
  mmm() {}
}
''');
    await assertHasAssistAt(
        'AAA [',
        DartAssistKind.CONVERT_DOCUMENTATION_INTO_LINE,
        '''
class A {
  /// AAAAAAA [int] AAAAAAA
  /// BBBBBBBB BBBB BBBB
  /// CCC [A] CCCCCCCCCCC
  mmm() {}
}
''');
  }

  test_convertDocumentationIntoLine_OK_onText_hasFirstLine() async {
    resolveTestUnit('''
class A {
  /** AAAAAAA [int] AAAAAAA
   * BBBBBBBB BBBB BBBB
   * CCC [A] CCCCCCCCCCC
   */
  mmm() {}
}
''');
    await assertHasAssistAt(
        'AAA [',
        DartAssistKind.CONVERT_DOCUMENTATION_INTO_LINE,
        '''
class A {
  /// AAAAAAA [int] AAAAAAA
  /// BBBBBBBB BBBB BBBB
  /// CCC [A] CCCCCCCCCCC
  mmm() {}
}
''');
  }

  test_convertToBlockBody_BAD_noEnclosingFunction() async {
    resolveTestUnit('''
var v = 123;
''');
    await assertNoAssistAt('v =', DartAssistKind.CONVERT_INTO_BLOCK_BODY);
  }

  test_convertToBlockBody_BAD_notExpressionBlock() async {
    resolveTestUnit('''
fff() {
  return 123;
}
''');
    await assertNoAssistAt('fff() {', DartAssistKind.CONVERT_INTO_BLOCK_BODY);
  }

  test_convertToBlockBody_OK_async() async {
    resolveTestUnit('''
class A {
  mmm() async => 123;
}
''');
    await assertHasAssistAt(
        'mmm()',
        DartAssistKind.CONVERT_INTO_BLOCK_BODY,
        '''
class A {
  mmm() async {
    return 123;
  }
}
''');
  }

  test_convertToBlockBody_OK_closure() async {
    resolveTestUnit('''
setup(x) {}
main() {
  setup(() => 42);
}
''');
    await assertHasAssistAt(
        '() => 42',
        DartAssistKind.CONVERT_INTO_BLOCK_BODY,
        '''
setup(x) {}
main() {
  setup(() {
    return 42;
  });
}
''');
    {
      Position exitPos = change.selection;
      expect(exitPos, isNotNull);
      expect(exitPos.file, testFile);
      expect(exitPos.offset - 3, resultCode.indexOf('42;'));
    }
  }

  test_convertToBlockBody_OK_closure_voidExpression() async {
    resolveTestUnit('''
setup(x) {}
main() {
  setup(() => print('done'));
}
''');
    await assertHasAssistAt(
        '() => print',
        DartAssistKind.CONVERT_INTO_BLOCK_BODY,
        '''
setup(x) {}
main() {
  setup(() {
    print('done');
  });
}
''');
    {
      Position exitPos = change.selection;
      expect(exitPos, isNotNull);
      expect(exitPos.file, testFile);
      expect(exitPos.offset - 3, resultCode.indexOf("');"));
    }
  }

  test_convertToBlockBody_OK_constructor() async {
    resolveTestUnit('''
class A {
  factory A() => null;
}
''');
    await assertHasAssistAt(
        'A()',
        DartAssistKind.CONVERT_INTO_BLOCK_BODY,
        '''
class A {
  factory A() {
    return null;
  }
}
''');
  }

  test_convertToBlockBody_OK_method() async {
    resolveTestUnit('''
class A {
  mmm() => 123;
}
''');
    await assertHasAssistAt(
        'mmm()',
        DartAssistKind.CONVERT_INTO_BLOCK_BODY,
        '''
class A {
  mmm() {
    return 123;
  }
}
''');
  }

  test_convertToBlockBody_OK_onName() async {
    resolveTestUnit('''
fff() => 123;
''');
    await assertHasAssistAt(
        'fff()',
        DartAssistKind.CONVERT_INTO_BLOCK_BODY,
        '''
fff() {
  return 123;
}
''');
  }

  test_convertToBlockBody_OK_onValue() async {
    resolveTestUnit('''
fff() => 123;
''');
    await assertHasAssistAt(
        '23;',
        DartAssistKind.CONVERT_INTO_BLOCK_BODY,
        '''
fff() {
  return 123;
}
''');
  }

  test_convertToExpressionBody_BAD_already() async {
    resolveTestUnit('''
fff() => 42;
''');
    await assertNoAssistAt(
        'fff()', DartAssistKind.CONVERT_INTO_EXPRESSION_BODY);
  }

  test_convertToExpressionBody_BAD_moreThanOneStatement() async {
    resolveTestUnit('''
fff() {
  var v = 42;
  return v;
}
''');
    await assertNoAssistAt(
        'fff()', DartAssistKind.CONVERT_INTO_EXPRESSION_BODY);
  }

  test_convertToExpressionBody_BAD_noEnclosingFunction() async {
    resolveTestUnit('''
var V = 42;
''');
    await assertNoAssistAt('V = ', DartAssistKind.CONVERT_INTO_EXPRESSION_BODY);
  }

  test_convertToExpressionBody_BAD_noReturn() async {
    resolveTestUnit('''
fff() {
  var v = 42;
}
''');
    await assertNoAssistAt(
        'fff()', DartAssistKind.CONVERT_INTO_EXPRESSION_BODY);
  }

  test_convertToExpressionBody_BAD_noReturnValue() async {
    resolveTestUnit('''
fff() {
  return;
}
''');
    await assertNoAssistAt(
        'fff()', DartAssistKind.CONVERT_INTO_EXPRESSION_BODY);
  }

  test_convertToExpressionBody_OK_async() async {
    resolveTestUnit('''
class A {
  mmm() async {
    return 42;
  }
}
''');
    await assertHasAssistAt(
        'mmm',
        DartAssistKind.CONVERT_INTO_EXPRESSION_BODY,
        '''
class A {
  mmm() async => 42;
}
''');
  }

  test_convertToExpressionBody_OK_closure() async {
    resolveTestUnit('''
setup(x) {}
main() {
  setup(() {
    return 42;
  });
}
''');
    await assertHasAssistAt(
        '42;',
        DartAssistKind.CONVERT_INTO_EXPRESSION_BODY,
        '''
setup(x) {}
main() {
  setup(() => 42);
}
''');
  }

  test_convertToExpressionBody_OK_closure_voidExpression() async {
    resolveTestUnit('''
setup(x) {}
main() {
  setup(() {
    print('test');
  });
}
''');
    await assertHasAssistAt(
        'print(',
        DartAssistKind.CONVERT_INTO_EXPRESSION_BODY,
        '''
setup(x) {}
main() {
  setup(() => print('test'));
}
''');
  }

  test_convertToExpressionBody_OK_constructor() async {
    resolveTestUnit('''
class A {
  factory A() {
    return null;
  }
}
''');
    await assertHasAssistAt(
        'A()',
        DartAssistKind.CONVERT_INTO_EXPRESSION_BODY,
        '''
class A {
  factory A() => null;
}
''');
  }

  test_convertToExpressionBody_OK_function_onBlock() async {
    resolveTestUnit('''
fff() {
  return 42;
}
''');
    await assertHasAssistAt(
        '{',
        DartAssistKind.CONVERT_INTO_EXPRESSION_BODY,
        '''
fff() => 42;
''');
  }

  test_convertToExpressionBody_OK_function_onName() async {
    resolveTestUnit('''
fff() {
  return 42;
}
''');
    await assertHasAssistAt(
        'ff()',
        DartAssistKind.CONVERT_INTO_EXPRESSION_BODY,
        '''
fff() => 42;
''');
  }

  test_convertToExpressionBody_OK_method_onBlock() async {
    resolveTestUnit('''
class A {
  m() { // marker
    return 42;
  }
}
''');
    await assertHasAssistAt(
        '{ // marker',
        DartAssistKind.CONVERT_INTO_EXPRESSION_BODY,
        '''
class A {
  m() => 42;
}
''');
  }

  test_convertToExpressionBody_OK_topFunction_onReturnStatement() async {
    resolveTestUnit('''
fff() {
  return 42;
}
''');
    await assertHasAssistAt(
        'return',
        DartAssistKind.CONVERT_INTO_EXPRESSION_BODY,
        '''
fff() => 42;
''');
  }

  test_convertToFieldParameter_BAD_additionalUse() async {
    resolveTestUnit('''
class A {
  int aaa2;
  int bbb2;
  A(int aaa) : aaa2 = aaa, bbb2 = aaa;
}
''');
    await assertNoAssistAt('aaa)', DartAssistKind.CONVERT_TO_FIELD_PARAMETER);
  }

  test_convertToFieldParameter_BAD_notPureAssignment() async {
    resolveTestUnit('''
class A {
  int aaa2;
  A(int aaa) : aaa2 = aaa * 2;
}
''');
    await assertNoAssistAt('aaa)', DartAssistKind.CONVERT_TO_FIELD_PARAMETER);
  }

  test_convertToFieldParameter_OK_firstInitializer() async {
    resolveTestUnit('''
class A {
  double aaa2;
  int bbb2;
  A(int aaa, int bbb) : aaa2 = aaa, bbb2 = bbb;
}
''');
    await assertHasAssistAt(
        'aaa, ',
        DartAssistKind.CONVERT_TO_FIELD_PARAMETER,
        '''
class A {
  double aaa2;
  int bbb2;
  A(this.aaa2, int bbb) : bbb2 = bbb;
}
''');
  }

  test_convertToFieldParameter_OK_onParameterName_inInitializer() async {
    resolveTestUnit('''
class A {
  int test2;
  A(int test) : test2 = test {
  }
}
''');
    await assertHasAssistAt(
        'test {',
        DartAssistKind.CONVERT_TO_FIELD_PARAMETER,
        '''
class A {
  int test2;
  A(this.test2) {
  }
}
''');
  }

  test_convertToFieldParameter_OK_onParameterName_inParameters() async {
    resolveTestUnit('''
class A {
  int test;
  A(int test) : test = test {
  }
}
''');
    await assertHasAssistAt(
        'test)',
        DartAssistKind.CONVERT_TO_FIELD_PARAMETER,
        '''
class A {
  int test;
  A(this.test) {
  }
}
''');
  }

  test_convertToFieldParameter_OK_secondInitializer() async {
    resolveTestUnit('''
class A {
  double aaa2;
  int bbb2;
  A(int aaa, int bbb) : aaa2 = aaa, bbb2 = bbb;
}
''');
    await assertHasAssistAt(
        'bbb)',
        DartAssistKind.CONVERT_TO_FIELD_PARAMETER,
        '''
class A {
  double aaa2;
  int bbb2;
  A(int aaa, this.bbb2) : aaa2 = aaa;
}
''');
  }

  test_convertToForIndex_BAD_bodyNotBlock() async {
    resolveTestUnit('''
main(List<String> items) {
  for (String item in items) print(item);
}
''');
    await assertNoAssistAt(
        'for (String', DartAssistKind.CONVERT_INTO_FOR_INDEX);
  }

  test_convertToForIndex_BAD_doesNotDeclareVariable() async {
    resolveTestUnit('''
main(List<String> items) {
  String item;
  for (item in items) {
    print(item);
  }
}
''');
    await assertNoAssistAt('for (item', DartAssistKind.CONVERT_INTO_FOR_INDEX);
  }

  test_convertToForIndex_BAD_iterableIsNotVariable() async {
    resolveTestUnit('''
main() {
  for (String item in ['a', 'b', 'c']) {
    print(item);
  }
}
''');
    await assertNoAssistAt(
        'for (String', DartAssistKind.CONVERT_INTO_FOR_INDEX);
  }

  test_convertToForIndex_BAD_iterableNotList() async {
    resolveTestUnit('''
main(Iterable<String> items) {
  for (String item in items) {
    print(item);
  }
}
''');
    await assertNoAssistAt(
        'for (String', DartAssistKind.CONVERT_INTO_FOR_INDEX);
  }

  test_convertToForIndex_BAD_usesIJK() async {
    resolveTestUnit('''
main(List<String> items) {
  for (String item in items) {
    print(item);
    int i, j, k;
  }
}
''');
    await assertNoAssistAt(
        'for (String', DartAssistKind.CONVERT_INTO_FOR_INDEX);
  }

  test_convertToForIndex_OK_onDeclaredIdentifier_name() async {
    resolveTestUnit('''
main(List<String> items) {
  for (String item in items) {
    print(item);
  }
}
''');
    await assertHasAssistAt(
        'item in',
        DartAssistKind.CONVERT_INTO_FOR_INDEX,
        '''
main(List<String> items) {
  for (int i = 0; i < items.length; i++) {
    String item = items[i];
    print(item);
  }
}
''');
  }

  test_convertToForIndex_OK_onDeclaredIdentifier_type() async {
    resolveTestUnit('''
main(List<String> items) {
  for (String item in items) {
    print(item);
  }
}
''');
    await assertHasAssistAt(
        'tring item',
        DartAssistKind.CONVERT_INTO_FOR_INDEX,
        '''
main(List<String> items) {
  for (int i = 0; i < items.length; i++) {
    String item = items[i];
    print(item);
  }
}
''');
  }

  test_convertToForIndex_OK_onFor() async {
    resolveTestUnit('''
main(List<String> items) {
  for (String item in items) {
    print(item);
  }
}
''');
    await assertHasAssistAt(
        'for (String',
        DartAssistKind.CONVERT_INTO_FOR_INDEX,
        '''
main(List<String> items) {
  for (int i = 0; i < items.length; i++) {
    String item = items[i];
    print(item);
  }
}
''');
  }

  test_convertToForIndex_OK_usesI() async {
    resolveTestUnit('''
main(List<String> items) {
  for (String item in items) {
    int i = 0;
  }
}
''');
    await assertHasAssistAt(
        'for (String',
        DartAssistKind.CONVERT_INTO_FOR_INDEX,
        '''
main(List<String> items) {
  for (int j = 0; j < items.length; j++) {
    String item = items[j];
    int i = 0;
  }
}
''');
  }

  test_convertToForIndex_OK_usesIJ() async {
    resolveTestUnit('''
main(List<String> items) {
  for (String item in items) {
    print(item);
    int i = 0, j = 1;
  }
}
''');
    await assertHasAssistAt(
        'for (String',
        DartAssistKind.CONVERT_INTO_FOR_INDEX,
        '''
main(List<String> items) {
  for (int k = 0; k < items.length; k++) {
    String item = items[k];
    print(item);
    int i = 0, j = 1;
  }
}
''');
  }

  test_convertToIsNot_BAD_is_alreadyIsNot() async {
    resolveTestUnit('''
main(p) {
  p is! String;
}
''');
    await assertNoAssistAt('is!', DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  test_convertToIsNot_BAD_is_noEnclosingParenthesis() async {
    resolveTestUnit('''
main(p) {
  p is String;
}
''');
    await assertNoAssistAt('is String', DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  test_convertToIsNot_BAD_is_noPrefix() async {
    resolveTestUnit('''
main(p) {
  (p is String);
}
''');
    await assertNoAssistAt('is String', DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  test_convertToIsNot_BAD_is_notIsExpression() async {
    resolveTestUnit('''
main(p) {
  123 + 456;
}
''');
    await assertNoAssistAt('123 +', DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  test_convertToIsNot_BAD_is_notTheNotOperator() async {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
main(p) {
  ++(p is String);
}
''');
    await assertNoAssistAt('is String', DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  test_convertToIsNot_BAD_not_alreadyIsNot() async {
    resolveTestUnit('''
main(p) {
  !(p is! String);
}
''');
    await assertNoAssistAt('!(p', DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  test_convertToIsNot_BAD_not_noEnclosingParenthesis() async {
    resolveTestUnit('''
main(p) {
  !p;
}
''');
    await assertNoAssistAt('!p', DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  test_convertToIsNot_BAD_not_notIsExpression() async {
    resolveTestUnit('''
main(p) {
  !(p == null);
}
''');
    await assertNoAssistAt('!(p', DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  test_convertToIsNot_BAD_not_notTheNotOperator() async {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
main(p) {
  ++(p is String);
}
''');
    await assertNoAssistAt('++(', DartAssistKind.CONVERT_INTO_IS_NOT);
  }

  test_convertToIsNot_OK_childOfIs_left() async {
    resolveTestUnit('''
main(p) {
  !(p is String);
}
''');
    await assertHasAssistAt(
        'p is',
        DartAssistKind.CONVERT_INTO_IS_NOT,
        '''
main(p) {
  p is! String;
}
''');
  }

  test_convertToIsNot_OK_childOfIs_right() async {
    resolveTestUnit('''
main(p) {
  !(p is String);
}
''');
    await assertHasAssistAt(
        'String)',
        DartAssistKind.CONVERT_INTO_IS_NOT,
        '''
main(p) {
  p is! String;
}
''');
  }

  test_convertToIsNot_OK_is() async {
    resolveTestUnit('''
main(p) {
  !(p is String);
}
''');
    await assertHasAssistAt(
        'is String',
        DartAssistKind.CONVERT_INTO_IS_NOT,
        '''
main(p) {
  p is! String;
}
''');
  }

  test_convertToIsNot_OK_is_higherPrecedencePrefix() async {
    resolveTestUnit('''
main(p) {
  !!(p is String);
}
''');
    await assertHasAssistAt(
        'is String',
        DartAssistKind.CONVERT_INTO_IS_NOT,
        '''
main(p) {
  !(p is! String);
}
''');
  }

  test_convertToIsNot_OK_is_not_higherPrecedencePrefix() async {
    resolveTestUnit('''
main(p) {
  !!(p is String);
}
''');
    await assertHasAssistAt(
        '!(p',
        DartAssistKind.CONVERT_INTO_IS_NOT,
        '''
main(p) {
  !(p is! String);
}
''');
  }

  test_convertToIsNot_OK_not() async {
    resolveTestUnit('''
main(p) {
  !(p is String);
}
''');
    await assertHasAssistAt(
        '!(p',
        DartAssistKind.CONVERT_INTO_IS_NOT,
        '''
main(p) {
  p is! String;
}
''');
  }

  test_convertToIsNot_OK_parentheses() async {
    resolveTestUnit('''
main(p) {
  !(p is String);
}
''');
    await assertHasAssistAt(
        '(p is',
        DartAssistKind.CONVERT_INTO_IS_NOT,
        '''
main(p) {
  p is! String;
}
''');
  }

  test_convertToIsNotEmpty_BAD_noBang() async {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
main(String str) {
  ~str.isEmpty;
}
''');
    await assertNoAssistAt(
        'isEmpty;', DartAssistKind.CONVERT_INTO_IS_NOT_EMPTY);
  }

  test_convertToIsNotEmpty_BAD_noIsNotEmpty() async {
    resolveTestUnit('''
class A {
  bool get isEmpty => false;
}
main(A a) {
  !a.isEmpty;
}
''');
    await assertNoAssistAt(
        'isEmpty;', DartAssistKind.CONVERT_INTO_IS_NOT_EMPTY);
  }

  test_convertToIsNotEmpty_BAD_notInPrefixExpression() async {
    resolveTestUnit('''
main(String str) {
  str.isEmpty;
}
''');
    await assertNoAssistAt(
        'isEmpty;', DartAssistKind.CONVERT_INTO_IS_NOT_EMPTY);
  }

  test_convertToIsNotEmpty_BAD_notIsEmpty() async {
    resolveTestUnit('''
main(int p) {
  !p.isEven;
}
''');
    await assertNoAssistAt('isEven;', DartAssistKind.CONVERT_INTO_IS_NOT_EMPTY);
  }

  test_convertToIsNotEmpty_OK_on_isEmpty() async {
    resolveTestUnit('''
main(String str) {
  !str.isEmpty;
}
''');
    await assertHasAssistAt(
        'isEmpty',
        DartAssistKind.CONVERT_INTO_IS_NOT_EMPTY,
        '''
main(String str) {
  str.isNotEmpty;
}
''');
  }

  test_convertToIsNotEmpty_OK_on_str() async {
    resolveTestUnit('''
main(String str) {
  !str.isEmpty;
}
''');
    await assertHasAssistAt(
        'str.',
        DartAssistKind.CONVERT_INTO_IS_NOT_EMPTY,
        '''
main(String str) {
  str.isNotEmpty;
}
''');
  }

  test_convertToIsNotEmpty_OK_propertyAccess() async {
    resolveTestUnit('''
main(String str) {
  !'text'.isEmpty;
}
''');
    await assertHasAssistAt(
        'isEmpty',
        DartAssistKind.CONVERT_INTO_IS_NOT_EMPTY,
        '''
main(String str) {
  'text'.isNotEmpty;
}
''');
  }

  test_convertToNormalParameter_OK_dynamic() async {
    resolveTestUnit('''
class A {
  var test;
  A(this.test) {
  }
}
''');
    await assertHasAssistAt(
        'test)',
        DartAssistKind.CONVERT_TO_NORMAL_PARAMETER,
        '''
class A {
  var test;
  A(test) : test = test {
  }
}
''');
  }

  test_convertToNormalParameter_OK_firstInitializer() async {
    resolveTestUnit('''
class A {
  int test;
  A(this.test) {
  }
}
''');
    await assertHasAssistAt(
        'test)',
        DartAssistKind.CONVERT_TO_NORMAL_PARAMETER,
        '''
class A {
  int test;
  A(int test) : test = test {
  }
}
''');
  }

  test_convertToNormalParameter_OK_secondInitializer() async {
    resolveTestUnit('''
class A {
  double aaa;
  int bbb;
  A(this.bbb) : aaa = 1.0;
}
''');
    await assertHasAssistAt(
        'bbb)',
        DartAssistKind.CONVERT_TO_NORMAL_PARAMETER,
        '''
class A {
  double aaa;
  int bbb;
  A(int bbb) : aaa = 1.0, bbb = bbb;
}
''');
  }

  test_encapsulateField_BAD_alreadyPrivate() async {
    resolveTestUnit('''
class A {
  int _test = 42;
}
main(A a) {
  print(a._test);
}
''');
    await assertNoAssistAt('_test =', DartAssistKind.ENCAPSULATE_FIELD);
  }

  test_encapsulateField_BAD_final() async {
    resolveTestUnit('''
class A {
  final int test = 42;
}
''');
    await assertNoAssistAt('test =', DartAssistKind.ENCAPSULATE_FIELD);
  }

  test_encapsulateField_BAD_multipleFields() async {
    resolveTestUnit('''
class A {
  int aaa, bbb, ccc;
}
main(A a) {
  print(a.bbb);
}
''');
    await assertNoAssistAt('bbb, ', DartAssistKind.ENCAPSULATE_FIELD);
  }

  test_encapsulateField_BAD_notOnName() async {
    resolveTestUnit('''
class A {
  int test = 1 + 2 + 3;
}
''');
    await assertNoAssistAt('+ 2', DartAssistKind.ENCAPSULATE_FIELD);
  }

  test_encapsulateField_BAD_parseError() async {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
class A {
  int; // marker
}
main(A a) {
  print(a.test);
}
''');
    await assertNoAssistAt('; // marker', DartAssistKind.ENCAPSULATE_FIELD);
  }

  test_encapsulateField_BAD_static() async {
    resolveTestUnit('''
class A {
  static int test = 42;
}
''');
    await assertNoAssistAt('test =', DartAssistKind.ENCAPSULATE_FIELD);
  }

  test_encapsulateField_OK_hasType() async {
    resolveTestUnit('''
class A {
  int test = 42;
  A(this.test);
}
main(A a) {
  print(a.test);
}
''');
    await assertHasAssistAt(
        'test = 42',
        DartAssistKind.ENCAPSULATE_FIELD,
        '''
class A {
  int _test = 42;

  int get test => _test;

  void set test(int test) {
    _test = test;
  }
  A(this._test);
}
main(A a) {
  print(a.test);
}
''');
  }

  test_encapsulateField_OK_noType() async {
    resolveTestUnit('''
class A {
  var test = 42;
}
main(A a) {
  print(a.test);
}
''');
    await assertHasAssistAt(
        'test = 42',
        DartAssistKind.ENCAPSULATE_FIELD,
        '''
class A {
  var _test = 42;

  get test => _test;

  void set test(test) {
    _test = test;
  }
}
main(A a) {
  print(a.test);
}
''');
  }

  test_exchangeBinaryExpressionArguments_BAD_extraLength() async {
    resolveTestUnit('''
main() {
  111 + 222;
}
''');
    length = 3;
    await assertNoAssistAt('+ 222', DartAssistKind.EXCHANGE_OPERANDS);
  }

  test_exchangeBinaryExpressionArguments_BAD_onOperand() async {
    resolveTestUnit('''
main() {
  111 + 222;
}
''');
    length = 3;
    await assertNoAssistAt('11 +', DartAssistKind.EXCHANGE_OPERANDS);
  }

  test_exchangeBinaryExpressionArguments_BAD_selectionWithBinary() async {
    resolveTestUnit('''
main() {
  1 + 2 + 3;
}
''');
    length = '1 + 2 + 3'.length;
    await assertNoAssistAt('1 + 2 + 3', DartAssistKind.EXCHANGE_OPERANDS);
  }

  test_exchangeBinaryExpressionArguments_OK_compare() async {
    const initialOperators = const ['<', '<=', '>', '>='];
    const resultOperators = const ['>', '>=', '<', '<='];
    for (int i = 0; i <= 0; i++) {
      String initialOperator = initialOperators[i];
      String resultOperator = resultOperators[i];
      resolveTestUnit('''
bool main(int a, int b) {
  return a $initialOperator b;
}
''');
      await assertHasAssistAt(
          initialOperator,
          DartAssistKind.EXCHANGE_OPERANDS,
          '''
bool main(int a, int b) {
  return b $resultOperator a;
}
''');
    }
  }

  test_exchangeBinaryExpressionArguments_OK_extended_mixOperator_1() async {
    resolveTestUnit('''
main() {
  1 * 2 * 3 + 4;
}
''');
    await assertHasAssistAt(
        '* 2',
        DartAssistKind.EXCHANGE_OPERANDS,
        '''
main() {
  2 * 3 * 1 + 4;
}
''');
  }

  test_exchangeBinaryExpressionArguments_OK_extended_mixOperator_2() async {
    resolveTestUnit('''
main() {
  1 + 2 - 3 + 4;
}
''');
    await assertHasAssistAt(
        '+ 2',
        DartAssistKind.EXCHANGE_OPERANDS,
        '''
main() {
  2 + 1 - 3 + 4;
}
''');
  }

  test_exchangeBinaryExpressionArguments_OK_extended_sameOperator_afterFirst() async {
    resolveTestUnit('''
main() {
  1 + 2 + 3;
}
''');
    await assertHasAssistAt(
        '+ 2',
        DartAssistKind.EXCHANGE_OPERANDS,
        '''
main() {
  2 + 3 + 1;
}
''');
  }

  test_exchangeBinaryExpressionArguments_OK_extended_sameOperator_afterSecond() async {
    resolveTestUnit('''
main() {
  1 + 2 + 3;
}
''');
    await assertHasAssistAt(
        '+ 3',
        DartAssistKind.EXCHANGE_OPERANDS,
        '''
main() {
  3 + 1 + 2;
}
''');
  }

  test_exchangeBinaryExpressionArguments_OK_simple_afterOperator() async {
    resolveTestUnit('''
main() {
  1 + 2;
}
''');
    await assertHasAssistAt(
        ' 2',
        DartAssistKind.EXCHANGE_OPERANDS,
        '''
main() {
  2 + 1;
}
''');
  }

  test_exchangeBinaryExpressionArguments_OK_simple_beforeOperator() async {
    resolveTestUnit('''
main() {
  1 + 2;
}
''');
    await assertHasAssistAt(
        '+ 2',
        DartAssistKind.EXCHANGE_OPERANDS,
        '''
main() {
  2 + 1;
}
''');
  }

  test_exchangeBinaryExpressionArguments_OK_simple_fullSelection() async {
    resolveTestUnit('''
main() {
  1 + 2;
}
''');
    length = '1 + 2'.length;
    await assertHasAssistAt(
        '1 + 2',
        DartAssistKind.EXCHANGE_OPERANDS,
        '''
main() {
  2 + 1;
}
''');
  }

  test_exchangeBinaryExpressionArguments_OK_simple_withLength() async {
    resolveTestUnit('''
main() {
  1 + 2;
}
''');
    length = 2;
    await assertHasAssistAt(
        '+ 2',
        DartAssistKind.EXCHANGE_OPERANDS,
        '''
main() {
  2 + 1;
}
''');
  }

  test_importAddShow_BAD_hasShow() async {
    resolveTestUnit('''
import 'dart:math' show PI;
main() {
  PI;
}
''');
    await assertNoAssistAt('import ', DartAssistKind.IMPORT_ADD_SHOW);
  }

  test_importAddShow_BAD_unresolvedUri() async {
    resolveTestUnit('''
import '/no/such/lib.dart';
''');
    await assertNoAssistAt('import ', DartAssistKind.IMPORT_ADD_SHOW);
  }

  test_importAddShow_BAD_unused() async {
    resolveTestUnit('''
import 'dart:math';
''');
    await assertNoAssistAt('import ', DartAssistKind.IMPORT_ADD_SHOW);
  }

  test_importAddShow_OK_hasUnresolvedIdentifier() async {
    resolveTestUnit('''
import 'dart:math';
main(x) {
  PI;
  return x.foo();
}
''');
    await assertHasAssistAt(
        'import ',
        DartAssistKind.IMPORT_ADD_SHOW,
        '''
import 'dart:math' show PI;
main(x) {
  PI;
  return x.foo();
}
''');
  }

  test_importAddShow_OK_onDirective() async {
    resolveTestUnit('''
import 'dart:math';
main() {
  PI;
  E;
  max(1, 2);
}
''');
    await assertHasAssistAt(
        'import ',
        DartAssistKind.IMPORT_ADD_SHOW,
        '''
import 'dart:math' show E, PI, max;
main() {
  PI;
  E;
  max(1, 2);
}
''');
  }

  test_importAddShow_OK_onUri() async {
    resolveTestUnit('''
import 'dart:math';
main() {
  PI;
  E;
  max(1, 2);
}
''');
    await assertHasAssistAt(
        'art:math',
        DartAssistKind.IMPORT_ADD_SHOW,
        '''
import 'dart:math' show E, PI, max;
main() {
  PI;
  E;
  max(1, 2);
}
''');
  }

  test_introduceLocalTestedType_BAD_notBlock() async {
    resolveTestUnit('''
main(p) {
  if (p is String)
    print('not a block');
}
''');
    await assertNoAssistAt('if (p', DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE);
  }

  test_introduceLocalTestedType_BAD_notIsExpression() async {
    resolveTestUnit('''
main(p) {
  if (p == null) {
  }
}
''');
    await assertNoAssistAt('if (p', DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE);
  }

  test_introduceLocalTestedType_BAD_notStatement() async {
    resolveTestUnit('''
class C {
  bool b;
  C(v) : b = v is int;
}''');
    await assertNoAssistAt('is int', DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE);
  }

  test_introduceLocalTestedType_OK_if_is() async {
    resolveTestUnit('''
class MyTypeName {}
main(p) {
  if (p is MyTypeName) {
  }
  p = null;
}
''');
    String expected = '''
class MyTypeName {}
main(p) {
  if (p is MyTypeName) {
    MyTypeName myTypeName = p;
  }
  p = null;
}
''';
    await assertHasAssistAt(
        'is MyType', DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE, expected);
    _assertLinkedGroup(
        change.linkedEditGroups[0],
        ['myTypeName = '],
        expectedSuggestions(LinkedEditSuggestionKind.VARIABLE,
            ['myTypeName', 'typeName', 'name']));
    // another good location
    await assertHasAssistAt(
        'if (p', DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE, expected);
  }

  test_introduceLocalTestedType_OK_if_isNot() async {
    resolveTestUnit('''
class MyTypeName {}
main(p) {
  if (p is! MyTypeName) {
    return;
  }
}
''');
    String expected = '''
class MyTypeName {}
main(p) {
  if (p is! MyTypeName) {
    return;
  }
  MyTypeName myTypeName = p;
}
''';
    await assertHasAssistAt(
        'is! MyType', DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE, expected);
    _assertLinkedGroup(
        change.linkedEditGroups[0],
        ['myTypeName = '],
        expectedSuggestions(LinkedEditSuggestionKind.VARIABLE,
            ['myTypeName', 'typeName', 'name']));
    // another good location
    await assertHasAssistAt(
        'if (p', DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE, expected);
  }

  test_introduceLocalTestedType_OK_while() async {
    resolveTestUnit('''
main(p) {
  while (p is String) {
  }
  p = null;
}
''');
    String expected = '''
main(p) {
  while (p is String) {
    String s = p;
  }
  p = null;
}
''';
    await assertHasAssistAt(
        'is String', DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE, expected);
    await assertHasAssistAt(
        'while (p', DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE, expected);
  }

  test_invalidSelection() async {
    resolveTestUnit('');
    List<Assist> assists =
        await computeAssists(plugin, context, testUnit.element.source, -1, 0);
    expect(assists, isEmpty);
  }

  test_invertIfStatement_blocks() async {
    resolveTestUnit('''
main() {
  if (true) {
    0;
  } else {
    1;
  }
}
''');
    await assertHasAssistAt(
        'if (',
        DartAssistKind.INVERT_IF_STATEMENT,
        '''
main() {
  if (false) {
    1;
  } else {
    0;
  }
}
''');
  }

  test_invertIfStatement_statements() async {
    resolveTestUnit('''
main() {
  if (true)
    0;
  else
    1;
}
''');
    await assertHasAssistAt(
        'if (',
        DartAssistKind.INVERT_IF_STATEMENT,
        '''
main() {
  if (false)
    1;
  else
    0;
}
''');
  }

  test_joinIfStatementInner_BAD_innerNotIf() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    print(0);
  }
}
''');
    await assertNoAssistAt('if (1 ==', DartAssistKind.JOIN_IF_WITH_INNER);
  }

  test_joinIfStatementInner_BAD_innerWithElse() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    } else {
      print(1);
    }
  }
}
''');
    await assertNoAssistAt('if (1 ==', DartAssistKind.JOIN_IF_WITH_INNER);
  }

  test_joinIfStatementInner_BAD_statementAfterInner() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(2);
    }
    print(1);
  }
}
''');
    await assertNoAssistAt('if (1 ==', DartAssistKind.JOIN_IF_WITH_INNER);
  }

  test_joinIfStatementInner_BAD_statementBeforeInner() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    print(1);
    if (2 == 2) {
      print(2);
    }
  }
}
''');
    await assertNoAssistAt('if (1 ==', DartAssistKind.JOIN_IF_WITH_INNER);
  }

  test_joinIfStatementInner_BAD_targetNotIf() async {
    resolveTestUnit('''
main() {
  print(0);
}
''');
    await assertNoAssistAt('print', DartAssistKind.JOIN_IF_WITH_INNER);
  }

  test_joinIfStatementInner_BAD_targetWithElse() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  } else {
    print(1);
  }
}
''');
    await assertNoAssistAt('if (1 ==', DartAssistKind.JOIN_IF_WITH_INNER);
  }

  test_joinIfStatementInner_OK_conditionAndOr() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2 || 3 == 3) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt(
        'if (1 ==',
        DartAssistKind.JOIN_IF_WITH_INNER,
        '''
main() {
  if (1 == 1 && (2 == 2 || 3 == 3)) {
    print(0);
  }
}
''');
  }

  test_joinIfStatementInner_OK_conditionInvocation() async {
    resolveTestUnit('''
main() {
  if (isCheck()) {
    if (2 == 2) {
      print(0);
    }
  }
}
bool isCheck() => false;
''');
    await assertHasAssistAt(
        'if (isCheck',
        DartAssistKind.JOIN_IF_WITH_INNER,
        '''
main() {
  if (isCheck() && 2 == 2) {
    print(0);
  }
}
bool isCheck() => false;
''');
  }

  test_joinIfStatementInner_OK_conditionOrAnd() async {
    resolveTestUnit('''
main() {
  if (1 == 1 || 2 == 2) {
    if (3 == 3) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt(
        'if (1 ==',
        DartAssistKind.JOIN_IF_WITH_INNER,
        '''
main() {
  if ((1 == 1 || 2 == 2) && 3 == 3) {
    print(0);
  }
}
''');
  }

  test_joinIfStatementInner_OK_onCondition() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt(
        '1 ==',
        DartAssistKind.JOIN_IF_WITH_INNER,
        '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  test_joinIfStatementInner_OK_simpleConditions_block_block() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt(
        'if (1 ==',
        DartAssistKind.JOIN_IF_WITH_INNER,
        '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  test_joinIfStatementInner_OK_simpleConditions_block_single() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2)
      print(0);
  }
}
''');
    await assertHasAssistAt(
        'if (1 ==',
        DartAssistKind.JOIN_IF_WITH_INNER,
        '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  test_joinIfStatementInner_OK_simpleConditions_single_blockMulti() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(1);
      print(2);
      print(3);
    }
  }
}
''');
    await assertHasAssistAt(
        'if (1 ==',
        DartAssistKind.JOIN_IF_WITH_INNER,
        '''
main() {
  if (1 == 1 && 2 == 2) {
    print(1);
    print(2);
    print(3);
  }
}
''');
  }

  test_joinIfStatementInner_OK_simpleConditions_single_blockOne() async {
    resolveTestUnit('''
main() {
  if (1 == 1)
    if (2 == 2) {
      print(0);
    }
}
''');
    await assertHasAssistAt(
        'if (1 ==',
        DartAssistKind.JOIN_IF_WITH_INNER,
        '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  test_joinIfStatementOuter_BAD_outerNotIf() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    print(0);
  }
}
''');
    await assertNoAssistAt('if (1 == 1', DartAssistKind.JOIN_IF_WITH_OUTER);
  }

  test_joinIfStatementOuter_BAD_outerWithElse() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  } else {
    print(1);
  }
}
''');
    await assertNoAssistAt('if (2 == 2', DartAssistKind.JOIN_IF_WITH_OUTER);
  }

  test_joinIfStatementOuter_BAD_statementAfterInner() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(2);
    }
    print(1);
  }
}
''');
    await assertNoAssistAt('if (2 == 2', DartAssistKind.JOIN_IF_WITH_OUTER);
  }

  test_joinIfStatementOuter_BAD_statementBeforeInner() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    print(1);
    if (2 == 2) {
      print(2);
    }
  }
}
''');
    await assertNoAssistAt('if (2 == 2', DartAssistKind.JOIN_IF_WITH_OUTER);
  }

  test_joinIfStatementOuter_BAD_targetNotIf() async {
    resolveTestUnit('''
main() {
  print(0);
}
''');
    await assertNoAssistAt('print', DartAssistKind.JOIN_IF_WITH_OUTER);
  }

  test_joinIfStatementOuter_BAD_targetWithElse() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    } else {
      print(1);
    }
  }
}
''');
    await assertNoAssistAt('if (2 == 2', DartAssistKind.JOIN_IF_WITH_OUTER);
  }

  test_joinIfStatementOuter_OK_conditionAndOr() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2 || 3 == 3) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt(
        'if (2 ==',
        DartAssistKind.JOIN_IF_WITH_OUTER,
        '''
main() {
  if (1 == 1 && (2 == 2 || 3 == 3)) {
    print(0);
  }
}
''');
  }

  test_joinIfStatementOuter_OK_conditionInvocation() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (isCheck()) {
      print(0);
    }
  }
}
bool isCheck() => false;
''');
    await assertHasAssistAt(
        'if (isCheck',
        DartAssistKind.JOIN_IF_WITH_OUTER,
        '''
main() {
  if (1 == 1 && isCheck()) {
    print(0);
  }
}
bool isCheck() => false;
''');
  }

  test_joinIfStatementOuter_OK_conditionOrAnd() async {
    resolveTestUnit('''
main() {
  if (1 == 1 || 2 == 2) {
    if (3 == 3) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt(
        'if (3 == 3',
        DartAssistKind.JOIN_IF_WITH_OUTER,
        '''
main() {
  if ((1 == 1 || 2 == 2) && 3 == 3) {
    print(0);
  }
}
''');
  }

  test_joinIfStatementOuter_OK_onCondition() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt(
        'if (2 == 2',
        DartAssistKind.JOIN_IF_WITH_OUTER,
        '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  test_joinIfStatementOuter_OK_simpleConditions_block_block() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt(
        'if (2 == 2',
        DartAssistKind.JOIN_IF_WITH_OUTER,
        '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  test_joinIfStatementOuter_OK_simpleConditions_block_single() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2)
      print(0);
  }
}
''');
    await assertHasAssistAt(
        'if (2 == 2',
        DartAssistKind.JOIN_IF_WITH_OUTER,
        '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  test_joinIfStatementOuter_OK_simpleConditions_single_blockMulti() async {
    resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(1);
      print(2);
      print(3);
    }
  }
}
''');
    await assertHasAssistAt(
        'if (2 == 2',
        DartAssistKind.JOIN_IF_WITH_OUTER,
        '''
main() {
  if (1 == 1 && 2 == 2) {
    print(1);
    print(2);
    print(3);
  }
}
''');
  }

  test_joinIfStatementOuter_OK_simpleConditions_single_blockOne() async {
    resolveTestUnit('''
main() {
  if (1 == 1)
    if (2 == 2) {
      print(0);
    }
}
''');
    await assertHasAssistAt(
        'if (2 == 2',
        DartAssistKind.JOIN_IF_WITH_OUTER,
        '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  test_joinVariableDeclaration_onAssignment_BAD_hasInitializer() async {
    resolveTestUnit('''
main() {
  var v = 1;
  v = 2;
}
''');
    await assertNoAssistAt('v = 2', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onAssignment_BAD_notAdjacent() async {
    resolveTestUnit('''
main() {
  var v;
  var bar;
  v = 1;
}
''');
    await assertNoAssistAt('v = 1', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onAssignment_BAD_notAssignment() async {
    resolveTestUnit('''
main() {
  var v;
  v += 1;
}
''');
    await assertNoAssistAt('v += 1', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onAssignment_BAD_notDeclaration() async {
    resolveTestUnit('''
main(var v) {
  v = 1;
}
''');
    await assertNoAssistAt('v = 1', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onAssignment_BAD_notLeftArgument() async {
    resolveTestUnit('''
main() {
  var v;
  1 + v; // marker
}
''');
    await assertNoAssistAt(
        'v; // marker', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onAssignment_BAD_notOneVariable() async {
    resolveTestUnit('''
main() {
  var v, v2;
  v = 1;
}
''');
    await assertNoAssistAt('v = 1', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onAssignment_BAD_notResolved() async {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
main() {
  var v;
  x = 1;
}
''');
    await assertNoAssistAt('x = 1', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onAssignment_BAD_notSameBlock() async {
    resolveTestUnit('''
main() {
  var v;
  {
    v = 1;
  }
}
''');
    await assertNoAssistAt('v = 1', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onAssignment_OK() async {
    resolveTestUnit('''
main() {
  var v;
  v = 1;
}
''');
    await assertHasAssistAt(
        'v =',
        DartAssistKind.JOIN_VARIABLE_DECLARATION,
        '''
main() {
  var v = 1;
}
''');
  }

  test_joinVariableDeclaration_onDeclaration_BAD_hasInitializer() async {
    resolveTestUnit('''
main() {
  var v = 1;
  v = 2;
}
''');
    await assertNoAssistAt('v = 1', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onDeclaration_BAD_lastStatement() async {
    resolveTestUnit('''
main() {
  if (true)
    var v;
}
''');
    await assertNoAssistAt('v;', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onDeclaration_BAD_nextNotAssignmentExpression() async {
    resolveTestUnit('''
main() {
  var v;
  42;
}
''');
    await assertNoAssistAt('v;', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onDeclaration_BAD_nextNotExpressionStatement() async {
    resolveTestUnit('''
main() {
  var v;
  if (true) return;
}
''');
    await assertNoAssistAt('v;', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onDeclaration_BAD_nextNotPureAssignment() async {
    resolveTestUnit('''
main() {
  var v;
  v += 1;
}
''');
    await assertNoAssistAt('v;', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onDeclaration_BAD_notOneVariable() async {
    resolveTestUnit('''
main() {
  var v, v2;
  v = 1;
}
''');
    await assertNoAssistAt('v, ', DartAssistKind.JOIN_VARIABLE_DECLARATION);
  }

  test_joinVariableDeclaration_onDeclaration_OK_onName() async {
    resolveTestUnit('''
main() {
  var v;
  v = 1;
}
''');
    await assertHasAssistAt(
        'v;',
        DartAssistKind.JOIN_VARIABLE_DECLARATION,
        '''
main() {
  var v = 1;
}
''');
  }

  test_joinVariableDeclaration_onDeclaration_OK_onType() async {
    resolveTestUnit('''
main() {
  int v;
  v = 1;
}
''');
    await assertHasAssistAt(
        'int v',
        DartAssistKind.JOIN_VARIABLE_DECLARATION,
        '''
main() {
  int v = 1;
}
''');
  }

  test_joinVariableDeclaration_onDeclaration_OK_onVar() async {
    resolveTestUnit('''
main() {
  var v;
  v = 1;
}
''');
    await assertHasAssistAt(
        'var v',
        DartAssistKind.JOIN_VARIABLE_DECLARATION,
        '''
main() {
  var v = 1;
}
''');
  }

  test_removeTypeAnnotation_classField_OK() async {
    resolveTestUnit('''
class A {
  int v = 1;
}
''');
    await assertHasAssistAt(
        'v = ',
        DartAssistKind.REMOVE_TYPE_ANNOTATION,
        '''
class A {
  var v = 1;
}
''');
  }

  test_removeTypeAnnotation_classField_OK_final() async {
    resolveTestUnit('''
class A {
  final int v = 1;
}
''');
    await assertHasAssistAt(
        'v = ',
        DartAssistKind.REMOVE_TYPE_ANNOTATION,
        '''
class A {
  final v = 1;
}
''');
  }

  test_removeTypeAnnotation_localVariable_BAD_onInitializer() async {
    resolveTestUnit('''
main() {
  final int v = 1;
}
''');
    await assertNoAssistAt('1;', DartAssistKind.REMOVE_TYPE_ANNOTATION);
  }

  test_removeTypeAnnotation_localVariable_OK() async {
    resolveTestUnit('''
main() {
  int a = 1, b = 2;
}
''');
    await assertHasAssistAt(
        'int ',
        DartAssistKind.REMOVE_TYPE_ANNOTATION,
        '''
main() {
  var a = 1, b = 2;
}
''');
  }

  test_removeTypeAnnotation_localVariable_OK_const() async {
    resolveTestUnit('''
main() {
  const int v = 1;
}
''');
    await assertHasAssistAt(
        'int ',
        DartAssistKind.REMOVE_TYPE_ANNOTATION,
        '''
main() {
  const v = 1;
}
''');
  }

  test_removeTypeAnnotation_localVariable_OK_final() async {
    resolveTestUnit('''
main() {
  final int v = 1;
}
''');
    await assertHasAssistAt(
        'int ',
        DartAssistKind.REMOVE_TYPE_ANNOTATION,
        '''
main() {
  final v = 1;
}
''');
  }

  test_removeTypeAnnotation_topLevelVariable_BAD_syntheticName() async {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
MyType
''');
    await assertNoAssistAt('MyType', DartAssistKind.REMOVE_TYPE_ANNOTATION);
  }

  test_removeTypeAnnotation_topLevelVariable_OK() async {
    resolveTestUnit('''
int V = 1;
''');
    await assertHasAssistAt(
        'int ',
        DartAssistKind.REMOVE_TYPE_ANNOTATION,
        '''
var V = 1;
''');
  }

  test_removeTypeAnnotation_topLevelVariable_OK_final() async {
    resolveTestUnit('''
final int V = 1;
''');
    await assertHasAssistAt(
        'int ',
        DartAssistKind.REMOVE_TYPE_ANNOTATION,
        '''
final V = 1;
''');
  }

  test_replaceConditionalWithIfElse_BAD_noEnclosingStatement() async {
    resolveTestUnit('''
var v = true ? 111 : 222;
''');
    await assertNoAssistAt(
        '? 111', DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE);
  }

  test_replaceConditionalWithIfElse_BAD_notConditional() async {
    resolveTestUnit('''
main() {
  var v = 42;
}
''');
    await assertNoAssistAt(
        'v = 42', DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE);
  }

  test_replaceConditionalWithIfElse_OK_assignment() async {
    resolveTestUnit('''
main() {
  var v;
  v = true ? 111 : 222;
}
''');
    // on conditional
    await assertHasAssistAt(
        '11 :',
        DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE,
        '''
main() {
  var v;
  if (true) {
    v = 111;
  } else {
    v = 222;
  }
}
''');
    // on variable
    await assertHasAssistAt(
        'v =',
        DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE,
        '''
main() {
  var v;
  if (true) {
    v = 111;
  } else {
    v = 222;
  }
}
''');
  }

  test_replaceConditionalWithIfElse_OK_return() async {
    resolveTestUnit('''
main() {
  return true ? 111 : 222;
}
''');
    await assertHasAssistAt(
        'return ',
        DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE,
        '''
main() {
  if (true) {
    return 111;
  } else {
    return 222;
  }
}
''');
  }

  test_replaceConditionalWithIfElse_OK_variableDeclaration() async {
    resolveTestUnit('''
main() {
  int a = 1, vvv = true ? 111 : 222, b = 2;
}
''');
    await assertHasAssistAt(
        '11 :',
        DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE,
        '''
main() {
  int a = 1, vvv, b = 2;
  if (true) {
    vvv = 111;
  } else {
    vvv = 222;
  }
}
''');
  }

  test_replaceIfElseWithConditional_BAD_expressionVsReturn() async {
    resolveTestUnit('''
main() {
  if (true) {
    print(42);
  } else {
    return;
  }
}
''');
    await assertNoAssistAt(
        'else', DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL);
  }

  test_replaceIfElseWithConditional_BAD_notIfStatement() async {
    resolveTestUnit('''
main() {
  print(0);
}
''');
    await assertNoAssistAt(
        'print', DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL);
  }

  test_replaceIfElseWithConditional_BAD_notSingleStatement() async {
    resolveTestUnit('''
main() {
  int vvv;
  if (true) {
    print(0);
    vvv = 111;
  } else {
    print(0);
    vvv = 222;
  }
}
''');
    await assertNoAssistAt(
        'if (true)', DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL);
  }

  test_replaceIfElseWithConditional_OK_assignment() async {
    resolveTestUnit('''
main() {
  int vvv;
  if (true) {
    vvv = 111;
  } else {
    vvv = 222;
  }
}
''');
    await assertHasAssistAt(
        'if (true)',
        DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL,
        '''
main() {
  int vvv;
  vvv = true ? 111 : 222;
}
''');
  }

  test_replaceIfElseWithConditional_OK_return() async {
    resolveTestUnit('''
main() {
  if (true) {
    return 111;
  } else {
    return 222;
  }
}
''');
    await assertHasAssistAt(
        'if (true)',
        DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL,
        '''
main() {
  return true ? 111 : 222;
}
''');
  }

  test_splitAndCondition_BAD_hasElse() async {
    resolveTestUnit('''
main() {
  if (1 == 1 && 2 == 2) {
    print(1);
  } else {
    print(2);
  }
}
''');
    await assertNoAssistAt('&& 2', DartAssistKind.SPLIT_AND_CONDITION);
  }

  test_splitAndCondition_BAD_notAnd() async {
    resolveTestUnit('''
main() {
  if (1 == 1 || 2 == 2) {
    print(0);
  }
}
''');
    await assertNoAssistAt('|| 2', DartAssistKind.SPLIT_AND_CONDITION);
  }

  test_splitAndCondition_BAD_notPartOfIf() async {
    resolveTestUnit('''
main() {
  print(1 == 1 && 2 == 2);
}
''');
    await assertNoAssistAt('&& 2', DartAssistKind.SPLIT_AND_CONDITION);
  }

  test_splitAndCondition_BAD_notTopLevelAnd() async {
    resolveTestUnit('''
main() {
  if (true || (1 == 1 && 2 == 2)) {
    print(0);
  }
  if (true && (3 == 3 && 4 == 4)) {
    print(0);
  }
}
''');
    await assertNoAssistAt('&& 2', DartAssistKind.SPLIT_AND_CONDITION);
    await assertNoAssistAt('&& 4', DartAssistKind.SPLIT_AND_CONDITION);
  }

  test_splitAndCondition_OK_innerAndExpression() async {
    resolveTestUnit('''
main() {
  if (1 == 1 && 2 == 2 && 3 == 3) {
    print(0);
  }
}
''');
    await assertHasAssistAt(
        '&& 2 == 2',
        DartAssistKind.SPLIT_AND_CONDITION,
        '''
main() {
  if (1 == 1) {
    if (2 == 2 && 3 == 3) {
      print(0);
    }
  }
}
''');
  }

  test_splitAndCondition_OK_thenBlock() async {
    resolveTestUnit('''
main() {
  if (true && false) {
    print(0);
    if (3 == 3) {
      print(1);
    }
  }
}
''');
    await assertHasAssistAt(
        '&& false',
        DartAssistKind.SPLIT_AND_CONDITION,
        '''
main() {
  if (true) {
    if (false) {
      print(0);
      if (3 == 3) {
        print(1);
      }
    }
  }
}
''');
  }

  test_splitAndCondition_OK_thenStatement() async {
    resolveTestUnit('''
main() {
  if (true && false)
    print(0);
}
''');
    await assertHasAssistAt(
        '&& false',
        DartAssistKind.SPLIT_AND_CONDITION,
        '''
main() {
  if (true)
    if (false)
      print(0);
}
''');
  }

  test_splitAndCondition_wrong() async {
    resolveTestUnit('''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
  print(3 == 3 && 4 == 4);
}
''');
    // not binary expression
    await assertNoAssistAt('main() {', DartAssistKind.SPLIT_AND_CONDITION);
    // selection is not empty and includes more than just operator
    {
      length = 5;
      await assertNoAssistAt('&& 2 == 2', DartAssistKind.SPLIT_AND_CONDITION);
    }
  }

  test_splitVariableDeclaration_BAD_notOneVariable() async {
    resolveTestUnit('''
main() {
  var v = 1, v2;
}
''');
    await assertNoAssistAt('v = 1', DartAssistKind.SPLIT_VARIABLE_DECLARATION);
  }

  test_splitVariableDeclaration_OK_onName() async {
    resolveTestUnit('''
main() {
  var v = 1;
}
''');
    await assertHasAssistAt(
        'v =',
        DartAssistKind.SPLIT_VARIABLE_DECLARATION,
        '''
main() {
  var v;
  v = 1;
}
''');
  }

  test_splitVariableDeclaration_OK_onType() async {
    resolveTestUnit('''
main() {
  int v = 1;
}
''');
    await assertHasAssistAt(
        'int ',
        DartAssistKind.SPLIT_VARIABLE_DECLARATION,
        '''
main() {
  int v;
  v = 1;
}
''');
  }

  test_splitVariableDeclaration_OK_onVar() async {
    resolveTestUnit('''
main() {
  var v = 1;
}
''');
    await assertHasAssistAt(
        'var ',
        DartAssistKind.SPLIT_VARIABLE_DECLARATION,
        '''
main() {
  var v;
  v = 1;
}
''');
  }

  test_surroundWith_block() async {
    resolveTestUnit('''
main() {
// start
  print(0);
  print(1);
// end
}
''');
    _setStartEndSelection();
    await assertHasAssist(
        DartAssistKind.SURROUND_WITH_BLOCK,
        '''
main() {
// start
  {
    print(0);
    print(1);
  }
// end
}
''');
  }

  test_surroundWith_doWhile() async {
    resolveTestUnit('''
main() {
// start
  print(0);
  print(1);
// end
}
''');
    _setStartEndSelection();
    await assertHasAssist(
        DartAssistKind.SURROUND_WITH_DO_WHILE,
        '''
main() {
// start
  do {
    print(0);
    print(1);
  } while (condition);
// end
}
''');
  }

  test_surroundWith_for() async {
    resolveTestUnit('''
main() {
// start
  print(0);
  print(1);
// end
}
''');
    _setStartEndSelection();
    await assertHasAssist(
        DartAssistKind.SURROUND_WITH_FOR,
        '''
main() {
// start
  for (var v = init; condition; increment) {
    print(0);
    print(1);
  }
// end
}
''');
  }

  test_surroundWith_forIn() async {
    resolveTestUnit('''
main() {
// start
  print(0);
  print(1);
// end
}
''');
    _setStartEndSelection();
    await assertHasAssist(
        DartAssistKind.SURROUND_WITH_FOR_IN,
        '''
main() {
// start
  for (var item in iterable) {
    print(0);
    print(1);
  }
// end
}
''');
  }

  test_surroundWith_if() async {
    resolveTestUnit('''
main() {
// start
  print(0);
  print(1);
// end
}
''');
    _setStartEndSelection();
    await assertHasAssist(
        DartAssistKind.SURROUND_WITH_IF,
        '''
main() {
// start
  if (condition) {
    print(0);
    print(1);
  }
// end
}
''');
  }

  test_surroundWith_tryCatch() async {
    resolveTestUnit('''
main() {
// start
  print(0);
  print(1);
// end
}
''');
    _setStartEndSelection();
    await assertHasAssist(
        DartAssistKind.SURROUND_WITH_TRY_CATCH,
        '''
main() {
// start
  try {
    print(0);
    print(1);
  } on Exception catch (e) {
    // TODO
  }
// end
}
''');
  }

  test_surroundWith_tryFinally() async {
    resolveTestUnit('''
main() {
// start
  print(0);
  print(1);
// end
}
''');
    _setStartEndSelection();
    await assertHasAssist(
        DartAssistKind.SURROUND_WITH_TRY_FINALLY,
        '''
main() {
// start
  try {
    print(0);
    print(1);
  } finally {
    // TODO
  }
// end
}
''');
  }

  test_surroundWith_while() async {
    resolveTestUnit('''
main() {
// start
  print(0);
  print(1);
// end
}
''');
    _setStartEndSelection();
    await assertHasAssist(
        DartAssistKind.SURROUND_WITH_WHILE,
        '''
main() {
// start
  while (condition) {
    print(0);
    print(1);
  }
// end
}
''');
  }

  /**
   * Computes assists and verifies that there is an assist of the given kind.
   */
  Future<Assist> _assertHasAssist(AssistKind kind) async {
    List<Assist> assists = await computeAssists(
        plugin, context, testUnit.element.source, offset, length);
    for (Assist assist in assists) {
      if (assist.kind == kind) {
        return assist;
      }
    }
    throw fail('Expected to find assist $kind in\n${assists.join('\n')}');
  }

  void _assertLinkedGroup(LinkedEditGroup group, List<String> expectedStrings,
      [List<LinkedEditSuggestion> expectedSuggestions]) {
    List<Position> expectedPositions = _findResultPositions(expectedStrings);
    expect(group.positions, unorderedEquals(expectedPositions));
    if (expectedSuggestions != null) {
      expect(group.suggestions, unorderedEquals(expectedSuggestions));
    }
  }

  List<Position> _findResultPositions(List<String> searchStrings) {
    List<Position> positions = <Position>[];
    for (String search in searchStrings) {
      int offset = resultCode.indexOf(search);
      positions.add(new Position(testFile, offset));
    }
    return positions;
  }

  void _setStartEndSelection() {
    offset = findOffset('// start\n') + '// start\n'.length;
    length = findOffset('// end') - offset;
  }
}
