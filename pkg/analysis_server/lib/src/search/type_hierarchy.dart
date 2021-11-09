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
  final LibraryElement _pivotLibrary;
  final ElementKind _pivotKind;
  final String? _pivotName;
  late bool _pivotFieldFinal;
  ClassElement? _pivotClass;

  final List<TypeHierarchyItem> _items = <TypeHierarchyItem>[];
  final List<ClassElement> _itemClassElements = <ClassElement>[];
  final Map<Element, TypeHierarchyItem> _elementItemMap =
      HashMap<Element, TypeHierarchyItem>();

  TypeHierarchyComputer(this._searchEngine, this._pivotElement)
      : _pivotLibrary = _pivotElement.library!,
        _pivotKind = _pivotElement.kind,
        _pivotName = _pivotElement.name {
    // try to find enclosing ClassElement
    Element? element = _pivotElement;
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

  bool get _isNonNullableByDefault => _pivotLibrary.isNonNullableByDefault;

  /// Returns the computed type hierarchy, maybe `null`.
  Future<List<TypeHierarchyItem>?> compute() async {
    var pivotClass = _pivotClass;
    if (pivotClass != null) {
      _createSuperItem(pivotClass, null);
      var superLength = _items.length;
      await _createSubclasses(_items[0], 0, pivotClass);

      // sort subclasses only
      if (_items.length > superLength + 1) {
        var subList = _items.sublist(superLength);
        subList
            .sort((a, b) => a.classElement.name.compareTo(b.classElement.name));
        for (var i = 0; i < subList.length; i++) {
          _items[i + superLength] = subList[i];
        }
      }

      return _items;
    }
    return null;
  }

  /// Returns the computed super type only type hierarchy, maybe `null`.
  List<TypeHierarchyItem>? computeSuper() {
    var pivotClass = _pivotClass;
    if (pivotClass != null) {
      _createSuperItem(pivotClass, null);
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
      await _createSubclasses(subItem, subItemId, subItemElement);
    }
  }

  int _createSuperItem(
      ClassElement classElement, List<DartType>? typeArguments) {
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
        displayName = classElement.displayName + '<' + typeArgumentsStr + '>';
      }
      var memberElement = _findMemberElement(classElement);
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

  ExecutableElement? _findMemberElement(ClassElement clazz) {
    var pivotName = _pivotName;
    if (pivotName == null) {
      return null;
    }
    ExecutableElement? result;
    // try to find in the class itself
    if (_pivotKind == ElementKind.METHOD) {
      result = clazz.getMethod(pivotName);
    } else if (_pivotKind == ElementKind.GETTER) {
      result = clazz.getGetter(pivotName);
    } else if (_pivotKind == ElementKind.SETTER) {
      result = clazz.getSetter(pivotName);
    } else if (_pivotKind == ElementKind.FIELD) {
      result = clazz.getGetter(pivotName);
      if (result == null && !_pivotFieldFinal) {
        result = clazz.getSetter(pivotName);
      }
    }
    if (result != null && result.isAccessibleIn(_pivotLibrary)) {
      return result;
    }
    // try to find in the class mixin
    for (var mixin in clazz.mixins.reversed) {
      var mixinElement = mixin.element;
      if (_pivotKind == ElementKind.METHOD) {
        result = mixinElement.lookUpMethod(pivotName, _pivotLibrary);
      } else if (_pivotKind == ElementKind.GETTER) {
        result = mixinElement.lookUpGetter(pivotName, _pivotLibrary);
      } else if (_pivotKind == ElementKind.SETTER) {
        result = mixinElement.lookUpSetter(pivotName, _pivotLibrary);
      } else if (_pivotKind == ElementKind.FIELD) {
        result = mixinElement.lookUpGetter(pivotName, _pivotLibrary);
        if (result == null && !_pivotFieldFinal) {
          result = mixinElement.lookUpSetter(pivotName, _pivotLibrary);
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
