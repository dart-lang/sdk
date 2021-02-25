// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterOutlineComputerTest);
    defineReflectiveTests(OutlineComputerTest);
  });
}

class AbstractOutlineComputerTest extends AbstractContextTest {
  String testPath;
  String testCode;

  @override
  void setUp() {
    super.setUp();
    testPath = convertPath('/home/test/lib/test.dart');
  }

  Future<Outline> _computeOutline(String code) async {
    testCode = code;
    newFile(testPath, content: code);
    var resolveResult = await session.getResolvedUnit(testPath);
    return DartUnitOutlineComputer(
      resolveResult,
      withBasicFlutter: true,
    ).compute();
  }
}

@reflectiveTest
class FlutterOutlineComputerTest extends AbstractOutlineComputerTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_columnWithChildren() async {
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Column(children: [
      const Text('aaa'),
      const Text('bbb'),
    ]); // Column
  }
}
''');
    expect(_toText(unitOutline), r'''
MyWidget
  build
    Column
      Text('aaa')
      Text('bbb')
''');
    var myWidget = unitOutline.children[0];
    var build = myWidget.children[0];

    var columnOutline = build.children[0];
    {
      var offset = testCode.indexOf('new Column');
      var length = testCode.indexOf('; // Column') - offset;
      _expect(columnOutline,
          name: 'Column',
          elementOffset: offset,
          offset: offset,
          length: length);
    }

    {
      var textOutline = columnOutline.children[0];
      var text = "const Text('aaa')";
      var offset = testCode.indexOf(text);
      _expect(textOutline,
          name: "Text('aaa')",
          elementOffset: offset,
          offset: offset,
          length: text.length);
    }

    {
      var textOutline = columnOutline.children[1];
      var text = "const Text('bbb')";
      var offset = testCode.indexOf(text);
      _expect(textOutline,
          name: "Text('bbb')",
          elementOffset: offset,
          offset: offset,
          length: text.length);
    }
  }

  void _expect(Outline outline,
      {@required String name,
      @required int elementOffset,
      @required int offset,
      @required int length}) {
    var element = outline.element;
    expect(element.name, name);
    expect(element.location.offset, elementOffset);
    expect(outline.offset, offset);
    expect(outline.length, length);
  }

  static String _toText(Outline outline) {
    var buffer = StringBuffer();

    void writeOutline(Outline outline, String indent) {
      buffer.write(indent);
      buffer.writeln(outline.element.name);
      for (var child in outline.children ?? const []) {
        writeOutline(child, '$indent  ');
      }
    }

    for (var child in outline.children) {
      writeOutline(child, '');
    }
    return buffer.toString();
  }
}

@reflectiveTest
class OutlineComputerTest extends AbstractOutlineComputerTest {
  Future<void> test_class() async {
    var unitOutline = await _computeOutline('''
