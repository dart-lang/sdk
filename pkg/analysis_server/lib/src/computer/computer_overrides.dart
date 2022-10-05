// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/protocol_server.dart' as proto;
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';

/// Return the elements that the given [element] overrides.
OverriddenElements findOverriddenElements(Element element) {
  if (element.enclosingElement is InterfaceElement) {
    return _OverriddenElementsFinder(element).find();
  }
  return OverriddenElements(element, <Element>[], <Element>[]);
}

/// A computer for class member overrides in a Dart [CompilationUnit].
class DartUnitOverridesComputer {
  final CompilationUnit _unit;
  final List<proto.Override> _overrides = <proto.Override>[];

  DartUnitOverridesComputer(this._unit);

  /// Returns the computed occurrences, not `null`.
  List<proto.Override> compute() {
    for (var unitMember in _unit.declarations) {
      if (unitMember is ClassDeclaration) {
        _classMembers(unitMember.members);
      } else if (unitMember is EnumDeclaration) {
        _classMembers(unitMember.members);
      } else if (unitMember is MixinDeclaration) {
        _classMembers(unitMember.members);
      }
    }
    return _overrides;
  }

  /// Add a new [Override] for the declaration with the given name [token].
  void _addOverride(Token token, Element? element) {
    if (element != null) {
      var overridesResult = _OverriddenElementsFinder(element).find();
      var superElements = overridesResult.superElements;
      var interfaceElements = overridesResult.interfaceElements;
      if (superElements.isNotEmpty || interfaceElements.isNotEmpty) {
        var superMember = superElements.isNotEmpty
            ? proto.newOverriddenMember_fromEngine(
                superElements.first.nonSynthetic,
                withNullability: _unit.isNonNullableByDefault)
            : null;
        var interfaceMembers = interfaceElements
            .map((member) => proto.newOverriddenMember_fromEngine(
                member.nonSynthetic,
                withNullability: _unit.isNonNullableByDefault))
            .toList();
        _overrides.add(proto.Override(token.offset, token.length,
            superclassMember: superMember,
            interfaceMembers: nullIfEmpty(interfaceMembers)));
      }
    }
  }

  void _classMembers(List<ClassMember> members) {
    for (var classMember in members) {
      if (classMember is MethodDeclaration) {
        if (classMember.isStatic) {
          continue;
        }
        _addOverride(classMember.name, classMember.declaredElement);
      }
      if (classMember is FieldDeclaration) {
        if (classMember.isStatic) {
          continue;
        }
        List<VariableDeclaration> fields = classMember.fields.variables;
        for (var field in fields) {
          _addOverride(field.name, field.declaredElement);
        }
      }
    }
  }
}

/// The container with elements that a class member overrides.
class OverriddenElements {
  /// The element that overrides other class members.
  final Element element;

  /// The elements that [element] overrides and which is defined in a class that
  /// is a superclass of the class that defines [element].
  final List<Element> superElements;

  /// The elements that [element] overrides and which is defined in a class that
  /// which is implemented by the class that defines [element].
  final List<Element> interfaceElements;

  OverriddenElements(this.element, this.superElements, this.interfaceElements);
}

class _OverriddenElementsFinder {
  Element _seed;
  LibraryElement _library;
  InterfaceElement _class;
  String _name;
  List<ElementKind> _kinds;

  final List<Element> _superElements = <Element>[];
  final List<Element> _interfaceElements = <Element>[];
  final Set<InterfaceElement> _visited = {};

  factory _OverriddenElementsFinder(Element seed) {
    var class_ = seed.enclosingElement as InterfaceElement;
    var library = class_.library;
    var name = seed.displayName;
    List<ElementKind> kinds;
    if (seed is FieldElement) {
      kinds = [
        ElementKind.GETTER,
        if (!seed.isFinal) ElementKind.SETTER,
      ];
    } else if (seed is MethodElement) {
      kinds = const [ElementKind.METHOD];
    } else if (seed is PropertyAccessorElement) {
      kinds = seed.isGetter
          ? const [ElementKind.GETTER]
          : const [ElementKind.SETTER];
    } else {
      kinds = const [];
    }
    return _OverriddenElementsFinder._(seed, library, class_, name, kinds);
  }

  _OverriddenElementsFinder._(
      this._seed, this._library, this._class, this._name, this._kinds);

  /// Add the [OverriddenElements] for this element.
  OverriddenElements find() {
    _visited.clear();
    _addSuperOverrides(_class, withThisType: false);
    _visited.clear();
    _addInterfaceOverrides(_class, false);
    _superElements.forEach(_interfaceElements.remove);
    return OverriddenElements(_seed, _superElements, _interfaceElements);
  }

  void _addInterfaceOverrides(InterfaceElement? class_, bool checkType) {
    if (class_ == null) {
      return;
    }
    if (!_visited.add(class_)) {
      return;
    }
    // this type
    if (checkType) {
      var element = _lookupMember(class_);
      if (element != null && !_interfaceElements.contains(element)) {
        _interfaceElements.add(element);
      }
    }
    // interfaces
    for (var interfaceType in class_.interfaces) {
      _addInterfaceOverrides(interfaceType.element, true);
    }
    // super
    _addInterfaceOverrides(class_.supertype?.element, checkType);
  }

  void _addSuperOverrides(InterfaceElement? class_,
      {bool withThisType = true}) {
    if (class_ == null) {
      return;
    }
    if (!_visited.add(class_)) {
      return;
    }

    if (withThisType) {
      var element = _lookupMember(class_);
      if (element != null && !_superElements.contains(element)) {
        _superElements.add(element);
      }
    }

    _addSuperOverrides(class_.supertype?.element);
    for (var mixin_ in class_.mixins) {
      _addSuperOverrides(mixin_.element);
    }
    if (class_ is MixinElement) {
      for (var constraint in class_.superclassConstraints) {
        _addSuperOverrides(constraint.element);
      }
    }
  }

  Element? _lookupMember(InterfaceElement classElement) {
    Element? member;
    // method
    if (_kinds.contains(ElementKind.METHOD)) {
      member = classElement.lookUpMethod(_name, _library);
      if (member != null) {
        return member;
      }
    }
    // getter
    if (_kinds.contains(ElementKind.GETTER)) {
      member = classElement.lookUpGetter(_name, _library);
      if (member != null) {
        return member;
      }
    }
    // setter
    if (_kinds.contains(ElementKind.SETTER)) {
      member = classElement.lookUpSetter('$_name=', _library);
      if (member != null) {
        return member;
      }
    }
    // not found
    return null;
  }
}
