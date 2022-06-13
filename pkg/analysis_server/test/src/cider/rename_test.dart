// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/cider/rename.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utilities/mock_packages.dart';
import 'cider_service.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CiderRenameComputerTest);
  });
}

@reflectiveTest
class CiderRenameComputerTest extends CiderServiceTest {
  late _CorrectionContext _correctionContext;
  late LineInfo? _lineInfo;
  late String _testCode;

  @override
  void setUp() {
    super.setUp();
    BazelMockPackages.instance.addFlutter(resourceProvider);
  }

  void test_cannotRename_inSdk() async {
    var refactor = await _compute(r'''
void f() {
  new String.^fromCharCodes([]);
}
''');

    expect(refactor, isNull);
  }

  void test_canRename_class() async {
    var refactor = await _compute(r'''
class ^Old {}
}
''');

    expect(refactor!.refactoringElement.element.name, 'Old');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_canRename_field() async {
    var refactor = await _compute(r'''
class A {
 int ^bar;
 void foo() {
   bar = 5;
 }
}
''');

    expect(refactor!.refactoringElement.element.name, 'bar');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_canRename_field_static_private() async {
    var refactor = await _compute(r'''
class A{
  static const ^_val = 1234;
}
''');

    expect(refactor, isNotNull);
    expect(refactor!.refactoringElement.element.name, '_val');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_canRename_function() async {
    var refactor = await _compute(r'''
void ^foo() {
}
''');

    expect(refactor!.refactoringElement.element.name, 'foo');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_canRename_label() async {
    var refactor = await _compute(r'''
void f() {
  myLabel:
  while (true) {
    continue ^myLabel;
    break myLabel;
  }
}
''');

    expect(refactor, isNotNull);
    expect(refactor!.refactoringElement.element.name, 'myLabel');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_canRename_local() async {
    var refactor = await _compute(r'''
void foo() {
  var ^a = 0; var b = a + 1;
}
''');

    expect(refactor!.refactoringElement.element.name, 'a');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_canRename_method() async {
    var refactor = await _compute(r'''
extension E on int {
  void ^foo() {}
}
''');

    expect(refactor!.refactoringElement.element.name, 'foo');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_canRename_operator() async {
    var refactor = await _compute(r'''
class A{
  A operator ^+(A other) => this;
}
''');

    expect(refactor, isNull);
  }

  void test_canRename_parameter() async {
    var refactor = await _compute(r'''
void foo(int ^bar) {
  var a = bar + 1;
}
''');

    expect(refactor, isNotNull);
    expect(refactor!.refactoringElement.element.name, 'bar');
    expect(refactor.refactoringElement.offset, _correctionContext.offset);
  }

  void test_checkName_class() async {
    var result = await _checkName(r'''
class ^Old {}
''', 'New');

    expect(result!.status.problems.length, 0);
    expect(result.oldName, 'Old');
  }

  void test_checkName_function() async {
    var result = await _checkName(r'''
int ^foo() => 2;
''', 'bar');

    expect(result!.status.problems.length, 0);
    expect(result.oldName, 'foo');
  }

  void test_checkName_local() async {
    var result = await _checkName(r'''
void foo() {
  var ^a = 0; var b = a + 1;
}
''', 'bar');

    expect(result!.status.problems.length, 0);
    expect(result.oldName, 'a');
  }

  void test_checkName_local_invalid() async {
    var result = await _checkName(r'''
void foo() {
  var ^a = 0; var b = a + 1;
}
''', 'Aa');

    expect(result!.status.problems.length, 1);
    expect(result.oldName, 'a');
  }

  void test_checkName_newName() async {
    var result = await _checkName(r'''
class A {
  A.^test() {}
}
''', 'test');

    expect(result!.status.problems.length, 1);
    expect(result.status.hasError, isTrue);
  }

  void test_checkName_parameter() async {
    var result = await _checkName(r'''
void foo(String ^a) {
  var b = a + 1;
}
''', 'bar');

    expect(result!.status.problems.length, 0);
    expect(result.oldName, 'a');
  }

  void test_checkName_topLevelVariable() async {
    var result = await _checkName(r'''
var ^foo;
''', 'bar');

    expect(result!.status.problems.length, 0);
    expect(result.oldName, 'foo');
  }

  void test_checkName_TypeAlias() async {
    var result = await _checkName(r'''
typedef ^Foo = void Function();
''', 'Bar');

    expect(result!.status.problems.length, 0);
    expect(result.oldName, 'Foo');
  }

  void test_rename_class() async {
    var testCode = '''
class ^Old implements Other {
  Old() {}
  Old.named() {}
}
class Other {
  factory Other.a() = Old;
  factory Other.b() = Old.named;
}
void f() {
  Old t1 = new Old();
  Old t2 = new Old.named();
}
''';
    var result = await _rename(testCode, 'New');
    _assertTestChangeResult('''
class New implements Other {
  New() {}
  New.named() {}
}
class Other {
  factory Other.a() = New;
  factory Other.b() = New.named;
}
void f() {
  New t1 = new New();
  New t2 = new New.named();
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_class_flutterWidget() async {
    var testCode = '''
import 'package:flutter/material.dart';

class ^TestPage extends StatefulWidget {
  const TestPage();

  @override
  State<TestPage> createState() => TestPageState();
}

class TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) => throw 0;
}
''';

    var result = await _rename(testCode, 'NewPage');
    expect(result!.replaceMatches.length, 1);
    expect(result.replaceMatches.first.matches, [
      ReplaceInfo('NewPage', CharacterLocation(4, 9), 8),
      ReplaceInfo('NewPage', CharacterLocation(7, 9), 8),
      ReplaceInfo('NewPage', CharacterLocation(10, 35), 8),
      ReplaceInfo('NewPage', CharacterLocation(3, 7), 8)
    ]);
    expect(result.flutterWidgetRename != null, isTrue);
    expect(result.flutterWidgetRename!.name, 'NewPageState');
    expect(
        result.flutterWidgetRename!.replacements.first.matches
            .map((m) => m.startPosition)
            .toList(),
        [CharacterLocation(7, 36), CharacterLocation(10, 7)]);
  }

  void test_rename_constructor_add() async {
    var testCode = '''
// ignore: deprecated_new_in_comment_reference
/// Documentation for [new A] and [A.new]
class A {
  ^A() {} // marker
  factory A._() = A;
}
class B extends A {
  B() : super() {}
}
void f() {
  new A();
  A.new;
}
''';

    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult('''
// ignore: deprecated_new_in_comment_reference
/// Documentation for [new A.newName] and [A.newName]
class A {
  A.newName() {} // marker
  factory A._() = A.newName;
}
class B extends A {
  B() : super.newName() {}
}
void f() {
  new A.newName();
  A.newName;
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_constructor_enum() async {
    var testCode = '''
/// [E.new]
enum E {
  v1(), v2.new(), v3, v4.other();
  const ^E(); // 0
  const E.other() : this();
}
''';

    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult('''
/// [E.newName]
enum E {
  v1.newName(), v2.newName(), v3.newName(), v4.other();
  const E.newName(); // 0
  const E.other() : this.newName();
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_constructor_enum_hasConstructor() async {
    var testCode = '''
/// [E.new]
enum E {
  v1(), v2.^new(), v3;

  factory E.other() => throw 0;
}
''';

    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult('''
/// [E.newName]
enum E {
  v1.newName(), v2.newName(), v3.newName();

  factory E.other() => throw 0;

  const E.newName();
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_constructor_enum_hasField() async {
    var testCode = '''
/// [E.new]
enum E {
  v1(), v2.^new(), v3;

  final int foo = 0;
}
''';

    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult('''
/// [E.newName]
enum E {
  v1.newName(), v2.newName(), v3.newName();

  final int foo = 0;

  const E.newName();
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_constructor_enum_hasMethod() async {
    var testCode = '''
/// [E.new]
enum E {
  v1(), v2.^new(), v3;

  void foo() {}
}
''';

    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult('''
/// [E.newName]
enum E {
  v1.newName(), v2.newName(), v3.newName();

  const E.newName();

  void foo() {}
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_constructor_enum_named() async {
    var testCode = '''
/// [E.test]
enum E {
  v1.^test(), v2.other();
  const E.test(); // 0
  const E.other() : this.test();
}
''';

    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult('''
/// [E.newName]
enum E {
  v1.newName(), v2.other();
  const E.newName(); // 0
  const E.other() : this.newName();
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_constructor_enum_remove() async {
    var testCode = '''
/// [E]
enum E {
  v1.test(), v2.other();
  const E.^test(); // 0
  const E.other() : this.test();
}
''';

    var result = await _rename(testCode, '');
    _assertTestChangeResult('''
/// [E]
enum E {
  v1(), v2.other();
  const E(); // 0
  const E.other() : this();
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_constructor_named() async {
    var testCode = '''
// ignore: deprecated_new_in_comment_reference
/// Documentation for [A.test] and [new A.test]
class A {
  A.^test() {} // marker
  factory A._() = A.test;
}
class B extends A {
  B() : super.test() {}
}
void f() {
  new A.test();
  A.test;
}
''';

    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult('''
// ignore: deprecated_new_in_comment_reference
/// Documentation for [A.newName] and [new A.newName]
class A {
  A.newName() {} // marker
  factory A._() = A.newName;
}
class B extends A {
  B() : super.newName() {}
}
void f() {
  new A.newName();
  A.newName;
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_constructor_remove() async {
    var testCode = '''
// ignore: deprecated_new_in_comment_reference
/// Documentation for [A.test] and [new A.test]
class A {
  A.^test() {} // marker
  factory A._() = A.test;
}
class B extends A {
  B() : super.test() {}
}
void f() {
  new A.test();
  A.test;
}
''';

    var result = await _rename(testCode, '');
    _assertTestChangeResult('''
// ignore: deprecated_new_in_comment_reference
/// Documentation for [A] and [new A]
class A {
  A() {} // marker
  factory A._() = A;
}
class B extends A {
  B() : super() {}
}
void f() {
  new A();
  A.new;
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_constructor_synthetic() async {
    var testCode = '''
// ignore: deprecated_new_in_comment_reference
/// Documentation for [new A] and [A.new]
class A {
  int field = 0;
}
class B extends A {
  B() : super() {}
}
void f() {
  new A();
  A.^new;
}
''';

    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult('''
// ignore: deprecated_new_in_comment_reference
/// Documentation for [new A.newName] and [A.newName]
class A {
  int field = 0;

  A.newName();
}
class B extends A {
  B() : super.newName() {}
}
void f() {
  new A.newName();
  A.newName;
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_field() async {
    var testCode = '''
class A{
  int get ^x => 5;
}

void foo() {
  var m = A().x;
}
''';

    var result = await _rename(testCode, 'y');
    _assertTestChangeResult('''
class A{
  int get y => 5;
}

void foo() {
  var m = A().y;
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_field_static_private() async {
    var testCode = '''
class A{
  static const ^_val = 1234;
}

void foo() {
  print(A._val);
}
''';

    var result = await _rename(testCode, '_newVal');
    _assertTestChangeResult('''
class A{
  static const _newVal = 1234;
}

void foo() {
  print(A._newVal);
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_function() async {
    var testCode = '''
test() {}
^foo() {}
void f() {
  print(test);
  print(test());
  foo();
}
''';

    var result = await _rename(testCode, 'bar');
    _assertTestChangeResult('''
test() {}
bar() {}
void f() {
  print(test);
  print(test());
  bar();
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_function_imported() async {
    var a = newFile('/workspace/dart/test/lib/a.dart', r'''
foo() {}
''');
    await fileResolver.resolve2(path: a.path);
    var result = await _rename(r'''
import 'a.dart';
void f() {
  ^foo();
}
''', 'bar');

    expect(result!.replaceMatches.length, 2);
    expect(result.replaceMatches.first.matches,
        [ReplaceInfo('bar', CharacterLocation(3, 3), 3)]);
    expect(result.replaceMatches[1].matches,
        [ReplaceInfo('bar', CharacterLocation(1, 1), 3)]);
  }

  void test_rename_import() async {
    var testCode = '''
import 'dart:async';
^import 'dart:math' show Random, min hide max;
void f() {
  Future f;
  Random r;
  min(1, 2);
}
''';

    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult('''
import 'dart:async';
import 'dart:math' as newName show Random, min hide max;
void f() {
  Future f;
  newName.Random r;
  newName.min(1, 2);
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_import_hasCurlyBrackets() async {
    var testCode = r'''
// test
^import 'dart:async';
void f() {
  Future f;
  print('Future type: ${Future}');
}
''';

    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult(r'''
// test
import 'dart:async' as newName;
void f() {
  newName.Future f;
  print('Future type: ${newName.Future}');
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_import_noCurlyBrackets() async {
    var testCode = r'''
// test
^import 'dart:async';
void f() {
  Future f;
  print('Future type: $Future');
}
''';
    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult(r'''
// test
import 'dart:async' as newName;
void f() {
  newName.Future f;
  print('Future type: ${newName.Future}');
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_import_onPrefixElement() async {
    var testCode = '''
import 'dart:async' as test;
import 'dart:math' as test;
void f() {
  test.Future f;
  ^test.pi;
  test.e;
}
''';
    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult('''
import 'dart:async' as test;
import 'dart:math' as newName;
void f() {
  test.Future f;
  newName.pi;
  newName.e;
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_import_prefix() async {
    var testCode = '''
import 'dart:math' as test;
^import 'dart:async' as test;
void f() {
  test.max(1, 2);
  test.Future f;
}
''';
    var result = await _rename(testCode, 'newName');
    _assertTestChangeResult('''
import 'dart:math' as test;
import 'dart:async' as newName;
void f() {
  test.max(1, 2);
  newName.Future f;
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_import_remove_prefix() async {
    var testCode = '''
import 'dart:math' as test;
^import 'dart:async' as test;
void f() {
  test.Future f;
}
''';

    var result = await _rename(testCode, '');
    _assertTestChangeResult('''
import 'dart:math' as test;
import 'dart:async';
void f() {
  Future f;
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_local() async {
    var testCode = '''
void foo() {
  var ^a = 0; var b = a + 1;
}
''';

    var result = await _rename(testCode, 'bar');
    _assertTestChangeResult('''
void foo() {
  var bar = 0; var b = bar + 1;
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_method_imported() async {
    var a = newFile('/workspace/dart/test/lib/a.dart', r'''
class A {
  foo() {}
}
''');
    await fileResolver.resolve2(path: a.path);
    var result = await _rename(r'''
import 'a.dart';
void f() {
  var a = A().^foo();
}
''', 'bar');
    expect(result!.replaceMatches.length, 2);
    expect(result.replaceMatches.first.matches,
        [ReplaceInfo('bar', CharacterLocation(3, 15), 3)]);
    expect(result.replaceMatches[1].matches,
        [ReplaceInfo('bar', CharacterLocation(2, 3), 3)]);
  }

  void test_rename_parameter() async {
    var testCode = '''
void foo(String ^a) {
  var b = a + 1;
}
''';
    var result = await _rename(testCode, 'bar');
    _assertTestChangeResult('''
void foo(String bar) {
  var b = bar + 1;
}
''', result!.replaceMatches.first.matches);
  }

  void test_rename_propertyAccessor() async {
    var testCode = '''
get foo {}
set foo(x) {}
void f() {
  print(foo);
  ^foo = 1;
  foo += 2;
''';
    var result = await _rename(testCode, 'bar');
    _assertTestChangeResult('''
get bar {}
set bar(x) {}
void f() {
  print(bar);
  bar = 1;
  bar += 2;
''', result!.replaceMatches.first.matches);
  }

  void test_rename_typeAlias_functionType() async {
    var testCode = '''
typedef ^F = void Function();
void f(F a) {}
''';

    var result = await _rename(testCode, 'bar');
    _assertTestChangeResult('''
typedef bar = void Function();
void f(bar a) {}
''', result!.replaceMatches.first.matches);
  }

  // Asserts that the results of the rename is the [expectedCode].
  void _assertTestChangeResult(
      String expectedCode, List<ReplaceInfo> changes) async {
    var edits = <SourceEdit>[];
    for (var change in changes) {
      var offset =
          _lineInfo!.getOffsetOfLine(change.startPosition.lineNumber - 1) +
              change.startPosition.columnNumber -
              1;
      edits.add(SourceEdit(offset, change.length, change.replacementText));
    }
    edits.sort((a, b) => a.offset.compareTo(b.offset));
    edits = edits.reversed.toList();
    // validate resulting code
    var actualCode = SourceEdit.applySequence(_testCode, edits);
    expect(actualCode, expectedCode);
  }

  Future<CheckNameResponse?> _checkName(String content, String newName) async {
    _updateFile(content);

    var canRename = await CiderRenameComputer(
      fileResolver,
    ).canRename2(
      convertPath(testPath),
      _correctionContext.line,
      _correctionContext.character,
    );
    return canRename?.checkNewName(newName);
  }

  Future<CanRenameResponse?> _compute(String content) async {
    _updateFile(content);

    return CiderRenameComputer(
      fileResolver,
    ).canRename2(
      convertPath(testPath),
      _correctionContext.line,
      _correctionContext.character,
    );
  }

  Future<RenameResponse?> _rename(String content, String newName) async {
    _updateFile(content);

    var canRename = await CiderRenameComputer(
      fileResolver,
    ).canRename2(
      convertPath(testPath),
      _correctionContext.line,
      _correctionContext.character,
    );
    _lineInfo = canRename?.lineInfo;
    return canRename?.checkNewName(newName)?.computeRenameRanges2();
  }

  void _updateFile(String content) {
    var offset = content.indexOf('^');
    expect(offset, isPositive, reason: 'Expected to find ^');
    expect(content.indexOf('^', offset + 1), -1, reason: 'Expected only one ^');

    var lineInfo = LineInfo.fromContent(content);
    var location = lineInfo.getLocation(offset);

    _testCode = content.substring(0, offset) + content.substring(offset + 1);
    newFile(testPath, _testCode);

    _correctionContext = _CorrectionContext(
      content,
      offset,
      location.lineNumber - 1,
      location.columnNumber - 1,
    );
  }
}

class _CorrectionContext {
  final String content;
  final int offset;
  final int line;
  final int character;

  _CorrectionContext(this.content, this.offset, this.line, this.character);
}
