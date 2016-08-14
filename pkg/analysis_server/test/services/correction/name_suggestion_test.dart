// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction.name_suggestion;

import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_single_unit.dart';
import '../../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(VariableNameSuggestionTest);
}

@reflectiveTest
class VariableNameSuggestionTest extends AbstractSingleUnitTest {
  void test_forExpression_cast() {
    resolveTestUnit('''
main() {
  var sortedNodes;
  var res = sortedNodes as String;
}
''');
    var excluded = new Set<String>.from([]);
    var expr = findNodeAtString('as String', (node) => node is AsExpression);
    expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  void test_forExpression_expectedType() {
    resolveTestUnit('''
class TreeNode {}
main() {
  TreeNode node = null;
}
''');
    Set<String> excluded = new Set<String>.from([]);
    DartType expectedType = (findElement('node') as LocalVariableElement).type;
    Expression assignedExpression =
        findNodeAtString('null;', (node) => node is NullLiteral);
    List<String> suggestions = getVariableNameSuggestionsForExpression(
        expectedType, assignedExpression, excluded);
    expect(suggestions, unorderedEquals(['treeNode', 'node']));
  }

  void test_forExpression_expectedType_double() {
    resolveTestUnit('''
main() {
  double res = 0.0;
}
''');
    DartType expectedType = (findElement('res') as LocalVariableElement).type;
    Expression assignedExpression = findNodeAtString('0.0;');
    // first choice for "double" is "d"
    expect(
        getVariableNameSuggestionsForExpression(
            expectedType, assignedExpression, new Set.from([])),
        unorderedEquals(['d']));
    // if "d" is used, try "e", "f", etc
    expect(
        getVariableNameSuggestionsForExpression(
            expectedType, assignedExpression, new Set.from(['d', 'e'])),
        unorderedEquals(['f']));
  }

  void test_forExpression_expectedType_int() {
    resolveTestUnit('''
main() {
  int res = 0;
}
''');
    DartType expectedType = (findElement('res') as LocalVariableElement).type;
    Expression assignedExpression = findNodeAtString('0;');
    // first choice for "int" is "i"
    expect(
        getVariableNameSuggestionsForExpression(
            expectedType, assignedExpression, new Set.from([])),
        unorderedEquals(['i']));
    // if "i" is used, try "j", "k", etc
    expect(
        getVariableNameSuggestionsForExpression(
            expectedType, assignedExpression, new Set.from(['i', 'j'])),
        unorderedEquals(['k']));
  }

  void test_forExpression_expectedType_String() {
    resolveTestUnit('''
main() {
  String res = 'abc';
}
''');
    DartType expectedType = (findElement('res') as LocalVariableElement).type;
    Expression assignedExpression = findNodeAtString("'abc';");
    // first choice for "String" is "s"
    expect(
        getVariableNameSuggestionsForExpression(
            expectedType, assignedExpression, new Set.from([])),
        unorderedEquals(['s']));
  }

  void test_forExpression_instanceCreation() {
    verifyNoTestUnitErrors = false;
    resolveTestUnit('''
import 'dart:math' as p;
main(p) {
  new NoSuchClass();
  new p.NoSuchClass();
  new NoSuchClass.named();
}
''');
    var excluded = new Set<String>.from([]);
    expect(
        getVariableNameSuggestionsForExpression(
            null, findNodeAtString('new NoSuchClass()'), excluded),
        unorderedEquals(['noSuchClass', 'suchClass', 'class']));
    expect(
        getVariableNameSuggestionsForExpression(
            null, findNodeAtString('new NoSuchClass.named()'), excluded),
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

  void test_forExpression_invocationArgument_named() {
    resolveTestUnit('''
foo({a, b, c}) {}
main() {
  foo(a: 111, c: 333, b: 222);
}
''');
    var excluded = new Set<String>.from([]);
    {
      var expr = findNodeAtString('111');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['a']));
    }
    {
      var expr = findNodeAtString('222');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['b']));
    }
    {
      var expr = findNodeAtString('333');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['c']));
    }
  }

  void test_forExpression_invocationArgument_optional() {
    resolveTestUnit('''
foo(a, [b = 2, c = 3]) {}
main() {
  foo(111, 222, 333);
}
''');
    var excluded = new Set<String>.from([]);
    {
      var expr = findNodeAtString('111');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['a']));
    }
    {
      var expr = findNodeAtString('222');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['b']));
    }
    {
      var expr = findNodeAtString('333');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['c']));
    }
  }

  void test_forExpression_invocationArgument_positional() {
    resolveTestUnit('''
foo(a, b) {}
main() {
  foo(111, 222);
}
''');
    var excluded = new Set<String>.from([]);
    {
      var expr = findNodeAtString('111');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['a']));
    }
    {
      var expr = findNodeAtString('222');
      expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
          unorderedEquals(['b']));
    }
  }

  void test_forExpression_methodInvocation() {
    resolveTestUnit('''
main(p) {
  var res = p.getSortedNodes();
}
''');
    var excluded = new Set<String>.from([]);
    var expr = findNodeAtString('p.get', (node) => node is MethodInvocation);
    expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  void test_forExpression_methodInvocation_noPrefix() {
    resolveTestUnit('''
main(p) {
  var res = p.sortedNodes();
}
''');
    var excluded = new Set<String>.from([]);
    var expr = findNodeAtString('p.sorted', (node) => node is MethodInvocation);
    expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  void test_forExpression_name_get() {
    resolveTestUnit('''
main(p) {
  var res = p.get();
}
''');
    var excluded = new Set<String>.from([]);
    var expr = findNodeAtString('p.get', (node) => node is MethodInvocation);
    expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
        unorderedEquals([]));
  }

  void test_forExpression_prefixedIdentifier() {
    resolveTestUnit('''
main(p) {
  var res = p.sortedNodes;
}
''');
    var excluded = new Set<String>.from([]);
    expect(
        getVariableNameSuggestionsForExpression(
            null,
            findNodeAtString('p.sorted', (node) => node is PrefixedIdentifier),
            excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  void test_forExpression_privateName() {
    resolveTestUnit('''
main(p) {
  p._name;
  p._computeSuffix();
}
''');
    var excluded = new Set<String>.from([]);
    expect(
        getVariableNameSuggestionsForExpression(
            null,
            findNodeAtString('p._name', (node) => node is PrefixedIdentifier),
            excluded),
        unorderedEquals(['name']));
    expect(
        getVariableNameSuggestionsForExpression(
            null,
            findNodeAtString('p._compute', (node) => node is MethodInvocation),
            excluded),
        unorderedEquals(['computeSuffix', 'suffix']));
  }

  void test_forExpression_propertyAccess() {
    resolveTestUnit('''
main(p) {
  var res = p.q.sortedNodes;
}
''');
    var excluded = new Set<String>.from([]);
    PropertyAccess expression =
        findNodeAtString('p.q.sorted', (node) => node is PropertyAccess);
    expect(getVariableNameSuggestionsForExpression(null, expression, excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  void test_forExpression_simpleName() {
    resolveTestUnit('''
main(p) {
  var sortedNodes = null;
  var res = sortedNodes;
}
''');
    var excluded = new Set<String>.from([]);
    var expr = findNodeAtString('sortedNodes;');
    expect(getVariableNameSuggestionsForExpression(null, expr, excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  void test_forExpression_unqualifiedInvocation() {
    resolveTestUnit('''
getSortedNodes() => [];
main(p) {
  var res = getSortedNodes();
}
''');
    var excluded = new Set<String>.from([]);
    expect(
        getVariableNameSuggestionsForExpression(
            null,
            findNodeAtString(
                'getSortedNodes();', (node) => node is MethodInvocation),
            excluded),
        unorderedEquals(['sortedNodes', 'nodes']));
  }

  void test_forText() {
    {
      Set<String> excluded = new Set<String>.from([]);
      List<String> suggestions =
          getVariableNameSuggestionsForText('Goodbye, cruel world!', excluded);
      expect(suggestions,
          unorderedEquals(['goodbyeCruelWorld', 'cruelWorld', 'world']));
    }
    {
      Set<String> excluded = new Set<String>.from(['world']);
      List<String> suggestions =
          getVariableNameSuggestionsForText('Goodbye, cruel world!', excluded);
      expect(suggestions,
          unorderedEquals(['goodbyeCruelWorld', 'cruelWorld', 'world2']));
    }
  }
}