abstract class A<K, V> {
  int fa, fb;
  String fc;
  A(int i, String s);
  A.name(num p);
  A._privateName(num p);
  static String ma(int pa) => null;
  _mb(int pb);
  R mc<R, P>(P p) {}
  String get propA => null;
  set propB(int v) {}
}
class B {
  B(int p);
}
String fa(int pa) => null;
R fb<R, P>(P p) {}
''');
    var topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(4));
    // A
    {
      var outline_A = topOutlines[0];
      var element_A = outline_A.element;
      expect(element_A.kind, ElementKind.CLASS);
      expect(element_A.name, 'A');
      expect(element_A.typeParameters, '<K, V>');
      {
        var location = element_A.location;
        expect(location.offset, testCode.indexOf('A<K, V> {'));
        expect(location.length, 1);
      }
      expect(element_A.parameters, null);
      expect(element_A.returnType, null);
      // A children
      var outlines_A = outline_A.children;
      expect(outlines_A, hasLength(11));
      {
        var outline = outlines_A[0];
        var element = outline.element;
        expect(element.kind, ElementKind.FIELD);
        expect(element.name, 'fa');
        expect(element.parameters, isNull);
        expect(element.returnType, 'int');
      }
      {
        var outline = outlines_A[1];
        var element = outline.element;
        expect(element.kind, ElementKind.FIELD);
        expect(element.name, 'fb');
        expect(element.parameters, isNull);
        expect(element.returnType, 'int');
      }
      {
        var outline = outlines_A[2];
        var element = outline.element;
        expect(element.kind, ElementKind.FIELD);
        expect(element.name, 'fc');
        expect(element.parameters, isNull);
        expect(element.returnType, 'String');
      }
      {
        var outline = outlines_A[3];
        var element = outline.element;
        expect(element.kind, ElementKind.CONSTRUCTOR);
        expect(element.name, 'A');
        {
          var location = element.location;
          expect(location.offset, testCode.indexOf('A(int i, String s);'));
          expect(location.length, 'A'.length);
        }
        expect(element.parameters, '(int i, String s)');
        expect(element.returnType, isNull);
        expect(element.isAbstract, isFalse);
        expect(element.isStatic, isFalse);
      }
      {
        var outline = outlines_A[4];
        var element = outline.element;
        expect(element.kind, ElementKind.CONSTRUCTOR);
        expect(element.name, 'A.name');
        {
          var location = element.location;
          expect(location.offset, testCode.indexOf('name(num p);'));
          expect(location.length, 'name'.length);
        }
        expect(element.parameters, '(num p)');
        expect(element.returnType, isNull);
        expect(element.isAbstract, isFalse);
        expect(element.isStatic, isFalse);
      }
      {
        var outline = outlines_A[5];
        var element = outline.element;
        expect(element.kind, ElementKind.CONSTRUCTOR);
        expect(element.name, 'A._privateName');
        {
          var location = element.location;
          expect(location.offset, testCode.indexOf('_privateName(num p);'));
          expect(location.length, '_privateName'.length);
        }
        expect(element.parameters, '(num p)');
        expect(element.returnType, isNull);
        expect(element.isAbstract, isFalse);
        expect(element.isStatic, isFalse);
      }
      {
        var outline = outlines_A[6];
        var element = outline.element;
        expect(element.kind, ElementKind.METHOD);
        expect(element.name, 'ma');
        {
          var location = element.location;
          expect(location.offset, testCode.indexOf('ma(int pa) => null;'));
          expect(location.length, 'ma'.length);
        }
        expect(element.parameters, '(int pa)');
        expect(element.returnType, 'String');
        expect(element.isAbstract, isFalse);
        expect(element.isStatic, isTrue);
      }
      {
        var outline = outlines_A[7];
        var element = outline.element;
        expect(element.kind, ElementKind.METHOD);
        expect(element.name, '_mb');
        {
          var location = element.location;
          expect(location.offset, testCode.indexOf('_mb(int pb);'));
          expect(location.length, '_mb'.length);
        }
        expect(element.parameters, '(int pb)');
        expect(element.returnType, '');
        expect(element.isAbstract, isTrue);
        expect(element.isStatic, isFalse);
      }
      {
        var outline = outlines_A[8];
        var element = outline.element;
        expect(element.kind, ElementKind.METHOD);
        expect(element.name, 'mc');
        {
          var location = element.location;
          expect(location.offset, testCode.indexOf('mc<R, P>'));
          expect(location.length, 'mc'.length);
        }
        expect(element.parameters, '(P p)');
        expect(element.returnType, 'R');
        expect(element.typeParameters, '<R, P>');
        expect(element.isAbstract, isFalse);
        expect(element.isStatic, isFalse);
      }
      {
        var outline = outlines_A[9];
        var element = outline.element;
        expect(element.kind, ElementKind.GETTER);
        expect(element.name, 'propA');
        {
          var location = element.location;
          expect(location.offset, testCode.indexOf('propA => null;'));
          expect(location.length, 'propA'.length);
        }
        expect(element.parameters, isNull);
        expect(element.returnType, 'String');
      }
      {
        var outline = outlines_A[10];
        var element = outline.element;
        expect(element.kind, ElementKind.SETTER);
        expect(element.name, 'propB');
        {
          var location = element.location;
          expect(location.offset, testCode.indexOf('propB(int v) {}'));
          expect(location.length, 'propB'.length);
        }
        expect(element.parameters, '(int v)');
        expect(element.returnType, '');
      }
    }
    // B
    {
      var outline_B = topOutlines[1];
      var element_B = outline_B.element;
      expect(element_B.kind, ElementKind.CLASS);
      expect(element_B.name, 'B');
      expect(element_B.typeParameters, isNull);
      {
        var location = element_B.location;
        expect(location.offset, testCode.indexOf('B {'));
        expect(location.length, 1);
      }
      expect(element_B.parameters, null);
      expect(element_B.returnType, null);
      // B children
      var outlines_B = outline_B.children;
      expect(outlines_B, hasLength(1));
      {
        var outline = outlines_B[0];
        var element = outline.element;
        expect(element.kind, ElementKind.CONSTRUCTOR);
        expect(element.name, 'B');
        {
          var location = element.location;
          expect(location.offset, testCode.indexOf('B(int p);'));
          expect(location.length, 'B'.length);
        }
        expect(element.parameters, '(int p)');
        expect(element.returnType, isNull);
      }
    }
    {
      var outline = topOutlines[2];
      var element = outline.element;
      expect(element.kind, ElementKind.FUNCTION);
      expect(element.name, 'fa');
      {
        var location = element.location;
        expect(location.offset, testCode.indexOf('fa(int pa)'));
        expect(location.length, 'ma'.length);
      }
      expect(element.parameters, '(int pa)');
      expect(element.returnType, 'String');
      expect(element.isAbstract, isFalse);
      expect(element.isStatic, isTrue);
    }
    {
      var outline = topOutlines[3];
      var element = outline.element;
      expect(element.kind, ElementKind.FUNCTION);
      expect(element.name, 'fb');
      {
        var location = element.location;
        expect(location.offset, testCode.indexOf('fb<R, P>'));
        expect(location.length, 'fb'.length);
      }
      expect(element.parameters, '(P p)');
      expect(element.returnType, 'R');
      expect(element.typeParameters, '<R, P>');
      expect(element.isAbstract, isFalse);
      expect(element.isStatic, isTrue);
    }
  }

  Future<void> test_enum() async {
    var unitOutline = await _computeOutline('''
