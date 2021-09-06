// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableNameSuggestionTest);
  });
}

@reflectiveTest
class VariableNameSuggestionTest extends AbstractSingleUnitTest {
  Future<void> test_forExpression_cast() async {
    await resolveTestCode('''
void f() {
  var sortedNodes;
  var res = sortedNodes as String;
}
''');
    var excluded = <String>{};
    var expr = findNode.as_('as String');
    expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  Future<void> test_forExpression_expectedType() async {
    await resolveTestCode('''
class TreeNode {}
void f() {
  TreeNode? node = null;
}
''');
    var excluded = <String>{};
    var expectedType = findElement.localVar('node').type;
    var assignedExpression = findNode.nullLiteral('null;');
    var suggestions = getVariableNameSuggestionsForExpression(
        expectedType, assignedExpression, excluded);
    expect(suggestions, unorderedEquals(['treeNode', 'node']));
  }

  Future<void> test_forExpression_expectedType_double() async {
    await resolveTestCode('''
void f() {
  double res = 0.0;
}
''');
    var expectedType = findElement.localVar('res').type;
    var assignedExpression = findNode.doubleLiteral('0.0;');
    // first choice for "double" is "d"
    expect(
        getVariableNameSuggestionsForExpression(
            expectedType, assignedExpression, {}),
        unorderedEquals(['d']));
    // if "d" is used, try "e", "f", etc
    expect(
        getVariableNameSuggestionsForExpression(
            expectedType, assignedExpression, {'d', 'e'}),
        unorderedEquals(['f']));
  }

  Future<void> test_forExpression_expectedType_int() async {
    await resolveTestCode('''
void f() {
  int res = 0;
}
''');
    var expectedType = findElement.localVar('res').type;
    var assignedExpression = findNode.integerLiteral('0;');
    // first choice for "int" is "i"
    expect(
        getVariableNameSuggestionsForExpression(
            expectedType, assignedExpression, {}),
        unorderedEquals(['i']));
    // if "i" is used, try "j", "k", etc
    expect(
        getVariableNameSuggestionsForExpression(
            expectedType, assignedExpression, {'i', 'j'}),
        unorderedEquals(['k']));
  }

  Future<void> test_forExpression_expectedType_String() async {
    await resolveTestCode('''
void f() {
  String res = 'abc';
}
''');
    var expectedType = findElement.localVar('res').type;
    var assignedExpression = findNode.stringLiteral("'abc';");
    // first choice for "String" is "s"
    expect(
        getVariableNameSuggestionsForExpression(
            expectedType, assignedExpression, {}),
        unorderedEquals(['s']));
  }

  Future<void> test_forExpression_inBuildMethod() async {
    await resolveTestCode('''
class A {
  void build() {
    Map l = Map();
  }
}
''');
    var excluded = <String>{};
    var expr = findNode.instanceCreation('Map(');
    expect(
        getVariableNameSuggestionsForExpression(null, expr, excluded,
            isMethod: false),
        unorderedEquals(['map']));
    expect(
        getVariableNameSuggestionsForExpression(null, expr, excluded,
            isMethod: true),
        unorderedEquals(['buildMap']));
  }

  Future<void> test_forExpression_indexExpression_endsWithE() async {
    await resolveTestCode('''
void f() {
  var topNodes = [0, 1, 2];
  print(topNodes[0]);
}
''');
    var excluded = <String>{};
    var expr = findNode.index('topNodes[0]');
    var names = getVariableNameSuggestionsForExpression(null, expr, excluded);
    expect(names, unorderedEquals(['topNode', 'node', 'object']));
  }

  Future<void> test_forExpression_instanceCreation() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
import 'dart:math' as p;
void f(p) {
  new NoSuchClass();
  new p.NoSuchClass();
  new NoSuchClass.named();
}
''');
    var excluded = <String>{};
    expect(
        getVariableNameSuggestionsForExpression(
            null, findNode.instanceCreation('new NoSuchClass()'), excluded),
        unorderedEquals(['noSuchClass', 'suchClass', 'class']));
    expect(
        getVariableNameSuggestionsForExpression(null,
            findNode.instanceCreation('new NoSuchClass.named()'), excluded),
        unorderedEquals(['noSuchClass', 'suchClass', 'class']));
    // TODO(scheglov) This test does not work.
    // In "p.NoSuchClass" the identifier "p" is not resolved to a PrefixElement.
//    expect(
//        getVariableNameSuggestionsForExpression(
//            null,
//            findNodeAtString('new p.NoSuchClass()'),
//            excluded),
//        unorderedEquals(['noSuchClass', 'suchClass', 'class']));
  }

  Future<void> test_forExpression_invocationArgument_named() async {
    await resolveTestCode('''
foo({a, b, c}) {}
void f() {
  foo(a: 111, c: 333, b: 222);
}
''');
    var excluded = <String>{};
    {
      var expr = findNode.integerLiteral('111');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['a']));
    }
    {
      var expr = findNode.integerLiteral('222');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['b']));
    }
    {
      var expr = findNode.integerLiteral('333');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['c']));
    }
  }

  Future<void> test_forExpression_invocationArgument_optional() async {
    await resolveTestCode('''
foo(a, [b = 2, c = 3]) {}
void f() {
  foo(111, 222, 333);
}
''');
    var excluded = <String>{};
    {
      var expr = findNode.integerLiteral('111');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['a']));
    }
    {
      var expr = findNode.integerLiteral('222');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['b']));
    }
    {
      var expr = findNode.integerLiteral('333');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['c']));
    }
  }

  Future<void> test_forExpression_invocationArgument_positional() async {
    await resolveTestCode('''
foo(a, b) {}
void f() {
  foo(111, 222);
}
''');
    var excluded = <String>{};
    {
      var expr = findNode.integerLiteral('111');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['a']));
    }
    {
      var expr = findNode.integerLiteral('222');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['b']));
    }
  }

  Future<void> test_forExpression_methodInvocation() async {
    await resolveTestCode('''
void f(p) {
  var res = p.getSortedNodes();
}
''');
    var excluded = <String>{};
    var expr = findNode.methodInvocation('p.get');
    expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  Future<void> test_forExpression_methodInvocation_noPrefix() async {
    await resolveTestCode('''
void f(p) {
  var res = p.sortedNodes();
}
''');
    var excluded = <String>{};
    var expr = findNode.methodInvocation('p.sorted');
    expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  Future<void> test_forExpression_name_get() async {
    await resolveTestCode('''
void f(p) {
  var res = p.get();
}
''');
    var excluded = <String>{};
    var expr = findNode.methodInvocation('p.get');
    expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
        unorderedEquals([]));
  }

  Future<void> test_forExpression_prefixedIdentifier() async {
    await resolveTestCode('''
void f(p) {
  var res = p.sortedNodes;
}
''');
    var excluded = <String>{};
    expect(
        getVariableNameSuggestionsForExpression(
            null, findNode.prefixed('p.sorted'), excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  Future<void> test_forExpression_privateName() async {
    await resolveTestCode('''
void f(p) {
  p._name;
  p._computeSuffix();
}
''');
    var excluded = <String>{};
    expect(
        getVariableNameSuggestionsForExpression(
            null, findNode.prefixed('p._name'), excluded),
        unorderedEquals(['name']));
    expect(
        getVariableNameSuggestionsForExpression(
            null, findNode.methodInvocation('p._compute'), excluded),
        unorderedEquals(['computeSuffix', 'suffix']));
  }

  Future<void> test_forExpression_propertyAccess() async {
    await resolveTestCode('''
void f(p) {
  var res = p.q.sortedNodes;
}
''');
    var excluded = <String>{};
    var expression = findNode.propertyAccess('.sorted');
    expect(getVariableNameSuggestionsForExpression(null, expression, excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  Future<void> test_forExpression_simpleName() async {
    await resolveTestCode('''
void f(p) {
  var sortedNodes = null;
  var res = sortedNodes;
}
''');
    var excluded = <String>{};
    var expr = findNode.simple('sortedNodes;');
    expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  Future<void> test_forExpression_unqualifiedInvocation() async {
    await resolveTestCode('''
getSortedNodes() => [];
void f(p) {
  var res = getSortedNodes();
}
''');
    var excluded = <String>{};
    expect(
        getVariableNameSuggestionsForExpression(
            null, findNode.methodInvocation('getSortedNodes();'), excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  void test_forText() {
    {
      var excluded = <String>{};
      var suggestions =
          getVariableNameSuggestionsForText('Goodbye, cruel world!', excluded);
      expect(suggestions,
          unorderedEquals(['goodbyeCruelWorld', 'cruelWorld', 'world']));
    }
    {
      var excluded = <String>{'world'};
      var suggestions =
          getVariableNameSuggestionsForText('Goodbye, cruel world!', excluded);
      expect(suggestions,
          unorderedEquals(['goodbyeCruelWorld', 'cruelWorld', 'world2']));
    }
  }
}
