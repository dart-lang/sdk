// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart' as graph;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// Builds extension types, in particular representation types. There might be
/// dependencies between them, so they all should be processed simultaneously.
void buildExtensionTypes(Linker linker, List<AstNode> declarations) {
  final walker = _Walker(linker);
  final nodes = <_Node>[];
  final elements = <ExtensionTypeElementImpl>[];
  for (final declaration in declarations) {
    if (declaration is ExtensionTypeDeclarationImpl) {
      final node = walker.getNode(declaration);
      nodes.add(node);
      elements.add(node.element);
    }
  }

  for (final node in nodes) {
    walker.walk(node);
  }

  _breakImplementsCycles(elements);
}

/// Clears interfaces for extension types that have cycles.
void _breakImplementsCycles(List<ExtensionTypeElementImpl> elements) {
  final walker = _ImplementsWalker();
  for (final element in elements) {
    final node = walker.getNode(element);
    walker.walk(node);
  }
}

/// Collector of referenced extension types in a type.
class _DependenciesCollector extends RecursiveTypeVisitor {
  final List<ExtensionTypeElementImpl> dependencies = [];

  @override
  bool visitInterfaceType(InterfaceType type) {
    final element = type.element;
    if (element is ExtensionTypeElementImpl) {
      dependencies.add(element);
    }

    return super.visitInterfaceType(type);
  }
}

class _ExtensionTypeErasure extends ReplacementVisitor {
  DartType perform(DartType type) {
    return type.accept(this) ?? type;
  }

  @override
  DartType? visitInterfaceType(covariant InterfaceTypeImpl type) {
    final typeErasure = type.representationTypeErasure;
    if (typeErasure != null) {
      return typeErasure;
    }

    return super.visitInterfaceType(type);
  }
}

class _ImplementsNode extends graph.Node<_ImplementsNode> {
  final _ImplementsWalker walker;
  final ExtensionTypeElementImpl element;

  @override
  bool isEvaluated = false;

  _ImplementsNode(this.walker, this.element);

  @override
  List<_ImplementsNode> computeDependencies() {
    return element.interfaces
        .map((interface) => interface.element)
        .whereType<ExtensionTypeElementImpl>()
        .map(walker.getNode)
        .toList();
  }

  void _evaluate() {
    isEvaluated = true;
  }

  void _markCircular() {
    isEvaluated = true;
    element.hasImplementsSelfReference = true;

    final representationType = element.representation.type;
    final typeSystem = element.library.typeSystem;

    final superInterface = typeSystem.isNonNullable(representationType)
        ? typeSystem.objectNone
        : typeSystem.objectQuestion;
    element.interfaces = [superInterface];
  }
}

class _ImplementsWalker extends graph.DependencyWalker<_ImplementsNode> {
  final Map<ExtensionTypeElementImpl, _ImplementsNode> nodeMap = Map.identity();

  @override
  void evaluate(_ImplementsNode v) {
    v._evaluate();
  }

  @override
  void evaluateScc(List<_ImplementsNode> scc) {
    for (final node in scc) {
      node._markCircular();
    }
  }

  _ImplementsNode getNode(ExtensionTypeElementImpl element) {
    return nodeMap[element] ??= _ImplementsNode(this, element);
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
    final type = node.representation.fieldType.typeOrThrow;
    final visitor = _DependenciesCollector();
    type.accept(visitor);

    final dependencies = <_Node>[];
    for (final element in visitor.dependencies) {
      final declaration = walker.linker.elementNodes[element];
      if (declaration is ExtensionTypeDeclarationImpl) {
        final node = walker.getNode(declaration);
        dependencies.add(node);
      }
    }

    return dependencies;
  }

  void _evaluate() {
    final type = node.representation.fieldType.typeOrThrow;
    _evaluateWithType(type);
  }

  void _evaluateWithType(DartType type) {
    final typeSystem = element.library.typeSystem;

    element.representation.type = type;
    element.typeErasure = _ExtensionTypeErasure().perform(type);

    var interfaces = node.implementsClause?.interfaces
        .map((e) => e.type)
        .whereType<InterfaceType>()
        .where(typeSystem.isValidExtensionTypeSuperinterface)
        .toFixedList();
    if (interfaces == null || interfaces.isEmpty) {
      final superInterface = typeSystem.isNonNullable(type)
          ? typeSystem.objectNone
          : typeSystem.objectQuestion;
      interfaces = [superInterface];
    }
    element.interfaces = interfaces;

    final primaryConstructor = element.constructors.first;
    final primaryFormalParameter = primaryConstructor.parameters.first;
    primaryFormalParameter as FieldFormalParameterElementImpl;
    primaryFormalParameter.type = type;
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
    for (final node in scc) {
      node._markCircular();
    }
  }

  _Node getNode(ExtensionTypeDeclarationImpl node) {
    final element = node.declaredElement!;
    return nodeMap[element] ??= _Node(this, node, element);
  }
}
