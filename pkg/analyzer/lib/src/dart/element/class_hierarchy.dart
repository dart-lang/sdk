// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/resolver.dart';

class ClassHierarchy {
  final Map<ClassElement, _Hierarchy> _map = {};

  List<InterfaceType> implementedInterfaces(ClassElement element) {
    var hierarchy = _map[element];

    if (hierarchy != null) {
      return hierarchy.interfaces;
    }

    hierarchy = _Hierarchy(
      interfaces: const <InterfaceType>[],
    );
    _map[element] = hierarchy;

    var library = element.library as LibraryElementImpl;
    var typeSystem = library.typeSystem;
    var map = <ClassElement, _ClassInterfaceType>{};

    void appendOne(InterfaceType type) {
      var element = type.element;
      if (library.isNonNullableByDefault) {
        var classResult = map[element];
        if (classResult == null) {
          classResult = _ClassInterfaceType(typeSystem);
          map[element] = classResult;
        }
        classResult.update(type);
      } else {
        map[element] ??= _ClassInterfaceType(typeSystem)..update(type);
      }
    }

    void append(InterfaceType type) {
      if (type == null) {
        return;
      }

      appendOne(type);

      var substitution = Substitution.fromInterfaceType(type);
      var rawInterfaces = implementedInterfaces(type.element);
      for (var rawInterface in rawInterfaces) {
        var newInterface = substitution.substituteType(rawInterface);
        newInterface = library.toLegacyTypeIfOptOut(newInterface);
        appendOne(newInterface);
      }
    }

    append(element.supertype);
    for (var type in element.superclassConstraints) {
      append(type);
    }
    for (var type in element.interfaces) {
      append(type);
    }
    for (var type in element.mixins) {
      append(type);
    }

    var result = map.values.map((e) => e.type).toList(growable: false);
    hierarchy.interfaces = result;
    return result;
  }

  void remove(ClassElement element) {
    _map.remove(element);
  }
}

class _ClassInterfaceType {
  final TypeSystemImpl _typeSystem;

  InterfaceType _notNormalized;
  InterfaceType _currentMerge;

  _ClassInterfaceType(this._typeSystem);

  InterfaceType get type => _currentMerge ?? _notNormalized;

  void update(InterfaceType type) {
    if (_currentMerge == null) {
      if (_notNormalized == null) {
        _notNormalized = type;
        return;
      } else {
        _currentMerge = _typeSystem.normalize(_notNormalized);
      }
    }

    var normType = _typeSystem.normalize(type);
    try {
      _currentMerge = _typeSystem.topMerge(_currentMerge, normType);
    } catch (e) {
      // ignored
    }
  }
}

class _Hierarchy {
  List<InterfaceType> interfaces;

  _Hierarchy({this.interfaces});
}
