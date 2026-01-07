// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart' as graph;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/summary2/link.dart';

/// Builds extension types, in particular representation types. There might be
/// dependencies between them, so they all should be processed simultaneously.
void buildExtensionTypes(Linker linker) {
  var walker = _Walker(linker);
  var nodes = <_Node>[];
  for (var builder in linker.builders.values) {
    for (var element in builder.element.extensionTypes) {
      nodes.add(walker.getNode(element));
    }
  }

  for (var node in nodes) {
    walker.walk(node);
  }
}

/// Collector of referenced extension types in a type.
class _DependenciesCollector extends RecursiveTypeVisitor {
  final List<ExtensionTypeElementImpl> dependencies = [];

  _DependenciesCollector() : super(includeTypeAliasArguments: false);

  @override
  bool visitInterfaceType(InterfaceType type) {
    var element = type.element;
    if (element is ExtensionTypeElementImpl) {
      dependencies.add(element);
    }

    return super.visitInterfaceType(type);
  }
}

class _Node extends graph.Node<_Node> {
  final _Walker walker;
  final ExtensionTypeElementImpl element;

  @override
  bool isEvaluated = false;

  _Node(this.walker, this.element);

  @override
  List<_Node> computeDependencies() {
    var type = element.representation.type;
    var visitor = _DependenciesCollector();
    type.accept(visitor);

    var dependencies = <_Node>[];
    for (var element in visitor.dependencies) {
      if (walker.linker.isLinkingElement(element)) {
        var node = walker.getNode(element);
        dependencies.add(node);
      }
    }

    return dependencies;
  }

  void _evaluate() {
    var type = element.representation.type;
    _evaluateWithType(type);
  }

  void _evaluateWithType(TypeImpl type) {
    element.typeErasure = type.extensionTypeErasure;
    isEvaluated = true;
  }

  void _markCircular() {
    element.hasRepresentationSelfReference = true;

    var representation = element.representation;
    representation.type = InvalidTypeImpl.instance;
    representation.declaringFormalParameter?.type = InvalidTypeImpl.instance;

    _evaluateWithType(InvalidTypeImpl.instance);
  }
}

class _Walker extends graph.DependencyWalker<_Node> {
  final Linker linker;
  final Map<ExtensionTypeElementImpl, _Node> nodeMap = Map.identity();

  _Walker(this.linker);

  @override
  void evaluate(_Node v) {
    v._evaluate();
  }

  @override
  void evaluateScc(List<_Node> scc) {
    for (var node in scc) {
      node._markCircular();
    }
  }

  _Node getNode(ExtensionTypeElementImpl element) {
    return nodeMap[element] ??= _Node(this, element);
  }
}
