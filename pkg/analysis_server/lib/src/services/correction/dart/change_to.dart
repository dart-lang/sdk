// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/levenshtein.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A predicate is a one-argument function that returns a boolean value.
typedef _ElementPredicate = bool Function(Element argument);

class ChangeTo extends CorrectionProducer {
  /// The kind of elements that should be proposed.
  final _ReplacementKind _kind;

  /// The name to which the undefined name will be changed.
  String _proposedName = '';

  /// Initialize a newly created instance that will propose classes and mixins.
  ChangeTo.annotation() : _kind = _ReplacementKind.annotation;

  /// Initialize a newly created instance that will propose classes and mixins.
  ChangeTo.classOrMixin() : _kind = _ReplacementKind.classOrMixin;

  /// Initialize a newly created instance that will propose fields.
  ChangeTo.field() : _kind = _ReplacementKind.field;

  /// Initialize a newly created instance that will propose functions.
  ChangeTo.function() : _kind = _ReplacementKind.function;

  /// Initialize a newly created instance that will propose getters and setters.
  ChangeTo.getterOrSetter() : _kind = _ReplacementKind.getterOrSetter;

  /// Initialize a newly created instance that will propose methods.
  ChangeTo.method() : _kind = _ReplacementKind.method;

  /// Initialize a newly created instance that will propose super formal
  /// parameters.
  ChangeTo.superFormalParameter()
      : _kind = _ReplacementKind.superFormalParameter;

  @override
  List<Object> get fixArguments => [_proposedName];

