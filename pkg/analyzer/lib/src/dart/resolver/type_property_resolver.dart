// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:meta/meta.dart';

/// Helper for resolving properties (getters, setters, or methods).
class TypePropertyResolver {
  final ResolverVisitor _resolver;
  final LibraryElement _definingLibrary;
  final bool _isNonNullableByDefault;
  final TypeSystemImpl _typeSystem;
  final TypeProviderImpl _typeProvider;
  final ExtensionMemberResolver _extensionResolver;

  Expression _receiver;
  String _name;
  AstNode _nameErrorNode;

  ResolutionResult _result = ResolutionResult.none;

  TypePropertyResolver(this._resolver)
      : _definingLibrary = _resolver.definingLibrary,
        _isNonNullableByDefault = _resolver.typeSystem.isNonNullableByDefault,
        _typeSystem = _resolver.typeSystem,
        _typeProvider = _resolver.typeProvider,
        _extensionResolver = _resolver.extensionResolver;

  /// Look up the property with the given [name] in the [receiverType].
  ///
  /// The [receiver] might be `null`, used to identify `super`.
  ///
  /// The [receiverErrorNode] is the node to report nullable dereference,
  /// if the [receiverType] is potentially nullable.
  ///
  /// The [nameErrorNode] is used to report the ambiguous extension issue.
  ResolutionResult resolve({
    @required Expression receiver,
    @required DartType receiverType,
    @required String name,
    @required AstNode receiverErrorNode,
    @required Expression nameErrorNode,
  }) {
    _receiver = receiver;
    _name = name;
    _nameErrorNode = nameErrorNode;
    _result = ResolutionResult.none;

    receiverType = _resolveTypeParameter(receiverType);

    if (_isNonNullableByDefault &&
        _typeSystem.isPotentiallyNullable(receiverType)) {
      _lookupExtension(receiverType);

      if (_result.isNone) {
        _lookupInterfaceType(_typeProvider.objectType);
      }

      if (_result.isNone && !receiverType.isDynamic) {
        _resolver.nullableDereferenceVerifier.report(
          receiverErrorNode,
          receiverType,
        );
        // Recovery, get some resolution.
        _lookupType(receiverType);
      }

      _toLegacy();
      return _result;
    } else {
      _lookupType(receiverType);

      if (_result.isNone) {
        _lookupExtension(receiverType);
      }

      if (_result.isNone) {
        _lookupInterfaceType(_typeProvider.objectType);
      }

      _toLegacy();
      return _result;
    }
  }

  void _lookupExtension(DartType type) {
    _result = _extensionResolver.findExtension(type, _name, _nameErrorNode);
  }

  void _lookupInterfaceType(InterfaceType type) {
    var isSuper = _receiver is SuperExpression;

    ExecutableElement typeGetter;
    ExecutableElement typeSetter;

    if (_name == '[]') {
      typeGetter = type.lookUpMethod2(
        '[]',
        _definingLibrary,
        concrete: isSuper,
        inherited: isSuper,
      );

      typeSetter = type.lookUpMethod2(
        '[]=',
        _definingLibrary,
        concrete: isSuper,
        inherited: isSuper,
      );
    } else {
      var classElement = type.element as AbstractClassElementImpl;
      var getterName = Name(_definingLibrary.source.uri, _name);
      var setterName = Name(_definingLibrary.source.uri, '$_name=');
      typeGetter = _resolver.inheritance
              .getMember(type, getterName, forSuper: isSuper) ??
          classElement.lookupStaticGetter(_name, _definingLibrary) ??
          classElement.lookupStaticMethod(_name, _definingLibrary);
      typeSetter = _resolver.inheritance
              .getMember(type, setterName, forSuper: isSuper) ??
          classElement.lookupStaticSetter(_name, _definingLibrary);
    }

    if (typeGetter != null || typeSetter != null) {
      _result = ResolutionResult(getter: typeGetter, setter: typeSetter);
    }
  }

  void _lookupType(DartType type) {
    if (type is InterfaceType) {
      _lookupInterfaceType(type);
    } else if (type is FunctionType) {
      _lookupInterfaceType(_typeProvider.functionType);
    }
  }

  /// If the given [type] is a type parameter, replace it with its bound.
  /// Otherwise, return the original type.
  DartType _resolveTypeParameter(DartType type) {
    return type?.resolveToBound(_typeProvider.objectType);
  }

  void _toLegacy() {
    if (_result.isSingle) {
      _result = ResolutionResult(
        getter: _resolver.toLegacyElement(_result.getter),
        setter: _resolver.toLegacyElement(_result.setter),
      );
    }
  }
}
