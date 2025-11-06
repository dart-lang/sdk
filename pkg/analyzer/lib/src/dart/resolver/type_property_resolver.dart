// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving properties (getters, setters, or methods).
class TypePropertyResolver {
  final ResolverVisitor _resolver;
  final LibraryElementImpl _definingLibrary;
  final TypeSystemImpl _typeSystem;
  final TypeProviderImpl _typeProvider;
  final ExtensionMemberResolver _extensionResolver;

  late Expression? _receiver;
  late SyntacticEntity _nameErrorEntity;
  late String _name;
  late bool _hasRead;
  late bool _hasWrite;

  bool _needsGetterError = false;
  bool _reportedGetterError = false;
  InternalExecutableElement? _getterRequested;
  InternalExecutableElement? _getterRecovery;

  bool _needsSetterError = false;
  bool _reportedSetterError = false;
  InternalExecutableElement? _setterRequested;
  InternalExecutableElement? _setterRecovery;

  TypePropertyResolver(this._resolver)
    : _definingLibrary = _resolver.definingLibrary,
      _typeSystem = _resolver.typeSystem,
      _typeProvider = _resolver.typeProvider,
      _extensionResolver = _resolver.extensionResolver;

  bool get _hasGetterOrSetter {
    return _getterRequested != null || _setterRequested != null;
  }

  /// Look up the property with the given [name] in the [receiverType].
  ///
  /// The [receiver] might be `null`, used to identify `super`.
  ///
  /// The [propertyErrorEntity] is the node to report nullable dereference,
  /// if the [receiverType] is potentially nullable.
  ///
  /// The [nameErrorEntity] is used to report an ambiguous extension issue.
  ResolutionResult resolve({
    required ExpressionImpl? receiver,
    required TypeImpl receiverType,
    required String name,
    required bool hasRead,
    required bool hasWrite,
    required SyntacticEntity propertyErrorEntity,
    required SyntacticEntity nameErrorEntity,
    AstNode? parentNode,
  }) {
    _receiver = receiver;
    _name = name;
    _hasRead = hasRead;
    _hasWrite = hasWrite;
    _nameErrorEntity = nameErrorEntity;
    _resetResult();

    if (name == 'new') {
      _needsGetterError = true;
      _needsSetterError = true;
      return _toResult();
    }

    if (_typeSystem.isDynamicBounded(receiverType) ||
        _typeSystem.isInvalidBounded(receiverType)) {
      _lookupInterfaceType(_typeProvider.objectType, recoverWithStatic: false);
      _needsGetterError = false;
      _needsSetterError = false;
      return _toResult();
    }

    bool isNullable;
    if (receiverType.isExtensionType) {
      isNullable = receiverType.nullabilitySuffix == NullabilitySuffix.question;
    } else {
      isNullable = _typeSystem.isPotentiallyNullable(receiverType);
    }

    if (isNullable) {
      _lookupInterfaceType(_typeProvider.objectType);
      if (_hasGetterOrSetter) {
        return _toResult();
      }

      _lookupExtension(receiverType);
      if (_hasGetterOrSetter) {
        return _toResult();
      }

      if (parentNode == null) {
        if (receiver != null) {
          parentNode = receiver.parent;
        } else if (propertyErrorEntity is AstNode) {
          parentNode = propertyErrorEntity.parent;
        } else {
          throw StateError(
            'Either `receiver` must be non-null or '
            '`propertyErrorEntity` must be an AstNode to report an unchecked '
            'invocation of a nullable value.',
          );
        }
      }

      CompileTimeErrorCode errorCode;
      List<String> arguments;
      if (parentNode == null) {
        errorCode = CompileTimeErrorCode.uncheckedInvocationOfNullableValue;
        arguments = [];
      } else {
        if (parentNode is CascadeExpression) {
          parentNode = parentNode.cascadeSections.first;
        }
        if (parentNode is BinaryExpression || parentNode is RelationalPattern) {
          errorCode =
              CompileTimeErrorCode.uncheckedOperatorInvocationOfNullableValue;
          arguments = [name];
        } else if (parentNode is MethodInvocation ||
            parentNode is MethodReferenceExpression) {
          errorCode =
              CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue;
          arguments = [name];
        } else if (parentNode is FunctionExpressionInvocation) {
          errorCode = CompileTimeErrorCode.uncheckedInvocationOfNullableValue;
          arguments = [];
        } else {
          errorCode =
              CompileTimeErrorCode.uncheckedPropertyAccessOfNullableValue;
          arguments = [name];
        }
      }

      List<DiagnosticMessage> messages = [];
      var flow = _resolver.flowAnalysis.flow;
      if (flow != null) {
        if (receiver != null) {
          messages = _resolver.computeWhyNotPromotedMessages(
            nameErrorEntity,
            flow.whyNotPromoted(receiver)(),
          );
        } else {
          var thisType = _resolver.thisType;
          if (thisType != null) {
            messages = _resolver.computeWhyNotPromotedMessages(
              nameErrorEntity,
              flow.whyNotPromotedImplicitThis(SharedTypeView(thisType))(),
            );
          }
        }
      }
      _resolver.nullableDereferenceVerifier.report(
        errorCode,
        propertyErrorEntity,
        receiverType,
        arguments: arguments,
        messages: messages,
      );
      _reportedGetterError = true;
      _reportedSetterError = true;

      // Recovery, get some resolution.
      receiverType = _typeSystem.resolveToBound(receiverType);
      if (receiverType is InterfaceTypeImpl) {
        _lookupInterfaceType(receiverType);
      }

      return _toResult();
    } else {
      var receiverTypeResolved = _typeSystem.resolveToBound(receiverType);

      if (receiverTypeResolved is InterfaceTypeImpl) {
        _lookupInterfaceType(receiverTypeResolved);
        if (_hasGetterOrSetter) {
          return _toResult();
        }
        if (receiverTypeResolved.isDartCoreFunction &&
            _name == MethodElement.CALL_METHOD_NAME) {
          _needsGetterError = false;
          _needsSetterError = false;
          return _toResult();
        }
      }

      if (receiverTypeResolved is FunctionTypeImpl &&
          _name == MethodElement.CALL_METHOD_NAME) {
        return ResolutionResult(
          needsGetterError: false,
          needsSetterError: false,
          callFunctionType: receiverTypeResolved,
        );
      }

      if (receiverTypeResolved is NeverType) {
        _lookupInterfaceType(_typeProvider.objectType);
        _needsGetterError = false;
        _needsSetterError = false;
        return _toResult();
      }

      if (receiverTypeResolved is RecordTypeImpl) {
        var field = receiverTypeResolved.fieldByName(name);
        if (field != null) {
          return ResolutionResult(recordField: field, needsGetterError: false);
        }
        _needsGetterError = true;
        _needsSetterError = true;
      }

      _lookupExtension(receiverType);
      if (_hasGetterOrSetter) {
        return _toResult();
      }

      _lookupInterfaceType(_typeProvider.objectType);

      return _toResult();
    }
  }

