// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Information about a class with nested properties.
///
/// If the property value is set, and the expression is an
/// [InstanceCreationExpression], we add nested properties for parameters of
/// the used constructor.
///
/// If the property value is not set, but its type is a class, we still could
/// add nested properties for this property. But we need to know how to
/// materialize it - which constructor to call, and with which arguments.
///
/// This class provides such "how to materialize" information.
class ClassDescription {
  final ClassElement element;
  final ConstructorElement constructor;

  /// Mapping from a parameter to the default code for the corresponding
  /// argument in a new instance creation that calls the [constructor].
  ///
  /// TODO(scheglov) Should be a generator, not just [String].
  /// In general case we might need to import some libraries.
  final Map<ParameterElement, String> parameterToDefaultCode;

  ClassDescription(
    this.element,
    this.constructor,
    this.parameterToDefaultCode,
  );
}

/// The lazy-fill registry of [ClassDescription].
class ClassDescriptionRegistry {
  final Map<ClassElement, ClassDescription> _map = {};

  /// Flush all data, because there was a change to a file.
  void flush() {
    _map.clear();
  }

  /// If we know how to materialize the [element], return [ClassDescription].
  /// Otherwise return `null`.
  ClassDescription get(ClassElement element) {
    var description = _map[element];
    if (description == null) {
      description = _classDescription(element);
      if (description != null) {
        _map[element] = description;
      }
    }
    return description;
  }

  /// Return `true` if properties should be created for instances of [type].
  bool hasNestedProperties(DartType type) {
    if (type is InterfaceType) {
      return _isOptedInClass(type.element);
    }
    return false;
  }

  ClassDescription _classDescription(ClassElement element) {
    if (!_isOptedInClass(element)) return null;

    var constructor = element.unnamedConstructor;
    if (constructor == null) return null;

    var parameters = constructor.parameters;
    var defaultValueMap = <ParameterElement, String>{};

    for (var parameter in parameters) {
      if (parameter.isNotOptional || parameter.hasRequired) {
        return null;
      }
    }

    return ClassDescription(element, constructor, defaultValueMap);
  }

  bool _isOptedInClass(ClassElement element) {
    return _isClass(
          element,
          'package:flutter/src/widgets/container.dart',
          'Container',
        ) ||
        _isClass(
          element,
          'package:flutter/src/painting/text_style.dart',
          'TextStyle',
        );
  }

  static bool _isClass(ClassElement element, String uri, String name) {
    return element.name == name && element.library.source.uri.toString() == uri;
  }
}
