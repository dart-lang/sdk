// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = r'Omit type annotations for local variables.';

const _details = r'''

**CONSIDER** omitting type annotations for local variables.

Usually, the types of local variables can be easily inferred, so it isn't
necessary to annotate them.

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

class OmitLocalVariableTypes extends LintRule implements NodeLintRule {
  OmitLocalVariableTypes()
      : super(
            name: 'omit_local_variable_types',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  List<String> get incompatibleRules => const ['always_specify_types'];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitForStatement(ForStatement node) {
    final loopParts = node.forLoopParts;
    if (loopParts is ForPartsWithDeclarations) {
      _visitVariableDeclarationList(loopParts.variables);
    } else if (loopParts is ForEachPartsWithDeclaration) {
      final loopVariableType = loopParts.loopVariable.type;
      final staticType = loopVariableType?.type;
      if (staticType == null || staticType.isDynamic) {
        return;
      }
      final iterableType = loopParts.iterable.staticType;
      if (iterableType is InterfaceType) {
        final iterableInterfaces = DartTypeUtilities.getImplementedInterfaces(
                iterableType)
            .where((type) =>
                DartTypeUtilities.isInterface(type, 'Iterable', 'dart.core'));
        if (iterableInterfaces.length == 1 &&
            iterableInterfaces.first.typeArguments.first == staticType) {
          rule.reportLint(loopVariableType);
        }
      }
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _visitVariableDeclarationList(node.variables);
  }

  void _visitVariableDeclarationList(VariableDeclarationList node) {
    final staticType = node?.type?.type;
    if (staticType == null || staticType.isDynamic) {
      return;
    }
    for (final child in node.variables) {
      if (child.initializer?.staticType != staticType) {
        return;
      }
    }
    rule.reportLint(node);
  }
}
