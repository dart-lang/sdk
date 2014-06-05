// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.analysis.notification.outline;

import 'dart:async';
import 'dart:mirrors';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import 'analysis_abstract.dart';
import 'reflective_tests.dart';


main() {
  group('notification.outline', () {
    runReflectiveTests(AnalysisNotificationOutlineTest);
  });
}


@ReflectiveTestCase()
class AnalysisNotificationOutlineTest extends AbstractAnalysisTest {
  _Outline outline;

  void processNotification(Notification notification) {
    if (notification.event == NOTIFICATION_OUTLINE) {
      String file = notification.getParameter(FILE);
      if (file == testFile) {
        Map<String, Object> json = notification.getParameter(OUTLINE);
        outline = new _Outline.fromJson(json);
      }
    }
  }

  Future prepareOutline(then()) {
    addAnalysisSubscription(AnalysisService.OUTLINE, testFile);
    return waitForTasksFinished().then((_) {
      then();
    });
  }

  test_class() {
    addTestFile('''
class A {
  int fa, fb;
  String fc;
  A(int i, String s);
  A.name(num p);
  A._privateName(num p);
  static String ma(int pa) => null;
  _mb(int pb);
  String get propA => null;
  set propB(int v) {}
}
class B {
  B(int p);
}");
''');
    return prepareOutline(() {
      _Outline unitOutline = outline;
      List<_Outline> topOutlines = unitOutline.children;
      expect(topOutlines, hasLength(2));
      // A
      {
        _Outline outline_A = topOutlines[0];
        expect(outline_A.kind, _OutlineKind.CLASS);
        expect(outline_A.name, "A");
        expect(outline_A.nameOffset, testCode.indexOf("A {"));
        expect(outline_A.nameLength, 1);
        expect(outline_A.arguments, null);
        expect(outline_A.returnType, null);
        // A children
        List<_Outline> outlines_A = outline_A.children;
        expect(outlines_A, hasLength(10));
        {
          _Outline outline = outlines_A[0];
          expect(outline.kind, _OutlineKind.FIELD);
          expect(outline.name, "fa");
          expect(outline.arguments, isNull);
          expect(outline.returnType, "int");
        }
        {
          _Outline outline = outlines_A[1];
          expect(outline.kind, _OutlineKind.FIELD);
          expect(outline.name, "fb");
          expect(outline.arguments, isNull);
          expect(outline.returnType, "int");
        }
        {
          _Outline outline = outlines_A[2];
          expect(outline.kind, _OutlineKind.FIELD);
          expect(outline.name, "fc");
          expect(outline.arguments, isNull);
          expect(outline.returnType, "String");
        }
        {
          _Outline outline = outlines_A[3];
          expect(outline.kind, _OutlineKind.CONSTRUCTOR);
          expect(outline.name, "A");
          expect(outline.nameOffset, testCode.indexOf("A(int i, String s);"));
          expect(outline.nameLength, "A".length);
          expect(outline.arguments, "(int i, String s)");
          expect(outline.returnType, isNull);
          expect(outline.isAbstract, isFalse);
          expect(outline.isStatic, isFalse);
        }
        {
          _Outline outline = outlines_A[4];
          expect(outline.kind, _OutlineKind.CONSTRUCTOR);
          expect(outline.name, "A.name");
          expect(outline.nameOffset, testCode.indexOf("name(num p);"));
          expect(outline.nameLength, "name".length);
          expect(outline.arguments, "(num p)");
          expect(outline.returnType, isNull);
          expect(outline.isAbstract, isFalse);
          expect(outline.isStatic, isFalse);
        }
        {
          _Outline outline = outlines_A[5];
          expect(outline.kind, _OutlineKind.CONSTRUCTOR);
          expect(outline.name, "A._privateName");
          expect(outline.nameOffset, testCode.indexOf("_privateName(num p);"));
          expect(outline.nameLength, "_privateName".length);
          expect(outline.arguments, "(num p)");
          expect(outline.returnType, isNull);
          expect(outline.isAbstract, isFalse);
          expect(outline.isStatic, isFalse);
        }
        {
          _Outline outline = outlines_A[6];
          expect(outline.kind, _OutlineKind.METHOD);
          expect(outline.name, "ma");
          expect(outline.nameOffset, testCode.indexOf("ma(int pa) => null;"));
          expect(outline.nameLength, "ma".length);
          expect(outline.arguments, "(int pa)");
          expect(outline.returnType, "String");
          expect(outline.isAbstract, isFalse);
          expect(outline.isStatic, isTrue);
        }
        {
          _Outline outline = outlines_A[7];
          expect(outline.kind, _OutlineKind.METHOD);
          expect(outline.name, "_mb");
          expect(outline.nameOffset, testCode.indexOf("_mb(int pb);"));
          expect(outline.nameLength, "_mb".length);
          expect(outline.arguments, "(int pb)");
          expect(outline.returnType, "");
          expect(outline.isAbstract, isTrue);
          expect(outline.isStatic, isFalse);
        }
        {
          _Outline outline = outlines_A[8];
          expect(outline.kind, _OutlineKind.GETTER);
          expect(outline.name, "propA");
          expect(outline.nameOffset, testCode.indexOf("propA => null;"));
          expect(outline.nameLength, "propA".length);
          expect(outline.arguments, "");
          expect(outline.returnType, "String");
        }
        {
          _Outline outline = outlines_A[9];
          expect(outline.kind, _OutlineKind.SETTER);
          expect(outline.name, "propB");
          expect(outline.nameOffset, testCode.indexOf("propB(int v) {}"));
          expect(outline.nameLength, "propB".length);
          expect(outline.arguments, "(int v)");
          expect(outline.returnType, "");
        }
      }
      // B
      {
        _Outline outline_B = topOutlines[1];
        expect(outline_B.kind, _OutlineKind.CLASS);
        expect(outline_B.name, "B");
        expect(outline_B.nameOffset, testCode.indexOf("B {"));
        expect(outline_B.nameLength, 1);
        expect(outline_B.arguments, null);
        expect(outline_B.returnType, null);
        // B children
        List<_Outline> outlines_B = outline_B.children;
        expect(outlines_B, hasLength(1));
        {
          _Outline outline = outlines_B[0];
          expect(outline.kind, _OutlineKind.CONSTRUCTOR);
          expect(outline.name, "B");
          expect(outline.nameOffset, testCode.indexOf("B(int p);"));
          expect(outline.nameLength, "B".length);
          expect(outline.arguments, "(int p)");
          expect(outline.returnType, isNull);
        }
      }
    });
  }

