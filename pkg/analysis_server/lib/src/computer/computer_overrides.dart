// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/protocol_server.dart' as proto;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/**
 * Return the elements that the given [element] overrides.
 */
OverriddenElements findOverriddenElements(Element element) {
  if (element?.enclosingElement is ClassElement) {
    return new _OverriddenElementsFinder(element).find();
  }
  return new OverriddenElements(element, <Element>[], <Element>[]);
}

/**
 * A computer for class member overrides in a Dart [CompilationUnit].
 */
class DartUnitOverridesComputer {
  final CompilationUnit _unit;
  final List<proto.Override> _overrides = <proto.Override>[];

  DartUnitOverridesComputer(this._unit);

  /**
   * Returns the computed occurrences, not `null`.
   */
  List<proto.Override> compute() {
    for (CompilationUnitMember unitMember in _unit.declarations) {
      if (unitMember is ClassDeclaration) {
        for (ClassMember classMember in unitMember.members) {
          if (classMember is MethodDeclaration) {
            if (classMember.isStatic) {
              continue;
            }
            _addOverride(classMember.name);
          }
          if (classMember is FieldDeclaration) {
            if (classMember.isStatic) {
              continue;
            }
            List<VariableDeclaration> fields = classMember.fields.variables;
            for (VariableDeclaration field in fields) {
              _addOverride(field.name);
            }
          }
        }
      }
    }
    return _overrides;
  }

  /**
   * Add a new [Override] for the declaration with the given name [node].
   */
  void _addOverride(SimpleIdentifier node) {
    Element element = node.staticElement;
    OverriddenElements overridesResult =
        new _OverriddenElementsFinder(element).find();
    List<Element> superElements = overridesResult.superElements;
    List<Element> interfaceElements = overridesResult.interfaceElements;
    if (superElements.isNotEmpty || interfaceElements.isNotEmpty) {
      proto.OverriddenMember superMember = superElements.isNotEmpty
          ? proto.newOverriddenMember_fromEngine(superElements.first)
          : null;
      List<proto.OverriddenMember> interfaceMembers = interfaceElements
          .map((member) => proto.newOverriddenMember_fromEngine(member))
          .toList();
      _overrides.add(new proto.Override(node.offset, node.length,
          superclassMember: superMember,
          interfaceMembers: nullIfEmpty(interfaceMembers)));
    }
  }
}

/**
 * The container with elements that a class member overrides.
 */
class OverriddenElements {
  /**
   * The element that overrides other class members.
   */
  final Element element;

  /**
   * The elements that [element] overrides and which is defined in a class that
   * is a superclass of the class that defines [element].
   */
  final List<Element> superElements;

  /**
   * The elements that [element] overrides and which is defined in a class that
   * which is implemented by the class that defines [element].
   */
  final List<Element> interfaceElements;

  OverriddenElements(this.element, this.superElements, this.interfaceElements);
}

class _OverriddenElementsFinder {
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

  Element _seed;
  LibraryElement _library;
  ClassElement _class;
  String _name;
  List<ElementKind> _kinds;

  List<Element> _superElements = <Element>[];
  List<Element> _interfaceElements = <Element>[];
  Set<InterfaceType> _visited = new Set<InterfaceType>();

  _OverriddenElementsFinder(Element seed) {
    _seed = seed;
    _class = seed.enclosingElement;
    if (_class == null) {
      // TODO(brianwilkerson) Remove this code when the issue has been fixed
      // (https://github.com/dart-lang/sdk/issues/25884)
      Type type = seed.runtimeType;
      String name = seed.name;
      throw new ArgumentError(
          'The $type named $name does not have an enclosing element');
    }
    _library = _class.library;
    _name = seed.displayName;
    if (seed is MethodElement) {
      _kinds = METHOD_KINDS;
    } else if (seed is PropertyAccessorElement) {
      _kinds = seed.isGetter ? GETTER_KINDS : SETTER_KINDS;
    } else {
      _kinds = FIELD_KINDS;
    }
  }

  /**
   * Add the [OverriddenElements] for this element.
   */
  OverriddenElements find() {
    _visited.clear();
    _addSuperOverrides(_class.supertype);
    _visited.clear();
    _addInterfaceOverrides(_class.type, false);
    _superElements.forEach(_interfaceElements.remove);
    return new OverriddenElements(_seed, _superElements, _interfaceElements);
  }

  void _addInterfaceOverrides(InterfaceType type, bool checkType) {
    if (type == null) {
      return;
    }
    if (!_visited.add(type)) {
      return;
    }
    // this type
    if (checkType) {
      Element element = _lookupMember(type.element);
      if (element != null && !_interfaceElements.contains(element)) {
        _interfaceElements.add(element);
      }
    }
    // interfaces
    for (InterfaceType interfaceType in type.interfaces) {
      _addInterfaceOverrides(interfaceType, true);
    }
    // super
    _addInterfaceOverrides(type.superclass, checkType);
  }

  void _addSuperOverrides(InterfaceType type) {
    if (type == null) {
      return;
    }
    if (!_visited.add(type)) {
      return;
    }
    // this type
    Element element = _lookupMember(type.element);
    if (element != null && !_superElements.contains(element)) {
      _superElements.add(element);
    }
    // super
    _addSuperOverrides(type.superclass);
  }

  Element _lookupMember(ClassElement classElement) {
    if (classElement == null) {
      return null;
    }
    Element member;
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
      member = classElement.lookUpSetter(_name + '=', _library);
      if (member != null) {
        return member;
      }
    }
    // not found
    return null;
  }
}