enum MyEnum {
  A, B, C
}
''');
    var topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(1));
    // MyEnum
    {
      var outline_MyEnum = topOutlines[0];
      var element_MyEnum = outline_MyEnum.element;
      expect(element_MyEnum.kind, ElementKind.ENUM);
      expect(element_MyEnum.name, 'MyEnum');
      {
        var location = element_MyEnum.location;
        expect(location.offset, testCode.indexOf('MyEnum {'));
        expect(location.length, 'MyEnum'.length);
      }
      expect(element_MyEnum.parameters, null);
      expect(element_MyEnum.returnType, null);
      // MyEnum children
      var outlines_MyEnum = outline_MyEnum.children;
      expect(outlines_MyEnum, hasLength(3));
      _isEnumConstant(outlines_MyEnum[0], 'A');
      _isEnumConstant(outlines_MyEnum[1], 'B');
      _isEnumConstant(outlines_MyEnum[2], 'C');
    }
  }

  Future<void> test_extension_named() async {
    var unitOutline = await _computeOutline('''
extension MyExt on String {
  int get halfLength => length ~/ 2;
  void writeOn(StringBuffer b) {
    b.write(this);
  }
}
''');
    var topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(1));
    // MyExt
    {
      var outline_MyExt = topOutlines[0];
      var element_MyExt = outline_MyExt.element;
      expect(element_MyExt.kind, ElementKind.EXTENSION);
      expect(element_MyExt.name, 'MyExt');
      {
        var location = element_MyExt.location;
        expect(location.offset, testCode.indexOf('MyExt on'));
        expect(location.length, 'MyExt'.length);
      }
      expect(element_MyExt.parameters, null);
      expect(element_MyExt.returnType, null);
      // StringUtilities children
      var outlines_MyExt = outline_MyExt.children;
      expect(outlines_MyExt, hasLength(2));
    }
  }

  Future<void> test_extension_unnamed() async {
    var unitOutline = await _computeOutline('''
extension on String {
  int get halfLength => length ~/ 2;
  void writeOn(StringBuffer b) {
    b.write(this);
  }
}
''');
    var topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(1));
    // MyExt
    {
      var outline_MyExt = topOutlines[0];
      var element_MyExt = outline_MyExt.element;
      expect(element_MyExt.kind, ElementKind.EXTENSION);
      expect(element_MyExt.name, '');
      {
        var location = element_MyExt.location;
        expect(location.offset, testCode.indexOf('String'));
        expect(location.length, 'String'.length);
      }
      expect(element_MyExt.parameters, null);
      expect(element_MyExt.returnType, null);
      // StringUtilities children
      var outlines_MyExt = outline_MyExt.children;
      expect(outlines_MyExt, hasLength(2));
    }
  }

  Future<void> test_genericTypeAlias_incomplete() async {
    var unitOutline = await _computeOutline('''
typedef F = Object;
''');
    var topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(1));
    // F
    var outline_F = topOutlines[0];
    var element_F = outline_F.element;
    expect(element_F.kind, ElementKind.FUNCTION_TYPE_ALIAS);
    expect(element_F.name, 'F');
    {
      var location = element_F.location;
      expect(location.offset, testCode.indexOf('F ='));
      expect(location.length, 'F'.length);
    }
    expect(element_F.parameters, '');
    expect(element_F.returnType, '');
  }

  Future<void> test_genericTypeAlias_minimal() async {
    var unitOutline = await _computeOutline('''
typedef F = void Function();
''');
    var topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(1));
    // F
    var outline_F = topOutlines[0];
    var element_F = outline_F.element;
    expect(element_F.kind, ElementKind.FUNCTION_TYPE_ALIAS);
    expect(element_F.name, 'F');
    {
      var location = element_F.location;
      expect(location.offset, testCode.indexOf('F ='));
      expect(location.length, 'F'.length);
    }
    expect(element_F.parameters, '()');
    expect(element_F.returnType, 'void');
  }

  Future<void> test_genericTypeAlias_noReturnType() async {
    var unitOutline = await _computeOutline('''
