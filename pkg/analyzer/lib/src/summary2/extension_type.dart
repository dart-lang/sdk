// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart' as graph;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// Builds extension types, in particular representation types. There might be
/// dependencies between them, so they all should be processed simultaneously.
void buildExtensionTypes(Linker linker, List<AstNode> declarations) {
  var walker = _Walker(linker);
  var nodes = <_Node>[];
  var elements = <ExtensionTypeElementImpl>[];
  for (var declaration in declarations) {
    if (declaration is ExtensionTypeDeclarationImpl) {
      var element = declaration.declaredFragment!.element;
      var node = walker.getNode(declaration);
      nodes.add(node);
      elements.add(element);
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
  final ExtensionTypeDeclarationImpl node;
  final ExtensionTypeElementImpl element;

  @override
  bool isEvaluated = false;

  _Node(this.walker, this.node, this.element);

  @override
  List<_Node> computeDependencies() {
    var type = node.representation.fieldType.typeOrThrow;
    var visitor = _DependenciesCollector();
    type.accept(visitor);

    var dependencies = <_Node>[];
    for (var element in visitor.dependencies) {
      if (walker.linker.isLinkingElement(element)) {
        var declaration = walker.linker.getLinkingNode2(element.firstFragment);
        if (declaration is ExtensionTypeDeclarationImpl) {
          var node = walker.getNode(declaration);
          dependencies.add(node);
        }
      }
    }

    return dependencies;
  }

  void _evaluate() {
    var type = node.representation.fieldType.typeOrThrow;
    _evaluateWithType(type);
  }

  void _evaluateWithType(TypeImpl type) {
    var typeSystem = element.library.typeSystem;

    element.representation.type = type;
    element.primaryFormalParameter.type = type;

    element.typeErasure = type.extensionTypeErasure;
    element.interfaces = element.interfaces
        .whereType<InterfaceType>()
        .where(typeSystem.isValidExtensionTypeSuperinterface)
        .toFixedList();

    isEvaluated = true;
  }

  void _markCircular() {
    element.hasRepresentationSelfReference = true;
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

  _Node getNode(ExtensionTypeDeclarationImpl node) {
    var element = node.declaredFragment!.element;
    return nodeMap[element] ??= _Node(this, node, element);
  }
}
