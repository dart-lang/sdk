// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';

/// Verifies that the return type of the getter matches the parameter type
/// of the corresponding setter. Where "match" means "subtype" in non-nullable,
/// and "assignable" in legacy.
class GetterSetterTypesVerifier {
  final LibraryElementImpl library;
  final TypeSystemImpl _typeSystem;
  final DiagnosticReporter _diagnosticReporter;

  GetterSetterTypesVerifier({
    required this.library,
    required DiagnosticReporter diagnosticReporter,
  }) : _typeSystem = library.typeSystem,
       _diagnosticReporter = diagnosticReporter;

  bool get _skipGetterSetterTypesCheck {
    return library.featureSet.isEnabled(Feature.getter_setter_error);
  }

  void checkExtension(ExtensionElementImpl element) {
    if (_skipGetterSetterTypesCheck) {
      return;
    }

    for (var getter in element.getters) {
      _checkLocalGetter(getter);
    }
  }

  void checkExtensionType(
    ExtensionTypeElementImpl element,
    Interface interface,
  ) {
    if (_skipGetterSetterTypesCheck) {
      return;
    }

    checkInterface(element, interface);
    checkStaticGetters(element.getters);
  }

  void checkInterface(InterfaceElementImpl element, Interface interface) {
    if (_skipGetterSetterTypesCheck) {
      return;
    }

    var libraryUri = element.library.uri;

    var interfaceMap = interface.map;
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
            Element errorElement;
            if (getter.enclosingElement == element) {
              if (element is ExtensionTypeElementImpl &&
                  element.representation.getter == getter) {
                errorElement = setter;
              } else {
                errorElement = getter;
              }
            } else if (setter.enclosingElement == element) {
              errorElement = setter;
            } else {
              errorElement = element;
            }

            var getterName = getter.displayName;
            if (getter.enclosingElement != element) {
              var getterClassName = getter.enclosingElement!.displayName;
              getterName = '$getterClassName.$getterName';
            }

            var setterName = setter.displayName;
            if (setter.enclosingElement != element) {
              var setterClassName = setter.enclosingElement!.displayName;
              setterName = '$setterClassName.$setterName';
            }

            _diagnosticReporter.atElement2(
              errorElement,
              CompileTimeErrorCode.getterNotSubtypeSetterTypes,
              arguments: [getterName, getterType, setterType, setterName],
            );
          }
        }
      }
    }
  }

  void checkStaticGetters(List<InternalGetterElement> getters) {
    if (_skipGetterSetterTypesCheck) {
      return;
    }

    for (var getter in getters) {
      if (getter.isStatic) {
        _checkLocalGetter(getter);
      }
    }
  }

  void _checkLocalGetter(InternalGetterElement getter) {
    var name = getter.name;
    if (name == null) {
      return;
    }

    var setter = getter.variable.setter;
    if (setter == null) {
      return;
    }

    var setterType = _getSetterType(setter);
    if (setterType == null) {
      return;
    }

    var getterType = _getGetterType(getter);
    if (!_typeSystem.isSubtypeOf(getterType, setterType)) {
      _diagnosticReporter.atElement2(
        getter,
        CompileTimeErrorCode.getterNotSubtypeSetterTypes,
        arguments: [name, getterType, setterType, name],
      );
    }
  }

  /// Return the return type of the [getter].
  static TypeImpl _getGetterType(InternalGetterElement getter) {
    return getter.returnType;
  }

  /// Return the type of the first parameter of the [setter].
  static TypeImpl? _getSetterType(InternalSetterElement setter) {
    var parameters = setter.formalParameters;
    if (parameters.isNotEmpty) {
      return parameters[0].type;
    } else {
      return null;
    }
  }
}