  void _lookupExtension(TypeImpl type) {
    var getterName = Name(_definingLibrary.uri, _name);
    var result = _extensionResolver.findExtension(
      type,
      _nameErrorEntity,
      getterName,
    );
    _reportedGetterError = result == ExtensionResolutionError.ambiguous;
    _reportedSetterError = result == ExtensionResolutionError.ambiguous;

    if (result.getter2 != null) {
      _needsGetterError = false;
      _getterRequested = result.getter2;
    }

    if (result.setter2 != null) {
      _needsSetterError = false;
      _setterRequested = result.setter2;
    }
  }

  void _lookupInterfaceType(
    InterfaceTypeImpl type, {
    bool recoverWithStatic = true,
  }) {
    var isSuper = _receiver is SuperExpression;

    if (_hasRead) {
      var getterName = Name(_definingLibrary.uri, _name);
      _getterRequested = _resolver.inheritance.getMember3(
        type,
        getterName,
        forSuper: isSuper,
      );
      _needsGetterError = _getterRequested == null;

      if (_getterRequested == null && recoverWithStatic) {
        var classElement = type.element;
        _getterRecovery ??=
            classElement.lookupStaticGetter(_name, _definingLibrary) ??
            classElement.lookupStaticMethod(_name, _definingLibrary);
        _needsGetterError = _getterRecovery == null;
      }
    }

    if (_hasWrite) {
      var setterName = Name(_definingLibrary.uri, '$_name=');
      _setterRequested = _resolver.inheritance.getMember3(
        type,
        setterName,
        forSuper: isSuper,
      );
      _needsSetterError = _setterRequested == null;

      if (_setterRequested == null && recoverWithStatic) {
        var classElement = type.element;
        _setterRecovery ??= classElement.lookupStaticSetter(
          _name,
          _definingLibrary,
        );
        _needsSetterError = _setterRecovery == null;
      }
    }

    // If we wanted a getter, but it is not in the interface, then check
    // if there is the setter, i.e. the basename at all. If there is, we
    // should not check extensions.
    if (_hasRead && _getterRequested == null) {
      var setterName = Name(_definingLibrary.uri, '$_name=');
      _setterRequested = _resolver.inheritance.getMember3(
        type,
        setterName,
        forSuper: isSuper,
      );
    }

    if (_hasWrite && _setterRequested == null) {
      var getterName = Name(_definingLibrary.uri, _name);
      _getterRequested = _resolver.inheritance.getMember3(
        type,
        getterName,
        forSuper: isSuper,
      );
    }
  }

  void _resetResult() {
    _needsGetterError = false;
    _reportedGetterError = false;
    _getterRequested = null;
    _getterRecovery = null;

    _needsSetterError = false;
    _reportedSetterError = false;
    _setterRequested = null;
    _setterRecovery = null;
  }

  ResolutionResult _toResult() {
    var getter = _getterRequested ?? _getterRecovery;
    var setter = _setterRequested ?? _setterRecovery;

    return ResolutionResult(
      getter2: getter,
      // Parser recovery resulting in an empty property name should not be
      // reported as an undefined getter.
      needsGetterError:
          _needsGetterError && _name.isNotEmpty && !_reportedGetterError,
      isGetterInvalid: _needsGetterError || _reportedGetterError,
      setter2: setter,
      needsSetterError: _needsSetterError && !_reportedSetterError,
    );
  }
}
