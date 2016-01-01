// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.notification.outline;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';
import '../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(_AnalysisNotificationOutlineTest);
}

@reflectiveTest
class _AnalysisNotificationOutlineTest extends AbstractAnalysisTest {
  FileKind fileKind;
  String libraryName;
  Outline outline;

  Future prepareOutline() {
    addAnalysisSubscription(AnalysisService.OUTLINE, testFile);
    return waitForTasksFinished();
  }

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_OUTLINE) {
      var params = new AnalysisOutlineParams.fromNotification(notification);
      if (params.file == testFile) {
        fileKind = params.kind;
        libraryName = params.libraryName;
        outline = params.outline;
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  test_afterAnalysis() async {
    addTestFile('''
class AAA {
}
class BBB {
}
''');
    await waitForTasksFinished();
    expect(outline, isNull);
    await prepareOutline();
    Outline unitOutline = outline;
    List<Outline> outlines = unitOutline.children;
    expect(outlines, hasLength(2));
  }

  test_class() async {
    addTestFile('''
class A<K, V> {
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
    await prepareOutline();
    Outline unitOutline = outline;
    List<Outline> topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(2));
    // A
    {
      Outline outline_A = topOutlines[0];
      Element element_A = outline_A.element;
      expect(element_A.kind, ElementKind.CLASS);
      expect(element_A.name, "A");
      expect(element_A.typeParameters, "<K, V>");
      {
        Location location = element_A.location;
        expect(location.offset, testCode.indexOf("A<K, V> {"));
        expect(location.length, 1);
      }
      expect(element_A.parameters, null);
      expect(element_A.returnType, null);
      // A children
      List<Outline> outlines_A = outline_A.children;
      expect(outlines_A, hasLength(10));
      {
        Outline outline = outlines_A[0];
        Element element = outline.element;
        expect(element.kind, ElementKind.FIELD);
        expect(element.name, "fa");
        expect(element.parameters, isNull);
        expect(element.returnType, "int");
      }
      {
        Outline outline = outlines_A[1];
        Element element = outline.element;
        expect(element.kind, ElementKind.FIELD);
        expect(element.name, "fb");
        expect(element.parameters, isNull);
        expect(element.returnType, "int");
      }
      {
        Outline outline = outlines_A[2];
        Element element = outline.element;
        expect(element.kind, ElementKind.FIELD);
        expect(element.name, "fc");
        expect(element.parameters, isNull);
        expect(element.returnType, "String");
      }
      {
        Outline outline = outlines_A[3];
        Element element = outline.element;
        expect(element.kind, ElementKind.CONSTRUCTOR);
        expect(element.name, "A");
        {
          Location location = element.location;
          expect(location.offset, testCode.indexOf("A(int i, String s);"));
          expect(location.length, "A".length);
        }
        expect(element.parameters, "(int i, String s)");
        expect(element.returnType, isNull);
        expect(element.isAbstract, isFalse);
        expect(element.isStatic, isFalse);
      }
      {
        Outline outline = outlines_A[4];
        Element element = outline.element;
        expect(element.kind, ElementKind.CONSTRUCTOR);
        expect(element.name, "A.name");
        {
          Location location = element.location;
          expect(location.offset, testCode.indexOf("name(num p);"));
          expect(location.length, "name".length);
        }
        expect(element.parameters, "(num p)");
        expect(element.returnType, isNull);
        expect(element.isAbstract, isFalse);
        expect(element.isStatic, isFalse);
      }
      {
        Outline outline = outlines_A[5];
        Element element = outline.element;
        expect(element.kind, ElementKind.CONSTRUCTOR);
        expect(element.name, "A._privateName");
        {
          Location location = element.location;
          expect(location.offset, testCode.indexOf("_privateName(num p);"));
          expect(location.length, "_privateName".length);
        }
        expect(element.parameters, "(num p)");
        expect(element.returnType, isNull);
        expect(element.isAbstract, isFalse);
        expect(element.isStatic, isFalse);
      }
      {
        Outline outline = outlines_A[6];
        Element element = outline.element;
        expect(element.kind, ElementKind.METHOD);
        expect(element.name, "ma");
        {
          Location location = element.location;
          expect(location.offset, testCode.indexOf("ma(int pa) => null;"));
          expect(location.length, "ma".length);
        }
        expect(element.parameters, "(int pa)");
        expect(element.returnType, "String");
        expect(element.isAbstract, isFalse);
        expect(element.isStatic, isTrue);
      }
      {
        Outline outline = outlines_A[7];
        Element element = outline.element;
        expect(element.kind, ElementKind.METHOD);
        expect(element.name, "_mb");
        {
          Location location = element.location;
          expect(location.offset, testCode.indexOf("_mb(int pb);"));
          expect(location.length, "_mb".length);
        }
        expect(element.parameters, "(int pb)");
        expect(element.returnType, "");
        expect(element.isAbstract, isTrue);
        expect(element.isStatic, isFalse);
      }
      {
        Outline outline = outlines_A[8];
        Element element = outline.element;
        expect(element.kind, ElementKind.GETTER);
        expect(element.name, "propA");
        {
          Location location = element.location;
          expect(location.offset, testCode.indexOf("propA => null;"));
          expect(location.length, "propA".length);
        }
        expect(element.parameters, isNull);
        expect(element.returnType, "String");
      }
      {
        Outline outline = outlines_A[9];
        Element element = outline.element;
        expect(element.kind, ElementKind.SETTER);
        expect(element.name, "propB");
        {
          Location location = element.location;
          expect(location.offset, testCode.indexOf("propB(int v) {}"));
          expect(location.length, "propB".length);
        }
        expect(element.parameters, "(int v)");
        expect(element.returnType, "");
      }
    }
    // B
    {
      Outline outline_B = topOutlines[1];
      Element element_B = outline_B.element;
      expect(element_B.kind, ElementKind.CLASS);
      expect(element_B.name, "B");
      expect(element_B.typeParameters, isNull);
      {
        Location location = element_B.location;
        expect(location.offset, testCode.indexOf("B {"));
        expect(location.length, 1);
      }
      expect(element_B.parameters, null);
      expect(element_B.returnType, null);
      // B children
      List<Outline> outlines_B = outline_B.children;
      expect(outlines_B, hasLength(1));
      {
        Outline outline = outlines_B[0];
        Element element = outline.element;
        expect(element.kind, ElementKind.CONSTRUCTOR);
        expect(element.name, "B");
        {
          Location location = element.location;
          expect(location.offset, testCode.indexOf("B(int p);"));
          expect(location.length, "B".length);
        }
        expect(element.parameters, "(int p)");
        expect(element.returnType, isNull);
      }
    }
  }

  test_enum() async {
    addTestFile('''
enum MyEnum {
  A, B, C
}
''');
    await prepareOutline();
    Outline unitOutline = outline;
    List<Outline> topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(1));
    // MyEnum
    {
      Outline outline_MyEnum = topOutlines[0];
      Element element_MyEnum = outline_MyEnum.element;
      expect(element_MyEnum.kind, ElementKind.ENUM);
      expect(element_MyEnum.name, "MyEnum");
      {
        Location location = element_MyEnum.location;
        expect(location.offset, testCode.indexOf("MyEnum {"));
        expect(location.length, 'MyEnum'.length);
      }
      expect(element_MyEnum.parameters, null);
      expect(element_MyEnum.returnType, null);
      // MyEnum children
      List<Outline> outlines_MyEnum = outline_MyEnum.children;
      expect(outlines_MyEnum, hasLength(3));
      _isEnumConstant(outlines_MyEnum[0], 'A');
      _isEnumConstant(outlines_MyEnum[1], 'B');
      _isEnumConstant(outlines_MyEnum[2], 'C');
    }
  }

  /**
   * Code like this caused NPE in the past.
   *
   * https://code.google.com/p/dart/issues/detail?id=21373
   */
  test_invalidGetterInConstructor() async {
    addTestFile('''
class A {
  A() {
    get badGetter {
      const int CONST = 0;
    }
  }
}
''');
    await prepareOutline();
    expect(outline, isNotNull);
  }

  test_libraryName_hasLibraryDirective() async {
    addTestFile('''
library my.lib;
''');
    await prepareOutline();
    expect(fileKind, FileKind.LIBRARY);
    expect(libraryName, 'my.lib');
  }

  test_libraryName_hasLibraryPartOfDirectives() async {
    addTestFile('''
part of lib.in.part.of;
library my.lib;
''');
    await prepareOutline();
    expect(fileKind, FileKind.LIBRARY);
    expect(libraryName, 'my.lib');
  }

  test_libraryName_hasPartOfDirective() async {
    addTestFile('''
part of my.lib;
''');
    await prepareOutline();
    expect(fileKind, FileKind.PART);
    expect(libraryName, 'my.lib');
  }

  test_libraryName_noDirectives() async {
    addTestFile('''
class A {}
''');
    await prepareOutline();
    expect(fileKind, FileKind.LIBRARY);
    expect(libraryName, isNull);
  }

  test_localFunctions() async {
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
    await prepareOutline();
    Outline unitOutline = outline;
    List<Outline> topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(2));
    // A
    {
      Outline outline_A = topOutlines[0];
      Element element_A = outline_A.element;
      expect(element_A.kind, ElementKind.CLASS);
      expect(element_A.name, "A");
      {
        Location location = element_A.location;
        expect(location.offset, testCode.indexOf("A {"));
        expect(location.length, "A".length);
      }
      expect(element_A.parameters, null);
      expect(element_A.returnType, null);
      // A children
      List<Outline> outlines_A = outline_A.children;
      expect(outlines_A, hasLength(2));
      {
        Outline constructorOutline = outlines_A[0];
        Element constructorElement = constructorOutline.element;
        expect(constructorElement.kind, ElementKind.CONSTRUCTOR);
        expect(constructorElement.name, "A");
        {
          Location location = constructorElement.location;
          expect(location.offset, testCode.indexOf("A() {"));
          expect(location.length, "A".length);
        }
        expect(constructorElement.parameters, "()");
        expect(constructorElement.returnType, isNull);
        // local function
        List<Outline> outlines_constructor = constructorOutline.children;
        expect(outlines_constructor, hasLength(1));
        {
          Outline outline = outlines_constructor[0];
          Element element = outline.element;
          expect(element.kind, ElementKind.FUNCTION);
          expect(element.name, "local_A");
          {
            Location location = element.location;
            expect(location.offset, testCode.indexOf("local_A() {}"));
            expect(location.length, "local_A".length);
          }
          expect(element.parameters, "()");
          expect(element.returnType, "int");
        }
      }
      {
        Outline outline_m = outlines_A[1];
        Element element_m = outline_m.element;
        expect(element_m.kind, ElementKind.METHOD);
        expect(element_m.name, "m");
        {
          Location location = element_m.location;
          expect(location.offset, testCode.indexOf("m() {"));
          expect(location.length, "m".length);
        }
        expect(element_m.parameters, "()");
        expect(element_m.returnType, "");
        // local function
        List<Outline> methodChildren = outline_m.children;
        expect(methodChildren, hasLength(1));
        {
          Outline outline = methodChildren[0];
          Element element = outline.element;
          expect(element.kind, ElementKind.FUNCTION);
          expect(element.name, "local_m");
          {
            Location location = element.location;
            expect(location.offset, testCode.indexOf("local_m() {}"));
            expect(location.length, "local_m".length);
          }
          expect(element.parameters, "()");
          expect(element.returnType, "");
        }
      }
    }
    // f()
    {
      Outline outline_f = topOutlines[1];
      Element element_f = outline_f.element;
      expect(element_f.kind, ElementKind.FUNCTION);
      expect(element_f.name, "f");
      {
        Location location = element_f.location;
        expect(location.offset, testCode.indexOf("f() {"));
        expect(location.length, "f".length);
      }
      expect(element_f.parameters, "()");
      expect(element_f.returnType, "");
      // f() children
      List<Outline> outlines_f = outline_f.children;
      expect(outlines_f, hasLength(2));
      {
        Outline outline_f1 = outlines_f[0];
        Element element_f1 = outline_f1.element;
        expect(element_f1.kind, ElementKind.FUNCTION);
        expect(element_f1.name, "local_f1");
        {
          Location location = element_f1.location;
          expect(location.offset, testCode.indexOf("local_f1(int i) {}"));
          expect(location.length, "local_f1".length);
        }
        expect(element_f1.parameters, "(int i)");
        expect(element_f1.returnType, "");
      }
      {
        Outline outline_f2 = outlines_f[1];
        Element element_f2 = outline_f2.element;
        expect(element_f2.kind, ElementKind.FUNCTION);
        expect(element_f2.name, "local_f2");
        {
          Location location = element_f2.location;
          expect(location.offset, testCode.indexOf("local_f2(String s) {"));
          expect(location.length, "local_f2".length);
        }
        expect(element_f2.parameters, "(String s)");
        expect(element_f2.returnType, "");
        // local_f2() local function
        List<Outline> outlines_f2 = outline_f2.children;
        expect(outlines_f2, hasLength(1));
        {
          Outline outline_f21 = outlines_f2[0];
          Element element_f21 = outline_f21.element;
          expect(element_f21.kind, ElementKind.FUNCTION);
          expect(element_f21.name, "local_f21");
          {
            Location location = element_f21.location;
            expect(location.offset, testCode.indexOf("local_f21(int p) {"));
            expect(location.length, "local_f21".length);
          }
          expect(element_f21.parameters, "(int p)");
          expect(element_f21.returnType, "");
        }
      }
    }
  }

  test_sourceRange_inClass() async {
    addTestFile('''
class A { // leftA
  int methodA() {} // endA
  int methodB() {} // endB
}
''');
    await prepareOutline();
    Outline unitOutline = outline;
    List<Outline> outlines = unitOutline.children[0].children;
    expect(outlines, hasLength(2));
    // methodA
    {
      Outline outline = outlines[0];
      Element element = outline.element;
      expect(element.kind, ElementKind.METHOD);
      expect(element.name, "methodA");
      {
        int offset = testCode.indexOf(" // leftA");
        int end = testCode.indexOf(" // endA");
        expect(outline.offset, offset);
        expect(outline.length, end - offset);
      }
    }
    // methodB
    {
      Outline outline = outlines[1];
      Element element = outline.element;
      expect(element.kind, ElementKind.METHOD);
      expect(element.name, "methodB");
      {
        int offset = testCode.indexOf(" // endA");
        int end = testCode.indexOf(" // endB");
        expect(outline.offset, offset);
        expect(outline.length, end - offset);
      }
    }
  }

  test_sourceRange_inClass_inVariableList() async {
    addTestFile('''
class A { // leftA
  int fieldA, fieldB, fieldC; // marker
  int fieldD; // marker2
}
''');
    await prepareOutline();
    Outline unitOutline = outline;
    List<Outline> outlines = unitOutline.children[0].children;
    expect(outlines, hasLength(4));
    // fieldA
    {
      Outline outline = outlines[0];
      Element element = outline.element;
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, "fieldA");
      {
        int offset = testCode.indexOf(" // leftA");
        int end = testCode.indexOf(", fieldB");
        expect(outline.offset, offset);
        expect(outline.length, end - offset);
      }
    }
    // fieldB
    {
      Outline outline = outlines[1];
      Element element = outline.element;
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, "fieldB");
      {
        int offset = testCode.indexOf(", fieldB");
        int end = testCode.indexOf(", fieldC");
        expect(outline.offset, offset);
        expect(outline.length, end - offset);
      }
    }
    // fieldC
    {
      Outline outline = outlines[2];
      Element element = outline.element;
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, "fieldC");
      {
        int offset = testCode.indexOf(", fieldC");
        int end = testCode.indexOf(" // marker");
        expect(outline.offset, offset);
        expect(outline.length, end - offset);
      }
    }
    // fieldD
    {
      Outline outline = outlines[3];
      Element element = outline.element;
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, "fieldD");
      {
        int offset = testCode.indexOf(" // marker");
        int end = testCode.indexOf(" // marker2");
        expect(outline.offset, offset);
        expect(outline.length, end - offset);
      }
    }
  }

  test_sourceRange_inUnit() async {
    addTestFile('''
library lib;
/// My first class.
class A {
} // endA
class B {
} // endB
''');
    await prepareOutline();
    Outline unitOutline = outline;
    List<Outline> topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(2));
    // A
    {
      Outline outline = topOutlines[0];
      Element element = outline.element;
      expect(element.kind, ElementKind.CLASS);
      expect(element.name, "A");
      {
        int offset = testCode.indexOf("/// My first class.");
        int end = testCode.indexOf(" // endA");
        expect(outline.offset, offset);
        expect(outline.length, end - offset);
      }
    }
    // B
    {
      Outline outline = topOutlines[1];
      Element element = outline.element;
      expect(element.kind, ElementKind.CLASS);
      expect(element.name, "B");
      {
        int offset = testCode.indexOf(" // endA");
        int end = testCode.indexOf(" // endB");
        expect(outline.offset, offset);
        expect(outline.length, end - offset);
      }
    }
  }

  test_sourceRange_inUnit_inVariableList() async {
    addTestFile('''
int fieldA, fieldB, fieldC; // marker
int fieldD; // marker2
''');
    await prepareOutline();
    Outline unitOutline = outline;
    List<Outline> outlines = unitOutline.children;
    expect(outlines, hasLength(4));
    // fieldA
    {
      Outline outline = outlines[0];
      Element element = outline.element;
      expect(element.kind, ElementKind.TOP_LEVEL_VARIABLE);
      expect(element.name, "fieldA");
      {
        int offset = 0;
        int end = testCode.indexOf(", fieldB");
        expect(outline.offset, offset);
        expect(outline.length, end - offset);
      }
    }
    // fieldB
    {
      Outline outline = outlines[1];
      Element element = outline.element;
      expect(element.kind, ElementKind.TOP_LEVEL_VARIABLE);
      expect(element.name, "fieldB");
      {
        int offset = testCode.indexOf(", fieldB");
        int end = testCode.indexOf(", fieldC");
        expect(outline.offset, offset);
        expect(outline.length, end - offset);
      }
    }
    // fieldC
    {
      Outline outline = outlines[2];
      Element element = outline.element;
      expect(element.kind, ElementKind.TOP_LEVEL_VARIABLE);
      expect(element.name, "fieldC");
      {
        int offset = testCode.indexOf(", fieldC");
        int end = testCode.indexOf(" // marker");
        expect(outline.offset, offset);
        expect(outline.length, end - offset);
      }
    }
    // fieldD
    {
      Outline outline = outlines[3];
      Element element = outline.element;
      expect(element.kind, ElementKind.TOP_LEVEL_VARIABLE);
      expect(element.name, "fieldD");
      {
        int offset = testCode.indexOf(" // marker");
        int end = testCode.indexOf(" // marker2");
        expect(outline.offset, offset);
        expect(outline.length, end - offset);
      }
    }
  }

  test_topLevel() async {
    addTestFile('''
typedef String FTA<K, V>(int i, String s);
typedef FTB(int p);
class A<T> {}
class B {}
class CTA<T> = A<T> with B;
class CTB = A with B;
String fA(int i, String s) => null;
fB(int p) => null;
String get propA => null;
set propB(int v) {}
''');
    await prepareOutline();
    Outline unitOutline = outline;
    List<Outline> topOutlines = unitOutline.children;
    expect(topOutlines, hasLength(10));
    // FTA
    {
      Outline outline = topOutlines[0];
      Element element = outline.element;
      expect(element.kind, ElementKind.FUNCTION_TYPE_ALIAS);
      expect(element.name, "FTA");
      expect(element.typeParameters, "<K, V>");
      {
        Location location = element.location;
        expect(location.offset, testCode.indexOf("FTA<K, V>("));
        expect(location.length, "FTA".length);
      }
      expect(element.parameters, "(int i, String s)");
      expect(element.returnType, "String");
    }
    // FTB
    {
      Outline outline = topOutlines[1];
      Element element = outline.element;
      expect(element.kind, ElementKind.FUNCTION_TYPE_ALIAS);
      expect(element.name, "FTB");
      expect(element.typeParameters, isNull);
      {
        Location location = element.location;
        expect(location.offset, testCode.indexOf("FTB("));
        expect(location.length, "FTB".length);
      }
      expect(element.parameters, "(int p)");
      expect(element.returnType, "");
    }
    // CTA
    {
      Outline outline = topOutlines[4];
      Element element = outline.element;
      expect(element.kind, ElementKind.CLASS_TYPE_ALIAS);
      expect(element.name, "CTA");
      expect(element.typeParameters, '<T>');
      {
        Location location = element.location;
        expect(location.offset, testCode.indexOf("CTA<T> ="));
        expect(location.length, "CTA".length);
      }
      expect(element.parameters, isNull);
      expect(element.returnType, isNull);
    }
    // CTB
    {
      Outline outline = topOutlines[5];
      Element element = outline.element;
      expect(element.kind, ElementKind.CLASS_TYPE_ALIAS);
      expect(element.name, 'CTB');
      expect(element.typeParameters, isNull);
      expect(element.returnType, isNull);
    }
    // fA
    {
      Outline outline = topOutlines[6];
      Element element = outline.element;
      expect(element.kind, ElementKind.FUNCTION);
      expect(element.name, "fA");
      {
        Location location = element.location;
        expect(location.offset, testCode.indexOf("fA("));
        expect(location.length, "fA".length);
      }
      expect(element.parameters, "(int i, String s)");
      expect(element.returnType, "String");
    }
    // fB
    {
      Outline outline = topOutlines[7];
      Element element = outline.element;
      expect(element.kind, ElementKind.FUNCTION);
      expect(element.name, "fB");
      {
        Location location = element.location;
        expect(location.offset, testCode.indexOf("fB("));
        expect(location.length, "fB".length);
      }
      expect(element.parameters, "(int p)");
      expect(element.returnType, "");
    }
    // propA
    {
      Outline outline = topOutlines[8];
      Element element = outline.element;
      expect(element.kind, ElementKind.GETTER);
      expect(element.name, "propA");
      {
        Location location = element.location;
        expect(location.offset, testCode.indexOf("propA => null;"));
        expect(location.length, "propA".length);
      }
      expect(element.parameters, "");
      expect(element.returnType, "String");
    }
    // propB
    {
      Outline outline = topOutlines[9];
      Element element = outline.element;
      expect(element.kind, ElementKind.SETTER);
      expect(element.name, "propB");
      {
        Location location = element.location;
        expect(location.offset, testCode.indexOf("propB(int v) {}"));
        expect(location.length, "propB".length);
      }
      expect(element.parameters, "(int v)");
      expect(element.returnType, "");
    }
  }

  void _isEnumConstant(Outline outline, String name) {
    Element element = outline.element;
    expect(element.kind, ElementKind.ENUM_CONSTANT);
    expect(element.name, name);
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
  }
}
