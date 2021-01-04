// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';
import 'package:analyzer/src/task/inference_error.dart';
import 'package:analyzer/src/task/strong_mode.dart';
import 'package:meta/meta.dart';

AstNode _getLinkedNode(Element element) {
  return (element as ElementImpl).linkedNode;
}

/// Resolver for typed constant top-level variables and fields initializers.
///
/// Initializers of untyped variables are resolved during [TopLevelInference].
class ConstantInitializersResolver {
  final Linker linker;

  CompilationUnitElement _unitElement;
  LibraryElement _library;
  bool _enclosingClassHasConstConstructor = false;
  Scope _scope;

  ConstantInitializersResolver(this.linker);

  void perform() {
    for (var builder in linker.builders.values) {
      _library = builder.element;
      for (var unit in _library.units) {
        _unitElement = unit;
        unit.extensions.forEach(_resolveExtensionFields);
        unit.mixins.forEach(_resolveClassFields);
        unit.types.forEach(_resolveClassFields);

        _scope = builder.scope;
        unit.topLevelVariables.forEach(_resolveVariable);
      }
    }
  }

  void _resolveClassFields(ClassElement class_) {
    _enclosingClassHasConstConstructor =
        class_.constructors.any((c) => c.isConst);

    var node = _getLinkedNode(class_);
    _scope = LinkingNodeContext.get(node).scope;
    for (var element in class_.fields) {
      _resolveVariable(element);
    }
    _enclosingClassHasConstConstructor = false;
  }

  void _resolveExtensionFields(ExtensionElement extension_) {
    var node = _getLinkedNode(extension_);
    _scope = LinkingNodeContext.get(node).scope;
    for (var element in extension_.fields) {
      _resolveVariable(element);
    }
  }

  void _resolveVariable(VariableElement element) {
    if (element.isSynthetic) return;

    VariableDeclaration variable = _getLinkedNode(element);
    if (variable.initializer == null) return;

    VariableDeclarationList declarationList = variable.parent;
    var typeNode = declarationList.type;
    if (typeNode != null) {
      if (declarationList.isConst ||
          declarationList.isFinal && _enclosingClassHasConstConstructor) {
        var astResolver = AstResolver(linker, _unitElement, _scope);
        astResolver.resolve(
          variable.initializer,
          () {
            InferenceContext.setType(variable.initializer, typeNode.type);
            return variable.initializer;
          },
          isTopLevelVariableInitializer: true,
        );
      }
    }
  }
}

class TopLevelInference {
  final Linker linker;

  TopLevelInference(this.linker);

  void infer() {
    var initializerInference = _InitializerInference(linker);
    initializerInference.createNodes();

    _performOverrideInference();

    initializerInference.perform();
  }

  void _performOverrideInference() {
    var inferrer = InstanceMemberInferrer(linker.inheritance);
    for (var builder in linker.builders.values) {
      for (var unit in builder.element.units) {
        inferrer.inferCompilationUnit(unit);
      }
    }
  }
}

class _ConstructorInferenceNode extends _InferenceNode {
  final _InferenceWalker _walker;
  final ConstructorElement _constructor;

  /// The parameters that have types from [_fields].
  final List<FieldFormalParameter> _parameters = [];

  /// The parallel list of fields corresponding to [_parameters].
  final List<FieldElement> _fields = [];

  @override
  bool isEvaluated = false;

  _ConstructorInferenceNode(
    this._walker,
    this._constructor,
    Map<String, FieldElement> fieldMap,
  ) {
    for (var parameterElement in _constructor.parameters) {
      if (parameterElement is FieldFormalParameterElement) {
        var parameterNode = _getLinkedNode(parameterElement);
        if (parameterNode is DefaultFormalParameter) {
          var defaultParameter = parameterNode as DefaultFormalParameter;
          parameterNode = defaultParameter.parameter;
        }

        if (parameterNode is FieldFormalParameter &&
            parameterNode.type == null &&
            parameterNode.parameters == null) {
          parameterNode.identifier.staticElement = parameterElement;
          var name = parameterNode.identifier.name;
          var fieldElement = fieldMap[name];
          if (fieldElement != null) {
            _parameters.add(parameterNode);
            _fields.add(fieldElement);
          } else {
            (parameterElement as ParameterElementImpl).type =
                DynamicTypeImpl.instance;
          }
        }
      }
    }
  }

