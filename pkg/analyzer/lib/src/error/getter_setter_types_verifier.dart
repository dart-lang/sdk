// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
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

  void checkExtension(ExtensionElement2 element) {
    for (var getter in element.getters2) {
      _checkLocalGetter(getter);
    }
  }

  void checkExtensionType(ExtensionTypeElement2 element, Interface interface) {
    checkInterface(element, interface);
    checkStaticGetters(element.getters2);
  }

  void checkInterface(InterfaceElement2 element, Interface interface) {
    var libraryUri = element.library2.uri;

    var interfaceMap = interface.map2;
    for (var entry in interfaceMap.entries) {
      var getterName = entry.key;
      if (!getterName.isAccessibleFor(libraryUri)) continue;

      var getter = entry.value;
      if (getter.kind == ElementKind.GETTER) {
        var setter = interfaceMap[getterName.forSetter];
        if (setter != null && setter.formalParameters.length == 1) {
          var getterType = getter.returnType;
          var setterType = setter.formalParameters[0].type;
          if (!_typeSystem.isSubtypeOf(getterType, setterType)) {
            Element2 errorElement;
            if (getter.enclosingElement2 == element) {
              if (element is ExtensionTypeElement2 &&
                  element.representation2.getter2 == getter) {
                errorElement = setter;
              } else {
                errorElement = getter;
              }
            } else if (setter.enclosingElement2 == element) {
              errorElement = setter;
            } else {
              errorElement = element;
            }

            var getterName = getter.displayName;
            if (getter.enclosingElement2 != element) {
              var getterClassName = getter.enclosingElement2!.displayName;
              getterName = '$getterClassName.$getterName';
            }

            var setterName = setter.displayName;
            if (setter.enclosingElement2 != element) {
              var setterClassName = setter.enclosingElement2!.displayName;
              setterName = '$setterClassName.$setterName';
            }

            _errorReporter.atElement2(
              errorElement,
              CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES,
              arguments: [getterName, getterType, setterType, setterName],
            );
          }
        }
      }
    }
  }

  void checkStaticGetters(List<GetterElement> getters) {
    for (var getter in getters) {
      if (getter.isStatic) {
        _checkLocalGetter(getter);
      }
    }
  }

  void _checkLocalGetter(GetterElement getter) {
    var name = getter.name3;
    if (name == null) {
      return;
    }

    var setter = getter.variable3?.setter2;
    if (setter == null) {
      return;
    }

    var setterType = _getSetterType(setter);
    if (setterType == null) {
      return;
    }

    var getterType = _getGetterType(getter);
    if (!_typeSystem.isSubtypeOf(getterType, setterType)) {
      _errorReporter.atElement2(
        getter,
        CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES,
        arguments: [name, getterType, setterType, name],
      );
    }
  }

  /// Return the return type of the [getter].
  static DartType _getGetterType(GetterElement getter) {
    return getter.returnType;
  }

  /// Return the type of the first parameter of the [setter].
  static DartType? _getSetterType(SetterElement setter) {
    var parameters = setter.formalParameters;
    if (parameters.isNotEmpty) {
      return parameters[0].type;
    } else {
      return null;
    }
  }
}
