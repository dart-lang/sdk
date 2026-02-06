// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';
import '../../utils/test_code_extensions.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterOutlineComputerTest);
    defineReflectiveTests(OutlineComputerTest);
  });
}

class AbstractOutlineComputerTest extends AbstractContextTest {
  late TestCode parsedTestCode;
  late String testPath;
  late String testCode;

  @override
  void setUp() {
    super.setUp();
    testPath = convertPath('$testPackageLibPath/test.dart');
  }

  Future<Outline> _computeOutline(String code) async {
    parsedTestCode = TestCode.parseNormalized(code);
    testCode = parsedTestCode.code;
    newFile(testPath, testCode);
    var resolveResult = await getResolvedUnit(testFile);
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
    var myWidget = unitOutline.children![0];
    var build = myWidget.children![0];

    var columnOutline = build.children![0];
    {
      var offset = testCode.indexOf('new Column');
      var length = testCode.indexOf('; // Column') - offset;
      _expect(
        columnOutline,
        name: 'Column',
        elementOffset: offset,
        offset: offset,
        length: length,
      );
    }

    {
      var textOutline = columnOutline.children![0];
      var text = "const Text('aaa')";
      var offset = testCode.indexOf(text);
      _expect(
        textOutline,
        name: "Text('aaa')",
        elementOffset: offset,
        offset: offset,
        length: text.length,
      );
    }

    {
      var textOutline = columnOutline.children![1];
      var text = "const Text('bbb')";
      var offset = testCode.indexOf(text);
      _expect(
        textOutline,
        name: "Text('bbb')",
        elementOffset: offset,
        offset: offset,
        length: text.length,
      );
    }
  }

  void _expect(
    Outline outline, {
    required String name,
    required int elementOffset,
    required int offset,
    required int length,
  }) {
    var element = outline.element;
    expect(element.name, name);
    expect(element.location!.offset, elementOffset);
    expect(outline.offset, offset);
    expect(outline.length, length);
  }

  static String _toText(Outline outline) {
    var buffer = StringBuffer();

    void writeOutline(Outline outline, String indent) {
      buffer.write(indent);
      buffer.writeln(outline.element.name);
      for (var child in outline.children ?? const <Outline>[]) {
        writeOutline(child, '$indent  ');
      }
    }

    for (var child in outline.children!) {
      writeOutline(child, '');
    }
    return buffer.toString();
  }
}

@reflectiveTest
class OutlineComputerTest extends AbstractOutlineComputerTest {
  void assertJson(Object object, Map<String, dynamic> expected) {
    var expectedJson = JsonEncoder.withIndent('  ').convert(expected);
    var actual = JsonEncoder.withIndent('  ').convert(object);
    if (actual != expectedJson) {
      print('-----');
      print(actual);
      print('-----');
    }
    expect(actual, expectedJson);
  }

  Matcher hasCodeOffsetLength(TestCodeRange range) {
    return TypeMatcher<Outline>()
        .having(
          (outline) => outline.codeOffset,
          'codeOffset',
          range.sourceRange.offset,
        )
        .having(
          (outline) => outline.codeLength,
          'codeLength',
          range.sourceRange.length,
        );
  }