typedef F = Function();
''');
    var topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(1));
    // F
    var outline_F = topOutlines[0];
    var element_F = outline_F.element;
    expect(element_F.kind, ElementKind.FUNCTION_TYPE_ALIAS);
    expect(element_F.name, 'F');
    {
      var location = element_F.location;
      expect(location.offset, testCode.indexOf('F ='));
      expect(location.length, 'F'.length);
    }
    expect(element_F.parameters, '()');
    expect(element_F.returnType, '');
  }

  Future<void> test_groupAndTest() async {
    var outline = await _computeOutline('''
void group(name, closure) {}
void test(name) {}
void main() {
  group('group1', () {
    group('group1_1', () {
      test('test1_1_1');
      test('test1_1_2');
    });
    group('group1_2', () {
      test('test1_2_1');
    });
  });
  group('group2', () {
      test('test2_1');
      test('test2_2');
  });
}
''');
    // unit
    var unit_children = outline.children;
    expect(unit_children, hasLength(3));
    // main
    var main_outline = unit_children[2];
    _expect(main_outline,
        kind: ElementKind.FUNCTION,
        name: 'main',
        offset: testCode.indexOf('main() {'),
        parameters: '()',
        returnType: 'void');
    var main_children = main_outline.children;
    expect(main_children, hasLength(2));
    // group1
    var group1_outline = main_children[0];
    _expect(group1_outline,
        kind: ElementKind.UNIT_TEST_GROUP,
        length: 5,
        name: 'group("group1")',
        offset: testCode.indexOf("group('group1'"));
    var group1_children = group1_outline.children;
    expect(group1_children, hasLength(2));
    // group1_1
    var group1_1_outline = group1_children[0];
    _expect(group1_1_outline,
        kind: ElementKind.UNIT_TEST_GROUP,
        length: 5,
        name: 'group("group1_1")',
        offset: testCode.indexOf("group('group1_1'"));
    var group1_1_children = group1_1_outline.children;
    expect(group1_1_children, hasLength(2));
    // test1_1_1
    var test1_1_1_outline = group1_1_children[0];
    _expect(test1_1_1_outline,
        kind: ElementKind.UNIT_TEST_TEST,
        leaf: true,
        length: 4,
        name: 'test("test1_1_1")',
        offset: testCode.indexOf("test('test1_1_1'"));
    // test1_1_1
    var test1_1_2_outline = group1_1_children[1];
    _expect(test1_1_2_outline,
        kind: ElementKind.UNIT_TEST_TEST,
        leaf: true,
        length: 4,
        name: 'test("test1_1_2")',
        offset: testCode.indexOf("test('test1_1_2'"));
    // group1_2
    var group1_2_outline = group1_children[1];
    _expect(group1_2_outline,
        kind: ElementKind.UNIT_TEST_GROUP,
        length: 5,
        name: 'group("group1_2")',
        offset: testCode.indexOf("group('group1_2'"));
    var group1_2_children = group1_2_outline.children;
    expect(group1_2_children, hasLength(1));
    // test2_1
    var test1_2_1_outline = group1_2_children[0];
    _expect(test1_2_1_outline,
        kind: ElementKind.UNIT_TEST_TEST,
        leaf: true,
        length: 4,
        name: 'test("test1_2_1")',
        offset: testCode.indexOf("test('test1_2_1'"));
    // group2
    var group2_outline = main_children[1];
    _expect(group2_outline,
        kind: ElementKind.UNIT_TEST_GROUP,
        length: 5,
        name: 'group("group2")',
        offset: testCode.indexOf("group('group2'"));
    var group2_children = group2_outline.children;
    expect(group2_children, hasLength(2));
    // test2_1
    var test2_1_outline = group2_children[0];
    _expect(test2_1_outline,
        kind: ElementKind.UNIT_TEST_TEST,
        leaf: true,
        length: 4,
        name: 'test("test2_1")',
        offset: testCode.indexOf("test('test2_1'"));
    // test2_2
    var test2_2_outline = group2_children[1];
    _expect(test2_2_outline,
        kind: ElementKind.UNIT_TEST_TEST,
        leaf: true,
        length: 4,
        name: 'test("test2_2")',
        offset: testCode.indexOf("test('test2_2'"));
  }

  /// Code like this caused NPE in the past.
  ///
  /// https://code.google.com/p/dart/issues/detail?id=21373
  Future<void> test_invalidGetterInConstructor() async {
    var outline = await _computeOutline('''
class A {
  A() {
    get badGetter {
      const int CONST = 0;
    }
  }
}
''');
    expect(outline, isNotNull);
  }

  /// Code like this caused Dart2 failure in the past.
  ///
  /// https://github.com/dart-lang/sdk/issues/33228
  Future<void> test_invocation_ofParameter() async {
    var outline = await _computeOutline('''
