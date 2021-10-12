// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = r'Omit type annotations for local variables.';

const _details = r'''

**CONSIDER** omitting type annotations for local variables.

Usually, the types of local variables can be easily inferred, so it isn't
necessary to annotate them.

**BAD:**
```dart
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
```dart
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
    var visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitForStatement(ForStatement node) {
    var loopParts = node.forLoopParts;
    if (loopParts is ForPartsWithDeclarations) {
      _visitVariableDeclarationList(loopParts.variables);
    } else if (loopParts is ForEachPartsWithDeclaration) {
      var loopVariableType = loopParts.loopVariable.type;
      var staticType = loopVariableType?.type;
      if (staticType == null || staticType.isDynamic) {
        return;
      }
      var iterableType = loopParts.iterable.staticType;
      if (iterableType is InterfaceType) {
        var iterableInterfaces = DartTypeUtilities.getImplementedInterfaces(
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

  bool _dependsOnDeclaredTypeForInference(Expression? initializer) {
    if (initializer is MethodInvocation) {
      if (initializer.typeArguments == null) {
        var element = initializer.methodName.staticElement;
        if (element is FunctionElement) {
          if (element.returnType is TypeParameterType) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _visitVariableDeclarationList(VariableDeclarationList node) {
    var staticType = node.type?.type;
    if (staticType == null ||
        staticType.isDynamic ||
        staticType.isDartCoreNull) {
      return;
    }
    for (var child in node.variables) {
      var initializer = child.initializer;
      if (initializer?.staticType != staticType) {
        return;
      }
      if (_dependsOnDeclaredTypeForInference(initializer)) {
        return;
      }
    }
    rule.reportLint(node);
  }
}
