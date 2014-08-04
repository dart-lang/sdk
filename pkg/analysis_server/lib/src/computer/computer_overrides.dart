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
      OverriddenMember superMember = superEngineElement != null ?
          OverriddenMember.fromEngine(superEngineElement) :
          null;
      List<OverriddenMember> interfaceMembers =
          interfaceEngineElements.map(OverriddenMember.fromEngine).toList();
      _overrides.add(
          new Override(offset, length, superMember, interfaceMembers));
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


class OverriddenMember implements HasToJson {
  final Element element;
  final String className;

  OverriddenMember(this.element, this.className);

  Map<String, Object> toJson() {
    return {
      ELEMENT: element.toJson(),
      CLASS_NAME: className
    };
  }

  @override
  String toString() => toJson().toString();

  static OverriddenMember fromEngine(engine.Element member) {
    Element element = new Element.fromEngine(member);
    String className = member.enclosingElement.displayName;
    return new OverriddenMember(element, className);
  }

  static OverriddenMember fromJson(Map<String, Object> json) {
    Map<String, Object> elementJson = json[ELEMENT];
    Element element = new Element.fromJson(elementJson);
    String className = json[CLASS_NAME];
    return new OverriddenMember(element, className);
  }
}


class Override implements HasToJson {
  final int offset;
  final int length;
  final OverriddenMember superclassMember;
  final List<OverriddenMember> interfaceMembers;

  Override(this.offset, this.length, this.superclassMember,
      this.interfaceMembers);

  Map<String, Object> toJson() {
    Map<String, Object> json = <String, Object>{};
    json[OFFSET] = offset;
    json[LENGTH] = length;
    if (superclassMember != null) {
      json[SUPER_CLASS_MEMBER] = superclassMember.toJson();
    }
    if (interfaceMembers != null && interfaceMembers.isNotEmpty) {
      json[INTERFACE_MEMBERS] = objectToJson(interfaceMembers);
    }
    return json;
  }

  @override
  String toString() => toJson().toString();

  static Override fromJson(Map<String, Object> map) {
    int offset = map[OFFSET];
    int length = map[LENGTH];
    // super
    OverriddenMember superclassMember = null;
    {
      Map<String, Object> superJson = map[SUPER_CLASS_MEMBER];
      if (superJson != null) {
        superclassMember = OverriddenMember.fromJson(superJson);
      }
    }
    // interfaces
    List<OverriddenMember> interfaceElements = null;
    {
      List<Map<String, Object>> jsonList = map[INTERFACE_MEMBERS];
      if (jsonList != null) {
        interfaceElements = jsonList.map(OverriddenMember.fromJson).toList();
      }
    }
    // done
    return new Override(offset, length, superclassMember, interfaceElements);
  }
}
