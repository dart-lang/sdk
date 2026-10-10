// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/codes.dart';

/// Helper for resolving properties (getters, setters, or methods).
class TypePropertyResolver {
  final TypeAnalyzer _typeAnalyzer;
  final LibraryElementImpl _definingLibrary;
  final TypeSystemImpl _typeSystem;
  final TypeProviderImpl _typeProvider;
  final ExtensionMemberResolver _extensionResolver;

  late InstanceReceiver? _receiver;
  late SyntacticEntity _nameErrorEntity;
  late String _name;
  late bool _hasRead;
  late bool _hasWrite;

  /// The failure that has already been reported, for both the getter and the
  /// setter; the lookups that follow it are only for recovery.
  LookupOutcome? _reportedOutcome;

  LookupOutcome _getterOutcome = LookupOutcome.resolved;
  InternalExecutableElement? _getterRequested;
  InternalExecutableElement? _getterRecovery;

  LookupOutcome _setterOutcome = LookupOutcome.resolved;
  InternalExecutableElement? _setterRequested;
  InternalExecutableElement? _setterRecovery;

  TypePropertyResolver(this._typeAnalyzer)
    : _definingLibrary = _typeAnalyzer.definingLibrary,
      _typeSystem = _typeAnalyzer.typeSystem,
      _typeProvider = _typeAnalyzer.typeProvider,
      _extensionResolver = _typeAnalyzer.extensionResolver;

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
    required InstanceReceiverImpl? receiver,
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
      _getterOutcome = LookupOutcome.notFound;
      _setterOutcome = LookupOutcome.notFound;
      return _toResult();
    }

    if (_typeSystem.isDynamicBounded(receiverType) ||
        _typeSystem.isInvalidBounded(receiverType)) {
      _lookupInterfaceType(_typeProvider.objectType, recoverWithStatic: false);
      _getterOutcome = LookupOutcome.resolved;
      _setterOutcome = LookupOutcome.resolved;
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
          parentNode = receiver.parent2;
        } else if (propertyErrorEntity is AstNode) {
          parentNode = propertyErrorEntity.parent2;
        } else {
          throw StateError(
            'Either `receiver` must be non-null or '
            '`propertyErrorEntity` must be an AstNode to report an unchecked '
            'invocation of a nullable value.',
          );
        }
      }

      LocatableDiagnostic locatableDiagnostic;
      if (parentNode == null) {
        locatableDiagnostic = diag.uncheckedInvocationOfNullableValue;
      } else {
        if (parentNode is CascadeExpression) {
          parentNode = parentNode.sections.first.body;
        }
        if (parentNode is BinaryOperatorInvocation ||
            parentNode is RelationalPattern) {
          locatableDiagnostic = diag.uncheckedOperatorInvocationOfNullableValue
              .withArguments(operator: name);
        } else if (parentNode is ParsedValueArguments ||
            parentNode is NamedFunctionInvocation ||
            parentNode is MethodReferenceExpression ||
            parentNode is CompoundAssignment ||
            parentNode is IndexAssignmentTarget ||
            parentNode is IndexExpression2 ||
            parentNode is IncrementOrDecrementExpression ||
            parentNode is UnaryOperatorInvocation) {
          locatableDiagnostic = diag.uncheckedMethodInvocationOfNullableValue
              .withArguments(name: name);
        } else if (parentNode is CallInvocation) {
          locatableDiagnostic = diag.uncheckedInvocationOfNullableValue;
        } else {
          locatableDiagnostic = diag.uncheckedPropertyAccessOfNullableValue
              .withArguments(name: name);
        }
      }

      List<DiagnosticMessage> messages = [];
      var flow = _typeAnalyzer.flowAnalysis.flow;
      if (flow != null) {
        if (receiver is ExpressionImpl) {
          messages = _typeAnalyzer.computeWhyNotPromotedMessages(
            nameErrorEntity,
            flow.whyNotPromoted(
              _typeAnalyzer.flowAnalysis.getExpressionInfo(receiver),
            )(),
          );
        } else {
          var thisType = _typeAnalyzer.unpromotedThisType;
          if (thisType != null) {
            messages = _typeAnalyzer.computeWhyNotPromotedMessages(
              nameErrorEntity,
              flow.whyNotPromotedImplicitThis()(),
            );
          }
        }
      }
      _typeAnalyzer.nullableDereferenceVerifier.report(
        locatableDiagnostic,
        propertyErrorEntity,
        receiverType,
        messages: messages,
      );
      _reportedOutcome = LookupOutcome.nullableReceiver;

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
          _getterOutcome = LookupOutcome.resolved;
          _setterOutcome = LookupOutcome.resolved;
          return _toResult();
        }
      }

      if (receiverTypeResolved is FunctionTypeImpl &&
          _name == MethodElement.CALL_METHOD_NAME) {
        return ResolutionResult(
          getterOutcome: LookupOutcome.resolved,
          setterOutcome: LookupOutcome.resolved,
          callFunctionType: receiverTypeResolved,
        );
      }

      if (receiverTypeResolved is NeverType) {
        _lookupInterfaceType(_typeProvider.objectType);
        _getterOutcome = LookupOutcome.resolved;
        _setterOutcome = LookupOutcome.resolved;
        return _toResult();
      }

      if (receiverTypeResolved is RecordTypeImpl) {
        var field = receiverTypeResolved.fieldByName(name);
        if (field != null) {
          return ResolutionResult(
            recordField: field,
            getterOutcome: LookupOutcome.resolved,
          );
        }
        _getterOutcome = LookupOutcome.notFound;
        _setterOutcome = LookupOutcome.notFound;
      }

      _lookupExtension(receiverType);
      if (_hasGetterOrSetter) {
        return _toResult();
      }

      _lookupInterfaceType(_typeProvider.objectType);

      return _toResult();
    }
  }

  /// Resolve static invocations for [declaration].
  ResolutionResult resolveStaticExtension({
    required InterfaceElement declaration,
    required String name,
    required bool hasRead,
    required bool hasWrite,
    required SyntacticEntity propertyErrorEntity,
    required SyntacticEntity nameErrorEntity,
    AstNode? parentNode,
  }) {
    _name = name;
    _hasRead = hasRead;
    _hasWrite = hasWrite;
    _nameErrorEntity = nameErrorEntity;
    _resetResult();

    var memberName = Name(_definingLibrary.uri, _name);
    var result = _extensionResolver.findStaticExtension(
      declaration,
      _nameErrorEntity,
      memberName,
    );

    if (result == const AmbiguousStaticExtensionResolutionError()) {
      _reportedOutcome = LookupOutcome.ambiguousExtensions;
    }

    var outcome = LookupOutcome.of(result.member);
    _getterOutcome = outcome;
    _setterOutcome = outcome;

    if (result.member != null && hasRead) {
      _getterRequested = result.member;
    }

    if (result.member != null && hasWrite) {
      _setterRequested = result.member;
    }

    return _toResult();
  }

  void _lookupExtension(TypeImpl type) {
    var getterName = Name(_definingLibrary.uri, _name);
    var result = _extensionResolver.findExtension(
      type,
      _nameErrorEntity,
      getterName,
    );
    if (result == ExtensionResolutionError.ambiguous) {
      _reportedOutcome = LookupOutcome.ambiguousExtensions;
    }

    if (result.getter2 != null) {
      _getterOutcome = LookupOutcome.resolved;
      _getterRequested = result.getter2;
    }

    if (result.setter2 != null) {
      _setterOutcome = LookupOutcome.resolved;
      _setterRequested = result.setter2;
    }
  }

  void _lookupInterfaceType(
    InterfaceTypeImpl type, {
    bool recoverWithStatic = true,
  }) {
    var isSuper = _receiver is SuperReference;

    if (_hasRead) {
      var getterName = Name(_definingLibrary.uri, _name);
      _getterRequested = _typeAnalyzer.inheritance.getMember3(
        type,
        getterName,
        forSuper: isSuper,
      );
      _getterOutcome = LookupOutcome.of(_getterRequested);

      if (_getterRequested == null && recoverWithStatic) {
        var classElement = type.element;
        _getterRecovery ??=
            classElement.lookupStaticGetter(_name, _definingLibrary) ??
            classElement.lookupStaticMethod(_name, _definingLibrary);
        _getterOutcome = LookupOutcome.of(_getterRecovery);
      }
    }

    if (_hasWrite) {
      var setterName = Name(_definingLibrary.uri, '$_name=');
      _setterRequested = _typeAnalyzer.inheritance.getMember3(
        type,
        setterName,
        forSuper: isSuper,
      );
      _setterOutcome = LookupOutcome.of(_setterRequested);

      if (_setterRequested == null && recoverWithStatic) {
        var classElement = type.element;
        _setterRecovery ??= classElement.lookupStaticSetter(
          _name,
          _definingLibrary,
        );
        _setterOutcome = LookupOutcome.of(_setterRecovery);
      }
    }

    // If we wanted a getter, but it is not in the interface, then check
    // if there is the setter, i.e. the basename at all. If there is, we
    // should not check extensions.
    if (_hasRead && _getterRequested == null) {
      var setterName = Name(_definingLibrary.uri, '$_name=');
      _setterRequested = _typeAnalyzer.inheritance.getMember3(
        type,
        setterName,
        forSuper: isSuper,
      );
    }

    if (_hasWrite && _setterRequested == null) {
      var getterName = Name(_definingLibrary.uri, _name);
      _getterRequested = _typeAnalyzer.inheritance.getMember3(
        type,
        getterName,
        forSuper: isSuper,
      );
    }
  }

  void _resetResult() {
    _reportedOutcome = null;

    _getterOutcome = LookupOutcome.resolved;
    _getterRequested = null;
    _getterRecovery = null;

    _setterOutcome = LookupOutcome.resolved;
    _setterRequested = null;
    _setterRecovery = null;
  }

  ResolutionResult _toResult() {
    var getter = _getterRequested ?? _getterRecovery;
    var setter = _setterRequested ?? _setterRecovery;

    var getterOutcome = _reportedOutcome ?? _getterOutcome;
    if (getterOutcome == LookupOutcome.notFound && _name.isEmpty) {
      getterOutcome = LookupOutcome.missingName;
    }

    return ResolutionResult(
      getter2: getter,
      getterOutcome: getterOutcome,
      setter2: setter,
      setterOutcome: _reportedOutcome ?? _setterOutcome,
    );
  }
}
