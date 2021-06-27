// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
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
  })   : _typeSystem = typeSystem,
        _errorReporter = errorReporter;

  ErrorCode get _errorCode {
    return _isNonNullableByDefault
        ? CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES
        : CompileTimeErrorCode.GETTER_NOT_ASSIGNABLE_SETTER_TYPES;
  }

  bool get _isNonNullableByDefault => _typeSystem.isNonNullableByDefault;

  void checkExtension(ExtensionDeclaration node) {
    for (var getterNode in node.members) {
      if (getterNode is MethodDeclaration && getterNode.isGetter) {
        checkGetter(getterNode.name,
            getterNode.declaredElement as PropertyAccessorElement);
      }
    }
  }

  void checkGetter(
    SimpleIdentifier nameNode,
    PropertyAccessorElement getter,
  ) {
    assert(getter.isGetter);

    var setter = getter.correspondingSetter;
    if (setter == null) {
      return;
    }

    var getterType = _getGetterType(getter);
    var setterType = _getSetterType(setter);
    if (setterType == null) {
      return;
    }

    if (!_match(getterType, setterType)) {
      var name = nameNode.name;
      _errorReporter.reportErrorForNode(
        _errorCode,
        nameNode,
        [name, getterType, setterType, name],
      );
    }
  }

  void checkInterface(ClassElement classElement, Interface interface) {
    var libraryUri = classElement.library.source.uri;

    for (var name in interface.map.keys) {
      if (!name.isAccessibleFor(libraryUri)) continue;

      var getter = interface.map[name]!;
      if (getter.kind == ElementKind.GETTER) {
        var setter = interface.map[Name(libraryUri, '${name.name}=')];
        if (setter != null && setter.parameters.length == 1) {
          var getterType = getter.returnType;
          var setterType = setter.parameters[0].type;
          if (!_match(getterType, setterType)) {
            Element errorElement;
            if (getter.enclosingElement == classElement) {
              errorElement = getter;
            } else if (setter.enclosingElement == classElement) {
              errorElement = setter;
            } else {
              errorElement = classElement;
            }

            var getterName = getter.displayName;
            if (getter.enclosingElement != classElement) {
              var getterClassName = getter.enclosingElement.displayName;
              getterName = '$getterClassName.$getterName';
            }

            var setterName = setter.displayName;
            if (setter.enclosingElement != classElement) {
              var setterClassName = setter.enclosingElement.displayName;
              setterName = '$setterClassName.$setterName';
            }

            _errorReporter.reportErrorForElement(
              _errorCode,
              errorElement,
              [getterName, getterType, setterType, setterName],
            );
          }
        }
      }
    }
  }

  bool _match(DartType getterType, DartType setterType) {
    return _isNonNullableByDefault
        ? _typeSystem.isSubtypeOf(getterType, setterType)
        : _typeSystem.isAssignableTo(getterType, setterType);
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
