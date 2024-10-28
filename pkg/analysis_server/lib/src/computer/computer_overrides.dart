// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/protocol_server.dart' as proto;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:collection/collection.dart';

/// Return the elements that the given [element] overrides.
OverriddenElements findOverriddenElements(Element2 element) {
  if (element.enclosingElement2 is InterfaceElement2) {
    return _OverriddenElementsFinder(element).find();
  }
  return OverriddenElements(element, <Element2>[], <Element2>[]);
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
      } else if (unitMember is ExtensionTypeDeclaration) {
        _classMembers(unitMember.members);
      } else if (unitMember is MixinDeclaration) {
        _classMembers(unitMember.members);
      }
    }
    return _overrides;
  }

  /// Add a new [Override] for the declaration with the given name [token].
  void _addOverride(Token token, Element2? element) {
    if (element != null) {
      var overridesResult = _OverriddenElementsFinder(element).find();
      var superElements = overridesResult.superElements;
      var interfaceElements = overridesResult.interfaceElements;
      if (superElements.isNotEmpty || interfaceElements.isNotEmpty) {
        var superMember = superElements.isNotEmpty
            ? proto.newOverriddenMember_fromEngine(
                superElements.first.nonSynthetic2)
            : null;
        var interfaceMembers = interfaceElements
            .map((member) =>
                proto.newOverriddenMember_fromEngine(member.nonSynthetic2))
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
        _addOverride(classMember.name, classMember.declaredFragment?.element);
      }
      if (classMember is FieldDeclaration) {
        if (classMember.isStatic) {
          continue;
        }
        List<VariableDeclaration> fields = classMember.fields.variables;
        for (var field in fields) {
          _addOverride(field.name, field.declaredFragment?.element);
        }
      }
    }
  }
}

/// The container with elements that a class member overrides.
class OverriddenElements {
  /// The element that overrides other class members.
  final Element2 element;

  /// The elements that [element] overrides and which is defined in a class that
  /// is a superclass of the class that defines [element].
  final List<Element2> superElements;

  /// The elements that [element] overrides and which is defined in a class that
  /// which is implemented by the class that defines [element].
  final List<Element2> interfaceElements;

  OverriddenElements(this.element, this.superElements, this.interfaceElements);
}

class _OverriddenElementsFinder {
  Element2 _seed;
  LibraryElement2 _library;
  InterfaceElement2 _class;
  String _name;
  List<ElementKind> _kinds;

  final List<Element2> _superElements = <Element2>[];
  final List<Element2> _interfaceElements = <Element2>[];
  final Set<InterfaceElement2> _visited = {};

  factory _OverriddenElementsFinder(Element2 seed) {
    var class_ = seed.enclosingElement2 as InterfaceElement2;
    var library = class_.library2;
    var name = seed.displayName;
    List<ElementKind> kinds;
    if (seed is FieldElement2) {
      kinds = [
        ElementKind.GETTER,
        if (!seed.isFinal) ElementKind.SETTER,
      ];
    } else if (seed is MethodElement2) {
      kinds = const [ElementKind.METHOD];
    } else if (seed is GetterElement) {
      kinds = const [ElementKind.GETTER];
    } else if (seed is SetterElement) {
      kinds = const [ElementKind.SETTER];
    } else {
      kinds = const [];
    }
    return _OverriddenElementsFinder._(seed, library, class_, name, kinds);
  }

  _OverriddenElementsFinder._(
    this._seed,
    this._library,
    this._class,
    this._name,
    this._kinds,
  );

  /// Add the [OverriddenElements] for this element.
  OverriddenElements find() {
    _visited.clear();
    _addSuperOverrides(_class, withThisType: false);
    _visited.clear();
    _addInterfaceOverrides(_class, false);
    _superElements.forEach(_interfaceElements.remove);
    return OverriddenElements(_seed, _superElements, _interfaceElements);
  }

  void _addInterfaceOverrides(InterfaceElement2? class_, bool checkType) {
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
      _addInterfaceOverrides(interfaceType.element3, true);
    }
    // super
    _addInterfaceOverrides(class_.supertype?.element3, checkType);
  }

  void _addSuperOverrides(InterfaceElement2? class_,
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

    _addSuperOverrides(class_.supertype?.element3);
    for (var mixin_ in class_.mixins) {
      _addSuperOverrides(mixin_.element3);
    }
    if (class_ is MixinElement2) {
      for (var constraint in class_.superclassConstraints) {
        _addSuperOverrides(constraint.element3);
      }
    }
  }

  Element2? _lookupMember(InterfaceElement2 classElement) {
    var name = Name.forLibrary(_library, _name);

    /// Helper to find an element in [elements] that matches [targetName].
    Element2? findMatchingElement(
        Iterable<Element2> elements, Name targetName) {
      return elements.firstWhereOrNull((Element2 element) {
        var elementName = element.name3;
        return elementName != null &&
            Name.forLibrary(element.library2, elementName) == targetName;
      });
    }

    // method
    if (_kinds.contains(ElementKind.METHOD)) {
      var member = findMatchingElement(classElement.methods2, name);
      if (member != null) {
        return member;
      }
    }
    // getter
    if (_kinds.contains(ElementKind.GETTER)) {
      var member = findMatchingElement(classElement.getters2, name.forGetter);
      if (member != null) {
        return member;
      }
    }
    // setter
    if (_kinds.contains(ElementKind.SETTER)) {
      var member = findMatchingElement(classElement.setters2, name.forSetter);
      if (member != null) {
        return member;
      }
    }
    // not found
    return null;
  }
}