  @override
  String get displayName => '$_constructor';

  @override
  List<_InferenceNode> computeDependencies() {
    return _fields.map(_walker.getNode).where((node) => node != null).toList();
  }

  @override
  void evaluate() {
    for (var i = 0; i < _parameters.length; ++i) {
      var parameter = _parameters[i];
      var type = _fields[i].type;
      (parameter.declaredElement as ParameterElementImpl).type = type;
    }
    isEvaluated = true;
  }

  @override
  void markCircular(List<_InferenceNode> cycle) {
    for (var i = 0; i < _parameters.length; ++i) {
      var parameterNode = _parameters[i];
      (parameterNode.declaredElement as ParameterElementImpl).type =
          DynamicTypeImpl.instance;
    }
    isEvaluated = true;
  }
}

class _InferenceDependenciesCollector extends RecursiveAstVisitor<void> {
  final Set<Element> _set = Set.identity();

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var element = node.constructorName.staticElement?.declaration;
    if (element == null) return;

    _set.add(element);

    if (element.enclosingElement.typeParameters.isNotEmpty) {
      node.argumentList.accept(this);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element is PropertyAccessorElement && element.isGetter) {
      _set.add(element.variable);
    }
  }
}

abstract class _InferenceNode extends graph.Node<_InferenceNode> {
  String get displayName;

  void evaluate();

  void markCircular(List<_InferenceNode> cycle);
}

class _InferenceWalker extends graph.DependencyWalker<_InferenceNode> {
  final Linker _linker;
  final Map<Element, _InferenceNode> _nodes = Map.identity();

  _InferenceWalker(this._linker);

  @override
  void evaluate(_InferenceNode v) {
    v.evaluate();
  }

