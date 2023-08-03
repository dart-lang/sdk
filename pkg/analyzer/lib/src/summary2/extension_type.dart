// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart' as graph;
import 'package:analyzer/dart/element/element.dart';
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
  for (final declaration in declarations) {
    if (declaration is ExtensionTypeDeclarationImpl) {
      final node = walker.getNode(declaration);
      nodes.add(node);
    }
  }

  for (final node in nodes) {
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
    element.hasSelfReference = true;
    _evaluateWithType(InvalidTypeImpl.instance);
  }
}

class _Walker extends graph.DependencyWalker<_Node> {
  final Linker linker;
  final Map<ExtensionTypeElement, _Node> nodeMap = Map.identity();

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
