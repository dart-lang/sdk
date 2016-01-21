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
            SimpleIdentifier name = classMember.name;
            List<ElementKind> kinds;
            if (classMember.isGetter) {
              kinds = GETTER_KINDS;
            } else if (classMember.isSetter) {
              kinds = SETTER_KINDS;
            } else {
              kinds = METHOD_KINDS;
            }
            new _SingleOverrideComputer(_currentClass, name, kinds)
                .addOverrideTo(_overrides);
          }
          if (classMember is FieldDeclaration) {
            if (classMember.isStatic) {
              continue;
            }
            List<VariableDeclaration> fields = classMember.fields.variables;
            for (VariableDeclaration field in fields) {
              SimpleIdentifier name = field.name;
              new _SingleOverrideComputer(_currentClass, name, FIELD_KINDS)
                  .addOverrideTo(_overrides);
            }
          }
        }
      }
    }
    return _overrides;
  }
}

/**
 * Computer for [Override] for a single declaration.
 */
class _SingleOverrideComputer {
  final engine.LibraryElement currentLibrary;
  final engine.ClassElement currentClass;
  final SimpleIdentifier node;
  final String name;
  final List<ElementKind> kinds;

  _SingleOverrideComputer(
      engine.ClassElement currentClass, SimpleIdentifier node, this.kinds)
      : currentClass = currentClass,
        currentLibrary = currentClass.library,
        node = node,
        name = node.name;

  /**
   * Add a new [Override] for this declaration to the given [overrides].
   */
  void addOverrideTo(List<Override> overrides) {
    // super
    engine.Element superEngineElement;
    {
      engine.InterfaceType superType = currentClass.supertype;
      if (superType != null) {
        superEngineElement = _lookupMember(superType.element);
      }
    }
    // interfaces
    Set<engine.Element> interfaceEngineElements = new Set<engine.Element>();
    _addInterfaceOverrides(interfaceEngineElements, currentClass.type, false,
        new Set<engine.InterfaceType>());
    interfaceEngineElements.remove(superEngineElement);
    // is there any override?
    if (superEngineElement != null || interfaceEngineElements.isNotEmpty) {
      OverriddenMember superMember = superEngineElement != null
          ? newOverriddenMember_fromEngine(superEngineElement)
          : null;
      List<OverriddenMember> interfaceMembers = interfaceEngineElements
          .map((member) => newOverriddenMember_fromEngine(member))
          .toList();
      overrides.add(new Override(node.offset, node.length,
          superclassMember: superMember,
          interfaceMembers: nullIfEmpty(interfaceMembers)));
    }
  }

  void _addInterfaceOverrides(
      Set<engine.Element> elements,
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
      engine.Element element = _lookupMember(type.element);
      if (element != null) {
        elements.add(element);
        return;
      }
    }
    // check interfaces
    for (engine.InterfaceType interfaceType in type.interfaces) {
      _addInterfaceOverrides(elements, interfaceType, true, visited);
    }
    // check super
    _addInterfaceOverrides(elements, type.superclass, checkType, visited);
  }

  engine.Element _lookupMember(engine.ClassElement classElement) {
    if (classElement == null) {
      return null;
    }
    engine.Element member;
    // method
    if (kinds.contains(ElementKind.METHOD)) {
      member = classElement.lookUpMethod(name, currentLibrary);
      if (member != null) {
        return member;
      }
    }
    // getter
    if (kinds.contains(ElementKind.GETTER)) {
      member = classElement.lookUpGetter(name, currentLibrary);
      if (member != null) {
        return member;
      }
    }
    // setter
    if (kinds.contains(ElementKind.SETTER)) {
      member = classElement.lookUpSetter(name + '=', currentLibrary);
      if (member != null) {
        return member;
      }
    }
    // not found
    return null;
  }
}