main(p()) {
  p();
}
''');
    expect(outline, isNotNull);
  }

  Future<void> test_isTest_isTestGroup() async {
    writeTestPackageConfig(meta: true);
    var outline = await _computeOutline('''
import 'package:meta/meta.dart';

@isTestGroup
void myGroup(name, body()) {}

@isTest
void myTest(name) {}

void main() {
  myGroup('group1', () {
    myGroup('group1_1', () {
      myTest('test1_1_1');
      myTest('test1_1_2');
    });
    myGroup('group1_2', () {
      myTest('test1_2_1');
    });
  });
  myGroup('group2', () {
    myTest('test2_1');
    myTest('test2_2');
  });
}
''');
    // unit
    var unit_children = outline.children;
    expect(unit_children, hasLength(3));
    // main
    var main_outline = unit_children[2];
    _expect(main_outline,
        kind: ElementKind.FUNCTION,
        name: 'main',
        offset: testCode.indexOf('main() {'),
        parameters: '()',
        returnType: 'void');
    var main_children = main_outline.children;
    expect(main_children, hasLength(2));
    // group1
    var group1_outline = main_children[0];
    _expect(group1_outline,
        kind: ElementKind.UNIT_TEST_GROUP,
        length: 7,
        name: 'myGroup("group1")',
        offset: testCode.indexOf("myGroup('group1'"));
    var group1_children = group1_outline.children;
    expect(group1_children, hasLength(2));
    // group1_1
    var group1_1_outline = group1_children[0];
    _expect(group1_1_outline,
        kind: ElementKind.UNIT_TEST_GROUP,
        length: 7,
        name: 'myGroup("group1_1")',
        offset: testCode.indexOf("myGroup('group1_1'"));
    var group1_1_children = group1_1_outline.children;
    expect(group1_1_children, hasLength(2));
    // test1_1_1
    var test1_1_1_outline = group1_1_children[0];
    _expect(test1_1_1_outline,
        kind: ElementKind.UNIT_TEST_TEST,
        leaf: true,
        length: 6,
        name: 'myTest("test1_1_1")',
        offset: testCode.indexOf("myTest('test1_1_1'"));
    // test1_1_1
    var test1_1_2_outline = group1_1_children[1];
    _expect(test1_1_2_outline,
        kind: ElementKind.UNIT_TEST_TEST,
        leaf: true,
        length: 6,
        name: 'myTest("test1_1_2")',
        offset: testCode.indexOf("myTest('test1_1_2'"));
    // group1_2
    var group1_2_outline = group1_children[1];
    _expect(group1_2_outline,
        kind: ElementKind.UNIT_TEST_GROUP,
        length: 7,
        name: 'myGroup("group1_2")',
        offset: testCode.indexOf("myGroup('group1_2'"));
    var group1_2_children = group1_2_outline.children;
    expect(group1_2_children, hasLength(1));
    // test2_1
    var test1_2_1_outline = group1_2_children[0];
    _expect(test1_2_1_outline,
        kind: ElementKind.UNIT_TEST_TEST,
        leaf: true,
        length: 6,
        name: 'myTest("test1_2_1")',
        offset: testCode.indexOf("myTest('test1_2_1'"));
    // group2
    var group2_outline = main_children[1];
    _expect(group2_outline,
        kind: ElementKind.UNIT_TEST_GROUP,
        length: 7,
        name: 'myGroup("group2")',
        offset: testCode.indexOf("myGroup('group2'"));
    var group2_children = group2_outline.children;
    expect(group2_children, hasLength(2));
    // test2_1
    var test2_1_outline = group2_children[0];
    _expect(test2_1_outline,
        kind: ElementKind.UNIT_TEST_TEST,
        leaf: true,
        length: 6,
        name: 'myTest("test2_1")',
        offset: testCode.indexOf("myTest('test2_1'"));
    // test2_2
    var test2_2_outline = group2_children[1];
    _expect(test2_2_outline,
        kind: ElementKind.UNIT_TEST_TEST,
        leaf: true,
        length: 6,
        name: 'myTest("test2_2")',
        offset: testCode.indexOf("myTest('test2_2'"));
  }

  Future<void> test_localFunctions() async {
    var unitOutline = await _computeOutline('''
