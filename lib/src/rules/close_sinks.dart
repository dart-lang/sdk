// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.close_sinks;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/linter.dart';

typedef void _VisitVariableDeclaration(VariableDeclaration node);

typedef bool _Predicate(AstNode node);

typedef _Predicate _PredicateBuilder(VariableDeclaration v);

const _desc = r'Close instances of `dart.core.Sink`.';

const _details = r'''

**DO** invoke `close` on instances of `dart.core.Sink` to avoid memory leaks and
unexpected behaviors.

**BAD:**
```
class A {
  IOSink _sinkA;
  void init(filename) {
    _sinkA = new File(filename).openWrite(); // LINT
  }
}
```

**BAD:**
```
void someFunction() {
  IOSink _sinkF; // LINT
}
```

**GOOD:**
```
class B {
  IOSink _sinkB;
  void init(filename) {
    _sinkB = new File(filename).openWrite(); // OK
  }

  void dispose(filename) {
    _sinkB.close();
  }
}
```

**GOOD:**
```
void someFunctionOK() {
  IOSink _sinkFOK; // OK
  _sinkFOK.close();
}
```
''';

class CloseSinks extends LintRule {
  CloseSinks() : super(
      name: 'close_sinks',
      description: _desc,
      details: _details,
      group: Group.errors,
      maturity: Maturity.experimental);

  @override
  AstVisitor getVisitor() => new _Visitor(this);
}

class _Visitor extends SimpleAstVisitor {
  static _PredicateBuilder _isSinkReturn =
      (VariableDeclaration v) =>
      (n) => n is ReturnStatement &&
      n.expression is SimpleIdentifier &&
      (n.expression as SimpleIdentifier).token.lexeme == v.name.token.lexeme;

  static _PredicateBuilder _hasConstructorFieldInitializers =
      (VariableDeclaration v) =>
      (n) => n is ConstructorFieldInitializer &&
      n.fieldName.name == v.name.token.lexeme;

  static _PredicateBuilder _hasFieldFormalParemeter =
      (VariableDeclaration v) =>
      (n) => n is FieldFormalParameter &&
      n.identifier.name == v.name.token.lexeme;

  static List<_PredicateBuilder> _variablePredicateBuiders = [_isSinkReturn];
  static List<_PredicateBuilder> _fieldPredicateBuiders =
    [_hasConstructorFieldInitializers, _hasFieldFormalParemeter];

  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    FunctionBody function =
        node.getAncestor((a) => a is FunctionBody);
    node.variables.variables.forEach(
        _buildVariableReporter(function, _variablePredicateBuiders));
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    ClassDeclaration classDecl =
        node.getAncestor((a) => a is ClassDeclaration);
    node.fields.variables.forEach(
        _buildVariableReporter(classDecl, _fieldPredicateBuiders));
  }

  /// Builds a function that reports the variable node if the set of nodes
  /// inside the [container] node is empty for all the predicates resulting
  /// from building (predicates) with the provided [predicateBuilders] evaluated
  /// in the variable.
  _VisitVariableDeclaration _buildVariableReporter(AstNode container,
      List<_PredicateBuilder> predicateBuilders) =>
          (VariableDeclaration sink) {
        if (!_implementsDartCoreSink(sink.element.type)) {
          return;
        }

        List<AstNode> containerNodes = _traverseNodesInDFS(container);

        List<Iterable<AstNode>> validators = <Iterable<AstNode>>[];
        predicateBuilders.forEach((f) {
          validators.add(containerNodes.where(f(sink)));
        });

        validators.add(_findSinkAssignments(containerNodes, sink));
        validators.add(_findNodesClosingSink(containerNodes, sink));
        validators.add(_findCloseCallbackNodes(containerNodes, sink));
        // If any function is invoked with our sink, we supress lints. This is
        // because it is not so uncommon to close the sink there. We might not
        // have access to the body of such function at analysis time, so trying
        // to infer if the close method is invoked there is not always possible.
        // TODO: Should there be another lint more relaxed that omits this step?
        validators.add(_findMethodInvocations(containerNodes, sink));

        // Read this as: validators.forAll((i) => i.isEmpty).
        if (!validators.any((i) => !i.isEmpty)) {
          rule.reportLint(sink);
        }
      };
}

Iterable<AstNode> _findSinkAssignments(Iterable<AstNode> containerNodes,
    VariableDeclaration sink) =>
    containerNodes.where((n) {
      return n is AssignmentExpression &&
          ((n.leftHandSide is SimpleIdentifier &&
              // Assignment to sink as variable.
              (n.leftHandSide as SimpleIdentifier).token.lexeme ==
                  sink.name.token.lexeme) ||
              // Assignment to sink as setter.
              (n.leftHandSide is PropertyAccess &&
                  (n.leftHandSide as PropertyAccess)
                      .propertyName.token.lexeme == sink.name.token.lexeme))
          // Being assigned another reference.
          && n.rightHandSide is SimpleIdentifier;
    });

Iterable<AstNode> _findMethodInvocations(Iterable<AstNode> containerNodes,
    VariableDeclaration sink) {
  Iterable<MethodInvocation> prefixedIdentifiers =
  containerNodes.where((n) => n is MethodInvocation);
  return prefixedIdentifiers.where((n) =>
  n.argumentList.arguments.map((e) => e is SimpleIdentifier ? e.name : '')
      .contains(sink.name.token.lexeme));
}

Iterable<AstNode> _findCloseCallbackNodes(Iterable<AstNode> containerNodes,
    VariableDeclaration sink) {
  Iterable<PrefixedIdentifier> prefixedIdentifiers =
      containerNodes.where((n) => n is PrefixedIdentifier);
  return prefixedIdentifiers.where((n) =>
    n.prefix.token.lexeme == sink.name.token.lexeme &&
        n.identifier.token.lexeme == 'close');
}

Iterable<AstNode> _findNodesClosingSink(Iterable<AstNode> classNodes,
    VariableDeclaration variable) => classNodes.where(
    (n) => n is MethodInvocation &&
        n.methodName.name == 'close' &&
        ((n.target is SimpleIdentifier &&
            (n.target as SimpleIdentifier).name == variable.name.name) ||
            (n.getAncestor((a) => a == variable) != null)));

bool _implementsDartCoreSink(DartType type) {
  ClassElement element = type.element;
  return !element.isSynthetic &&
      type is InterfaceType &&
      element.allSupertypes.any(_isDartCoreSink);
}

bool _isDartCoreSink(InterfaceType interface) =>
    interface.name == 'Sink' &&
        interface.element.library.name == 'dart.core';

/// Builds the list resulting from traversing the node in DFS and does not
/// include the node itself.
List<AstNode> _traverseNodesInDFS(AstNode node) {
  List<AstNode> nodes = [];
  node.childEntities
      .where((c) => c is AstNode)
      .forEach((c) {
    nodes.add(c);
    nodes.addAll(_traverseNodesInDFS(c));
  });
  return nodes;
}