  test_sourceRange_inClass() {
    addTestFile('''
class A { // leftA
  int methodA() {} // endA
  int methodB() {} // endB
}
''');
    return prepareOutline(() {
      _Outline unitOutline = outline;
      List<_Outline> outlines = unitOutline.children[0].children;
      expect(outlines, hasLength(2));
      // methodA
      {
        _Outline outline = outlines[0];
        expect(outline.kind, _OutlineKind.METHOD);
        expect(outline.name, "methodA");
        {
          int offset = testCode.indexOf(" // leftA");
          int end = testCode.indexOf(" // endA");
          expect(outline.elementOffset, offset);
          expect(outline.elementLength, end - offset);
        }
      }
      // methodB
      {
        _Outline outline = outlines[1];
        expect(outline.kind, _OutlineKind.METHOD);
        expect(outline.name, "methodB");
        {
          int offset = testCode.indexOf(" // endA");
          int end = testCode.indexOf(" // endB");
          expect(outline.elementOffset, offset);
          expect(outline.elementLength, end - offset);
        }
      }
    });
  }

  test_sourceRange_inClass_inVariableList() {
    addTestFile('''
class A { // leftA
  int fieldA, fieldB, fieldC; // marker
  int fieldD; // marker2
}
''');
    return prepareOutline(() {
      _Outline unitOutline = outline;
      List<_Outline> outlines = unitOutline.children[0].children;
      expect(outlines, hasLength(4));
      // fieldA
      {
        _Outline outline = outlines[0];
        expect(outline.kind, _OutlineKind.FIELD);
        expect(outline.name, "fieldA");
        {
          int offset = testCode.indexOf(" // leftA");
          int end = testCode.indexOf(", fieldB");
          expect(outline.elementOffset, offset);
          expect(outline.elementLength, end - offset);
        }
      }
      // fieldB
      {
        _Outline outline = outlines[1];
        expect(outline.kind, _OutlineKind.FIELD);
        expect(outline.name, "fieldB");
        {
          int offset = testCode.indexOf(", fieldB");
          int end = testCode.indexOf(", fieldC");
          expect(outline.elementOffset, offset);
          expect(outline.elementLength, end - offset);
        }
      }
      // fieldC
      {
        _Outline outline = outlines[2];
        expect(outline.kind, _OutlineKind.FIELD);
        expect(outline.name, "fieldC");
        {
          int offset = testCode.indexOf(", fieldC");
          int end = testCode.indexOf(" // marker");
          expect(outline.elementOffset, offset);
          expect(outline.elementLength, end - offset);
        }
      }
      // fieldD
      {
        _Outline outline = outlines[3];
        expect(outline.kind, _OutlineKind.FIELD);
        expect(outline.name, "fieldD");
        {
          int offset = testCode.indexOf(" // marker");
          int end = testCode.indexOf(" // marker2");
          expect(outline.elementOffset, offset);
          expect(outline.elementLength, end - offset);
        }
      }
    });
  }