  @override
  FixKind get fixKind => DartFixKind.CHANGE_TO;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // TODO(brianwilkerson) Unify these separate methods as much as is
    //  reasonably possible.
    // TODO(brianwilkerson) Consider proposing all of the names within a
    //  reasonable distance, rather than just the first near match we find.
    if (_kind == _ReplacementKind.annotation) {
      await _proposeAnnotation(builder);
    } else if (_kind == _ReplacementKind.classOrMixin) {
      await _proposeClassOrMixin(builder, node);
    } else if (_kind == _ReplacementKind.field) {
      await _proposeField(builder);
    } else if (_kind == _ReplacementKind.function) {
      await _proposeFunction(builder);
    } else if (_kind == _ReplacementKind.getterOrSetter) {
      await _proposeGetterOrSetter(builder);
    } else if (_kind == _ReplacementKind.method) {
      await _proposeMethod(builder);
    } else if (_kind == _ReplacementKind.superFormalParameter) {
      await _proposeSuperFormalParameter(builder);
    }
  }

  Iterable<ParameterElement> _formalParameterSuggestions(
      FunctionTypedElement element,
      Iterable<FormalParameter> formalParameters) {
    return element.parameters.where((superParam) =>
        superParam.isNamed &&
        !formalParameters
            .any((param) => superParam.name == param.name?.lexeme));
  }

  Future<void> _proposeAnnotation(ChangeBuilder builder) async {
    final node = this.node;
    if (node is Annotation) {
      var name = node.name;
      if (name.staticElement == null) {
        if (node.arguments != null) {
          await _proposeClassOrMixin(builder, name);
        }
      }
    }
  }

  Future<void> _proposeClassOrMixin(ChangeBuilder builder, AstNode node) async {
    // Prepare the optional import prefix name.
    String? prefixName;
    if (node is PrefixedIdentifier &&
        node.parent is NamedType &&
        node.prefix.staticElement is PrefixElement) {
      prefixName = node.prefix.name;
      node = node.identifier;
    }
    // Process if looks like a type.
    var name = nameOfType(node);
    if (name != null) {
      // Prepare for selecting the closest element.
      var finder = _ClosestElementFinder(
          name, (Element element) => element is InterfaceElement);
      // Check elements of this library.
      if (prefixName == null) {
        for (var unit in resolvedResult.libraryElement.units) {
          finder._updateList(unit.classes);
        }
      }
      // Check elements from imports.
      for (var importElement in resolvedResult.libraryElement.libraryImports) {
        if (importElement.prefix?.element.name == prefixName) {
          var namespace = getImportNamespace(importElement);
          finder._updateList(namespace.values);
        }
      }
      // If we have a close enough element, suggest to use it.
      await _suggest(builder, node, finder._element?.name);
    }
  }

  Future<void> _proposeClassOrMixinMember(ChangeBuilder builder, Token node,
      Expression? target, _ElementPredicate predicate) async {
    var targetIdentifierElement =
        target is Identifier ? target.staticElement : null;
    var finder = _ClosestElementFinder(node.lexeme, predicate);
    // unqualified invocation
    if (target == null) {
      var clazz = this.node.thisOrAncestorOfType<ClassDeclaration>();
      if (clazz != null) {
        var interfaceElement = clazz.declaredElement!;
        _updateFinderWithClassMembers(finder, interfaceElement);
      }
    } else if (target is ExtensionOverride) {
      _updateFinderWithExtensionMembers(finder, target.element);
    } else if (targetIdentifierElement is ExtensionElement) {
      _updateFinderWithExtensionMembers(finder, targetIdentifierElement);
    } else {
      var interfaceElement = getTargetInterfaceElement(target);
      if (interfaceElement != null) {
        _updateFinderWithClassMembers(finder, interfaceElement);
      }
    }
    // if we have close enough element, suggest to use it
    await _suggest(builder, node, finder._element?.displayName);
  }

  Future<void> _proposeField(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! FieldFormalParameter) return;

    var exclusions = <String>{};
    var constructorDeclaration =
        node.thisOrAncestorOfType<ConstructorDeclaration>();
    var initializers = constructorDeclaration?.initializers;
    if (initializers != null) {
      for (var initializer in initializers) {
        if (initializer is ConstructorFieldInitializer) {
          exclusions.add(initializer.fieldName.name);
        }
      }
    }
    var formalParameterList = node.thisOrAncestorOfType<FormalParameterList>();
    if (formalParameterList != null) {
      for (var parameter in formalParameterList.parameters) {
        var name = parameter.name?.lexeme;
        if (name != null) {
          exclusions.add(name);
        }
      }
    }

    var type = node.type?.type;
    await _proposeClassOrMixinMember(builder, node.name, null,
        (Element element) {
      return element is FieldElement &&
          !exclusions.contains(element.name) &&
          !element.isSynthetic &&
          !element.isExternal &&
          (type == null || typeSystem.isAssignableTo(type, element.type));
    });
  }

  Future<void> _proposeFunction(ChangeBuilder builder) async {
    final node = this.node;
    if (node is SimpleIdentifier) {
      // Prepare the optional import prefix name.
      String? prefixName;
      {
        var invocation = node.parent;
        if (invocation is MethodInvocation && invocation.methodName == node) {
          var target = invocation.target;
          if (target is SimpleIdentifier &&
              target.staticElement is PrefixElement) {
            prefixName = target.name;
          }
        }
      }
      // Prepare for selecting the closest element.
      var finder = _ClosestElementFinder(
          node.name, (Element element) => element is FunctionElement);
      // Check to this library units.
      if (prefixName == null) {
        for (var unit in resolvedResult.libraryElement.units) {
          finder._updateList(unit.functions);
        }
      }
      // Check unprefixed imports.
      for (var importElement in resolvedResult.libraryElement.libraryImports) {
        if (importElement.prefix?.element.name == prefixName) {
          var namespace = getImportNamespace(importElement);
          finder._updateList(namespace.values);
        }
      }
      // If we have a close enough element, suggest to use it.
      await _suggest(builder, node, finder._element?.name);
    }
  }

  Future<void> _proposeGetterOrSetter(ChangeBuilder builder) async {
    final node = this.node;
    if (node is SimpleIdentifier) {
      // prepare target
      Expression? target;
      var parent = node.parent;
      if (parent is PrefixedIdentifier) {
        target = parent.prefix;
      } else if (parent is PropertyAccess) {
        target = parent.target;
      }
      // find getter or setter
      var wantGetter = node.inGetterContext();
      var wantSetter = node.inSetterContext();
      await _proposeClassOrMixinMember(builder, node.token, target,
          (Element element) {
        if (element is PropertyAccessorElement) {
          return wantGetter && element.isGetter ||
              wantSetter && element.isSetter;
        } else if (element is FieldElement) {
          return wantGetter && element.getter != null ||
              wantSetter && element.setter != null;
        }
        return false;
      });
    }
  }

  Future<void> _proposeMethod(ChangeBuilder builder) async {
    final node = this.node;
    var parent = node.parent;
    if (parent is MethodInvocation && node is SimpleIdentifier) {
      await _proposeClassOrMixinMember(builder, node.token, parent.realTarget,
          (Element element) => element is MethodElement && !element.isOperator);
    }
  }

  Future<void> _proposeSuperFormalParameter(ChangeBuilder builder) async {
    final superParameter = node;
    if (superParameter is! SuperFormalParameter) return;

    var constructorDeclaration =
        superParameter.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructorDeclaration == null) return;

    var formalParameters = constructorDeclaration.parameters.parameters
        .whereType<DefaultFormalParameter>();

    var finder =
        _ClosestElementFinder(superParameter.name.lexeme, (Element e) => true);

    var superInvocation = constructorDeclaration.initializers.lastOrNull;

    if (superInvocation is SuperConstructorInvocation) {
      var staticElement = superInvocation.staticElement;
      if (staticElement == null) return;

      var list = _formalParameterSuggestions(staticElement, formalParameters);
      finder._updateList(list);
    } else {
      var targetClassNode =
          superParameter.thisOrAncestorOfType<ClassDeclaration>();
      if (targetClassNode == null) return;

      var targetClassElement = targetClassNode.declaredElement!;
      var superType = targetClassElement.supertype;
      if (superType == null) return;

      for (var constructor in superType.constructors) {
        if (constructor.name.isEmpty) {
          var list = _formalParameterSuggestions(constructor, formalParameters);
          finder._updateList(list);
          break;
        }
      }
    }

    // If we have a close enough element, suggest to use it.
    await _suggest(builder, superParameter.name, finder._element?.name);
  }

  Future<void> _suggest(
      ChangeBuilder builder, SyntacticEntity node, String? name) async {
    if (name != null) {
      _proposedName = name;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.entity(node), _proposedName);
      });
    }
  }

  void _updateFinderWithClassMembers(
      _ClosestElementFinder finder, InterfaceElement clazz) {
    var members = getMembers(clazz);
    finder._updateList(members);
  }

  void _updateFinderWithExtensionMembers(
      _ClosestElementFinder finder, ExtensionElement? element) {
    if (element != null) {
      finder._updateList(getExtensionMembers(element));
    }
  }
}

/// Helper for finding [Element] with name closest to the given.
class _ClosestElementFinder {
  /// The maximum Levenshtein distance between the existing name and a possible
  /// replacement before the replacement is deemed to not be worth offering.
  static const _maxDistance = 3;

  /// The name to be replaced.
  final String _targetName;

  /// A function used to filter the possible elements to those of the right
  /// kind.
  final _ElementPredicate _predicate;

  int _distance = _maxDistance;

  Element? _element;

  _ClosestElementFinder(this._targetName, this._predicate);

  void _update(Element element) {
    if (_predicate(element)) {
      var name = element.name;
      if (name != null) {
        var memberDistance = levenshtein(name, _targetName, _distance);
        if (memberDistance < _distance) {
          _element = element;
          _distance = memberDistance;
        }
      }
    }
  }

  void _updateList(Iterable<Element> elements) {
    for (var element in elements) {
      _update(element);
    }
  }
}

/// A representation of the kind of element that should be suggested.
enum _ReplacementKind {
  annotation,
  classOrMixin,
  field,
  function,
  getterOrSetter,
  method,
  superFormalParameter,
}
