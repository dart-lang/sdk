// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/levenshtein.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A predicate is a one-argument function that returns a boolean value.
typedef _ElementPredicate = bool Function(Element2 argument);

class ChangeTo extends ResolvedCorrectionProducer {
  /// The kind of elements that should be proposed.
  final _ReplacementKind _kind;

  /// The name to which the undefined name will be changed.
  String _proposedName = '';

  /// Initializes a newly created instance that will propose classes and mixins.
  ChangeTo.annotation({required super.context})
    : _kind = _ReplacementKind.annotation;

  /// Initializes a newly created instance that will propose classes and mixins.
  ChangeTo.classOrMixin({required super.context})
    : _kind = _ReplacementKind.classOrMixin;

  /// Initializes a newly created instance that will propose fields.
  ChangeTo.field({required super.context}) : _kind = _ReplacementKind.field;

  /// Initializes a newly created instance that will propose functions.
  ChangeTo.function({required super.context})
    : _kind = _ReplacementKind.function;

  /// Initializes a newly created instance that will propose getters and
  /// setters.
  ChangeTo.getterOrSetter({required super.context})
    : _kind = _ReplacementKind.getterOrSetter;

  /// Initializes a newly created instance that will propose methods.
  ChangeTo.method({required super.context}) : _kind = _ReplacementKind.method;

  /// Initializes a newly created instance that will propose super formal
  /// parameters.
  ChangeTo.superFormalParameter({required super.context})
    : _kind = _ReplacementKind.superFormalParameter;

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  List<String> get fixArguments => [_proposedName];