class A {
  A() {
    int local_A() {}
  }
  m() {
    local_m() {}
  }
}
f() {
  local_f1(int i) {}
  local_f2(String s) {
    local_f21(int p) {}
  }
}
''');
    var topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(2));
    // A
    {
      var outline_A = topOutlines[0];
      var element_A = outline_A.element;
      expect(element_A.kind, ElementKind.CLASS);
      expect(element_A.name, 'A');
      {
        var location = element_A.location;
        expect(location.offset, testCode.indexOf('A {'));
        expect(location.length, 'A'.length);
      }
      expect(element_A.parameters, null);
      expect(element_A.returnType, null);
      // A children
      var outlines_A = outline_A.children;
      expect(outlines_A, hasLength(2));
      {
        var constructorOutline = outlines_A[0];
        var constructorElement = constructorOutline.element;
        expect(constructorElement.kind, ElementKind.CONSTRUCTOR);
        expect(constructorElement.name, 'A');
        {
          var location = constructorElement.location;
          expect(location.offset, testCode.indexOf('A() {'));
          expect(location.length, 'A'.length);
        }
        expect(constructorElement.parameters, '()');
        expect(constructorElement.returnType, isNull);
        // local function
        var outlines_constructor = constructorOutline.children;
        expect(outlines_constructor, hasLength(1));
        {
          var outline = outlines_constructor[0];
          var element = outline.element;
          expect(element.kind, ElementKind.FUNCTION);
          expect(element.name, 'local_A');
          {
            var location = element.location;
            expect(location.offset, testCode.indexOf('local_A() {}'));
            expect(location.length, 'local_A'.length);
          }
          expect(element.parameters, '()');
          expect(element.returnType, 'int');
        }
      }
      {
        var outline_m = outlines_A[1];
        var element_m = outline_m.element;
        expect(element_m.kind, ElementKind.METHOD);
        expect(element_m.name, 'm');
        {
          var location = element_m.location;
          expect(location.offset, testCode.indexOf('m() {'));
          expect(location.length, 'm'.length);
        }
        expect(element_m.parameters, '()');
        expect(element_m.returnType, '');
        // local function
        var methodChildren = outline_m.children;
        expect(methodChildren, hasLength(1));
        {
          var outline = methodChildren[0];
          var element = outline.element;
          expect(element.kind, ElementKind.FUNCTION);
          expect(element.name, 'local_m');
          {
            var location = element.location;
            expect(location.offset, testCode.indexOf('local_m() {}'));
            expect(location.length, 'local_m'.length);
          }
          expect(element.parameters, '()');
          expect(element.returnType, '');
        }
      }
    }
    // f()
    {
      var outline_f = topOutlines[1];
      var element_f = outline_f.element;
      expect(element_f.kind, ElementKind.FUNCTION);
      expect(element_f.name, 'f');
      {
        var location = element_f.location;
        expect(location.offset, testCode.indexOf('f() {'));
        expect(location.length, 'f'.length);
      }
      expect(element_f.parameters, '()');
      expect(element_f.returnType, '');
      // f() children
      var outlines_f = outline_f.children;
      expect(outlines_f, hasLength(2));
      {
        var outline_f1 = outlines_f[0];
        var element_f1 = outline_f1.element;
        expect(element_f1.kind, ElementKind.FUNCTION);
        expect(element_f1.name, 'local_f1');
        {
          var location = element_f1.location;
          expect(location.offset, testCode.indexOf('local_f1(int i) {}'));
          expect(location.length, 'local_f1'.length);
        }
        expect(element_f1.parameters, '(int i)');
        expect(element_f1.returnType, '');
      }
      {
        var outline_f2 = outlines_f[1];
        var element_f2 = outline_f2.element;
        expect(element_f2.kind, ElementKind.FUNCTION);
        expect(element_f2.name, 'local_f2');
        {
          var location = element_f2.location;
          expect(location.offset, testCode.indexOf('local_f2(String s) {'));
          expect(location.length, 'local_f2'.length);
        }
        expect(element_f2.parameters, '(String s)');
        expect(element_f2.returnType, '');
        // local_f2() local function
        var outlines_f2 = outline_f2.children;
        expect(outlines_f2, hasLength(1));
        {
          var outline_f21 = outlines_f2[0];
          var element_f21 = outline_f21.element;
          expect(element_f21.kind, ElementKind.FUNCTION);
          expect(element_f21.name, 'local_f21');
          {
            var location = element_f21.location;
            expect(location.offset, testCode.indexOf('local_f21(int p) {'));
            expect(location.length, 'local_f21'.length);
          }
          expect(element_f21.parameters, '(int p)');
          expect(element_f21.returnType, '');
        }
      }
    }
  }

  Future<void> test_mixin() async {
    var unitOutline = await _computeOutline('''
