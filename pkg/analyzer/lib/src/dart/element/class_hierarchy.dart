// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class ClassHierarchy {
  final Map<InterfaceElementImpl, _Hierarchy> _map = {};

  List<ClassHierarchyError> errors(InterfaceElementImpl element) {
    return _getHierarchy(element).errors;
  }

  List<InterfaceTypeImpl> implementedInterfaces(InterfaceElementImpl element) {
    return _getHierarchy(element).interfaces;
  }

  void remove(InterfaceElementImpl element) {
    element.resetCachedAllSupertypes();
    _map.remove(element);
  }

  /// Remove hierarchies for classes defined in specified libraries.
  void removeOfLibraries(Set<Uri> uriSet) {
    _map.removeWhere((element, _) {
      if (uriSet.contains(element.library.uri)) {
        element.resetCachedAllSupertypes();
        return true;
      }
      return false;
    });
  }

  _Hierarchy _getHierarchy(InterfaceElementImpl element) {
    var hierarchy = _map[element];
    if (hierarchy != null) {
      return hierarchy;
    }

    hierarchy = _Hierarchy(
      errors: const <ClassHierarchyError>[],
      interfaces: const <InterfaceTypeImpl>[],
    );
    _map[element] = hierarchy;

    var typeSystem = element.library.typeSystem;
    var interfacesMerger = InterfacesMerger(typeSystem);

    void append(InterfaceTypeImpl? type) {
      if (type == null) {
        return;
      }

      interfacesMerger.add(type);

      var substitution = Substitution.fromInterfaceType(type);
      var element = type.element;
      var rawInterfaces = implementedInterfaces(element);
      for (var rawInterface in rawInterfaces) {
        var newInterface = substitution.mapInterfaceType(rawInterface);
        interfacesMerger.add(newInterface);
      }
    }

    append(element.supertype);
    if (element is MixinElementImpl) {
      for (var type in element.superclassConstraints) {
        append(type);
      }
    }
    for (var type in element.interfaces) {
      append(type);
    }
    for (var type in element.mixins) {
      append(type);
    }

    var errors = <ClassHierarchyError>[];
    var interfaces = <InterfaceTypeImpl>[];
    for (var collector in interfacesMerger._map.values) {
      var error = collector._error;
      if (error != null) {
        errors.add(error);
      }
      interfaces.add(collector.type);
    }

    hierarchy.errors = errors.toFixedList();
    hierarchy.interfaces = interfaces.toFixedList();

    return hierarchy;
  }
}

abstract class ClassHierarchyError {}

/// This error is recorded when the same generic class is found in the
/// hierarchy of a class, and the type arguments are not compatible. What it
/// means to be compatible depends on whether the class is declared in a
/// legacy, or an opted-in library.
///
/// In legacy libraries LEGACY_ERASURE of the interfaces must be syntactically
/// equal.
///
/// In opted-in libraries NNBD_TOP_MERGE of NORM of the interfaces must be
/// successful.
class IncompatibleInterfacesClassHierarchyError extends ClassHierarchyError {
  final InterfaceTypeImpl first;
  final InterfaceTypeImpl second;

  IncompatibleInterfacesClassHierarchyError(this.first, this.second);
}

class InterfacesMerger {
  final TypeSystemImpl _typeSystem;
  final Map<InterfaceElementImpl, _ClassInterfaceType> _map = {};

  InterfacesMerger(this._typeSystem);

  List<InterfaceTypeImpl> get typeList {
    return _map.values.map((e) => e.type).toList();
  }

  void add(InterfaceTypeImpl type) {
    var element = type.element;
    var classResult = _map[element];
    if (classResult == null) {
      classResult = _ClassInterfaceType(
        _typeSystem,
        element is ClassElementImpl && element.isDartCoreObject,
      );
      _map[element] = classResult;
    }
    classResult.update(type);
  }

  void addWithSupertypes(InterfaceTypeImpl? type) {
    if (type != null) {
      for (var superType in type.allSupertypes) {
        add(superType);
      }
      add(type);
    }
  }
}

class _ClassInterfaceType {
  final TypeSystemImpl _typeSystem;
  final bool _isDartCoreObject;

  ClassHierarchyError? _error;

  InterfaceTypeImpl? _singleType;
  InterfaceTypeImpl? _currentResult;

  _ClassInterfaceType(this._typeSystem, this._isDartCoreObject);

  InterfaceTypeImpl get type => (_currentResult ?? _singleType)!;

  void update(InterfaceTypeImpl type) {
    if (_error != null) {
      return;
    }

    if (_currentResult == null) {
      if (_singleType == null) {
        _singleType = type;
        return;
      } else if (type == _singleType) {
        return;
      } else {
        _currentResult = _typeSystem.normalizeInterfaceType(_singleType!);
      }
    }

    var normType = _typeSystem.normalizeInterfaceType(type);
    try {
      _currentResult = _merge(_currentResult!, normType);
    } catch (e) {
      _error = IncompatibleInterfacesClassHierarchyError(_currentResult!, type);
    }
  }

  InterfaceTypeImpl _merge(InterfaceTypeImpl T1, InterfaceTypeImpl T2) {
    // Normally `Object?` cannot be a superinterface.
    // However, it can happen for extension types.
    if (_isDartCoreObject) {
      if (T1.nullabilitySuffix == NullabilitySuffix.question &&
          T2.nullabilitySuffix == NullabilitySuffix.none) {
        return T2;
      }
      if (T1.nullabilitySuffix == NullabilitySuffix.none &&
          T2.nullabilitySuffix == NullabilitySuffix.question) {
        return T1;
      }
    }

    return _typeSystem.topMerge(T1, T2) as InterfaceTypeImpl;
  }
}

class _Hierarchy {
  List<ClassHierarchyError> errors;
  List<InterfaceTypeImpl> interfaces;

  _Hierarchy({required this.errors, required this.interfaces});
}