  @override
  FixKind get fixKind => DartFixKind.CHANGE_TO;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // TODO(brianwilkerson): Unify these separate methods as much as is
    //  reasonably possible.
    // TODO(brianwilkerson): Consider proposing all of the names within a
    //  reasonable distance, rather than just the first near match we find.
    await switch (_kind) {
      _ReplacementKind.annotation => _proposeAnnotation(builder),
      _ReplacementKind.classOrMixin => _proposeClassOrMixin(builder, node),
      _ReplacementKind.field => _proposeField(builder),
      _ReplacementKind.function => _proposeFunction(builder),
      _ReplacementKind.getterOrSetter => _proposeGetterOrSetter(builder),
      _ReplacementKind.method => _proposeMethod(builder),
      _ReplacementKind.superFormalParameter => _proposeSuperFormalParameter(
        builder,
      ),
    };
  }

  Iterable<FormalParameterElement> _formalParameterSuggestions(
    FunctionTypedElement2 element,
    Iterable<FormalParameter> formalParameters,
  ) {
    return element.formalParameters.where(
      (superParam) =>
          superParam.isNamed &&
          !formalParameters.any(
            (param) => superParam.name3 == param.name?.lexeme,
          ),
    );
  }

  Future<void> _proposeAnnotation(ChangeBuilder builder) async {
    var node = this.node;
    if (node is Annotation) {
      var name = node.name;
      if (name.element == null) {
        if (node.arguments != null) {
          await _proposeClassOrMixin(builder, name);
        }
      }
    }
  }

  Future<void> _proposeClassOrMixin(ChangeBuilder builder, AstNode node) async {
    // Prepare the optional import prefix name.
    String? prefixName;
    Token? nameToken;
    if (node is NamedType) {
      prefixName = node.importPrefix?.name.lexeme;
      nameToken = node.name2;
    } else if (node is PrefixedIdentifier &&
        node.parent is NamedType &&
        node.prefix.element is PrefixElement2) {
      prefixName = node.prefix.name;
      nameToken = node.identifier.token;
    } else if (node is SimpleIdentifier) {
      nameToken = node.token;
    }
    // Process if looks like a type.
    if (nameToken != null) {
      // Prepare for selecting the closest element.
      var finder = _ClosestElementFinder(
        nameToken.lexeme,
        (element) => element is InterfaceElement2,
      );
      // Check elements of this library.
      if (prefixName == null) {
        finder._updateList(unitResult.libraryElement2.classes);
      }
      // Check elements from imports.
      for (var importElement
          in unitResult.libraryElement2.firstFragment.libraryImports2) {
        if (importElement.prefix2?.element.name3 == prefixName) {
          var namespace = getImportNamespace2(importElement);
          finder._updateList(namespace.values);
        }
      }
      // If we have a close enough element, suggest to use it.
      await _suggest(builder, nameToken, finder._element?.name3);
    }
  }

  Future<void> _proposeClassOrMixinMember(
    ChangeBuilder builder,
    Token node,
    Expression? target,
    _ElementPredicate predicate,
  ) async {
    var targetIdentifierElement = target is Identifier ? target.element : null;
    var finder = _ClosestElementFinder(node.lexeme, predicate);
    // unqualified invocation
    if (target == null) {
      var clazz = this.node.thisOrAncestorOfType<ClassDeclaration>();
      if (clazz != null) {
        var interfaceElement = clazz.declaredFragment!.element;
        _updateFinderWithClassMembers(finder, interfaceElement);
      }
    } else if (target is ExtensionOverride) {
      _updateFinderWithExtensionMembers(finder, target.element2);
    } else if (targetIdentifierElement is ExtensionElement2) {
      _updateFinderWithExtensionMembers(finder, targetIdentifierElement);
    } else {
      var interfaceElement = getTargetInterfaceElement2(target);
      if (interfaceElement != null) {
        _updateFinderWithClassMembers(finder, interfaceElement);
      }
    }
    // if we have close enough element, suggest to use it
    await _suggest(builder, node, finder._element?.displayName);
  }

  Future<void> _proposeField(ChangeBuilder builder) async {
    var node = this.node;
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
    await _proposeClassOrMixinMember(builder, node.name, null, (element) {
      return element is FieldElement2 &&
          !exclusions.contains(element.name3) &&
          !element.isSynthetic &&
          !element.isExternal &&
          (type == null ||
              typeSystem.isAssignableTo(
                type,
                element.type,
                strictCasts: analysisOptions.strictCasts,
              ));
    });
  }

  Future<void> _proposeFunction(ChangeBuilder builder) async {
    var node = this.node;
    if (node is SimpleIdentifier) {
      // Prepare the optional import prefix name.
      String? prefixName;
      {
        var invocation = node.parent;
        if (invocation is MethodInvocation && invocation.methodName == node) {
          var target = invocation.target;
          if (target is SimpleIdentifier && target.element is PrefixElement2) {
            prefixName = target.name;
          }
        }
      }
      // Prepare for selecting the closest element.
      var finder = _ClosestElementFinder(
        node.name,
        (element) => element is TopLevelFunctionElement,
      );
      // Check to this library units.
      if (prefixName == null) {
        for (var function in unitResult.libraryElement2.topLevelFunctions) {
          finder._update(function);
        }
      }
      // Check unprefixed imports.
      for (var importElement
          in unitResult.libraryElement2.firstFragment.libraryImports2) {
        if (importElement.prefix2?.element.name3 == prefixName) {
          var namespace = getImportNamespace2(importElement);
          finder._updateList(namespace.values);
        }
      }
      // If we have a close enough element, suggest to use it.
      await _suggest(builder, node, finder._element?.name3);
    }
  }

  Future<void> _proposeGetterOrSetter(ChangeBuilder builder) async {
    var node = this.node;
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
      await _proposeClassOrMixinMember(builder, node.token, target, (element) {
        if (element is GetterElement) {
          return wantGetter;
        } else if (element is SetterElement) {
          return wantSetter;
        } else if (element is FieldElement2) {
          return wantGetter && element.getter2 != null ||
              wantSetter && element.setter2 != null;
        }
        return false;
      });
    }
  }

  Future<void> _proposeMethod(ChangeBuilder builder) async {
    var node = this.node;
    var parent = node.parent;
    if (parent is MethodInvocation && node is SimpleIdentifier) {
      await _proposeClassOrMixinMember(
        builder,
        node.token,
        parent.realTarget,
        (element) => element is MethodElement2 && !element.isOperator,
      );
    }
  }

  Future<void> _proposeSuperFormalParameter(ChangeBuilder builder) async {
    var superParameter = node;
    if (superParameter is! SuperFormalParameter) return;

    var constructorDeclaration =
        superParameter.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructorDeclaration == null) return;

    var formalParameters =
        constructorDeclaration.parameters.parameters
            .whereType<DefaultFormalParameter>();

    var finder = _ClosestElementFinder(superParameter.name.lexeme, (e) => true);

    var superInvocation = constructorDeclaration.initializers.lastOrNull;

    if (superInvocation is SuperConstructorInvocation) {
      var element = superInvocation.element;
      if (element == null) return;

      var list = _formalParameterSuggestions(element, formalParameters);
      finder._updateList(list);
    } else {
      var targetClassNode =
          superParameter.thisOrAncestorOfType<ClassDeclaration>();
      if (targetClassNode == null) return;

      var targetClassElement = targetClassNode.declaredFragment!.element;
      var superType = targetClassElement.supertype;
      if (superType == null) return;

      for (var constructor in superType.constructors2) {
        if (constructor.name3 == 'new') {
          var list = _formalParameterSuggestions(constructor, formalParameters);
          finder._updateList(list);
          break;
        }
      }
    }

    // If we have a close enough element, suggest to use it.
    await _suggest(builder, superParameter.name, finder._element?.name3);
  }

  Future<void> _suggest(
    ChangeBuilder builder,
    SyntacticEntity node,
    String? name,
  ) async {
    if (name != null) {
      _proposedName = name;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.entity(node), _proposedName);
      });
    }
  }

  void _updateFinderWithClassMembers(
    _ClosestElementFinder finder,
    InterfaceElement2 clazz,
  ) {
    var members = getMembers(clazz);
    finder._updateList(members);
  }

  void _updateFinderWithExtensionMembers(
    _ClosestElementFinder finder,
    ExtensionElement2? element,
  ) {
    if (element != null) {
      finder._updateList(getExtensionMembers(element));
    }
  }
}

/// Helper for finding [Element2] with name closest to the given.
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

  Element2? _element;

  _ClosestElementFinder(this._targetName, this._predicate);

  void _update(Element2 element) {
    if (_predicate(element)) {
      var name = element.name3;
      if (name != null) {
        var memberDistance = levenshtein(name, _targetName, _distance);
        if (memberDistance < _distance) {
          _element = element;
          _distance = memberDistance;
        }
      }
    }
  }

  void _updateList(Iterable<Element2> elements) {
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