mixin M<N> {
  c(int d) {}
  String get e => null;
  set f(int g) {}
}
''');
    var topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(1));
    // M
    {
      var outline_M = topOutlines[0];
      var element_M = outline_M.element;
      expect(element_M.kind, ElementKind.MIXIN);
      expect(element_M.name, 'M');
      expect(element_M.typeParameters, '<N>');
      {
        var location = element_M.location;
        expect(location.offset, testCode.indexOf('M<N>'));
        expect(location.length, 1);
      }
      expect(element_M.parameters, isNull);
      expect(element_M.returnType, isNull);
      // M children
      var outlines_M = outline_M.children;
      expect(outlines_M, hasLength(3));
      {
        var outline = outlines_M[0];
        var element = outline.element;
        expect(element.kind, ElementKind.METHOD);
        expect(element.name, 'c');
        {
          var location = element.location;
          expect(location.offset, testCode.indexOf('c(int d)'));
          expect(location.length, 1);
        }
        expect(element.parameters, '(int d)');
        expect(element.returnType, '');
        expect(element.isAbstract, isFalse);
        expect(element.isStatic, isFalse);
      }
      {
        var outline = outlines_M[1];
        var element = outline.element;
        expect(element.kind, ElementKind.GETTER);
        expect(element.name, 'e');
        {
          var location = element.location;
          expect(location.offset, testCode.indexOf('e => null'));
          expect(location.length, 1);
        }
        expect(element.parameters, isNull);
        expect(element.returnType, 'String');
      }
      {
        var outline = outlines_M[2];
        var element = outline.element;
        expect(element.kind, ElementKind.SETTER);
        expect(element.name, 'f');
        {
          var location = element.location;
          expect(location.offset, testCode.indexOf('f(int g)'));
          expect(location.length, 1);
        }
        expect(element.parameters, '(int g)');
        expect(element.returnType, '');
      }
    }
  }

  Future<void> test_sourceRanges_fields() async {
    var unitOutline = await _computeOutline('''
class A {
  int fieldA, fieldB = 2;
  
  int fieldC;
  
  /// Documentation.
  int fieldD;
}
''');
    var outlines = unitOutline.children[0].children;
    expect(outlines, hasLength(4));

    // fieldA
    {
      var outline = outlines[0];
      var element = outline.element;
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, 'fieldA');

      expect(outline.offset, 12);
      expect(outline.length, 10);

      expect(outline.codeOffset, 16);
      expect(outline.codeLength, 6);
    }

    // fieldB
    {
      var outline = outlines[1];
      var element = outline.element;
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, 'fieldB');

      expect(outline.offset, 24);
      expect(outline.length, 11);

      expect(outline.codeOffset, 24);
      expect(outline.codeLength, 10);
    }

    // fieldC
    {
      var outline = outlines[2];
      var element = outline.element;
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, 'fieldC');

      expect(outline.offset, 41);
      expect(outline.length, 11);

      expect(outline.codeOffset, 45);
      expect(outline.codeLength, 6);
    }

    // fieldD
    {
      var outline = outlines[3];
      var element = outline.element;
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, 'fieldD');

      expect(outline.offset, 58);
      expect(outline.length, 32);

      expect(outline.codeOffset, 83);
      expect(outline.codeLength, 6);
    }
  }

  Future<void> test_sourceRanges_inUnit() async {
    var unitOutline = await _computeOutline('''
/// My first class.
class A {}

class B {}
''');
    var topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(2));

    // A
    {
      var outline = topOutlines[0];
      var element = outline.element;
      expect(element.kind, ElementKind.CLASS);
      expect(element.name, 'A');

      expect(outline.offset, 0);
      expect(outline.length, 30);

      expect(outline.codeOffset, 20);
      expect(outline.codeLength, 10);
    }

    // B
    {
      var outline = topOutlines[1];
      var element = outline.element;
      expect(element.kind, ElementKind.CLASS);
      expect(element.name, 'B');

      expect(outline.offset, 32);
      expect(outline.length, 10);

      expect(outline.codeOffset, 32);
      expect(outline.codeLength, 10);
    }
  }

  Future<void> test_sourceRanges_method() async {
    var unitOutline = await _computeOutline('''
class A {
  int methodA() {}
  
  /// Documentation.
  @override
  int methodB() {}
}
''');
    var outlines = unitOutline.children[0].children;
    expect(outlines, hasLength(2));

    // methodA
    {
      var outline = outlines[0];
      var element = outline.element;
      expect(element.kind, ElementKind.METHOD);
      expect(element.name, 'methodA');

      expect(outline.offset, 12);
      expect(outline.length, 16);

      expect(outline.codeOffset, 12);
      expect(outline.codeLength, 16);
    }

    // methodB
    {
      var outline = outlines[1];
      var element = outline.element;
      expect(element.kind, ElementKind.METHOD);
      expect(element.name, 'methodB');

      expect(outline.offset, 34);
      expect(outline.length, 49);

      expect(outline.codeOffset, 67);
      expect(outline.codeLength, 16);
    }
  }

  Future<void> test_topLevel() async {
    var unitOutline = await _computeOutline('''
