// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

class ClassHierarchy {
  final Map<InterfaceElementImpl, _Hierarchy> _map = {};

  List<ClassHierarchyError> errors(InterfaceElementImpl element) {
    return _getHierarchy(element).errors;
  }

  List<InterfaceType> implementedInterfaces(InterfaceElementImpl element) {
    return _getHierarchy(element).interfaces;
  }

  void remove(InterfaceElementImpl element) {
    assert(element.augmentationTarget == null);
    element.resetCachedAllSupertypes();
    _map.remove(element);
  }

  /// Remove hierarchies for classes defined in specified libraries.
  void removeOfLibraries(Set<Uri> uriSet) {
    _map.removeWhere((element, _) {
      if (uriSet.contains(element.librarySource.uri)) {
        element.resetCachedAllSupertypes();
        return true;
      }
      return false;
    });
  }

  _Hierarchy _getHierarchy(InterfaceElementImpl element) {
    var augmented = element.augmented;

    var hierarchy = _map[element];
    if (hierarchy != null) {
      return hierarchy;
    }

    hierarchy = _Hierarchy(
      errors: const <ClassHierarchyError>[],
      interfaces: const <InterfaceType>[],
    );
    _map[element] = hierarchy;

    var library = element.library;
    var typeSystem = library.typeSystem;
    var interfacesMerger = InterfacesMerger(typeSystem);

    void append(InterfaceType? type) {
      if (type == null) {
        return;
      }

      interfacesMerger.add(type);

      var substitution = Substitution.fromInterfaceType(type);
      var element = type.element as InterfaceElementImpl;
      var rawInterfaces = implementedInterfaces(element);
      for (var rawInterface in rawInterfaces) {
        var newInterface =
            substitution.substituteType(rawInterface) as InterfaceType;
        interfacesMerger.add(newInterface);
      }
    }

    append(element.supertype);
    if (augmented is AugmentedMixinElement) {
      for (var type in augmented.superclassConstraints) {
        append(type);
      }
    }
    for (var type in augmented.interfaces) {
      append(type);
    }
    for (var type in augmented.mixins) {
      append(type);
    }

    var errors = <ClassHierarchyError>[];
    var interfaces = <InterfaceType>[];
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
  final InterfaceType first;
  final InterfaceType second;

  IncompatibleInterfacesClassHierarchyError(this.first, this.second);
}

class InterfacesMerger {
  final TypeSystemImpl _typeSystem;
  final Map<InterfaceElement, _ClassInterfaceType> _map = {};

  InterfacesMerger(this._typeSystem);

  List<InterfaceType> get typeList {
    return _map.values.map((e) => e.type).toList();
  }

  void add(InterfaceType type) {
    var element = type.element;
    var classResult = _map[element];
    if (classResult == null) {
      classResult = _ClassInterfaceType(
        _typeSystem,
        element is ClassElement && element.isDartCoreObject,
      );
      _map[element] = classResult;
    }
    classResult.update(type);
  }

  void addWithSupertypes(InterfaceType? type) {
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

  InterfaceType? _singleType;
  InterfaceType? _currentResult;

  _ClassInterfaceType(this._typeSystem, this._isDartCoreObject);

  InterfaceType get type => (_currentResult ?? _singleType)!;

  void update(InterfaceType type) {
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
        _currentResult = _typeSystem.normalize(_singleType!) as InterfaceType;
      }
    }

    var normType = _typeSystem.normalize(type) as InterfaceType;
    try {
      _currentResult = _merge(_currentResult!, normType);
    } catch (e) {
      _error = IncompatibleInterfacesClassHierarchyError(
        _currentResult!,
        type,
      );
    }
  }

  InterfaceType _merge(InterfaceType T1, InterfaceType T2) {
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

    return _typeSystem.topMerge(T1, T2) as InterfaceType;
  }
}

class _Hierarchy {
  List<ClassHierarchyError> errors;
  List<InterfaceType> interfaces;

  _Hierarchy({
    required this.errors,
    required this.interfaces,
  });
}
