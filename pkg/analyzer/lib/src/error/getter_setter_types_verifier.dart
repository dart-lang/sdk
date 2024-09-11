// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';

/// Verifies that the return type of the getter matches the parameter type
/// of the corresponding setter. Where "match" means "subtype" in non-nullable,
/// and "assignable" in legacy.
class GetterSetterTypesVerifier {
  final TypeSystemImpl _typeSystem;
  final ErrorReporter _errorReporter;

  GetterSetterTypesVerifier({
    required TypeSystemImpl typeSystem,
    required ErrorReporter errorReporter,
  })  : _typeSystem = typeSystem,
        _errorReporter = errorReporter;

  void checkExtension(ExtensionElement element) {
    for (var getter in element.accessors) {
      if (getter.isGetter) {
        _checkLocalGetter(getter);
      }
    }
  }

  void checkExtensionType(ExtensionTypeElement element, Interface interface) {
    checkInterface(element, interface);
    checkStaticAccessors(element.accessors);
  }

  void checkInterface(InterfaceElement element, Interface interface) {
    var libraryUri = element.library.source.uri;

    for (var name in interface.map.keys) {
      if (!name.isAccessibleFor(libraryUri)) continue;

      var getter = interface.map[name]!;
      if (getter.kind == ElementKind.GETTER) {
        var setter = interface.map[Name(libraryUri, '${name.name}=')];
        if (setter != null && setter.parameters.length == 1) {
          var getterType = getter.returnType;
          var setterType = setter.parameters[0].type;
          if (!_typeSystem.isSubtypeOf(getterType, setterType)) {
            Element errorElement;
            if (getter.enclosingElement3 == element) {
              if (element is ExtensionTypeElement &&
                  element.representation.getter == getter) {
                errorElement = setter;
              } else {
                errorElement = getter;
              }
            } else if (setter.enclosingElement3 == element) {
              errorElement = setter;
            } else {
              errorElement = element;
            }

            var getterName = getter.displayName;
            if (getter.enclosingElement3 != element) {
              var getterClassName = getter.enclosingElement3.displayName;
              getterName = '$getterClassName.$getterName';
            }

            var setterName = setter.displayName;
            if (setter.enclosingElement3 != element) {
              var setterClassName = setter.enclosingElement3.displayName;
              setterName = '$setterClassName.$setterName';
            }

            _errorReporter.atElement(
              errorElement,
              CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES,
              arguments: [getterName, getterType, setterType, setterName],
            );
          }
        }
      }
    }
  }

  void checkStaticAccessors(List<PropertyAccessorElement> accessors) {
    for (var getter in accessors) {
      if (getter.isStatic && getter.isGetter) {
        _checkLocalGetter(getter);
      }
    }
  }

  void _checkLocalGetter(PropertyAccessorElement getter) {
    assert(getter.isGetter);
    var setter = getter.correspondingSetter;
    if (setter != null) {
      var getterType = _getGetterType(getter);
      var setterType = _getSetterType(setter);
      if (setterType != null) {
        if (!_typeSystem.isSubtypeOf(getterType, setterType)) {
          var name = getter.name;
          _errorReporter.atElement(
            getter,
            CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES,
            arguments: [name, getterType, setterType, name],
          );
        }
      }
    }
  }

  /// Return the return type of the [getter].
  static DartType _getGetterType(PropertyAccessorElement getter) {
    return getter.returnType;
  }

  /// Return the type of the first parameter of the [setter].
  static DartType? _getSetterType(PropertyAccessorElement setter) {
    var parameters = setter.parameters;
    if (parameters.isNotEmpty) {
      return parameters[0].type;
    } else {
      return null;
    }
  }
}
