// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.type_hierarhy;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/computer/element.dart' show
    engineElementToJson;
import 'package:analysis_services/constants.dart';
import 'package:analysis_services/json.dart';
import 'package:analysis_services/search/hierarchy.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A computer for a type hierarchy of an [Element].
 */
class TypeHierarchyComputer {
  final SearchEngine _searchEngine;
  ElementKind _pivotKind;
  String _pivotName;

  TypeHierarchyComputer(this._searchEngine);

  /**
   * Returns the computed type hierarchy, maybe `null`.
   */
  Future<TypeHierarchyItem> compute(Element element) {
    _pivotKind = element.kind;
    _pivotName = element.name;
    if (element is ExecutableElement &&
        element.enclosingElement is ClassElement) {
      element = element.enclosingElement;
    }
    if (element is ClassElement) {
      Set<ClassElement> processed = new HashSet<ClassElement>();
      InterfaceType type = element.type;
      TypeHierarchyItem item = createSuperItem(type, processed);
      return _createSubclasses(item, type, processed).then((_) {
        return item;
      });
    }
    return new Future.value(null);
  }

  TypeHierarchyItem createSuperItem(InterfaceType type,
      Set<ClassElement> processed) {
    // check for recursion
    if (!processed.add(type.element)) {
      return null;
    }
    // superclass
    TypeHierarchyItem superItem = null;
    {
      InterfaceType superType = type.superclass;
      if (superType != null) {
        superItem = createSuperItem(superType, processed);
      }
    }
    // mixins
    List<TypeHierarchyItem> mixinsItems;
    {
      List<InterfaceType> mixinsTypes = type.mixins;
      mixinsItems = mixinsTypes.map((InterfaceType type) {
        return createSuperItem(type, processed);
      }).toList();
    }
    // interfaces
    List<TypeHierarchyItem> interfacesItems;
    {
      List<InterfaceType> interfacesTypes = type.interfaces;
      interfacesItems = interfacesTypes.map((InterfaceType type) {
        return createSuperItem(type, processed);
      }).toList();
    }
    // done
    String displayName = null;
    if (type.typeArguments.isNotEmpty) {
      displayName = type.toString();
    }
    ClassElement classElement = type.element;
    ExecutableElement memberElement = findMemberElement(classElement);
    return new TypeHierarchyItem(
        classElement,
        memberElement,
        displayName,
        superItem,
        mixinsItems,
        interfacesItems);
  }

  ExecutableElement findMemberElement(ClassElement classElement) {
    if (_pivotKind == ElementKind.METHOD) {
      return classElement.getMethod(_pivotName);
    }
    if (_pivotKind == ElementKind.GETTER) {
      return classElement.getGetter(_pivotName);
    }
    if (_pivotKind == ElementKind.SETTER) {
      return classElement.getSetter(_pivotName);
    }
    return null;
  }

  Future _createSubclasses(TypeHierarchyItem item, InterfaceType type,
      Set<ClassElement> processed) {
    var future = getDirectSubClasses(_searchEngine, type.element);
    return future.then((Set<ClassElement> subElements) {
      for (ClassElement subElement in subElements) {
        // check for recursion
        if (!processed.add(subElement)) {
          continue;
        }
        // create a subclass item
        ExecutableElement subMemberElement = findMemberElement(subElement);
        TypeHierarchyItem subItem =
            new TypeHierarchyItem(
                subElement,
                subMemberElement,
                null,
                null,
                <TypeHierarchyItem>[],
                <TypeHierarchyItem>[]);
        item.subclasses.add(subItem);
      }
      // compute subclasses of subclasses
      return Future.forEach(item.subclasses, (TypeHierarchyItem subItem) {
        InterfaceType subType = subItem.classElement.type;
        return _createSubclasses(subItem, subType, processed);
      });
    });
  }
}


class TypeHierarchyItem implements HasToJson {
  final ClassElement classElement;
  final Element memberElement;
  final String displayName;
  final TypeHierarchyItem superclass;
  final List<TypeHierarchyItem> mixins;
  final List<TypeHierarchyItem> interfaces;
  List<TypeHierarchyItem> subclasses = <TypeHierarchyItem>[];

  TypeHierarchyItem(this.classElement, this.memberElement, this.displayName,
      this.superclass, this.mixins, this.interfaces);

  Map<String, Object> toJson() {
    Map<String, Object> json = {};
    json[CLASS_ELEMENT] = engineElementToJson(classElement);
    if (memberElement != null) {
      json[MEMBER_ELEMENT] = engineElementToJson(memberElement);
    }
    if (displayName != null) {
      json[DISPLAY_NAME] = displayName;
    }
    if (superclass != null) {
      json[SUPERCLASS] = objectToJson(superclass);
    }
    json[INTERFACES] = objectToJson(interfaces);
    json[MIXINS] = objectToJson(mixins);
    json[SUBCLASSES] = objectToJson(subclasses);
    return json;
  }
}