  test_sourceRange_inUnit() {
    addTestFile('''
class A {
} // endA
class B {
} // endB
''');
    return prepareOutline(() {
      _Outline unitOutline = outline;
      List<_Outline> topOutlines = unitOutline.children;
      expect(topOutlines, hasLength(2));
      // A
      {
        _Outline outline = topOutlines[0];
        expect(outline.kind, _OutlineKind.CLASS);
        expect(outline.name, "A");
        {
          int offset = 0;
          int end = testCode.indexOf(" // endA");
          expect(outline.elementOffset, offset);
          expect(outline.elementLength, end - offset);
        }
      }
      // B
      {
        _Outline outline = topOutlines[1];
        expect(outline.kind, _OutlineKind.CLASS);
        expect(outline.name, "B");
        {
          int offset = testCode.indexOf(" // endA");
          int end = testCode.indexOf(" // endB");
          expect(outline.elementOffset, offset);
          expect(outline.elementLength, end - offset);
        }
      }
    });
  }

  test_sourceRange_inUnit_inVariableList() {
    addTestFile('''
int fieldA, fieldB, fieldC; // marker
int fieldD; // marker2
''');
    return prepareOutline(() {
      _Outline unitOutline = outline;
      List<_Outline> outlines = unitOutline.children;
      expect(outlines, hasLength(4));
      // fieldA
      {
        _Outline outline = outlines[0];
        expect(outline.kind, _OutlineKind.TOP_LEVEL_VARIABLE);
        expect(outline.name, "fieldA");
        {
          int offset = 0;
          int end = testCode.indexOf(", fieldB");
          expect(outline.elementOffset, offset);
          expect(outline.elementLength, end - offset);
        }
      }
      // fieldB
      {
        _Outline outline = outlines[1];
        expect(outline.kind, _OutlineKind.TOP_LEVEL_VARIABLE);
        expect(outline.name, "fieldB");
        {
          int offset = testCode.indexOf(", fieldB");
          int end = testCode.indexOf(", fieldC");
          expect(outline.elementOffset, offset);
          expect(outline.elementLength, end - offset);
        }
      }
      // fieldC
      {
        _Outline outline = outlines[2];
        expect(outline.kind, _OutlineKind.TOP_LEVEL_VARIABLE);
        expect(outline.name, "fieldC");
        {
          int offset = testCode.indexOf(", fieldC");
          int end = testCode.indexOf(" // marker");
          expect(outline.elementOffset, offset);
          expect(outline.elementLength, end - offset);
        }
      }
      // fieldD
      {
        _Outline outline = outlines[3];
        expect(outline.kind, _OutlineKind.TOP_LEVEL_VARIABLE);
        expect(outline.name, "fieldD");
        {
          int offset = testCode.indexOf(" // marker");
          int end = testCode.indexOf(" // marker2");
          expect(outline.elementOffset, offset);
          expect(outline.elementLength, end - offset);
        }
      }
    });
  }

