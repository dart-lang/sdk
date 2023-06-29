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
  final TypeHierarchyComputerHelper helper;

  final List<TypeHierarchyItem> _items = <TypeHierarchyItem>[];
  final List<InterfaceElement> _itemClassElements = [];
  final Map<Element, TypeHierarchyItem> _elementItemMap =
      HashMap<Element, TypeHierarchyItem>();

  TypeHierarchyComputer(this._searchEngine, final Element pivotElement)
      : helper = TypeHierarchyComputerHelper.fromElement(pivotElement);

  bool get _isNonNullableByDefault =>
      helper.pivotLibrary.isNonNullableByDefault;

  /// Returns the computed type hierarchy, maybe `null`.
  Future<List<TypeHierarchyItem>?> compute() async {
    var pivotClass = helper.pivotClass;
    if (pivotClass != null) {
      _createSuperItem(pivotClass, null);
      var searchEngineCache = SearchEngineCache();
      await _createSubclasses(_items[0], 0, pivotClass, searchEngineCache);
      return _items;
    }
    return null;
  }

  /// Returns the computed super type only type hierarchy, maybe `null`.
  List<TypeHierarchyItem>? computeSuper() {
    var pivotClass = helper.pivotClass;
    if (pivotClass != null) {
      _createSuperItem(pivotClass, null);
      return _items;
    }
    return null;
  }

  Future<void> _createSubclasses(
      TypeHierarchyItem item,
      int itemId,
      InterfaceElement classElement,
      SearchEngineCache searchEngineCache) async {
    var subElements = await getDirectSubClasses(
        _searchEngine, classElement, searchEngineCache);
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
      var subMemberElement = helper.findMemberElement(subElement);
      var subMemberElementDeclared = subMemberElement?.nonSynthetic;
      subItem = TypeHierarchyItem(
          convertElement(subElement, withNullability: _isNonNullableByDefault),
          memberElement: subMemberElementDeclared != null
              ? convertElement(subMemberElementDeclared,
                  withNullability: _isNonNullableByDefault)
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
      await _createSubclasses(
          subItem, subItemId, subItemElement, searchEngineCache);
    }
  }

  int _createSuperItem(
      InterfaceElement classElement, List<DartType>? typeArguments) {
    // check for recursion
    var cachedItem = _elementItemMap[classElement];
    if (cachedItem != null) {
      return _items.indexOf(cachedItem);
    }
    // create an empty item now
    TypeHierarchyItem item;
    int itemId;
    {
      String? displayName;
      if (typeArguments != null && typeArguments.isNotEmpty) {
        var typeArgumentsStr = typeArguments
            .map((type) =>
                type.getDisplayString(withNullability: _isNonNullableByDefault))
            .join(', ');
        displayName = '${classElement.displayName}<$typeArgumentsStr>';
      }
      var memberElement = helper.findMemberElement(classElement);
      var memberElementDeclared = memberElement?.nonSynthetic;
      item = TypeHierarchyItem(
          convertElement(classElement,
              withNullability: _isNonNullableByDefault),
          displayName: displayName,
          memberElement: memberElementDeclared != null
              ? convertElement(memberElementDeclared,
                  withNullability: _isNonNullableByDefault)
              : null);
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
    for (var type in classElement.mixins) {
      var id = _createSuperItem(type.element, type.typeArguments);
      item.mixins.add(id);
    }
    // interfaces
    for (var type in classElement.interfaces) {
      var id = _createSuperItem(type.element, type.typeArguments);
      item.interfaces.add(id);
    }
    // done
    return itemId;
  }
}

class TypeHierarchyComputerHelper {
  final Element pivotElement;
  final LibraryElement pivotLibrary;
  final ElementKind pivotKind;
  final String? pivotName;
  final bool pivotFieldFinal;
  final InterfaceElement? pivotClass;

  TypeHierarchyComputerHelper(this.pivotElement, this.pivotLibrary,
      this.pivotKind, this.pivotName, this.pivotFieldFinal, this.pivotClass);

  factory TypeHierarchyComputerHelper.fromElement(final Element pivotElement) {
    // try to find enclosing ClassElement
    Element? element = pivotElement;
    bool pivotFieldFinal = false;
    if (pivotElement is FieldElement) {
      pivotFieldFinal = pivotElement.isFinal;
      element = pivotElement.enclosingElement2;
    }
    if (pivotElement is ExecutableElement) {
      element = pivotElement.enclosingElement2;
    }
    InterfaceElement? pivotClass;
    if (element is InterfaceElement) {
      pivotClass = element;
    }

    return TypeHierarchyComputerHelper(pivotElement, pivotElement.library!,
        pivotElement.kind, pivotElement.name, pivotFieldFinal, pivotClass);
  }

  ExecutableElement? findMemberElement(InterfaceElement clazz) {
    var pivotName = this.pivotName;
    if (pivotName == null) {
      return null;
    }
    ExecutableElement? result;
    // try to find in the class itself
    if (pivotKind == ElementKind.METHOD) {
      result = clazz.getMethod(pivotName);
    } else if (pivotKind == ElementKind.GETTER) {
      result = clazz.getGetter(pivotName);
    } else if (pivotKind == ElementKind.SETTER) {
      result = clazz.getSetter(pivotName);
    } else if (pivotKind == ElementKind.FIELD) {
      result = clazz.getGetter(pivotName);
      if (result == null && !pivotFieldFinal) {
        result = clazz.getSetter(pivotName);
      }
    }
    if (result != null && result.isAccessibleIn(pivotLibrary)) {
      return result;
    }
    // try to find in the class mixin
    for (var mixin in clazz.mixins.reversed) {
      var mixinElement = mixin.element;
      if (pivotKind == ElementKind.METHOD) {
        result = mixinElement.lookUpMethod(pivotName, pivotLibrary);
      } else if (pivotKind == ElementKind.GETTER) {
        result = mixinElement.lookUpGetter(pivotName, pivotLibrary);
      } else if (pivotKind == ElementKind.SETTER) {
        result = mixinElement.lookUpSetter(pivotName, pivotLibrary);
      } else if (pivotKind == ElementKind.FIELD) {
        result = mixinElement.lookUpGetter(pivotName, pivotLibrary);
        if (result == null && !pivotFieldFinal) {
          result = mixinElement.lookUpSetter(pivotName, pivotLibrary);
        }
      }
      if (result == pivotElement) {
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