  Matcher hasOffsetLength(TestCodeRange range) {
    return TypeMatcher<Outline>()
        .having((outline) => outline.offset, 'offset', range.sourceRange.offset)
        .having(
          (outline) => outline.length,
          'length',
          range.sourceRange.length,
        );
  }

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
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(4));
    // A
    {
      var outline_A = topOutlines[0];
      var element_A = outline_A.element;
      expect(element_A.kind, ElementKind.CLASS);
      expect(element_A.name, 'A');
      expect(element_A.typeParameters, '<K, V>');
      {
        var location = element_A.location!;
        expect(location.offset, testCode.indexOf('A<K, V> {'));
        expect(location.length, 1);
      }
      expect(element_A.parameters, null);
      expect(element_A.returnType, null);
      // A children
      var outlines_A = outline_A.children!;
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
          var location = element.location!;
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
          var location = element.location!;
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
          var location = element.location!;
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
          var location = element.location!;
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
          var location = element.location!;
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
          var location = element.location!;
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
          var location = element.location!;
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
          var location = element.location!;
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
        var location = element_B.location!;
        expect(location.offset, testCode.indexOf('B {'));
        expect(location.length, 1);
      }
      expect(element_B.parameters, null);
      expect(element_B.returnType, null);
      // B children
      var outlines_B = outline_B.children!;
      expect(outlines_B, hasLength(1));
      {
        var outline = outlines_B[0];
        var element = outline.element;
        expect(element.kind, ElementKind.CONSTRUCTOR);
        expect(element.name, 'B');
        {
          var location = element.location!;
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
        var location = element.location!;
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
        var location = element.location!;
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

  Future<void> test_class_augment() async {
    newFile('$testPackageLibPath/a.dart', '''
part 'test.dart';

class C {
  // Ensure that the outline for the augment doesn't include members from the
  // augmented class.
  void n() {}
}
''');
    var unitOutline = await _computeOutline('''
part of 'a.dart';

augment class C {
  String f = '';
  C();
  C.named();
  void m() {}
  augment m() {}
}
''');
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));
    // C
    var outline_C = topOutlines[0];
    var element_C = outline_C.element;
    expect(element_C.kind, ElementKind.CLASS);
    expect(element_C.name, 'C');
    // C children
    var outlines_C = outline_C.children!;
    expect(outlines_C, hasLength(5));
    // C.f
    var outline_f = outlines_C[0];
    var element_f = outline_f.element;
    expect(element_f.kind, ElementKind.FIELD);
    expect(element_f.name, 'f');
    // C.new
    var outline_new = outlines_C[1];
    var element_new = outline_new.element;
    expect(element_new.kind, ElementKind.CONSTRUCTOR);
    expect(element_new.name, 'C');
    // C.named
    var outline_named = outlines_C[2];
    var element_named = outline_named.element;
    expect(element_named.kind, ElementKind.CONSTRUCTOR);
    expect(element_named.name, 'C.named');
    // C.m
    var outline_m = outlines_C[3];
    var element_m = outline_m.element;
    expect(element_m.kind, ElementKind.METHOD);
    expect(element_m.name, 'm');
    expect(element_m.location?.offset, testCode.indexOf('m()'));
    // C.m augmented
    var outline_ma = outlines_C[4];
    var element_ma = outline_ma.element;
    expect(element_ma.kind, ElementKind.METHOD);
    expect(element_ma.name, 'm');
    expect(
      element_ma.location?.offset,
      testCode.indexOf('m()', testCode.indexOf('m()') + 1),
    );
  }

  Future<void> test_enum_constants() async {
    var unitOutline = await _computeOutline('''
/*[0*/enum /*[1*/E/*1]*/ {
  /*[2*/v1/*2]*/, /*[3*/v2/*3]*/
}/*0]*/
''');

    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));

    assertJson(topOutlines[0], {
      'element': {
        'kind': 'ENUM',
        'name': 'E',
        'location': _elementLocation(parsedTestCode.ranges[1]),
        'flags': 0,
      },
      ..._location(parsedTestCode.ranges[0], parsedTestCode.ranges[0]),
      'children': [
        {
          'element': {
            'kind': 'ENUM_CONSTANT',
            'name': 'v1',
            'location': _elementLocation(parsedTestCode.ranges[2]),
            'flags': 0,
          },
          ..._location(parsedTestCode.ranges[2], parsedTestCode.ranges[2]),
        },
        {
          'element': {
            'kind': 'ENUM_CONSTANT',
            'name': 'v2',
            'location': _elementLocation(parsedTestCode.ranges[3]),
            'flags': 0,
          },
          ..._location(parsedTestCode.ranges[3], parsedTestCode.ranges[3]),
        },
      ],
    });
  }

  Future<void> test_enum_members() async {
    var unitOutline = await _computeOutline('''
/*[0*/enum /*[1*/E/*1]*/ {
  /*[2*/v/*2]*/;
  /*[3*/final int /*[4*//*[5*/f/*4]*/ = 0/*5]*/;/*3]*/
  /*[6*/const /*[7*/E/*7]*/();/*6]*/
  /*[8*/const E./*[9*/named/*9]*/();/*8]*/
  /*[10*/void /*[11*/aMethod/*11]*/() {}/*10]*/;
  /*[12*/int get /*[13*/aGetter/*13]*/ => 0;/*12]*/
  /*[14*/set /*[15*/aSetter/*15]*/(int value) {}/*14]*/;
}/*0]*/
''');

    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));

    assertJson(topOutlines[0], {
      'element': {
        'kind': 'ENUM',
        'name': 'E',
        'location': _elementLocation(parsedTestCode.ranges[1]),
        'flags': 0,
      },
      ..._location(parsedTestCode.ranges[0], parsedTestCode.ranges[0]),
      'children': [
        {
          'element': {
            'kind': 'ENUM_CONSTANT',
            'name': 'v',
            'location': _elementLocation(parsedTestCode.ranges[2]),
            'flags': 0,
          },
          ..._location(parsedTestCode.ranges[2], parsedTestCode.ranges[2]),
        },
        {
          'element': {
            'kind': 'FIELD',
            'name': 'f',
            'location': _elementLocation(parsedTestCode.ranges[4]),
            'flags': 4,
            'returnType': 'int',
          },
          ..._location(parsedTestCode.ranges[3], parsedTestCode.ranges[5]),
        },
        {
          'element': {
            'kind': 'CONSTRUCTOR',
            'name': 'E',
            'location': _elementLocation(parsedTestCode.ranges[7]),
            'flags': 0,
            'parameters': '()',
          },
          ..._location(parsedTestCode.ranges[6], parsedTestCode.ranges[6]),
        },
        {
          'element': {
            'kind': 'CONSTRUCTOR',
            'name': 'E.named',
            'location': _elementLocation(parsedTestCode.ranges[9]),
            'flags': 0,
            'parameters': '()',
          },
          ..._location(parsedTestCode.ranges[8], parsedTestCode.ranges[8]),
        },
        {
          'element': {
            'kind': 'METHOD',
            'name': 'aMethod',
            'location': _elementLocation(parsedTestCode.ranges[11]),
            'flags': 0,
            'parameters': '()',
            'returnType': 'void',
          },
          ..._location(parsedTestCode.ranges[10], parsedTestCode.ranges[10]),
        },
        {
          'element': {
            'kind': 'GETTER',
            'name': 'aGetter',
            'location': _elementLocation(parsedTestCode.ranges[13]),
            'flags': 0,
            'returnType': 'int',
          },
          ..._location(parsedTestCode.ranges[12], parsedTestCode.ranges[12]),
        },
        {
          'element': {
            'kind': 'SETTER',
            'name': 'aSetter',
            'location': _elementLocation(parsedTestCode.ranges[15]),
            'flags': 0,
            'parameters': '(int value)',
            'returnType': '',
          },
          ..._location(parsedTestCode.ranges[14], parsedTestCode.ranges[14]),
        },
      ],
    });
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
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));
    // MyExt
    {
      var outline_MyExt = topOutlines[0];
      var element_MyExt = outline_MyExt.element;
      expect(element_MyExt.kind, ElementKind.EXTENSION);
      expect(element_MyExt.name, 'MyExt');
      {
        var location = element_MyExt.location!;
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
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));
    // MyExt
    {
      var outline_MyExt = topOutlines[0];
      var element_MyExt = outline_MyExt.element;
      expect(element_MyExt.kind, ElementKind.EXTENSION);
      expect(element_MyExt.name, '');
      {
        var location = element_MyExt.location!;
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

  Future<void> test_extensionType() async {
    var unitOutline = await _computeOutline('''
extension type A(int it) {
  int get foo => 0;
}
''');
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));
    // MyExt
    {
      var outline = topOutlines[0];
      var element = outline.element;
      expect(element.kind, ElementKind.EXTENSION_TYPE);
      expect(element.name, 'A');
      {
        var location = element.location!;
        expect(location.offset, testCode.indexOf('A'));
        expect(location.length, 'A'.length);
      }
      expect(element.parameters, null);
      expect(element.returnType, null);
      var outlines_A = outline.children;
      expect(outlines_A, hasLength(1));
    }
  }

  Future<void> test_factoryMethod_after() async {
    var unitOutline = await _computeOutline('''
class C {
  factory() => C();
}
''');
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));

    var outline_C = topOutlines[0];
    var element_C = outline_C.element;
    expect(element_C.kind, ElementKind.CLASS);
    expect(element_C.name, 'C');

    var outlines_C = outline_C.children!;
    expect(outlines_C, hasLength(1));

    var outline = outlines_C[0];
    var element = outline.element;
    expect(element.kind, ElementKind.CONSTRUCTOR);
    expect(element.name, '<unknown>');
  }

  Future<void> test_factoryMethod_before() async {
    var unitOutline = await _computeOutline('''
// @dart=3.10
class C {
  factory() => C();
}
''');
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));

    var outline_C = topOutlines[0];
    var element_C = outline_C.element;
    expect(element_C.kind, ElementKind.CLASS);
    expect(element_C.name, 'C');

    var outlines_C = outline_C.children!;
    expect(outlines_C, hasLength(1));

    var outline = outlines_C[0];
    var element = outline.element;
    expect(element.kind, ElementKind.METHOD);
    expect(element.name, 'factory');
  }

  Future<void> test_genericTypeAlias_functionType() async {
    var unitOutline = await _computeOutline('''
typedef F = void Function();
''');
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));
    // F
    var outline_F = topOutlines[0];
    var element_F = outline_F.element;
    expect(element_F.kind, ElementKind.FUNCTION_TYPE_ALIAS);
    expect(element_F.name, 'F');
    {
      var location = element_F.location!;
      expect(location.offset, testCode.indexOf('F ='));
      expect(location.length, 'F'.length);
    }
    expect(element_F.aliasedType, 'void Function()');
    expect(element_F.parameters, '()');
    expect(element_F.returnType, 'void');
    expect(element_F.typeParameters, isNull);
  }

  Future<void> test_genericTypeAlias_functionType_noReturnType() async {
    var unitOutline = await _computeOutline('''
typedef F = Function();
''');
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));
    // F
    var outline_F = topOutlines[0];
    var element_F = outline_F.element;
    expect(element_F.kind, ElementKind.FUNCTION_TYPE_ALIAS);
    expect(element_F.name, 'F');
    {
      var location = element_F.location!;
      expect(location.offset, testCode.indexOf('F ='));
      expect(location.length, 'F'.length);
    }
    expect(element_F.aliasedType, ' Function()');
    expect(element_F.parameters, '()');
    expect(element_F.returnType, '');
    expect(element_F.typeParameters, isNull);
  }

  Future<void> test_genericTypeAlias_interfaceType() async {
    var unitOutline = await _computeOutline('''
typedef F<T> = Map<int, T>;
''');
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));
    // F
    var outline_F = topOutlines[0];
    var element_F = outline_F.element;
    expect(element_F.kind, ElementKind.TYPE_ALIAS);
    expect(element_F.name, 'F');
    {
      var location = element_F.location!;
      expect(location.offset, testCode.indexOf('F<T> ='));
      expect(location.length, 'F'.length);
    }
    expect(element_F.aliasedType, 'Map<int, T>');
    expect(element_F.parameters, isNull);
    expect(element_F.returnType, isNull);
    expect(element_F.typeParameters, '<T>');
  }

  Future<void> test_groupAndTest() async {
    var outline = await _computeOutline('''
void group(name, closure) {}
void test(name) {}
void f() {
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
    var unit_children = outline.children!;
    expect(unit_children, hasLength(3));
    // f
    var f_outline = unit_children[2];
    _expect(
      f_outline,
      kind: ElementKind.FUNCTION,
      name: 'f',
      offset: testCode.indexOf('f() {'),
      parameters: '()',
      returnType: 'void',
    );
    var f_children = f_outline.children!;
    expect(f_children, hasLength(2));
    // group1
    var group1_outline = f_children[0];
    _expect(
      group1_outline,
      kind: ElementKind.UNIT_TEST_GROUP,
      length: 5,
      name: 'group("group1")',
      offset: testCode.indexOf("group('group1'"),
    );
    var group1_children = group1_outline.children!;
    expect(group1_children, hasLength(2));
    // group1_1
    var group1_1_outline = group1_children[0];
    _expect(
      group1_1_outline,
      kind: ElementKind.UNIT_TEST_GROUP,
      length: 5,
      name: 'group("group1_1")',
      offset: testCode.indexOf("group('group1_1'"),
    );
    var group1_1_children = group1_1_outline.children!;
    expect(group1_1_children, hasLength(2));
    // test1_1_1
    var test1_1_1_outline = group1_1_children[0];
    _expect(
      test1_1_1_outline,
      kind: ElementKind.UNIT_TEST_TEST,
      leaf: true,
      length: 4,
      name: 'test("test1_1_1")',
      offset: testCode.indexOf("test('test1_1_1'"),
    );
    // test1_1_1
    var test1_1_2_outline = group1_1_children[1];
    _expect(
      test1_1_2_outline,
      kind: ElementKind.UNIT_TEST_TEST,
      leaf: true,
      length: 4,
      name: 'test("test1_1_2")',
      offset: testCode.indexOf("test('test1_1_2'"),
    );
    // group1_2
    var group1_2_outline = group1_children[1];
    _expect(
      group1_2_outline,
      kind: ElementKind.UNIT_TEST_GROUP,
      length: 5,
      name: 'group("group1_2")',
      offset: testCode.indexOf("group('group1_2'"),
    );
    var group1_2_children = group1_2_outline.children!;
    expect(group1_2_children, hasLength(1));
    // test2_1
    var test1_2_1_outline = group1_2_children[0];
    _expect(
      test1_2_1_outline,
      kind: ElementKind.UNIT_TEST_TEST,
      leaf: true,
      length: 4,
      name: 'test("test1_2_1")',
      offset: testCode.indexOf("test('test1_2_1'"),
    );
    // group2
    var group2_outline = f_children[1];
    _expect(
      group2_outline,
      kind: ElementKind.UNIT_TEST_GROUP,
      length: 5,
      name: 'group("group2")',
      offset: testCode.indexOf("group('group2'"),
    );
    var group2_children = group2_outline.children!;
    expect(group2_children, hasLength(2));
    // test2_1
    var test2_1_outline = group2_children[0];
    _expect(
      test2_1_outline,
      kind: ElementKind.UNIT_TEST_TEST,
      leaf: true,
      length: 4,
      name: 'test("test2_1")',
      offset: testCode.indexOf("test('test2_1'"),
    );
    // test2_2
    var test2_2_outline = group2_children[1];
    _expect(
      test2_2_outline,
      kind: ElementKind.UNIT_TEST_TEST,
      leaf: true,
      length: 4,
      name: 'test("test2_2")',
      offset: testCode.indexOf("test('test2_2'"),
    );
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
void f(p()) {
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

void f() {
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
    var unit_children = outline.children!;
    expect(unit_children, hasLength(3));
    // f
    var f_outline = unit_children[2];
    _expect(
      f_outline,
      kind: ElementKind.FUNCTION,
      name: 'f',
      offset: testCode.indexOf('f() {'),
      parameters: '()',
      returnType: 'void',
    );
    var f_children = f_outline.children!;
    expect(f_children, hasLength(2));
    // group1
    var group1_outline = f_children[0];
    _expect(
      group1_outline,
      kind: ElementKind.UNIT_TEST_GROUP,
      length: 7,
      name: 'myGroup("group1")',
      offset: testCode.indexOf("myGroup('group1'"),
    );
    var group1_children = group1_outline.children!;
    expect(group1_children, hasLength(2));
    // group1_1
    var group1_1_outline = group1_children[0];
    _expect(
      group1_1_outline,
      kind: ElementKind.UNIT_TEST_GROUP,
      length: 7,
      name: 'myGroup("group1_1")',
      offset: testCode.indexOf("myGroup('group1_1'"),
    );
    var group1_1_children = group1_1_outline.children!;
    expect(group1_1_children, hasLength(2));
    // test1_1_1
    var test1_1_1_outline = group1_1_children[0];
    _expect(
      test1_1_1_outline,
      kind: ElementKind.UNIT_TEST_TEST,
      leaf: true,
      length: 6,
      name: 'myTest("test1_1_1")',
      offset: testCode.indexOf("myTest('test1_1_1'"),
    );
    // test1_1_1
    var test1_1_2_outline = group1_1_children[1];
    _expect(
      test1_1_2_outline,
      kind: ElementKind.UNIT_TEST_TEST,
      leaf: true,
      length: 6,
      name: 'myTest("test1_1_2")',
      offset: testCode.indexOf("myTest('test1_1_2'"),
    );
    // group1_2
    var group1_2_outline = group1_children[1];
    _expect(
      group1_2_outline,
      kind: ElementKind.UNIT_TEST_GROUP,
      length: 7,
      name: 'myGroup("group1_2")',
      offset: testCode.indexOf("myGroup('group1_2'"),
    );
    var group1_2_children = group1_2_outline.children!;
    expect(group1_2_children, hasLength(1));
    // test2_1
    var test1_2_1_outline = group1_2_children[0];
    _expect(
      test1_2_1_outline,
      kind: ElementKind.UNIT_TEST_TEST,
      leaf: true,
      length: 6,
      name: 'myTest("test1_2_1")',
      offset: testCode.indexOf("myTest('test1_2_1'"),
    );
    // group2
    var group2_outline = f_children[1];
    _expect(
      group2_outline,
      kind: ElementKind.UNIT_TEST_GROUP,
      length: 7,
      name: 'myGroup("group2")',
      offset: testCode.indexOf("myGroup('group2'"),
    );
    var group2_children = group2_outline.children!;
    expect(group2_children, hasLength(2));
    // test2_1
    var test2_1_outline = group2_children[0];
    _expect(
      test2_1_outline,
      kind: ElementKind.UNIT_TEST_TEST,
      leaf: true,
      length: 6,
      name: 'myTest("test2_1")',
      offset: testCode.indexOf("myTest('test2_1'"),
    );
    // test2_2
    var test2_2_outline = group2_children[1];
    _expect(
      test2_2_outline,
      kind: ElementKind.UNIT_TEST_TEST,
      leaf: true,
      length: 6,
      name: 'myTest("test2_2")',
      offset: testCode.indexOf("myTest('test2_2'"),
    );
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
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(2));
    // A
    {
      var outline_A = topOutlines[0];
      var element_A = outline_A.element;
      expect(element_A.kind, ElementKind.CLASS);
      expect(element_A.name, 'A');
      {
        var location = element_A.location!;
        expect(location.offset, testCode.indexOf('A {'));
        expect(location.length, 'A'.length);
      }
      expect(element_A.parameters, null);
      expect(element_A.returnType, null);
      // A children
      var outlines_A = outline_A.children!;
      expect(outlines_A, hasLength(2));
      {
        var constructorOutline = outlines_A[0];
        var constructorElement = constructorOutline.element;
        expect(constructorElement.kind, ElementKind.CONSTRUCTOR);
        expect(constructorElement.name, 'A');
        {
          var location = constructorElement.location!;
          expect(location.offset, testCode.indexOf('A() {'));
          expect(location.length, 'A'.length);
        }
        expect(constructorElement.parameters, '()');
        expect(constructorElement.returnType, isNull);
        // local function
        var outlines_constructor = constructorOutline.children!;
        expect(outlines_constructor, hasLength(1));
        {
          var outline = outlines_constructor[0];
          var element = outline.element;
          expect(element.kind, ElementKind.FUNCTION);
          expect(element.name, 'local_A');
          {
            var location = element.location!;
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
          var location = element_m.location!;
          expect(location.offset, testCode.indexOf('m() {'));
          expect(location.length, 'm'.length);
        }
        expect(element_m.parameters, '()');
        expect(element_m.returnType, '');
        // local function
        var methodChildren = outline_m.children!;
        expect(methodChildren, hasLength(1));
        {
          var outline = methodChildren[0];
          var element = outline.element;
          expect(element.kind, ElementKind.FUNCTION);
          expect(element.name, 'local_m');
          {
            var location = element.location!;
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
        var location = element_f.location!;
        expect(location.offset, testCode.indexOf('f() {'));
        expect(location.length, 'f'.length);
      }
      expect(element_f.parameters, '()');
      expect(element_f.returnType, '');
      // f() children
      var outlines_f = outline_f.children!;
      expect(outlines_f, hasLength(2));
      {
        var outline_f1 = outlines_f[0];
        var element_f1 = outline_f1.element;
        expect(element_f1.kind, ElementKind.FUNCTION);
        expect(element_f1.name, 'local_f1');
        {
          var location = element_f1.location!;
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
          var location = element_f2.location!;
          expect(location.offset, testCode.indexOf('local_f2(String s) {'));
          expect(location.length, 'local_f2'.length);
        }
        expect(element_f2.parameters, '(String s)');
        expect(element_f2.returnType, '');
        // local_f2() local function
        var outlines_f2 = outline_f2.children!;
        expect(outlines_f2, hasLength(1));
        {
          var outline_f21 = outlines_f2[0];
          var element_f21 = outline_f21.element;
          expect(element_f21.kind, ElementKind.FUNCTION);
          expect(element_f21.name, 'local_f21');
          {
            var location = element_f21.location!;
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
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));
    // M
    {
      var outline_M = topOutlines[0];
      var element_M = outline_M.element;
      expect(element_M.kind, ElementKind.MIXIN);
      expect(element_M.name, 'M');
      expect(element_M.typeParameters, '<N>');
      {
        var location = element_M.location!;
        expect(location.offset, testCode.indexOf('M<N>'));
        expect(location.length, 1);
      }
      expect(element_M.parameters, isNull);
      expect(element_M.returnType, isNull);
      // M children
      var outlines_M = outline_M.children!;
      expect(outlines_M, hasLength(3));
      {
        var outline = outlines_M[0];
        var element = outline.element;
        expect(element.kind, ElementKind.METHOD);
        expect(element.name, 'c');
        {
          var location = element.location!;
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
          var location = element.location!;
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
          var location = element.location!;
          expect(location.offset, testCode.indexOf('f(int g)'));
          expect(location.length, 1);
        }
        expect(element.parameters, '(int g)');
        expect(element.returnType, '');
      }
    }
  }

  Future<void> test_primaryConstructor() async {
    var unitOutline = await _computeOutline('''
abstract class C(var int x, final int y, int z) {}
''');
    var topOutlines = unitOutline.children!;

    // The class `C`.
    expect(topOutlines, hasLength(1));
    var outline_C = topOutlines[0];
    var element_C = outline_C.element;
    expect(element_C.kind, ElementKind.CLASS);
    expect(element_C.name, 'C');
    var location = element_C.location!;
    expect(location.offset, testCode.indexOf('C('));
    expect(location.length, 1);

    var outlines_A = outline_C.children!;
    expect(outlines_A, hasLength(3));

    // The primary constructor
    var outline_A_new = outlines_A[0];
    var element_A_new = outline_A_new.element;
    expect(element_A_new.kind, ElementKind.CONSTRUCTOR);
    expect(element_A_new.name, 'C');
    expect(element_A_new.parameters, '(var int x, final int y, int z)');
    expect(element_A_new.returnType, isNull);

    // The field `x`
    var outline_x = outlines_A[1];
    var element_x = outline_x.element;
    expect(element_x.kind, ElementKind.FIELD);
    expect(element_x.isFinal, false);
    expect(element_x.name, 'x');
    expect(element_x.parameters, isNull);
    expect(element_x.returnType, 'int');

    // The field `y`
    var outline_y = outlines_A[2];
    var element_y = outline_y.element;
    expect(element_y.kind, ElementKind.FIELD);
    expect(element_y.isFinal, true);
    expect(element_y.name, 'y');
    expect(element_y.parameters, isNull);
    expect(element_y.returnType, 'int');
  }

  Future<void> test_primaryConstructor_noClassBody() async {
    var unitOutline = await _computeOutline('''
class C(var int x);
''');
    var topOutlines = unitOutline.children!;

    // The class `C`.
    expect(topOutlines, hasLength(1));
    var outline_C = topOutlines[0];
    var element_C = outline_C.element;
    expect(element_C.kind, ElementKind.CLASS);
    expect(element_C.name, 'C');
    var location = element_C.location!;
    expect(location.offset, testCode.indexOf('C('));
    expect(location.length, 1);

    var outlines_A = outline_C.children!;
    expect(outlines_A, hasLength(2));

    // The primary constructor
    var outline_A_new = outlines_A[0];
    var element_A_new = outline_A_new.element;
    expect(element_A_new.kind, ElementKind.CONSTRUCTOR);
    expect(element_A_new.name, 'C');
    expect(element_A_new.parameters, '(var int x)');
    expect(element_A_new.returnType, isNull);

    // The field `x`
    var outline_x = outlines_A[1];
    var element_x = outline_x.element;
    expect(element_x.kind, ElementKind.FIELD);
    expect(element_x.isFinal, false);
    expect(element_x.name, 'x');
    expect(element_x.parameters, isNull);
    expect(element_x.returnType, 'int');
  }

  Future<void> test_primaryConstructor_parameterDefault_issue62390() async {
    var unitOutline = await _computeOutline('''
class A([final int x = 0]) {}
''');

    var topOutlines = unitOutline.children!;

    expect(topOutlines, hasLength(1));

    // The class `A`.
    var outline_A = topOutlines[0];
    var element_A = outline_A.element;
    expect(element_A.kind, ElementKind.CLASS);
    expect(element_A.name, 'A');
    var location = element_A.location!;
    expect(location.offset, testCode.indexOf('A('));
    expect(location.length, 1);

    var outlines_A = outline_A.children!;
    expect(outlines_A, hasLength(2));

    // The primary constructor
    var outline_A_new = outlines_A[0];
    var element_A_new = outline_A_new.element;
    expect(element_A_new.kind, ElementKind.CONSTRUCTOR);
    expect(element_A_new.name, 'A');
    expect(element_A_new.parameters, '([final int x = 0])');
    expect(element_A_new.returnType, isNull);

    // The field `x`
    var outline_x = outlines_A[1];
    var element_x = outline_x.element;
    expect(element_x.kind, ElementKind.FIELD);
    expect(element_x.isFinal, true);
    expect(element_x.name, 'x');
    expect(element_x.parameters, isNull);
    expect(element_x.returnType, 'int');
  }

  Future<void> test_privateNamedParameter() async {
    var unitOutline = await _computeOutline('''
class C {
  int? _x;
  C({this._x});
}
''');
    var topOutlines = unitOutline.children!;

    // The class `C`.
    expect(topOutlines, hasLength(1));
    var outline_C = topOutlines[0];
    var outlines_C = outline_C.children!;
    expect(outlines_C, hasLength(2));

    // The field '_x'.
    var outline_x = outlines_C[0];
    var element_x = outline_x.element;
    expect(element_x.kind, ElementKind.FIELD);
    expect(element_x.name, '_x');

    // The constructor.
    var outline_ctor = outlines_C[1];
    var element_ctor = outline_ctor.element;
    expect(element_ctor.kind, ElementKind.CONSTRUCTOR);
    expect(element_ctor.name, 'C');
    // TODO(rnystrom): It might be better to show the parameter signature as
    // it would appear to a caller like `({int? x})`, but that would be a large
    // change. Currently, outlines always show the parameter signature as it is
    // declared.
    // See: https://github.com/dart-lang/sdk/issues/62608
    expect(element_ctor.parameters, '({this._x})');
  }

  Future<void> test_sourceRanges_fields() async {
    var unitOutline = await _computeOutline('''
class A {
  /*[0*/int /*[1*/fieldA/*1]*//*0]*/, /*[2*//*[3*/fieldB = 2/*3]*/;/*2]*/

  /*[4*/int /*[5*/fieldC/*5]*/;/*4]*/

  /*[6*///// Documentation.
  int /*[7*/fieldD/*7]*/;/*6]*/
}
''');
    var outlines = unitOutline.children![0].children!;
    expect(outlines, hasLength(4));

    // fieldA
    {
      var outline = outlines[0];
      var element = outline.element;
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, 'fieldA');

      expect(outline, hasOffsetLength(parsedTestCode.ranges[0]));
      expect(outline, hasCodeOffsetLength(parsedTestCode.ranges[1]));
    }

    // fieldB
    {
      var outline = outlines[1];
      var element = outline.element;
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, 'fieldB');

      expect(outline, hasOffsetLength(parsedTestCode.ranges[2]));
      expect(outline, hasCodeOffsetLength(parsedTestCode.ranges[3]));
    }

    // fieldC
    {
      var outline = outlines[2];
      var element = outline.element;
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, 'fieldC');

      expect(outline, hasOffsetLength(parsedTestCode.ranges[4]));
      expect(outline, hasCodeOffsetLength(parsedTestCode.ranges[5]));
    }

    // fieldD
    {
      var outline = outlines[3];
      var element = outline.element;
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, 'fieldD');

      expect(outline, hasOffsetLength(parsedTestCode.ranges[6]));
      expect(outline, hasCodeOffsetLength(parsedTestCode.ranges[7]));
    }
  }

  Future<void> test_sourceRanges_inUnit() async {
    var unitOutline = await _computeOutline('''
/*[0*//// My first class.
/*[1*/class A {}/*1]*//*0]*/

/*[2*/class B {}/*2]*/
''');
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(2));

    // A
    {
      var outline = topOutlines[0];
      var element = outline.element;
      expect(element.kind, ElementKind.CLASS);
      expect(element.name, 'A');

      expect(outline, hasOffsetLength(parsedTestCode.ranges[0]));
      expect(outline, hasCodeOffsetLength(parsedTestCode.ranges[1]));
    }

    // B
    {
      var outline = topOutlines[1];
      var element = outline.element;
      expect(element.kind, ElementKind.CLASS);
      expect(element.name, 'B');

      expect(outline, hasOffsetLength(parsedTestCode.ranges[2]));
      expect(outline, hasCodeOffsetLength(parsedTestCode.ranges[2]));
    }
  }

  Future<void> test_sourceRanges_method() async {
    var unitOutline = await _computeOutline('''
class A {
  /*[0*/int methodA() {}/*0]*/

  /*[1*//// Documentation.
  @override
  /*[2*/int methodB() {}/*2]*//*1]*/
}
''');
    var outlines = unitOutline.children![0].children!;
    expect(outlines, hasLength(2));

    // methodA
    {
      var outline = outlines[0];
      var element = outline.element;
      expect(element.kind, ElementKind.METHOD);
      expect(element.name, 'methodA');

      expect(outline, hasOffsetLength(parsedTestCode.ranges[0]));
      expect(outline, hasCodeOffsetLength(parsedTestCode.ranges[0]));
    }

    // methodB
    {
      var outline = outlines[1];
      var element = outline.element;
      expect(element.kind, ElementKind.METHOD);
      expect(element.name, 'methodB');

      expect(outline, hasOffsetLength(parsedTestCode.ranges[1]));
      expect(outline, hasCodeOffsetLength(parsedTestCode.ranges[2]));
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
    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(11));
    // FTA
    {
      var outline = topOutlines[0];
      var element = outline.element;
      expect(element.kind, ElementKind.FUNCTION_TYPE_ALIAS);
      expect(element.name, 'FTA');
      expect(element.typeParameters, '<K, V>');
      {
        var location = element.location!;
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
        var location = element.location!;
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
        var location = element.location!;
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
        var location = element.location!;
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
        var location = element.location!;
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
        var location = element.location!;
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
        var location = element.location!;
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
        var location = element.location!;
        expect(location.offset, testCode.indexOf('propB(int v) {}'));
        expect(location.length, 'propB'.length);
      }
      expect(element.parameters, '(int v)');
      expect(element.returnType, '');
    }
  }

  Future<void> test_topLevelFunction_recordTypes() async {
    var unitOutline = await _computeOutline('''
/*[0*/(int, int) /*[1*/f/*1]*/((String, String) r) => throw '';/*0]*/
''');

    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));

    assertJson(topOutlines[0], {
      'element': {
        'kind': 'FUNCTION',
        'name': 'f',
        'location': _elementLocation(parsedTestCode.ranges[1]),
        'flags': 8,
        'parameters': '((String, String) r)',
        'returnType': '(int, int)',
      },
      ..._location(parsedTestCode.ranges[0], parsedTestCode.ranges[0]),
    });
  }

  Future<void> test_topLevelVariable_recordTypes() async {
    var unitOutline = await _computeOutline('''
/*[0*/(int, int)? /*[1*//*[2*/r/*2]*/ = null/*1]*/;/*0]*/
''');

    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));

    assertJson(topOutlines[0], {
      'element': {
        'kind': 'TOP_LEVEL_VARIABLE',
        'name': 'r',
        'location': _elementLocation(parsedTestCode.ranges[2]),
        'flags': 0,
        'returnType': '(int, int)?',
      },
      ..._location(parsedTestCode.ranges[0], parsedTestCode.ranges[1]),
    });
  }

  Future<void> test_wildcardLocalFunction() async {
    var unitOutline = await _computeOutline('''
/*[0*//*[1*/f/*1]*/() {
  /*[2*//*[3*/_/*3]*/() {
    /*[4*//*[5*/_/*5]*/(){}/*4]*/
  }/*2]*/
}/*0]*/
''');

    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));

    assertJson(topOutlines.first, {
      'element': {
        'kind': 'FUNCTION',
        'name': 'f',
        'location': _elementLocation(parsedTestCode.ranges[1]),
        'flags': 8,
        'parameters': '()',
        'returnType': '',
      },
      ..._location(parsedTestCode.ranges[0], parsedTestCode.ranges[0]),
      'children': [
        {
          'element': {
            'kind': 'FUNCTION',
            'name': '_',
            'location': _elementLocation(parsedTestCode.ranges[3]),
            'flags': 16,
            'parameters': '()',
            'returnType': '',
          },
          ..._location(parsedTestCode.ranges[2], parsedTestCode.ranges[2]),
          'children': [
            {
              'element': {
                'kind': 'FUNCTION',
                'name': '_',
                'location': _elementLocation(parsedTestCode.ranges[5]),
                'flags': 16,
                'parameters': '()',
                'returnType': '',
              },
              ..._location(parsedTestCode.ranges[4], parsedTestCode.ranges[4]),
            },
          ],
        },
      ],
    });
  }

  Future<void> test_wildcardLocalFunction_preWildcards() async {
    var unitOutline = await _computeOutline('''
// @dart = 3.4
// (pre wildcard-variables)

/*[0*//*[1*/f/*1]*/() {
  /*[2*//*[3*/_/*3]*/() {
    /*[4*//*[5*/_/*5]*/(){}/*4]*/
  }/*2]*/
}/*0]*/
''');

    var topOutlines = unitOutline.children!;
    expect(topOutlines, hasLength(1));

    assertJson(topOutlines.first, {
      'element': {
        'kind': 'FUNCTION',
        'name': 'f',
        'location': _elementLocation(parsedTestCode.ranges[1]),
        'flags': 8,
        'parameters': '()',
        'returnType': '',
      },
      ..._location(parsedTestCode.ranges[0], parsedTestCode.ranges[0]),
      'children': [
        {
          'element': {
            'kind': 'FUNCTION',
            'name': '_',
            'location': _elementLocation(parsedTestCode.ranges[3]),
            'flags': 16,
            'parameters': '()',
            'returnType': '',
          },
          ..._location(parsedTestCode.ranges[2], parsedTestCode.ranges[2]),
          'children': [
            {
              'element': {
                'kind': 'FUNCTION',
                'name': '_',
                'location': _elementLocation(parsedTestCode.ranges[5]),
                'flags': 16,
                'parameters': '()',
                'returnType': '',
              },
              ..._location(parsedTestCode.ranges[4], parsedTestCode.ranges[4]),
            },
          ],
        },
      ],
    });
  }

  Map<String, Object?> _elementLocation(TestCodeRange range) {
    return {
      'file': convertPath(testFilePath),
      'offset': range.sourceRange.offset,
      'length': range.sourceRange.length,
      'startLine': range.range.start.line + 1,
      'startColumn': range.range.start.character + 1,
      'endLine': range.range.end.line + 1,
      'endColumn': range.range.end.character + 1,
    };
  }

  void _expect(
    Outline outline, {
    ElementKind? kind,
    bool leaf = false,
    int? length,
    String? name,
    int? offset,
    String? parameters,
    String? returnType,
  }) {
    var element = outline.element;
    var location = element.location!;

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

  Map<String, Object?> _location(TestCodeRange name, TestCodeRange code) {
    return {
      'offset': name.sourceRange.offset,
      'length': name.sourceRange.length,
      'codeOffset': code.sourceRange.offset,
      'codeLength': code.sourceRange.length,
    };
  }
}