  test_localFunctions() {
    addTestFile('''
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
    return prepareOutline(() {
      _Outline unitOutline = outline;
      List<_Outline> topOutlines = unitOutline.children;
      expect(topOutlines, hasLength(2));
      // A
      {
        _Outline outline_A = topOutlines[0];
        expect(outline_A.kind, _OutlineKind.CLASS);
        expect(outline_A.name, "A");
        expect(outline_A.nameOffset, testCode.indexOf("A {"));
        expect(outline_A.nameLength, "A".length);
        expect(outline_A.arguments, null);
        expect(outline_A.returnType, null);
        // A children
        List<_Outline> outlines_A = outline_A.children;
        expect(outlines_A, hasLength(2));
        {
          _Outline constructorOutline = outlines_A[0];
          expect(constructorOutline.kind, _OutlineKind.CONSTRUCTOR);
          expect(constructorOutline.name, "A");
          expect(constructorOutline.nameOffset, testCode.indexOf("A() {"));
          expect(constructorOutline.nameLength, "A".length);
          expect(constructorOutline.arguments, "()");
          expect(constructorOutline.returnType, isNull);
          // local function
          List<_Outline> outlines_constructor = constructorOutline.children;
          expect(outlines_constructor, hasLength(1));
          {
            _Outline outline = outlines_constructor[0];
            expect(outline.kind, _OutlineKind.FUNCTION);
            expect(outline.name, "local_A");
            expect(outline.nameOffset, testCode.indexOf("local_A() {}"));
            expect(outline.nameLength, "local_A".length);
            expect(outline.arguments, "()");
            expect(outline.returnType, "int");
          }
        }
        {
          _Outline outline_m = outlines_A[1];
          expect(outline_m.kind, _OutlineKind.METHOD);
          expect(outline_m.name, "m");
          expect(outline_m.nameOffset, testCode.indexOf("m() {"));
          expect(outline_m.nameLength, "m".length);
          expect(outline_m.arguments, "()");
          expect(outline_m.returnType, "");
          // local function
          List<_Outline> methodChildren = outline_m.children;
          expect(methodChildren, hasLength(1));
          {
            _Outline outline = methodChildren[0];
            expect(outline.kind, _OutlineKind.FUNCTION);
            expect(outline.name, "local_m");
            expect(outline.nameOffset, testCode.indexOf("local_m() {}"));
            expect(outline.nameLength, "local_m".length);
            expect(outline.arguments, "()");
            expect(outline.returnType, "");
          }
        }
      }
      // f()
      {
        _Outline outline_f = topOutlines[1];
        expect(outline_f.kind, _OutlineKind.FUNCTION);
        expect(outline_f.name, "f");
        expect(outline_f.nameOffset, testCode.indexOf("f() {"));
        expect(outline_f.nameLength, "f".length);
        expect(outline_f.arguments, "()");
        expect(outline_f.returnType, "");
        // f() children
        List<_Outline> outlines_f = outline_f.children;
        expect(outlines_f, hasLength(2));
        {
          _Outline outline_f1 = outlines_f[0];
          expect(outline_f1.kind, _OutlineKind.FUNCTION);
          expect(outline_f1.name, "local_f1");
          expect(outline_f1.nameOffset, testCode.indexOf("local_f1(int i) {}"));
          expect(outline_f1.nameLength, "local_f1".length);
          expect(outline_f1.arguments, "(int i)");
          expect(outline_f1.returnType, "");
        }
        {
          _Outline outline_f2 = outlines_f[1];
          expect(outline_f2.kind, _OutlineKind.FUNCTION);
          expect(outline_f2.name, "local_f2");
          expect(outline_f2.nameOffset, testCode.indexOf("local_f2(String s) {"));
          expect(outline_f2.nameLength, "local_f2".length);
          expect(outline_f2.arguments, "(String s)");
          expect(outline_f2.returnType, "");
          // local_f2() local function
          List<_Outline> outlines_f2 = outline_f2.children;
          expect(outlines_f2, hasLength(1));
          {
            _Outline outline_f21 = outlines_f2[0];
            expect(outline_f21.kind, _OutlineKind.FUNCTION);
            expect(outline_f21.name, "local_f21");
            expect(outline_f21.nameOffset, testCode.indexOf("local_f21(int p) {"));
            expect(outline_f21.nameLength, "local_f21".length);
            expect(outline_f21.arguments, "(int p)");
            expect(outline_f21.returnType, "");
          }
        }
      }
    });
  }

  test_topLevel() {
    addTestFile('''
typedef String FTA(int i, String s);
typedef FTB(int p);
class A {}
class B {}
class CTA = A with B;
String fA(int i, String s) => null;
fB(int p) => null;
String get propA => null;
set propB(int v) {}
''');
    return prepareOutline(() {
      _Outline unitOutline = outline;
      List<_Outline> topOutlines = unitOutline.children;
      expect(topOutlines, hasLength(9));
      // FTA
      {
        _Outline outline = topOutlines[0];
        expect(outline.kind, _OutlineKind.FUNCTION_TYPE_ALIAS);
        expect(outline.name, "FTA");
        expect(outline.nameOffset, testCode.indexOf("FTA("));
        expect(outline.nameLength, "FTA".length);
        expect(outline.arguments, "(int i, String s)");
        expect(outline.returnType, "String");
      }
      // FTB
      {
        _Outline outline = topOutlines[1];
        expect(outline.kind, _OutlineKind.FUNCTION_TYPE_ALIAS);
        expect(outline.name, "FTB");
        expect(outline.nameOffset, testCode.indexOf("FTB("));
        expect(outline.nameLength, "FTB".length);
        expect(outline.arguments, "(int p)");
        expect(outline.returnType, "");
      }
      // CTA
      {
        _Outline outline = topOutlines[4];
        expect(outline.kind, _OutlineKind.CLASS_TYPE_ALIAS);
        expect(outline.name, "CTA");
        expect(outline.nameOffset, testCode.indexOf("CTA ="));
        expect(outline.nameLength, "CTA".length);
        expect(outline.arguments, isNull);
        expect(outline.returnType, isNull);
      }
      // fA
      {
        _Outline outline = topOutlines[5];
        expect(outline.kind, _OutlineKind.FUNCTION);
        expect(outline.name, "fA");
        expect(outline.nameOffset, testCode.indexOf("fA("));
        expect(outline.nameLength, "fA".length);
        expect(outline.arguments, "(int i, String s)");
        expect(outline.returnType, "String");
      }
      // fB
      {
        _Outline outline = topOutlines[6];
        expect(outline.kind, _OutlineKind.FUNCTION);
        expect(outline.name, "fB");
        expect(outline.nameOffset, testCode.indexOf("fB("));
        expect(outline.nameLength, "fB".length);
        expect(outline.arguments, "(int p)");
        expect(outline.returnType, "");
      }
      // propA
      {
        _Outline outline = topOutlines[7];
        expect(outline.kind, _OutlineKind.GETTER);
        expect(outline.name, "propA");
        expect(outline.nameOffset, testCode.indexOf("propA => null;"));
        expect(outline.nameLength, "propA".length);
        expect(outline.arguments, "");
        expect(outline.returnType, "String");
      }
      // propB
      {
        _Outline outline = topOutlines[8];
        expect(outline.kind, _OutlineKind.SETTER);
        expect(outline.name, "propB");
        expect(outline.nameOffset, testCode.indexOf("propB(int v) {}"));
        expect(outline.nameLength, "propB".length);
        expect(outline.arguments, "(int v)");
        expect(outline.returnType, "");
      }
    });
  }
}


/**
 * Element outline kinds.
 */
class _OutlineKind {
  static const _OutlineKind CLASS = const _OutlineKind('CLASS');
  static const _OutlineKind CLASS_TYPE_ALIAS = const _OutlineKind('CLASS_TYPE_ALIAS');
  static const _OutlineKind COMPILATION_UNIT = const _OutlineKind('COMPILATION_UNIT');
  static const _OutlineKind CONSTRUCTOR = const _OutlineKind('CONSTRUCTOR');
  static const _OutlineKind GETTER = const _OutlineKind('GETTER');
  static const _OutlineKind FIELD = const _OutlineKind('FIELD');
  static const _OutlineKind FUNCTION = const _OutlineKind('FUNCTION');
  static const _OutlineKind FUNCTION_TYPE_ALIAS = const _OutlineKind('FUNCTION_TYPE_ALIAS');
  static const _OutlineKind LIBRARY = const _OutlineKind('LIBRARY');
  static const _OutlineKind METHOD = const _OutlineKind('METHOD');
  static const _OutlineKind SETTER = const _OutlineKind('SETTER');
  static const _OutlineKind TOP_LEVEL_VARIABLE = const _OutlineKind('TOP_LEVEL_VARIABLE');
  static const _OutlineKind UNKNOWN = const _OutlineKind('UNKNOWN');
  static const _OutlineKind UNIT_TEST_CASE = const _OutlineKind('UNIT_TEST_CASE');
  static const _OutlineKind UNIT_TEST_GROUP = const _OutlineKind('UNIT_TEST_GROUP');

  final String name;

  const _OutlineKind(this.name);

  static _OutlineKind valueOf(String name) {
    ClassMirror classMirror = reflectClass(_OutlineKind);
    return classMirror.getField(new Symbol(name)).reflectee;
  }
}


class _Outline {
  static const List<_Outline> EMPTY_ARRAY = const <_Outline>[];

  _Outline parent;
  final _OutlineKind kind;
  final String name;
  final int nameOffset;
  final int nameLength;
  final int elementOffset;
  final int elementLength;
  final bool isAbstract;
  final bool isStatic;
  final String arguments;
  final String returnType;
  final List<_Outline> children = <_Outline>[];

  _Outline(this.kind, this.name,
           this.nameOffset, this.nameLength,
           this.elementOffset, this.elementLength,
           this.isAbstract, this.isStatic,
           this.arguments, this.returnType);

  factory _Outline.fromJson(Map<String, Object> map) {
    _Outline outline = new _Outline(
        _OutlineKind.valueOf(map[KIND]), map[NAME],
        map[NAME_OFFSET], map[NAME_LENGTH],
        map[ELEMENT_OFFSET], map[ELEMENT_LENGTH],
        map[IS_ABSTRACT], map[IS_STATIC],
        map[ARGUMENTS], map[RETURN_TYPE]);
    List<Map<String, Object>> childrenMaps = map[CHILDREN];
    if (childrenMaps != null) {
      childrenMaps.forEach((childMap) {
        outline.children.add(new _Outline.fromJson(childMap));
      });
    }
    return outline;
  }
}