  @override
  void evaluateScc(List<_InferenceNode> scc) {
    for (var node in scc) {
      node.markCircular(scc);
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

  CompilationUnitElement _unitElement;
  Scope _scope;

  _InitializerInference(this._linker) : _walker = _InferenceWalker(_linker);

  void createNodes() {
    for (var builder in _linker.builders.values) {
      for (var unit in builder.element.units) {
        _unitElement = unit;
        unit.extensions.forEach(_addExtensionElementFields);
        unit.mixins.forEach(_addClassElementFields);
        unit.types.forEach(_addClassConstructorFieldFormals);
        unit.types.forEach(_addClassElementFields);

        _scope = builder.scope;
        for (var element in unit.topLevelVariables) {
          _addVariableNode(element);
        }
      }
    }
  }

  void perform() {
    _walker.walkNodes();
  }

  void _addClassConstructorFieldFormals(ClassElement class_) {
    var fieldMap = <String, FieldElement>{};
    for (var field in class_.fields) {
      if (field.isStatic) continue;
      if (field.isSynthetic) continue;
      fieldMap[field.name] ??= field;
    }

    for (var constructor in class_.constructors) {
      var inferenceNode =
          _ConstructorInferenceNode(_walker, constructor, fieldMap);
      _walker._nodes[constructor] = inferenceNode;
    }
  }

  void _addClassElementFields(ClassElement class_) {
    var node = _getLinkedNode(class_);
    _scope = LinkingNodeContext.get(node).scope;
    for (var element in class_.fields) {
      _addVariableNode(element);
    }
  }

  void _addExtensionElementFields(ExtensionElement extension_) {
    var node = _getLinkedNode(extension_);
    _scope = LinkingNodeContext.get(node).scope;
    for (var element in extension_.fields) {
      _addVariableNode(element);
    }
  }

  void _addVariableNode(PropertyInducingElement element) {
    if (element.isSynthetic) return;

    var node = _getLinkedNode(element) as VariableDeclaration;
    var variableList = node.parent as VariableDeclarationList;
    if (variableList.type != null) {
      return;
    }

    if (node.initializer != null) {
      var inferenceNode =
          _VariableInferenceNode(_walker, _unitElement, _scope, node);
      _walker._nodes[element] = inferenceNode;
      (element as PropertyInducingElementImpl).typeInference =
          _PropertyInducingElementTypeInference(inferenceNode);
    } else {
      (element as PropertyInducingElementImpl).type = DynamicTypeImpl.instance;
    }
  }
}

class _PropertyInducingElementTypeInference
    implements PropertyInducingElementTypeInference {
  final _VariableInferenceNode _node;

  _PropertyInducingElementTypeInference(this._node);

  @override
  void perform() {
    if (!_node.isEvaluated) {
      _node._walker.walk(_node);
    }
  }
}

class _VariableInferenceNode extends _InferenceNode {
  final _InferenceWalker _walker;
  final CompilationUnitElement _unitElement;
  final TypeSystemImpl _typeSystem;
  final Scope _scope;
  final VariableDeclaration _node;

  @override
  bool isEvaluated = false;

  _VariableInferenceNode(
    this._walker,
    this._unitElement,
    this._scope,
    this._node,
  ) : _typeSystem = _unitElement.library.typeSystem;

  @override
  String get displayName {
    return _node.name.name;
  }

  bool get isImplicitlyTypedInstanceField {
    VariableDeclarationList variables = _node.parent;
    if (variables.type == null) {
      var parent = variables.parent;
      return parent is FieldDeclaration && !parent.isStatic;
    }
    return false;
  }

  PropertyInducingElementImpl get _elementImpl {
    return _node.declaredElement as PropertyInducingElementImpl;
  }

  @override
  List<_InferenceNode> computeDependencies() {
    _resolveInitializer(forDependencies: true);

    var collector = _InferenceDependenciesCollector();
    _node.initializer.accept(collector);

    if (collector._set.isEmpty) {
      return const <_InferenceNode>[];
    }

    var dependencies = collector._set
        .map(_walker.getNode)
        .where((node) => node != null)
        .toList();

    for (var node in dependencies) {
      if (node is _VariableInferenceNode &&
          node.isImplicitlyTypedInstanceField) {
        _elementImpl.type = DynamicTypeImpl.instance;
        isEvaluated = true;
        return const <_InferenceNode>[];
      }
    }

    return dependencies;
  }

  @override
  void evaluate() {
    _resolveInitializer(forDependencies: false);

    if (!_elementImpl.hasTypeInferred) {
      var initializerType = _node.initializer.staticType;
      initializerType = _refineType(initializerType);
      _elementImpl.type = initializerType;
    }

    isEvaluated = true;
  }

  @override
  void markCircular(List<_InferenceNode> cycle) {
    _elementImpl.type = DynamicTypeImpl.instance;

    var cycleNames = <String>{};
    for (var inferenceNode in cycle) {
      cycleNames.add(inferenceNode.displayName);
    }

    _elementImpl.typeInferenceError = TopLevelInferenceError(
      kind: TopLevelInferenceErrorKind.dependencyCycle,
      arguments: cycleNames.toList(),
    );

    isEvaluated = true;
  }

  DartType _refineType(DartType type) {
    if (type == null || type.isDartCoreNull) {
      return DynamicTypeImpl.instance;
    }

    if (_typeSystem.isNonNullableByDefault) {
      return _typeSystem.nonNullifyLegacy(type);
    } else {
      if (type.isBottom) {
        return DynamicTypeImpl.instance;
      }
      return type;
    }
  }

  void _resolveInitializer({@required bool forDependencies}) {
    var astResolver = AstResolver(_walker._linker, _unitElement, _scope);
    astResolver.resolve(
      _node.initializer,
      () => _node.initializer,
      buildElements: forDependencies,
      isTopLevelVariableInitializer: true,
    );
  }
}