typedef String FTA<K, V>(int i, String s);
typedef FTB(int p);
typedef GTAF<T> = void Function<S>(T t, S s);
class A<T> {}
class B {}
class CTA<T> = A<T> with B;
class CTB = A with B;
String fA(int i, String s) => null;
fB(int p) => null;
String get propA => null;
set propB(int v) {}
''');
    var topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(11));
    // FTA
    {
      var outline = topOutlines[0];
      var element = outline.element;
      expect(element.kind, ElementKind.FUNCTION_TYPE_ALIAS);
      expect(element.name, 'FTA');
      expect(element.typeParameters, '<K, V>');
      {
        var location = element.location;
        expect(location.offset, testCode.indexOf('FTA<K, V>('));
        expect(location.length, 'FTA'.length);
      }
      expect(element.parameters, '(int i, String s)');
      expect(element.returnType, 'String');
    }
    // FTB
    {
      var outline = topOutlines[1];
      var element = outline.element;
      expect(element.kind, ElementKind.FUNCTION_TYPE_ALIAS);
      expect(element.name, 'FTB');
      expect(element.typeParameters, isNull);
      {
        var location = element.location;
        expect(location.offset, testCode.indexOf('FTB('));
        expect(location.length, 'FTB'.length);
      }
      expect(element.parameters, '(int p)');
      expect(element.returnType, '');
    }
    // GenericTypeAlias - function
    {
      var outline = topOutlines[2];
      var element = outline.element;
      expect(element.kind, ElementKind.FUNCTION_TYPE_ALIAS);
      expect(element.name, 'GTAF');
      expect(element.typeParameters, '<T>');
      {
        var location = element.location;
        expect(location.offset, testCode.indexOf('GTAF<T> ='));
        expect(location.length, 'GTAF'.length);
      }
      expect(element.parameters, '(T t, S s)');
      expect(element.returnType, 'void');
    }
    // CTA
    {
      var outline = topOutlines[5];
      var element = outline.element;
      expect(element.kind, ElementKind.CLASS_TYPE_ALIAS);
      expect(element.name, 'CTA');
      expect(element.typeParameters, '<T>');
      {
        var location = element.location;
        expect(location.offset, testCode.indexOf('CTA<T> ='));
        expect(location.length, 'CTA'.length);
      }
      expect(element.parameters, isNull);
      expect(element.returnType, isNull);
    }
    // CTB
    {
      var outline = topOutlines[6];
      var element = outline.element;
      expect(element.kind, ElementKind.CLASS_TYPE_ALIAS);
      expect(element.name, 'CTB');
      expect(element.typeParameters, isNull);
      expect(element.returnType, isNull);
    }
    // fA
    {
      var outline = topOutlines[7];
      var element = outline.element;
      expect(element.kind, ElementKind.FUNCTION);
      expect(element.name, 'fA');
      {
        var location = element.location;
        expect(location.offset, testCode.indexOf('fA('));
        expect(location.length, 'fA'.length);
      }
      expect(element.parameters, '(int i, String s)');
      expect(element.returnType, 'String');
    }
    // fB
    {
      var outline = topOutlines[8];
      var element = outline.element;
      expect(element.kind, ElementKind.FUNCTION);
      expect(element.name, 'fB');
      {
        var location = element.location;
        expect(location.offset, testCode.indexOf('fB('));
        expect(location.length, 'fB'.length);
      }
      expect(element.parameters, '(int p)');
      expect(element.returnType, '');
    }
    // propA
    {
      var outline = topOutlines[9];
      var element = outline.element;
      expect(element.kind, ElementKind.GETTER);
      expect(element.name, 'propA');
      {
        var location = element.location;
        expect(location.offset, testCode.indexOf('propA => null;'));
        expect(location.length, 'propA'.length);
      }
      expect(element.parameters, '');
      expect(element.returnType, 'String');
    }
    // propB
    {
      var outline = topOutlines[10];
      var element = outline.element;
      expect(element.kind, ElementKind.SETTER);
      expect(element.name, 'propB');
      {
        var location = element.location;
        expect(location.offset, testCode.indexOf('propB(int v) {}'));
        expect(location.length, 'propB'.length);
      }
      expect(element.parameters, '(int v)');
      expect(element.returnType, '');
    }
  }

  void _expect(Outline outline,
      {ElementKind kind,
      bool leaf = false,
      int length,
      String name,
      int offset,
      String parameters,
      String returnType}) {
    var element = outline.element;
    var location = element.location;

    if (kind != null) {
      expect(element.kind, kind);
    }
    if (leaf) {
      expect(outline.children, isNull);
    }
    length ??= name?.length;
    if (length != null) {
      expect(location.length, length);
    }
    if (name != null) {
      expect(element.name, name);
    }
    if (offset != null) {
      expect(location.offset, offset);
    }
    if (parameters != null) {
      expect(element.parameters, parameters);
    }
    if (returnType != null) {
      expect(element.returnType, returnType);
    }
  }

  void _isEnumConstant(Outline outline, String name) {
    var element = outline.element;
    expect(element.kind, ElementKind.ENUM_CONSTANT);
    expect(element.name, name);
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
  }
}
