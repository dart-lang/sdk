// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/resolver_test_case.dart';
import '../../../generated/test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(Dart2InferenceTest);
  });
}

/// Tests for Dart2 inference rules back-ported from FrontEnd.
///
/// https://github.com/dart-lang/sdk/issues/31638
@reflectiveTest
class Dart2InferenceTest extends ResolverTestCase {
  @override
  AnalysisOptions get defaultAnalysisOptions =>
      new AnalysisOptionsImpl()..strongMode = true;

  @override
  bool get enableNewAnalysisDriver => true;

  test_forIn() async {
    var code = r'''
T f<T>() => null;

void test(Iterable<num> iter) {
  for (var w in f()) {} // 1
  for (var x in iter) {} // 2
  for (num y in f()) {} // 3
}
''';
    var source = addSource(code);
    var analysisResult = await computeAnalysisResult(source);
    var unit = analysisResult.unit;

    {
      var node = EngineTestCase.findSimpleIdentifier(unit, code, 'w in');
      VariableElement element = node.staticElement;
      expect(node.staticType, typeProvider.dynamicType);
      expect(element.type, typeProvider.dynamicType);

      var invocation = _findMethodInvocation(unit, code, 'f()) {} // 1');
      expect(invocation.staticType.toString(), 'Iterable<dynamic>');
    }

    {
      var node = EngineTestCase.findSimpleIdentifier(unit, code, 'x in');
      VariableElement element = node.staticElement;
      expect(node.staticType, typeProvider.numType);
      expect(element.type, typeProvider.numType);
    }

    {
      var node = EngineTestCase.findSimpleIdentifier(unit, code, 'y in');
      VariableElement element = node.staticElement;

      expect(node.staticType, typeProvider.numType);
      expect(element.type, typeProvider.numType);

      var invocation = _findMethodInvocation(unit, code, 'f()) {} // 3');
      expect(invocation.staticType.toString(), 'Iterable<num>');
    }
  }

  test_forIn_identifier() async {
    var code = r'''
T f<T>() => null;

class A {}

A aTopLevel;
void set aTopLevelSetter(A value) {}

class C {
  A aField;
  void set aSetter(A value) {}
  void test() {
    A aLocal;
    for (aLocal in f()) {} // local
    for (aField in f()) {} // field
    for (aSetter in f()) {} // setter
    for (aTopLevel in f()) {} // top variable
    for (aTopLevelSetter in f()) {} // top setter
  }
}''';
    var source = addSource(code);
    var analysisResult = await computeAnalysisResult(source);
    var unit = analysisResult.unit;

    void assertType(String prefix) {
      var invocation = _findMethodInvocation(unit, code, prefix);
      expect(invocation.staticType.toString(), 'Iterable<A>');
    }

    assertType('f()) {} // local');
    assertType('f()) {} // field');
    assertType('f()) {} // setter');
    assertType('f()) {} // top variable');
    assertType('f()) {} // top setter');
  }

  test_inferObject_whenDownwardNull() async {
    var code = r'''
int f(void Function(Null) f2) {}
void main() {
  f((x) {});
}
''';
    var source = addSource(code);
    var analysisResult = await computeAnalysisResult(source);
    var unit = analysisResult.unit;
    var xNode = EngineTestCase.findSimpleIdentifier(unit, code, 'x) {}');
    VariableElement xElement = xNode.staticElement;
    expect(xNode.staticType, typeProvider.objectType);
    expect(xElement.type, typeProvider.objectType);
  }

  MethodInvocation _findMethodInvocation(
      AstNode root, String code, String prefix) {
    return EngineTestCase.findNode(root, code, prefix, (n) {
      return n is MethodInvocation;
    });
  }
}
