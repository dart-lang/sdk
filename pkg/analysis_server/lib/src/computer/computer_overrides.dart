// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.overrides;

import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/dart/element/type.dart' as engine;
import 'package:analyzer/src/generated/ast.dart';

/**
 * A computer for class member overrides in a Dart [CompilationUnit].
 */
class DartUnitOverridesComputer {
  static const List<ElementKind> FIELD_KINDS = const <ElementKind>[
    ElementKind.FIELD,
    ElementKind.GETTER,
    ElementKind.SETTER
  ];

  static const List<ElementKind> GETTER_KINDS = const <ElementKind>[
    ElementKind.FIELD,
    ElementKind.GETTER
  ];

  static const List<ElementKind> METHOD_KINDS = const <ElementKind>[
    ElementKind.METHOD
  ];

  static const List<ElementKind> SETTER_KINDS = const <ElementKind>[
    ElementKind.FIELD,
    ElementKind.SETTER
  ];

  final CompilationUnit _unit;

  final List<Override> _overrides = <Override>[];
  engine.ClassElement _currentClass;

  DartUnitOverridesComputer(this._unit);

  /**
   * Returns the computed occurrences, not `null`.
   */
  List<Override> compute() {
    for (CompilationUnitMember unitMember in _unit.declarations) {
      if (unitMember is ClassDeclaration) {
        _currentClass = unitMember.element;
        for (ClassMember classMember in unitMember.members) {
          if (classMember is MethodDeclaration) {
            if (classMember.isStatic) {
              continue;
            }
            SimpleIdentifier nameNode = classMember.name;
            List<ElementKind> kinds;
            if (classMember.isGetter) {
              kinds = GETTER_KINDS;
            } else if (classMember.isSetter) {
              kinds = SETTER_KINDS;
            } else {
              kinds = METHOD_KINDS;
            }
            _addOverride(
                nameNode.offset, nameNode.length, nameNode.name, kinds);
          }
          if (classMember is FieldDeclaration) {
            if (classMember.isStatic) {
              continue;
            }
            List<VariableDeclaration> fields = classMember.fields.variables;
            for (VariableDeclaration field in fields) {
              SimpleIdentifier nameNode = field.name;
              _addOverride(
                  nameNode.offset, nameNode.length, nameNode.name, FIELD_KINDS);
            }
          }
        }
      }
    }
    return _overrides;
  }

  void _addInterfaceOverrides(
      Set<engine.Element> elements,
      String name,
      List<ElementKind> kinds,
      engine.InterfaceType type,
      bool checkType,
      Set<engine.InterfaceType> visited) {
    if (type == null) {
      return;
    }
    if (!visited.add(type)) {
      return;
    }
    // check type
    if (checkType) {
      engine.Element element = _lookupMember(type.element, name, kinds);
      if (element != null) {
        elements.add(element);
        return;
      }
    }
    // check interfaces
    for (engine.InterfaceType interfaceType in type.interfaces) {
      _addInterfaceOverrides(
          elements, name, kinds, interfaceType, true, visited);
    }
    // check super
    _addInterfaceOverrides(
        elements, name, kinds, type.superclass, checkType, visited);
  }

  void _addOverride(
      int offset, int length, String name, List<ElementKind> kinds) {
    // super
    engine.Element superEngineElement;
    {
      engine.InterfaceType superType = _currentClass.supertype;
      if (superType != null) {
        superEngineElement = _lookupMember(superType.element, name, kinds);
      }
    }
    // interfaces
    Set<engine.Element> interfaceEngineElements = new Set<engine.Element>();
    _addInterfaceOverrides(interfaceEngineElements, name, kinds,
        _currentClass.type, false, new Set<engine.InterfaceType>());
    interfaceEngineElements.remove(superEngineElement);
    // is there any override?
    if (superEngineElement != null || interfaceEngineElements.isNotEmpty) {
      OverriddenMember superMember = superEngineElement != null
          ? newOverriddenMember_fromEngine(superEngineElement)
          : null;
      List<OverriddenMember> interfaceMembers = interfaceEngineElements
          .map((member) => newOverriddenMember_fromEngine(member))
          .toList();
      _overrides.add(new Override(offset, length,
          superclassMember: superMember,
          interfaceMembers: nullIfEmpty(interfaceMembers)));
    }
  }

  static engine.Element _lookupMember(
      engine.ClassElement classElement, String name, List<ElementKind> kinds) {
    if (classElement == null) {
      return null;
    }
    engine.LibraryElement library = classElement.library;
    engine.Element member;
    // method
    if (kinds.contains(ElementKind.METHOD)) {
      member = classElement.lookUpMethod(name, library);
      if (member != null) {
        return member;
      }
    }
    // getter
    if (kinds.contains(ElementKind.GETTER)) {
      member = classElement.lookUpGetter(name, library);
      if (member != null) {
        return member;
      }
    }
    // setter
    if (kinds.contains(ElementKind.SETTER)) {
      member = classElement.lookUpSetter(name + '=', library);
      if (member != null) {
        return member;
      }
    }
    // not found
    return null;
  }
}
