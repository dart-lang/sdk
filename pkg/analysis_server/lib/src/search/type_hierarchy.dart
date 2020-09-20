// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/protocol_server.dart'
    show TypeHierarchyItem, convertElement;
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// A computer for a type hierarchy of an [Element].
class TypeHierarchyComputer {
  final SearchEngine _searchEngine;

  final Element _pivotElement;
  LibraryElement _pivotLibrary;
  ElementKind _pivotKind;
  String _pivotName;
  bool _pivotFieldFinal;
  ClassElement _pivotClass;

  final List<TypeHierarchyItem> _items = <TypeHierarchyItem>[];
  final List<ClassElement> _itemClassElements = <ClassElement>[];
  final Map<Element, TypeHierarchyItem> _elementItemMap =
      HashMap<Element, TypeHierarchyItem>();

  TypeHierarchyComputer(this._searchEngine, this._pivotElement) {
    _pivotLibrary = _pivotElement.library;
    _pivotKind = _pivotElement.kind;
    _pivotName = _pivotElement.name;
    // try to find enclosing ClassElement
    var element = _pivotElement;
    if (_pivotElement is FieldElement) {
      _pivotFieldFinal = (_pivotElement as FieldElement).isFinal;
      element = _pivotElement.enclosingElement;
    }
    if (_pivotElement is ExecutableElement) {
      element = _pivotElement.enclosingElement;
    }
    if (element is ClassElement) {
      _pivotClass = element;
    }
  }

  /// Returns the computed type hierarchy, maybe `null`.
  Future<List<TypeHierarchyItem>> compute() async {
    if (_pivotClass != null) {
      _createSuperItem(_pivotClass, null);
      await _createSubclasses(_items[0], 0, _pivotClass);
      return _items;
    }
    return null;
  }

  /// Returns the computed super type only type hierarchy, maybe `null`.
  List<TypeHierarchyItem> computeSuper() {
    if (_pivotClass != null) {
      _createSuperItem(_pivotClass, null);
      return _items;
    }
    return null;
  }

  Future _createSubclasses(
      TypeHierarchyItem item, int itemId, ClassElement classElement) async {
    var subElements = await getDirectSubClasses(_searchEngine, classElement);
    var subItemIds = <int>[];
    for (var subElement in subElements) {
      // check for recursion
      var subItem = _elementItemMap[subElement];
      if (subItem != null) {
        var id = _items.indexOf(subItem);
        item.subclasses.add(id);
        continue;
      }
      // create a subclass item
      var subMemberElement = _findMemberElement(subElement);
      subItem = TypeHierarchyItem(convertElement(subElement),
          memberElement: subMemberElement != null
              ? convertElement(subMemberElement)
              : null,
          superclass: itemId);
      var subItemId = _items.length;
      // remember
      _elementItemMap[subElement] = subItem;
      _items.add(subItem);
      _itemClassElements.add(subElement);
      // add to hierarchy
      item.subclasses.add(subItemId);
      subItemIds.add(subItemId);
    }
    // compute subclasses of subclasses
    for (var subItemId in subItemIds) {
      var subItem = _items[subItemId];
      var subItemElement = _itemClassElements[subItemId];
      await _createSubclasses(subItem, subItemId, subItemElement);
    }
  }

  int _createSuperItem(
      ClassElement classElement, List<DartType> typeArguments) {
    // check for recursion
    var item = _elementItemMap[classElement];
    if (item != null) {
      return _items.indexOf(item);
    }
    // create an empty item now
    int itemId;
    {
      String displayName;
      if (typeArguments != null && typeArguments.isNotEmpty) {
        var typeArgumentsStr = typeArguments
            .map((type) => type.getDisplayString(withNullability: false))
            .join(', ');
        displayName = classElement.displayName + '<' + typeArgumentsStr + '>';
      }
      var memberElement = _findMemberElement(classElement);
      item = TypeHierarchyItem(convertElement(classElement),
          displayName: displayName,
          memberElement:
              memberElement != null ? convertElement(memberElement) : null);
      _elementItemMap[classElement] = item;
      itemId = _items.length;
      _items.add(item);
      _itemClassElements.add(classElement);
    }
    // superclass
    {
      var superType = classElement.supertype;
      if (superType != null) {
        item.superclass = _createSuperItem(
          superType.element,
          superType.typeArguments,
        );
      }
    }
    // mixins
    classElement.mixins.forEach((InterfaceType type) {
      var id = _createSuperItem(type.element, type.typeArguments);
      item.mixins.add(id);
    });
    // interfaces
    classElement.interfaces.forEach((InterfaceType type) {
      var id = _createSuperItem(type.element, type.typeArguments);
      item.interfaces.add(id);
    });
    // done
    return itemId;
  }

  ExecutableElement _findMemberElement(ClassElement clazz) {
    ExecutableElement result;
    // try to find in the class itself
    if (_pivotKind == ElementKind.METHOD) {
      result = clazz.getMethod(_pivotName);
    } else if (_pivotKind == ElementKind.GETTER) {
      result = clazz.getGetter(_pivotName);
    } else if (_pivotKind == ElementKind.SETTER) {
      result = clazz.getSetter(_pivotName);
    } else if (_pivotKind == ElementKind.FIELD) {
      result = clazz.getGetter(_pivotName);
      if (result == null && !_pivotFieldFinal) {
        result = clazz.getSetter(_pivotName);
      }
    }
    if (result != null && result.isAccessibleIn(_pivotLibrary)) {
      return result;
    }
    // try to find in the class mixin
    for (var mixin in clazz.mixins.reversed) {
      var mixinElement = mixin.element;
      if (_pivotKind == ElementKind.METHOD) {
        result = mixinElement.lookUpMethod(_pivotName, _pivotLibrary);
      } else if (_pivotKind == ElementKind.GETTER) {
        result = mixinElement.lookUpGetter(_pivotName, _pivotLibrary);
      } else if (_pivotKind == ElementKind.SETTER) {
        result = mixinElement.lookUpSetter(_pivotName, _pivotLibrary);
      } else if (_pivotKind == ElementKind.FIELD) {
        result = mixinElement.lookUpGetter(_pivotName, _pivotLibrary);
        if (result == null && !_pivotFieldFinal) {
          result = mixinElement.lookUpSetter(_pivotName, _pivotLibrary);
        }
      }
      if (result == _pivotElement) {
        return null;
      }
      if (result != null) {
        return result;
      }
    }
    // not found
    return null;
  }
}
