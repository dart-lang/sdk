// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.omit_type_for_local_variables;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Omit the types for local variables.';

const _details = r'''

**CONSIDER** omitting the types for local variables.

**BAD:**
```
Map<int, List<Person>> groupByZip(Iterable<Person> people) {
  Map<int, List<Person>> peopleByZip = <int, List<Person>>{};
  for (Person person in people) {
    peopleByZip.putIfAbsent(person.zip, () => <Person>[]);
    peopleByZip[person.zip].add(person);
  }
  return peopleByZip;
}
```

**GOOD:**
```
Map<int, List<Person>> groupByZip(Iterable<Person> people) {
  var peopleByZip = <int, List<Person>>{};
  for (var person in people) {
    peopleByZip.putIfAbsent(person.zip, () => <Person>[]);
    peopleByZip[person.zip].add(person);
  }
  return peopleByZip;
}
```

''';

class OmitLocalVariableTypes extends LintRule {
  _Visitor _visitor;
  OmitLocalVariableTypes()
      : super(
            name: 'omit_local_variable_types',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitForEachStatement(ForEachStatement node) {
    final staticType = node.loopVariable.type;
    if (staticType == null) {
      return;
    }
    if (node.iterable.bestType is! InterfaceType) {
      return;
    }
    DartType iterableType = node.iterable.bestType;
    if (iterableType is InterfaceType &&
        iterableType.typeArguments.single == staticType.type) {
      rule.reportLint(node);
    }
  }

  @override
  visitForStatement(ForStatement node) {
    _visitVariableDeclarationList(node.variables);
  }

  @override
  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _visitVariableDeclarationList(node.variables);
  }

  _visitVariableDeclarationList(VariableDeclarationList node) {
    final staticType = node.type;
    if (staticType?.type == null) {
      return;
    }
    for (final child in node.variables) {
      if (child.initializer?.bestType != staticType.type) {
        return;
      }
    }
    rule.reportLint(node);
  }
}
