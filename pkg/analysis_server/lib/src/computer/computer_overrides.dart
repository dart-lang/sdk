// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.overrides;

import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_services/constants.dart';
import 'package:analysis_services/json.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart' as engine;


/**
 * A computer for class member overrides in a Dart [CompilationUnit].
 */
class DartUnitOverridesComputer {
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
            SimpleIdentifier nameNode = classMember.name;
            _addOverride(nameNode.offset, nameNode.length, nameNode.name);
          }
          if (classMember is FieldDeclaration) {
            List<VariableDeclaration> fields = classMember.fields.variables;
            for (VariableDeclaration field in fields) {
              SimpleIdentifier nameNode = field.name;
              _addOverride(nameNode.offset, nameNode.length, nameNode.name);
            }
          }
        }
      }
    }
    return _overrides.map((override) => override.toJson()).toList();
  }

  void _addOverride(int offset, int length, String name) {
    // super
    engine.Element superEngineElement;
    {
      engine.InterfaceType superType = _currentClass.supertype;
      if (superType != null) {
        superEngineElement = _lookupMember(superType.element, name);
      }
    }
    // interfaces
    List<engine.Element> interfaceEngineElements = <engine.Element>[];
    for (engine.InterfaceType interfaceType in _currentClass.interfaces) {
      engine.ClassElement interfaceElement = interfaceType.element;
      engine.Element interfaceMember = _lookupMember(interfaceElement, name);
      if (interfaceMember != null) {
        interfaceEngineElements.add(interfaceMember);
      }
    }
    // is there any override?
    if (superEngineElement != null || interfaceEngineElements.isNotEmpty) {
      Element superElement = superEngineElement != null ?
          new Element.fromEngine(superEngineElement) : null;
      List<Element> interfaceElements = interfaceEngineElements.map(
          (engineElement) {
        return new Element.fromEngine(engineElement);
      }).toList();
      _overrides.add(new Override(offset, length, superElement,
          interfaceElements));
    }
  }

  static engine.Element _lookupMember(engine.ClassElement classElement,
      String name) {
    if (classElement == null) {
      return null;
    }
    engine.LibraryElement library = classElement.library;
    // method
    engine.Element member = classElement.lookUpMethod(name, library);
    if (member != null) {
      return member;
    }
    // getter
    member = classElement.lookUpGetter(name, library);
    if (member != null) {
      return member;
    }
    // setter
    member = classElement.lookUpSetter(name + '=', library);
    if (member != null) {
      return member;
    }
    // not found
    return null;
  }
}


class Override implements HasToJson {
  final int offset;
  final int length;
  final Element superclassElement;
  final List<Element> interfaceElements;

  Override(this.offset, this.length, this.superclassElement,
      this.interfaceElements);

  factory Override.fromJson(Map<String, Object> map) {
    int offset = map[OFFSET];
    int length = map[LENGTH];
    // super
    Element superclassElement = null;
    {
      Map<String, Object> superJson = map[SUPER_CLASS_ELEMENT];
      if (superJson != null) {
        superclassElement = new Element.fromJson(superJson);
      }
    }
    // interfaces
    List<Element> interfaceElements = null;
    {
      List<Map<String, Object>> jsonList = map[INTERFACE_ELEMENTS];
      if (jsonList != null) {
        interfaceElements = <Element>[];
        for (Map<String, Object> json in jsonList) {
          interfaceElements.add(new Element.fromJson(json));
        }
      }
    }
    // done
    return new Override(offset, length, superclassElement, interfaceElements);
  }

  Map<String, Object> toJson() {
    Map<String, Object> json = <String, Object>{};
    json[OFFSET] = offset;
    json[LENGTH] = length;
    if (superclassElement != null) {
      json[SUPER_CLASS_ELEMENT] = superclassElement.toJson();
    }
    if (interfaceElements != null && interfaceElements.isNotEmpty) {
      json[INTERFACE_ELEMENTS] = interfaceElements.map((element) {
        return element.toJson();
      }).toList();
    }
    return json;
  }

  @override
  String toString() => toJson().toString();
}
