// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart' as graph;
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/link.dart';

/// Clears interfaces for declarations that have cycles.
void breakInterfaceCycles(Linker linker, List<AstNode> declarations) {
  var walker = _ImplementsWalker();
  var elements = <InterfaceElementImpl>[];
  for (var declaration in declarations) {
    if (declaration is DeclarationImpl) {
      var element = declaration.declaredFragment!.element;
      if (element is InterfaceElementImpl) {
        elements.add(element);
      }
    }
  }

  for (var element in elements) {
    var node = walker.getNode(element);
    walker.walk(node);
  }
}

class _ImplementsNode extends graph.Node<_ImplementsNode> {
  final _ImplementsWalker walker;
  final InterfaceElementImpl element;

  @override
  bool isEvaluated = false;

  _ImplementsNode(this.walker, this.element);

  @override
  List<_ImplementsNode> computeDependencies() {
    return [
          element.supertype,
          ...element.mixins,
          ...element.interfaces,
          if (element case MixinElementImpl element)
            ...element.superclassConstraints,
        ].nonNulls
        .map((interface) => interface.element)
        .map(walker.getNode)
        .toList();
  }

  void _evaluate() {
    isEvaluated = true;
  }

  void _markCircular(List<InterfaceElementImpl> elements) {
    isEvaluated = true;

    element.interfaceCycle = elements;

    var typeProvider = element.library.typeProvider;
    var typeSystem = element.library.typeSystem;

    switch (element) {
      case ClassElementImpl element:
        element.supertype = typeProvider.objectType;
        element.mixins = [];
        element.interfaces = [];
      case EnumElementImpl element:
        element.mixins = [];
        element.interfaces = [];
      case ExtensionTypeElementImpl element:
        element.hasImplementsSelfReference = true;
        var representationType = element.representation.type;
        var superInterface = typeSystem.isNonNullable(representationType)
            ? typeSystem.objectNone
            : typeSystem.objectQuestion;
        element.interfaces = [superInterface];
      case MixinElementImpl element:
        element.superclassConstraints = [typeProvider.objectType];
        element.interfaces = [];
      default:
        throw UnimplementedError('${element.runtimeType}');
    }
  }
}

class _ImplementsWalker extends graph.DependencyWalker<_ImplementsNode> {
  final Map<InterfaceElementImpl, _ImplementsNode> nodeMap = Map.identity();

  @override
  void evaluate(_ImplementsNode v) {
    v._evaluate();
  }

  @override
  void evaluateScc(List<_ImplementsNode> scc) {
    var elements = scc.map((node) => node.element).toList();
    for (var node in scc) {
      node._markCircular(elements);
    }
  }

  _ImplementsNode getNode(InterfaceElementImpl element) {
    return nodeMap[element] ??= _ImplementsNode(this, element);
  }
}
