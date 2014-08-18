// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.type_hierarhy;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/computer/element.dart' show
    engineElementToJson;
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/services/json.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A computer for a type hierarchy of an [Element].
 */
class TypeHierarchyComputer {
  final SearchEngine _searchEngine;

  ElementKind _pivotKind;
  String _pivotName;

  final List<TypeHierarchyItem> _items = <TypeHierarchyItem>[];
  final Map<Element, TypeHierarchyItem> _elementItemMap =
      new HashMap<Element, TypeHierarchyItem>();

  TypeHierarchyComputer(this._searchEngine);

  /**
   * Returns the computed type hierarchy, maybe `null`.
   */
  Future<List<TypeHierarchyItem>> compute(Element element) {
    _pivotKind = element.kind;
    _pivotName = element.name;
    if (element is ExecutableElement &&
        element.enclosingElement is ClassElement) {
      element = element.enclosingElement;
    }
    if (element is ClassElement) {
      InterfaceType type = element.type;
      _createSuperItem(type);
      return _createSubclasses(_items[0], type).then((_) {
        return new Future.value(_items);
      });
    }
    return new Future.value(null);
  }

  Future _createSubclasses(TypeHierarchyItem item, InterfaceType type) {
    var future = getDirectSubClasses(_searchEngine, type.element);
    return future.then((Set<ClassElement> subElements) {
      List<TypeHierarchyItem> subItems = <TypeHierarchyItem>[];
      for (ClassElement subElement in subElements) {
        // check for recursion
        TypeHierarchyItem subItem = _elementItemMap[subElement];
        if (subItem != null) {
          int id = _items.indexOf(subItem);
          subItem.subclasses.add(id);
          continue;
        }
        // create a subclass item
        ExecutableElement subMemberElement = _findMemberElement(subElement);
        subItem = new TypeHierarchyItem(
            _items.length,
            subElement,
            subMemberElement,
            null,
            item.id,
            <int>[],
            <int>[]);
        // remember
        _elementItemMap[subElement] = subItem;
        _items.add(subItem);
        // add to hierarchy
        item.subclasses.add(subItem.id);
        subItems.add(subItem);
      }
      // compute subclasses of subclasses
      return Future.forEach(subItems, (TypeHierarchyItem subItem) {
        InterfaceType subType = subItem.classElement.type;
        return _createSubclasses(subItem, subType);
      });
    });
  }

  int _createSuperItem(InterfaceType type) {
    // check for recursion
    TypeHierarchyItem item = _elementItemMap[type.element];
    if (item != null) {
      return _items.indexOf(item);
    }
    // create an empty item now
    {
      String displayName = null;
      if (type.typeArguments.isNotEmpty) {
        displayName = type.toString();
      }
      ClassElement classElement = type.element;
      ExecutableElement memberElement = _findMemberElement(classElement);
      item = new TypeHierarchyItem(
          _items.length,
          classElement,
          memberElement,
          displayName,
          null,
          <int>[],
          <int>[]);
      _elementItemMap[classElement] = item;
      _items.add(item);
    }
    // superclass
    {
      InterfaceType superType = type.superclass;
      if (superType != null) {
        item.superclass = _createSuperItem(superType);
      }
    }
    // mixins
    type.mixins.forEach((InterfaceType type) {
      int id = _createSuperItem(type);
      item.mixins.add(id);
    });
    // interfaces
    type.interfaces.forEach((InterfaceType type) {
      int id = _createSuperItem(type);
      item.interfaces.add(id);
    });
    // done
    return item.id;
  }

  ExecutableElement _findMemberElement(ClassElement classElement) {
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
}


class TypeHierarchyItem implements HasToJson {
  final int id;
  final ClassElement classElement;
  final Element memberElement;
  final String displayName;
  int superclass;
  final List<int> mixins;
  final List<int> interfaces;
  final List<int> subclasses = <int>[];

  TypeHierarchyItem(this.id, this.classElement, this.memberElement,
      this.displayName, this.superclass, this.mixins, this.interfaces);

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
