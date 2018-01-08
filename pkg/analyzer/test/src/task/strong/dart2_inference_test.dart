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

  test_bool_assert() async {
    var code = r'''
T f<T>() => null;

main() {
  assert(f()); // 1
  assert(f(), f()); // 2
}

class C {
  C() : assert(f()), // 3
        assert(f(), f()); // 4
}
''';
    var source = addSource(code);
    var analysisResult = await computeAnalysisResult(source);
    var unit = analysisResult.unit;

    String getType(String prefix) {
      var invocation = _findMethodInvocation(unit, code, prefix);
      return invocation.staticInvokeType.toString();
    }

    expect(getType('f()); // 1'), '() → bool');

    expect(getType('f(), '), '() → bool');
    expect(getType('f()); // 2'), '() → dynamic');

    expect(getType('f()), // 3'), '() → bool');

    expect(getType('f(), '), '() → bool');
    expect(getType('f()); // 4'), '() → dynamic');
  }

  test_bool_logical() async {
    var code = r'''
T f<T>() => null;

var v1 = f() || f(); // 1
var v2 = f() && f(); // 2

main() {
  var v1 = f() || f(); // 3
  var v2 = f() && f(); // 4
}
''';
    var source = addSource(code);
    var analysisResult = await computeAnalysisResult(source);
    var unit = analysisResult.unit;

    void assertType(String prefix) {
      var invocation = _findMethodInvocation(unit, code, prefix);
      expect(invocation.staticInvokeType.toString(), '() → bool');
    }

    assertType('f() || f(); // 1');
    assertType('f(); // 1');
    assertType('f() && f(); // 2');
    assertType('f(); // 2');

    assertType('f() || f(); // 3');
    assertType('f(); // 3');
    assertType('f() && f(); // 4');
    assertType('f(); // 4');
  }

  test_bool_statement() async {
    var code = r'''
T f<T>() => null;

main() {
  while (f()) {} // 1
  do {} while (f()); // 2
  if (f()) {} // 3
  for (; f(); ) {} // 4
}
''';
    var source = addSource(code);
    var analysisResult = await computeAnalysisResult(source);
    var unit = analysisResult.unit;

    void assertType(String prefix) {
      var invocation = _findMethodInvocation(unit, code, prefix);
      expect(invocation.staticInvokeType.toString(), '() → bool');
    }

    assertType('f()) {} // 1');
    assertType('f());');
    assertType('f()) {} // 3');
    assertType('f(); ) {} // 4');
  }

  test_closure_downwardReturnType_arrow() async {
    var code = r'''
void main() {
  List<int> Function() g;
  g = () => 42;
}
''';
    var source = addSource(code);
    var analysisResult = await computeAnalysisResult(source);
    var unit = analysisResult.unit;

    Expression closure = _findExpression(unit, code, '() => 42');
    expect(closure.staticType.toString(), '() → List<int>');
  }

  test_closure_downwardReturnType_block() async {
    var code = r'''
void main() {
  List<int> Function() g;
  g = () { // mark
    return 42;
  };
}
''';
    var source = addSource(code);
    var analysisResult = await computeAnalysisResult(source);
    var unit = analysisResult.unit;

    Expression closure = _findExpression(unit, code, '() { // mark');
    expect(closure.staticType.toString(), '() → List<int>');
  }

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

  test_switchExpression_asContext_forCases() async {
    var code = r'''
class C<T> {
  const C();
}

void test(C<int> x) {
  switch (x) {
    case const C():
      break;
    default:
      break;
  }
}''';
    var source = addSource(code);
    var analysisResult = await computeAnalysisResult(source);
    var unit = analysisResult.unit;

    var node = _findInstanceCreation(unit, code, 'const C():');
    expect(node.staticType.toString(), 'C<int>');
  }

  Expression _findExpression(AstNode root, String code, String prefix) {
    return EngineTestCase.findNode(root, code, prefix, (n) {
      return n is Expression;
    });
  }

  InstanceCreationExpression _findInstanceCreation(
      AstNode root, String code, String prefix) {
    return EngineTestCase.findNode(root, code, prefix, (n) {
      return n is InstanceCreationExpression;
    });
  }

  MethodInvocation _findMethodInvocation(
      AstNode root, String code, String prefix) {
    return EngineTestCase.findNode(root, code, prefix, (n) {
      return n is MethodInvocation;
    });
  }
}
