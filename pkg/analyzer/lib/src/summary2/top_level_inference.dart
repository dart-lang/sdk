// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';
import 'package:analyzer/src/task/strong_mode.dart';

DartType _dynamicIfNull(DartType type) {
  if (type == null || type.isBottom || type.isDartCoreNull) {
    return DynamicTypeImpl.instance;
  }
  return type;
}

AstNode _getLinkedNode(Element element) {
  return (element as ElementImpl).linkedNode;
}

class TopLevelInference {
  final Linker linker;

  TopLevelInference(this.linker);

  DynamicTypeImpl get _dynamicType => DynamicTypeImpl.instance;

  void infer() {
    _performOverrideInference();
    _InitializerInference(linker).perform();
    _inferConstructorFieldFormals();
  }

  void _inferConstructorFieldFormals() {
    for (var builder in linker.builders.values) {
      for (var unit in builder.element.units) {
        for (var class_ in unit.types) {
          var fields = <String, DartType>{};
          for (var field in class_.fields) {
            if (field.isSynthetic) continue;

            var name = field.name;
            var type = field.type;
            if (type == null) {
              throw StateError('Field $name should have a type.');
            }
            fields[name] ??= type;
          }

          for (var constructor in class_.constructors) {
            for (var parameter in constructor.parameters) {
              if (parameter is FieldFormalParameterElement) {
                var node = _getLinkedNode(parameter);
                if (node is DefaultFormalParameter) {
                  var defaultParameter = node as DefaultFormalParameter;
                  node = defaultParameter.parameter;
                }

                if (node is FieldFormalParameter &&
                    node.type == null &&
                    node.parameters == null) {
                  var name = parameter.name;
                  var type = fields[name] ?? _dynamicType;
                  LazyAst.setType(node, type);
                }
              }
            }
          }
        }
      }
    }
  }

  void _performOverrideInference() {
    for (var builder in linker.builders.values) {
      for (var unit in builder.element.units) {
        new InstanceMemberInferrer(
          linker.typeProvider,
          linker.inheritance,
        ).inferCompilationUnit(unit);
      }
    }
  }
}

class _InferenceDependenciesCollector extends RecursiveAstVisitor<void> {
  final Set<PropertyInducingElement> _set = Set.identity();

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element is PropertyAccessorElement && element.isGetter) {
      _set.add(element.variable);
    }
  }
}

class _InferenceNode extends graph.Node<_InferenceNode> {
  final _InferenceWalker _walker;
  final LibraryElement _library;
  final Scope _scope;
  final VariableDeclaration _node;

  @override
  bool isEvaluated = false;

  _InferenceNode(this._walker, this._library, this._scope, this._node);

  @override
  List<_InferenceNode> computeDependencies() {
    _node.initializer.accept(LocalElementBuilder(ElementHolder(), null));

    _resolveInitializer();

    var collector = _InferenceDependenciesCollector();
    _node.initializer.accept(collector);

    if (collector._set.isEmpty) {
      return const <_InferenceNode>[];
    }

    return collector._set
        .map(_walker.getNode)
        .where((node) => node != null)
        .toList();
  }

  void evaluate() {
    _resolveInitializer();

    VariableDeclarationList parent = _node.parent;
    if (parent.type == null) {
      var initializerType = _node.initializer.staticType;
      initializerType = _dynamicIfNull(initializerType);
      LazyAst.setType(_node, initializerType);
    }

    isEvaluated = true;
  }

  void markCircular() {
    LazyAst.setType(_node, DynamicTypeImpl.instance);
    isEvaluated = true;
  }

  void _resolveInitializer() {
    var astResolver = AstResolver(_walker._linker, _library, _scope);
    astResolver.resolve(_node.initializer);
  }
}

class _InferenceWalker extends graph.DependencyWalker<_InferenceNode> {
  final Linker _linker;
  final Map<Element, _InferenceNode> _nodes = Map.identity();

  _InferenceWalker(this._linker);

  void addNode(Element element, LibraryElement library, Scope scope,
      VariableDeclaration node) {
    _nodes[element] = _InferenceNode(this, library, scope, node);
  }

  @override
  void evaluate(_InferenceNode v) {
    v.evaluate();
  }

  @override
  void evaluateScc(List<_InferenceNode> scc) {
    for (var node in scc) {
      node.markCircular();
    }
  }

  _InferenceNode getNode(Element element) {
    return _nodes[element];
  }

  void walkNodes() {
    for (var node in _nodes.values) {
      if (!node.isEvaluated) {
        walk(node);
      }
    }
  }
}

class _InitializerInference {
  final Linker _linker;
  final _InferenceWalker _walker;

  LibraryElement _library;
  Scope _scope;

  _InitializerInference(this._linker) : _walker = _InferenceWalker(_linker);

  void perform() {
    for (var builder in _linker.builders.values) {
      _library = builder.element;
      for (var unit in _library.units) {
        for (var class_ in unit.types) {
          var node = _getLinkedNode(class_);
          _scope = LinkingNodeContext.get(node).scope;
          for (var element in class_.fields) {
            _addNode(element);
          }
        }

        _scope = builder.libraryScope;
        for (var element in unit.topLevelVariables) {
          _addNode(element);
        }
      }
    }
    _walker.walkNodes();
  }

  void _addNode(PropertyInducingElement element) {
    if (element.isSynthetic) return;

    VariableDeclaration node = _getLinkedNode(element);
    VariableDeclarationList variableList = node.parent;
    if (variableList.type == null || element.isConst) {
      if (node.initializer != null) {
        _walker.addNode(element, _library, _scope, node);
      } else {
        if (LazyAst.getType(node) == null) {
          LazyAst.setType(node, DynamicTypeImpl.instance);
        }
      }
    }
  }
}
