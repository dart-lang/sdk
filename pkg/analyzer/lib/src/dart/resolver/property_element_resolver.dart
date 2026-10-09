// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/lexical_lookup.dart';
import 'package:analyzer/src/dart/resolver/this_lookup.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/error/lookup_failure_reporter.dart';
import 'package:analyzer/src/generated/scope_helpers.dart';
import 'package:analyzer/src/generated/super_context.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

class PropertyElementResolver with ScopeHelpers {
  final TypeAnalyzer _typeAnalyzer;

  PropertyElementResolver(this._typeAnalyzer);

  @override
  DiagnosticReporter get diagnosticReporter => _typeAnalyzer.diagnosticReporter;

  LibraryElementImpl get _definingLibrary => _typeAnalyzer.definingLibrary;

  ExtensionMemberResolver get _extensionResolver =>
      _typeAnalyzer.extensionResolver;

  LookupFailureReporter get _lookupFailureReporter =>
      _typeAnalyzer.lookupFailureReporter;

  TypeSystemImpl get _typeSystem => _typeAnalyzer.typeSystem;

  ({IndexReadResolutionImpl? read, IndexWriteResolutionImpl? write})?
  resolveCascadeIndex({
    required AstNode node,
    required InstanceReceiverImpl receiver,
    required bool isNullAware,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (receiver is ExtensionOverride2Impl) {
      var result = _extensionResolver.getOverrideMember(receiver, '[]');
      var readElement = result.getter2;
      var writeElement = result.setter2;
      if (result != ExtensionResolutionError.ambiguous) {
        // `[]` is evaluated first, so a missing `[]` takes precedence.
        if (hasRead && readElement == null) {
          _reportUnresolvedIndex(
            node,
            diag.undefinedExtensionOperator.withArguments(
              operator: '[]',
              extensionName: receiver.element.name!,
            ),
          );
        } else if (hasWrite && writeElement == null) {
          _reportUnresolvedIndex(
            node,
            diag.undefinedExtensionOperator.withArguments(
              operator: '[]=',
              extensionName: receiver.element.name!,
            ),
          );
        }
      }
      return (
        read: hasRead
            ? _createIndexReadResolution(
                readElement,
                atDynamicTarget: false,
                isInvalid: readElement == null,
              )
            : null,
        write: hasWrite
            ? _createIndexWriteResolution(
                writeElement,
                atDynamicTarget: false,
                isInvalid: writeElement == null,
              )
            : null,
      );
    }

    var receiverType = _typeSystem.resolveToBound(
      _typeAnalyzer.instanceReceiverType(receiver),
    );
    if (identical(receiverType, NeverTypeImpl.instance)) {
      diagnosticReporter.report(diag.receiverOfTypeNever.at(receiver));
      return null;
    }
    if (isNullAware) {
      if (_typeSystem.isNull(receiverType)) {
        return null;
      }
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }
    if (receiverType is DynamicType) {
      return (
        read: hasRead ? const DynamicIndexReadResolutionImpl() : null,
        write: hasWrite ? const DynamicIndexWriteResolutionImpl() : null,
      );
    }
    if (receiverType is VoidType) {
      _reportUnresolvedIndex(node, diag.useOfVoidResult);
      return (
        read: hasRead
            ? InvalidIndexReadResolutionImpl(recoveryElement: null)
            : null,
        write: hasWrite
            ? InvalidIndexWriteResolutionImpl(recoveryElement: null)
            : null,
      );
    }

    var result = _typeAnalyzer.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: '[]',
      hasRead: hasRead,
      hasWrite: hasWrite,
      propertyErrorEntity: switch (node) {
        CascadeIndexExpression(:var leftBracket) => leftBracket,
        CascadeIndexAssignmentTarget(:var leftBracket) => leftBracket,
        _ => node,
      },
      nameErrorEntity: receiver,
      parentNode: node,
    );
    if (hasRead && result.needsGetterError) {
      _reportUnresolvedIndex(
        node,
        (receiver is SuperReference
                ? diag.undefinedSuperOperator
                : diag.undefinedOperator)
            .withArguments(operator: '[]', type: receiverType),
      );
    }
    if (hasWrite && result.needsSetterError) {
      _reportUnresolvedIndex(
        node,
        (receiver is SuperReference
                ? diag.undefinedSuperOperator
                : diag.undefinedOperator)
            .withArguments(operator: '[]=', type: receiverType),
      );
    }
    var isReceiverInvalid = receiverType is InvalidType;
    return (
      read: hasRead
          ? _createIndexReadResolution(
              result.getter2,
              atDynamicTarget: false,
              isInvalid: result.needsGetterError || isReceiverInvalid,
            )
          : null,
      write: hasWrite
          ? _createIndexWriteResolution(
              result.setter2,
              atDynamicTarget: false,
              isInvalid: result.needsSetterError || isReceiverInvalid,
            )
          : null,
    );
  }

  ({
    NamedReadResolutionImpl? read,
    NamedWriteResolutionImpl? write,
    ExpressionInfo? readExpressionInfo,
  })?
  resolveCascadeProperty({
    required ExpressionImpl node,
    required InstanceReceiverImpl receiver,
    required bool isNullAware,
    required Token propertyName,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (receiver is ExpressionImpl) {
      var receiverType = _typeSystem.resolveToBound(receiver.typeOrThrow);
      if (receiverType is NeverType &&
          receiverType.nullabilitySuffix == NullabilitySuffix.none) {
        diagnosticReporter.report(diag.receiverOfTypeNever.at(receiver));
        return null;
      }
      if (isNullAware && _typeSystem.isNull(receiverType)) {
        return null;
      }
    }

    var result = switch (receiver) {
      ExpressionImpl() => _resolve(
        node: node,
        target: receiver,
        isCascaded: true,
        isNullAware: isNullAware,
        propertyName: propertyName,
        hasRead: hasRead,
        hasWrite: hasWrite,
      ),
      ExtensionOverride2Impl() => _resolveTargetExtensionOverride(
        target: receiver,
        propertyName: propertyName,
        hasRead: hasRead,
        hasWrite: hasWrite,
      ),
      SuperReferenceImpl() => throw StateError(
        'A cascade receiver cannot be a super reference.',
      ),
    };

    var readElement = result.readElement2;
    var writeElement = result.writeElement2;
    NamedReadResolutionImpl? read;
    if (hasRead) {
      var functionCallTearOffResolution = switch (result.functionTypeCallType) {
        TypeImpl type => _functionCallTearOffResolution(
          receiverType: type,
          isCall: true,
          callFunctionType: result.callFunctionType,
        ),
        _ => null,
      };
      read =
          functionCallTearOffResolution ??
          (result.atDynamicTarget
              ? DynamicPropertyReadResolutionImpl()
              : _createPropertyReadResolution(
                      element: readElement,
                      recordField: result.recordField,
                      type: result.getType as TypeImpl?,
                    ) ??
                    InvalidNamedReadResolutionImpl(
                      recoveryElement:
                          readElement ??
                          result.readElementRecovery2 ??
                          writeElement,
                    ));
    }

    NamedWriteResolutionImpl? write;
    if (hasWrite) {
      write = result.atDynamicTarget
          ? const DynamicPropertyWriteResolutionImpl()
          : _createNamedWriteResolutionWithElement(writeElement) ??
                InvalidNamedWriteResolutionImpl(
                  recoveryElement:
                      writeElement ??
                      result.writeElementRecovery2 ??
                      readElement,
                );
    }

    return (
      read: read,
      write: write,
      readExpressionInfo: hasRead
          ? _typeAnalyzer.flowAnalysis.flow == null
                ? null
                : _typeAnalyzer.flowAnalysis.getExpressionInfo(node)
          : null,
    );
  }

  NamedReadResolutionImpl resolveDotShorthand(
    DotShorthandNameExpressionImpl node, {
    required TypeImpl contextType,
    required DotShorthandContextResolutionImpl shorthandContext,
  }) {
    if (shorthandContext case ValidDotShorthandContextResolutionImpl(
      lookupType: var context,
    )) {
      // Find constructor tearoffs.
      var element = context.lookUpConstructor(
        node.name.lexeme,
        _definingLibrary,
      );
      if (element != null) {
        if (!element.isFactory) {
          var enclosingElement = element.enclosingElement;
          if (enclosingElement is ClassElementImpl &&
              enclosingElement.isAbstract) {
            _typeAnalyzer.diagnosticReporter.report(
              diag.tearoffOfGenerativeConstructorOfAbstractClass.at(node),
            );
          }
        }

        // Infer type parameters.
        var elementToInfer = _typeAnalyzer.inferenceHelper
            .constructorElementToInfer(
              typeElement: context.element,
              constructorName: node.name,
              definingLibrary: _typeAnalyzer.definingLibrary,
            );
        if (elementToInfer != null &&
            elementToInfer.typeParameters.isNotEmpty) {
          var inferred =
              _typeAnalyzer.inferenceHelper.inferTearOff(
                    node,
                    elementToInfer.asType,
                    contextType: contextType,
                  )
                  as FunctionType;
          var inferredType = inferred.returnType;
          var constructorElement = SubstitutedConstructorElementImpl.from2(
            elementToInfer.element.baseElement,
            inferredType as InterfaceType,
          );
          return ExecutableTearOffResolutionImpl(element: constructorElement);
        }

        return ExecutableTearOffResolutionImpl(element: element);
      }

      // Didn't find any constructor tearoffs, look for static getters.
      var contextElement = context.element;
      var result = _resolveTargetInterfaceElement(
        typeReference: contextElement,
        isCascaded: false,
        propertyName: node.name,
        hasRead: true,
        hasWrite: false,
        dotShorthandContext: shorthandContext,
      );
      return _dotShorthandReadResolution(result);
    }

    diagnosticReporter.report(diag.dotShorthandMissingContext.at(node));
    return InvalidNamedReadResolutionImpl(recoveryElement: null);
  }

  void resolveImportPrefixedAssignmentTarget(
    ImportPrefixedAssignmentTargetImpl node,
  ) {
    var hasRead = node.hasRead;
    var result = _resolveTargetPrefixElement(
      target: node.importPrefix.element as PrefixElementImpl,
      nameToken: node.name,
      hasRead: hasRead,
      hasWrite: true,
    );
    if (hasRead) {
      var resolution = _propertyReadWriteTargetResult(result);
      node.read = resolution.read;
      node.write = resolution.write;
    } else {
      node.read = null;
      node.write =
          _createNamedWriteResolutionWithElement(result.writeElement2) ??
          InvalidNamedWriteResolutionImpl(
            recoveryElement: result.writeElement2 ?? result.readElement2,
          );
    }
  }

  NamedReadResolutionImpl resolveImportPrefixedNameExpression(
    ImportPrefixedNameExpressionImpl node,
  ) {
    var prefix = node.importPrefix;
    var prefixElement = prefix.element as PrefixElementImpl;

    var result = _resolveTargetPrefixElement(
      target: prefixElement,
      nameToken: node.name,
      hasRead: true,
      hasWrite: false,
    );
    var element = result.readElementRequested2;
    if (element is ExtensionElement) {
      diagnosticReporter.report(
        diag.extensionAsExpression
            .withArguments(
              name:
                  '${node.importPrefix.name.lexeme}'
                  '${node.importPrefix.period.lexeme}'
                  '${node.name.lexeme}',
            )
            .at(node),
      );
    }
    var recoveryElement = result.readElementRecovery2;
    if (element == null) {
      recoveryElement ??= result.writeElementRequested2;
    }
    return _createNamedReadResolutionWithElement(
          element,
          type: result.getType as TypeImpl? ?? _namedReadType(element),
        ) ??
        InvalidNamedReadResolutionImpl(
          recoveryElement: element ?? recoveryElement,
        );
  }

  IndexWriteResolutionImpl? resolveIndexDirectAssignmentTarget(
    ReceiverIndexAssignmentTargetImpl node,
  ) {
    var receiver = node.receiver;

    if (receiver is ExtensionOverride2Impl) {
      var result = _extensionResolver.getOverrideMember(receiver, '[]');
      var writeElement = result.setter2;
      var isInvalid = writeElement == null;
      if (isInvalid && result != ExtensionResolutionError.ambiguous) {
        _reportUnresolvedIndex(
          node,
          diag.undefinedExtensionOperator.withArguments(
            operator: '[]=',
            extensionName: receiver.element.name!,
          ),
        );
      }
      return _createIndexWriteResolution(
        writeElement,
        atDynamicTarget: false,
        isInvalid: isInvalid,
      );
    }

    var receiverType = _typeSystem.resolveToBound(
      _typeAnalyzer.instanceReceiverType(receiver),
    );
    if (receiverType is NeverType &&
        receiverType.nullabilitySuffix == NullabilitySuffix.none) {
      diagnosticReporter.report(diag.receiverOfTypeNever.at(receiver));
      return null;
    }
    if (node.question != null) {
      if (_typeSystem.isNull(receiverType)) {
        return null;
      }
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }
    if (receiverType is DynamicType) {
      return const DynamicIndexWriteResolutionImpl();
    }
    if (receiverType is VoidType) {
      _reportUnresolvedIndex(node, diag.useOfVoidResult);
      return InvalidIndexWriteResolutionImpl(recoveryElement: null);
    }

    var result = _typeAnalyzer.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: '[]',
      hasRead: false,
      hasWrite: true,
      propertyErrorEntity: node.leftBracket,
      nameErrorEntity: receiver,
      parentNode: node,
    );
    if (result.needsSetterError) {
      _reportUnresolvedIndex(
        node,
        (receiver is SuperReference
                ? diag.undefinedSuperOperator
                : diag.undefinedOperator)
            .withArguments(operator: '[]=', type: receiverType),
      );
    }
    return _createIndexWriteResolution(
      result.setter2,
      atDynamicTarget: false,
      isInvalid: result.needsSetterError || receiverType is InvalidType,
    );
  }

  ({IndexReadResolutionImpl read, IndexWriteResolutionImpl write})?
  resolveIndexReadWriteAssignmentTarget(
    ReceiverIndexAssignmentTargetImpl node,
  ) {
    var receiver = node.receiver;

    if (receiver is ExtensionOverride2Impl) {
      var result = _extensionResolver.getOverrideMember(receiver, '[]');
      var readElement = result.getter2;
      var writeElement = result.setter2;
      var isReadInvalid = readElement == null;
      var isWriteInvalid = writeElement == null;
      if (result != ExtensionResolutionError.ambiguous) {
        // `[]` is evaluated first, so a missing `[]` takes precedence.
        if (isReadInvalid) {
          _reportUnresolvedIndex(
            node,
            diag.undefinedExtensionOperator.withArguments(
              operator: '[]',
              extensionName: receiver.element.name!,
            ),
          );
        } else if (isWriteInvalid) {
          _reportUnresolvedIndex(
            node,
            diag.undefinedExtensionOperator.withArguments(
              operator: '[]=',
              extensionName: receiver.element.name!,
            ),
          );
        }
      }
      return (
        read: _createIndexReadResolution(
          readElement,
          atDynamicTarget: false,
          isInvalid: isReadInvalid,
        ),
        write: _createIndexWriteResolution(
          writeElement,
          atDynamicTarget: false,
          isInvalid: isWriteInvalid,
        ),
      );
    }

    var receiverType = _typeSystem.resolveToBound(
      _typeAnalyzer.instanceReceiverType(receiver),
    );
    if (receiverType is NeverType &&
        receiverType.nullabilitySuffix == NullabilitySuffix.none) {
      diagnosticReporter.report(diag.receiverOfTypeNever.at(receiver));
      return null;
    }
    if (node.question != null) {
      if (_typeSystem.isNull(receiverType)) {
        return null;
      }
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }
    if (receiverType is DynamicType) {
      return (
        read: const DynamicIndexReadResolutionImpl(),
        write: const DynamicIndexWriteResolutionImpl(),
      );
    }
    if (receiverType is VoidType) {
      _reportUnresolvedIndex(node, diag.useOfVoidResult);
      return (
        read: InvalidIndexReadResolutionImpl(recoveryElement: null),
        write: InvalidIndexWriteResolutionImpl(recoveryElement: null),
      );
    }

    var result = _typeAnalyzer.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: '[]',
      hasRead: true,
      hasWrite: true,
      propertyErrorEntity: node.leftBracket,
      nameErrorEntity: receiver,
      parentNode: node,
    );
    if (result.needsGetterError) {
      _reportUnresolvedIndex(
        node,
        (receiver is SuperReference
                ? diag.undefinedSuperOperator
                : diag.undefinedOperator)
            .withArguments(operator: '[]', type: receiverType),
      );
    }
    if (receiver is SuperReference) {
      // `[]` is evaluated first, so a missing `[]` takes precedence.
      if (result.needsSetterError && !result.needsGetterError) {
        _reportUnresolvedIndex(
          node,
          diag.undefinedSuperOperator.withArguments(
            operator: '[]=',
            type: receiverType,
          ),
        );
      }
    } else if (result.needsSetterError) {
      _reportUnresolvedIndex(
        node,
        diag.undefinedOperator.withArguments(
          operator: '[]=',
          type: receiverType,
        ),
      );
    }
    var isReceiverInvalid = receiverType is InvalidType;
    return (
      read: _createIndexReadResolution(
        result.getter2,
        atDynamicTarget: false,
        isInvalid: result.needsGetterError || isReceiverInvalid,
      ),
      write: _createIndexWriteResolution(
        result.setter2,
        atDynamicTarget: false,
        isInvalid: result.needsSetterError || isReceiverInvalid,
      ),
    );
  }

  /// Resolves the read operation of an ordinary value-producing index
  /// expression.
  IndexReadResolutionImpl? resolveReceiverIndexExpression(
    ReceiverIndexExpressionImpl node,
  ) {
    var receiver = node.receiver;

    if (receiver is ExtensionOverride2Impl) {
      var result = _extensionResolver.getOverrideMember(receiver, '[]');
      var element = result.getter2;
      var isInvalid = element == null;
      if (isInvalid && result != ExtensionResolutionError.ambiguous) {
        _reportUnresolvedIndex(
          node,
          diag.undefinedExtensionOperator.withArguments(
            operator: '[]',
            extensionName: receiver.element.name!,
          ),
        );
      }
      return _createIndexReadResolution(
        element,
        atDynamicTarget: false,
        isInvalid: isInvalid,
      );
    }

    var receiverType = _typeSystem.resolveToBound(
      _typeAnalyzer.instanceReceiverType(receiver),
    );
    if (receiverType is NeverType &&
        receiverType.nullabilitySuffix == NullabilitySuffix.none) {
      diagnosticReporter.report(diag.receiverOfTypeNever.at(receiver));
      return null;
    }
    if (node.question != null) {
      if (_typeSystem.isNull(receiverType)) {
        return null;
      }
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }
    if (receiverType is DynamicType) {
      return const DynamicIndexReadResolutionImpl();
    }
    if (receiverType is VoidType) {
      _reportUnresolvedIndex(node, diag.useOfVoidResult);
      return InvalidIndexReadResolutionImpl(recoveryElement: null);
    }

    var result = _typeAnalyzer.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: '[]',
      hasRead: true,
      hasWrite: false,
      propertyErrorEntity: node.leftBracket,
      nameErrorEntity: receiver,
      parentNode: node,
    );
    if (result.needsGetterError) {
      _reportUnresolvedIndex(
        node,
        (receiver is SuperReference
                ? diag.undefinedSuperOperator
                : diag.undefinedOperator)
            .withArguments(operator: '[]', type: receiverType),
      );
    }
    return _createIndexReadResolution(
      result.getter2,
      atDynamicTarget: false,
      isInvalid: result.needsGetterError || receiverType is InvalidType,
    );
  }

  NamedWriteResolutionImpl? resolveReceiverPropertyDirectAssignmentTarget(
    ReceiverPropertyAssignmentTargetImpl node,
  ) {
    var receiver = node.receiver;
    switch (receiver) {
      case SuperReferenceImpl():
        var result = _resolveTargetSuperReference(
          node: node,
          target: receiver,
          propertyName: node.name,
          hasRead: false,
          hasWrite: true,
        );
        return _createNamedWriteResolutionWithElement(
              result.writeElementRequested2,
            ) ??
            InvalidNamedWriteResolutionImpl(
              recoveryElement: result.writeElementRecovery2,
            );
      case StaticQualifierImpl():
        var result = _resolveStaticQualifier(
          receiver,
          name: node.name,
          hasRead: false,
          hasWrite: true,
        );
        return _createNamedWriteResolutionWithElement(
              result.writeElementRequested2,
            ) ??
            InvalidNamedWriteResolutionImpl(
              recoveryElement: result.writeElementRecovery2,
            );
      case ExtensionOverride2Impl():
        var result = _resolveTargetExtensionOverride(
          target: receiver,
          propertyName: node.name,
          hasRead: false,
          hasWrite: true,
        );
        return _createNamedWriteResolutionWithElement(
              result.writeElementRequested2,
            ) ??
            InvalidNamedWriteResolutionImpl(
              recoveryElement: result.writeElementRecovery2,
            );

      case ExpressionImpl():
        var receiverType = _typeAnalyzer.instanceReceiverType(receiver);

        if (receiverType is NeverType &&
            receiverType.nullabilitySuffix == NullabilitySuffix.none) {
          // V1 prefixed assignment targets recover without receiverOfTypeNever.
          if (receiver is UnqualifiedNameExpressionImpl &&
              node.operator.type == TokenType.PERIOD) {
            return InvalidNamedWriteResolutionImpl(recoveryElement: null);
          }
          diagnosticReporter.report(diag.receiverOfTypeNever.at(receiver));
          return null;
        }

        if (node.operator.type == TokenType.QUESTION_PERIOD) {
          if (_typeSystem.isNull(receiverType)) {
            return null;
          }
          receiverType = _typeSystem.promoteToNonNull(receiverType);
        }

        if (receiverType is DynamicType && node.name.lexeme != 'new') {
          return const DynamicPropertyWriteResolutionImpl();
        }

        if (receiverType is VoidType) {
          diagnosticReporter.report(diag.useOfVoidResult.at(node.name));
          return InvalidNamedWriteResolutionImpl(recoveryElement: null);
        }

        var result = _typeAnalyzer.typePropertyResolver.resolve(
          receiver: receiver,
          receiverType: receiverType,
          name: node.name.lexeme,
          hasRead: false,
          hasWrite: true,
          propertyErrorEntity: node.name,
          nameErrorEntity: node.name,
          parentNode: node.parent2,
        );

        var writeElement = result.setter2;
        _checkForStaticMember(receiver, node.name, writeElement);

        InternalExecutableElement? writeRecovery;
        if (result.needsSetterError) {
          var readResult = _typeAnalyzer.typePropertyResolver.resolve(
            receiver: receiver,
            receiverType: receiverType,
            name: node.name.lexeme,
            hasRead: true,
            hasWrite: false,
            propertyErrorEntity: node.name,
            nameErrorEntity: node.name,
            parentNode: node.parent2,
          );
          writeRecovery = readResult.getter2;
          _lookupFailureReporter.reportWriteFailure(
            domain: InstanceLookupDomain(receiverType),
            name: node.name,
            foundInstead: writeRecovery,
          );
        }

        return _createNamedWriteResolutionWithElement(writeElement) ??
            InvalidNamedWriteResolutionImpl(
              recoveryElement: writeElement ?? writeRecovery,
            );
    }
  }

  ({
    ExpressionInfo? expressionInfo,
    NamedReadResolutionImpl? resolution,
    TypeImpl type,
  })
  resolveReceiverPropertyExtraction(ReceiverPropertyExtractionImpl node) {
    var receiver = node.receiver;
    switch (receiver) {
      case SuperReferenceImpl():
        var result = _resolveTargetSuperReference(
          node: node,
          target: receiver,
          propertyName: node.name,
          hasRead: true,
          hasWrite: false,
        );
        var element = result.readElementRequested2;
        var resolution =
            _createNamedReadResolutionWithElement(
              element,
              type: element is InternalPropertyAccessorElement
                  ? result.getType as TypeImpl?
                  : _namedReadType(element),
            ) ??
            InvalidNamedReadResolutionImpl(
              recoveryElement: result.readElementRecovery2,
            );
        return (
          expressionInfo: _typeAnalyzer.flowAnalysis.getExpressionInfo(node),
          resolution: resolution,
          type: resolution.type,
        );
      case StaticQualifierImpl():
        var result = _resolveStaticQualifier(
          receiver,
          name: node.name,
          hasRead: true,
          hasWrite: false,
        );
        var readElement = result.readElementRequested2;
        var resolution =
            _createNamedReadResolutionWithElement(
              readElement,
              type: _namedReadType(readElement),
            ) ??
            InvalidNamedReadResolutionImpl(
              recoveryElement: result.readElementRecovery2,
            );
        return (
          expressionInfo: null,
          resolution: resolution,
          type: resolution.type,
        );
      case ExtensionOverride2Impl():
        var result = _resolveTargetExtensionOverride(
          target: receiver,
          propertyName: node.name,
          hasRead: true,
          hasWrite: false,
        );
        var readElement = result.readElementRequested2;
        var resolution =
            _createNamedReadResolutionWithElement(
              readElement,
              type: _namedReadType(readElement),
            ) ??
            InvalidNamedReadResolutionImpl(
              recoveryElement: result.readElementRecovery2,
            );
        return (
          expressionInfo: null,
          resolution: resolution,
          type: resolution.type,
        );

      case ExpressionImpl():
        var receiverType = _typeAnalyzer.instanceReceiverType(receiver);

        if (receiverType is NeverType &&
            receiverType.nullabilitySuffix == NullabilitySuffix.none) {
          // Bare-name and call-result reads retain the legacy dead-code diagnostic
          // at the selected name. Other receivers report receiverOfTypeNever.
          // TODO(scheglov): Unify diagnostics for Never receivers across receiver
          // forms. Preserve the legacy diagnostics during this migration.
          if (receiver is! FunctionInvocationImpl &&
              (receiver is! UnqualifiedNameExpressionImpl ||
                  node.operator.type != TokenType.PERIOD)) {
            diagnosticReporter.report(diag.receiverOfTypeNever.at(receiver));
            return (expressionInfo: null, resolution: null, type: receiverType);
          }
        }

        if (node.operator.type == TokenType.QUESTION_PERIOD) {
          if (_typeSystem.isNull(receiverType)) {
            return (
              expressionInfo: null,
              resolution: null,
              type: NeverTypeImpl.instance,
            );
          }
          receiverType = _typeSystem.promoteToNonNull(receiverType);
        }

        if (receiverType is VoidType) {
          diagnosticReporter.report(diag.useOfVoidResult.at(node.name));
          var resolution = InvalidNamedReadResolutionImpl(
            recoveryElement: null,
          );
          return (
            expressionInfo: null,
            resolution: resolution,
            type: resolution.type,
          );
        }

        var result = _typeAnalyzer.typePropertyResolver.resolve(
          receiver: receiver,
          receiverType: receiverType,
          name: node.name.lexeme,
          hasRead: true,
          hasWrite: false,
          propertyErrorEntity: node.name,
          nameErrorEntity: node.name,
          parentNode: node.parent2,
        );

        var functionCallTearOffResolution = _functionCallTearOffResolution(
          receiverType: receiverType,
          isCall: node.name.lexeme == MethodElement.CALL_METHOD_NAME,
          callFunctionType: result.callFunctionType,
        );
        if (functionCallTearOffResolution != null) {
          return (
            expressionInfo: null,
            resolution: functionCallTearOffResolution,
            type: functionCallTearOffResolution.type,
          );
        }

        var readElement = result.getter2;
        _checkForStaticMember(receiver, node.name, readElement);

        if (result.needsGetterError) {
          _lookupFailureReporter.reportReadFailure(
            domain: InstanceLookupDomain(receiverType),
            name: node.name,
            syntax: ReadSyntax.reference,
            foundInstead: null,
          );
        }

        var recordField = result.recordField;
        var readType = switch (readElement) {
          InternalPropertyAccessorElement(:var returnType) => returnType,
          InternalMethodElement(:var type) => type,
          _ => recordField?.type,
        };
        ExpressionInfo? expressionInfo;
        if (readType != null) {
          if (_typeAnalyzer.flowAnalysis.flow case var flow?) {
            var (
              promotedType: wrappedPromotedType,
              expressionInfo: readExpressionInfo,
            ) = flow.propertyGet(
              ExpressionPropertyTarget(
                _typeAnalyzer.flowAnalysis.getExpressionInfo(receiver),
              ),
              node.name.lexeme,
              readElement,
              SharedTypeView(readType),
            );
            expressionInfo = readExpressionInfo;
            readType =
                wrappedPromotedType?.unwrapTypeView<TypeImpl>() ?? readType;
          }
        }

        var resolution = _createPropertyReadResolution(
          element: readElement,
          recordField: recordField,
          type: readType,
        );
        if (receiverType is NeverType &&
            receiverType.nullabilitySuffix == NullabilitySuffix.none) {
          return (
            expressionInfo: expressionInfo,
            resolution: resolution,
            type: receiverType,
          );
        }
        resolution ??= _typeSystem.isDynamicBounded(receiverType)
            ? DynamicPropertyReadResolutionImpl()
            : InvalidNamedReadResolutionImpl(
                recoveryElement: readElement ?? result.setter2,
              );
        return (
          expressionInfo: expressionInfo,
          resolution: resolution,
          type: resolution.type,
        );
    }
  }

  ({
    NamedReadResolutionImpl read,
    NamedWriteResolutionImpl write,
    ExpressionInfo? readExpressionInfo,
  })?
  resolveReceiverPropertyReadWriteAssignmentTarget(
    ReceiverPropertyAssignmentTargetImpl node,
  ) {
    var receiver = node.receiver;
    switch (receiver) {
      case SuperReferenceImpl():
        return _propertyReadWriteTargetResult(
          _resolveTargetSuperReference(
            node: node,
            target: receiver,
            propertyName: node.name,
            hasRead: true,
            hasWrite: true,
          ),
        );
      case StaticQualifierImpl():
        return _propertyReadWriteTargetResult(
          _resolveStaticQualifier(
            receiver,
            name: node.name,
            hasRead: true,
            hasWrite: true,
          ),
        );
      case ExtensionOverride2Impl():
        var result = _resolveTargetExtensionOverride(
          target: receiver,
          propertyName: node.name,
          hasRead: true,
          hasWrite: true,
        );
        return _propertyReadWriteTargetResult(result);

      case ExpressionImpl():
        if (receiver case TypeLiteralImpl(
          type: NamedTypeImpl(element: InterfaceElementImpl typeReference),
        )) {
          var result = _resolveTargetInterfaceElement(
            typeReference: typeReference,
            isCascaded: false,
            propertyName: node.name,
            hasRead: true,
            hasWrite: true,
            dotShorthandContext: null,
          );
          return _propertyReadWriteTargetResult(result);
        }

        var receiverType = _typeAnalyzer.instanceReceiverType(receiver);

        if (receiverType is NeverType &&
            receiverType.nullabilitySuffix == NullabilitySuffix.none) {
          // Increment targets retain their existing receiverOfTypeNever behavior.
          if (node.parent2 is AssignmentExpression2Impl &&
              receiver is UnqualifiedNameExpressionImpl &&
              node.operator.type == TokenType.PERIOD) {
            return (
              read: InvalidNamedReadResolutionImpl(recoveryElement: null),
              write: InvalidNamedWriteResolutionImpl(recoveryElement: null),
              readExpressionInfo: null,
            );
          }
          diagnosticReporter.report(diag.receiverOfTypeNever.at(receiver));
          return null;
        }

        if (node.operator.type == TokenType.QUESTION_PERIOD) {
          if (_typeSystem.isNull(receiverType)) {
            return null;
          }
          receiverType = _typeSystem.promoteToNonNull(receiverType);
        }

        if (receiverType is VoidType) {
          diagnosticReporter.report(diag.useOfVoidResult.at(node.name));
          return (
            read: InvalidNamedReadResolutionImpl(recoveryElement: null),
            write: InvalidNamedWriteResolutionImpl(recoveryElement: null),
            readExpressionInfo: null,
          );
        }

        if (_typeSystem.isDynamicBounded(receiverType) &&
            node.name.lexeme != 'new') {
          return (
            read: DynamicPropertyReadResolutionImpl(),
            write: const DynamicPropertyWriteResolutionImpl(),
            readExpressionInfo: null,
          );
        }

        var result = _typeAnalyzer.typePropertyResolver.resolve(
          receiver: receiver,
          receiverType: receiverType,
          name: node.name.lexeme,
          hasRead: true,
          hasWrite: true,
          propertyErrorEntity: node.name,
          nameErrorEntity: node.name,
          parentNode: node,
        );

        var functionCallTearOffResolution = _functionCallTearOffResolution(
          receiverType: receiverType,
          isCall: node.name.lexeme == MethodElement.CALL_METHOD_NAME,
          callFunctionType: result.callFunctionType,
        );

        var readElement = result.getter2;
        var writeElement = result.setter2;
        _checkForStaticMember(receiver, node.name, readElement);
        _checkForStaticMember(receiver, node.name, writeElement);

        if (result.needsGetterError) {
          _lookupFailureReporter.reportReadFailure(
            domain: InstanceLookupDomain(receiverType),
            name: node.name,
            syntax: ReadSyntax.reference,
            foundInstead: null,
          );
        }
        if (result.needsSetterError) {
          _lookupFailureReporter.reportWriteFailure(
            domain: InstanceLookupDomain(receiverType),
            name: node.name,
            foundInstead: readElement,
          );
        }

        var recordField = result.recordField;
        var readType = switch (readElement) {
          InternalPropertyAccessorElement(:var returnType) => returnType,
          InternalMethodElement(:var type) => type,
          _ => recordField?.type,
        };
        ExpressionInfo? readExpressionInfo;
        if (readType != null) {
          if (_typeAnalyzer.flowAnalysis.flow case var flow?) {
            var (promotedType: wrappedPromotedType, :expressionInfo) = flow
                .propertyGet(
                  ExpressionPropertyTarget(
                    _typeAnalyzer.flowAnalysis.getExpressionInfo(receiver),
                  ),
                  node.name.lexeme,
                  readElement,
                  SharedTypeView(readType),
                );
            readExpressionInfo = expressionInfo;
            readType =
                wrappedPromotedType?.unwrapTypeView<TypeImpl>() ?? readType;
          }
        }

        var readResolution =
            functionCallTearOffResolution ??
            _createPropertyReadResolution(
              element: readElement,
              recordField: recordField,
              type: readType,
            );
        readResolution ??= InvalidNamedReadResolutionImpl(
          recoveryElement: readElement ?? writeElement,
        );
        NamedWriteResolutionImpl? writeResolution =
            _createNamedWriteResolutionWithElement(writeElement);
        writeResolution ??= InvalidNamedWriteResolutionImpl(
          recoveryElement: writeElement ?? readElement,
        );

        return (
          read: readResolution,
          write: writeResolution,
          readExpressionInfo: readExpressionInfo,
        );
    }
  }

  NamedWriteResolutionImpl resolveUnqualifiedNameAssignmentTarget(
    UnqualifiedNameAssignmentTargetImpl node,
  ) {
    var scopeLookupResult = node.scopeLookupResult!;
    reportDeprecatedExportUse(
      scopeLookupResult: scopeLookupResult,
      nameToken: node.name,
      hasRead: false,
      hasWrite: true,
    );

    return _resolveUnqualifiedNameWrite(node);
  }

  ({NamedReadResolutionImpl resolution, ExpressionInfo? expressionInfo})
  resolveUnqualifiedNameExpression(UnqualifiedNameExpressionImpl node) {
    var scopeLookupResult = node.scopeLookupResult!;
    reportDeprecatedExportUse(
      scopeLookupResult: scopeLookupResult,
      nameToken: node.name,
      hasRead: true,
      hasWrite: false,
    );
    var element = scopeLookupResult.getter;
    if (element is PrefixElement) {
      if (element.name case var name?) {
        diagnosticReporter.report(
          diag.prefixIdentifierNotFollowedByDot
              .withArguments(name: name)
              .at(node),
        );
      }
    } else if (element is ExtensionElement) {
      diagnosticReporter.report(
        node.parent2 is FunctionInstantiationImpl
            ? diag.disallowedTypeInstantiationExpression.at(node)
            : diag.extensionAsExpression
                  .withArguments(name: node.name.lexeme)
                  .at(node),
      );
    }
    return _resolveUnqualifiedNameRead(
      node: node,
      name: node.name,
      scopeLookupResult: scopeLookupResult,
    );
  }

  ({
    NamedReadResolutionImpl read,
    NamedWriteResolutionImpl write,
    ExpressionInfo? readExpressionInfo,
  })
  resolveUnqualifiedNameReadWriteAssignmentTarget(
    UnqualifiedNameAssignmentTargetImpl node,
  ) {
    var scopeLookupResult = node.scopeLookupResult!;
    reportDeprecatedExportUse(
      scopeLookupResult: scopeLookupResult,
      nameToken: node.name,
      hasRead: true,
      hasWrite: true,
    );

    var readResult = _resolveUnqualifiedNameRead(
      node: node,
      name: node.name,
      scopeLookupResult: scopeLookupResult,
    );
    var writeResolution = _resolveUnqualifiedNameWrite(node);
    return (
      read: readResult.resolution,
      write: writeResolution,
      readExpressionInfo: readResult.expressionInfo,
    );
  }

  void _checkForStaticMember(
    AstNode target,
    Token propertyName,
    ExecutableElement? element,
  ) {
    if (element != null && element.isStatic) {
      if (target is ExtensionOverride2) {
        diagnosticReporter.report(
          diag.extensionOverrideAccessToStaticMember.at(propertyName),
        );
      } else {
        var enclosingElement = element.enclosingElement;
        if (enclosingElement is ExtensionElement &&
            enclosingElement.name == null) {
          _typeAnalyzer.diagnosticReporter.report(
            diag.instanceAccessToStaticMemberOfUnnamedExtension
                .withArguments(
                  name: propertyName.lexeme,
                  kind: element.kind.displayName,
                )
                .at(propertyName),
          );
        } else {
          // It is safe to assume that `enclosingElement.name` is non-`null`
          // because it can only be `null` for extensions, and we handle that
          // case above.
          diagnosticReporter.report(
            diag.instanceAccessToStaticMember
                .withArguments(
                  memberName: propertyName.lexeme,
                  memberKind: element.kind.displayName,
                  enclosingElementName: enclosingElement!.name!,
                  enclosingElementKind: enclosingElement is MixinElement
                      ? 'mixin'
                      : enclosingElement.kind.displayName,
                )
                .at(propertyName),
          );
        }
      }
    }
  }

  IndexReadResolutionImpl _createIndexReadResolution(
    InternalExecutableElement? element, {
    required bool atDynamicTarget,
    required bool isInvalid,
  }) {
    if (element is InternalMethodElement) {
      if (!isInvalid && element.formalParameters.length == 1) {
        return MethodIndexReadResolutionImpl(
          element: element,
          type: element.returnType,
        );
      }
      return InvalidIndexReadResolutionImpl(recoveryElement: element);
    }
    if (!isInvalid && atDynamicTarget) {
      return const DynamicIndexReadResolutionImpl();
    }
    return InvalidIndexReadResolutionImpl(recoveryElement: null);
  }

  IndexWriteResolutionImpl _createIndexWriteResolution(
    InternalExecutableElement? element, {
    required bool atDynamicTarget,
    required bool isInvalid,
  }) {
    if (element is InternalMethodElement) {
      if (!isInvalid && element.formalParameters.length == 2) {
        return MethodIndexWriteResolutionImpl(element: element);
      }
      return InvalidIndexWriteResolutionImpl(recoveryElement: element);
    }
    if (!isInvalid && atDynamicTarget) {
      return const DynamicIndexWriteResolutionImpl();
    }
    return InvalidIndexWriteResolutionImpl(recoveryElement: null);
  }

  NamedReadResolutionWithElementImpl? _createNamedReadResolutionWithElement(
    Element? element, {
    required TypeImpl? type,
  }) {
    if (type == null) return null;
    if (element is InternalVariableElement) {
      return VariableReadResolutionImpl(element: element, type: type);
    }
    if (element is InternalGetterElement) {
      return GetterInvocationResolutionImpl(element: element, type: type);
    }
    if (element is InternalExecutableElement) {
      return ExecutableTearOffResolutionImpl(element: element);
    }
    return null;
  }

  NamedWriteResolutionWithElementImpl? _createNamedWriteResolutionWithElement(
    Element? element,
  ) {
    if (element is InternalVariableElement) {
      return VariableWriteResolutionImpl(
        element: element,
        acceptedType: element.type,
      );
    }
    if (element is InternalSetterElement &&
        element.formalParameters.length == 1) {
      return SetterInvocationResolutionImpl(element: element);
    }
    return null;
  }

  NamedReadResolutionImpl? _createPropertyReadResolution({
    required Element? element,
    required RecordTypeFieldImpl? recordField,
    required TypeImpl? type,
  }) {
    if (type == null) return null;
    if (element is InternalGetterElement) {
      return GetterInvocationResolutionImpl(element: element, type: type);
    }
    if (element is InternalExecutableElement) {
      return ExecutableTearOffResolutionImpl(element: element);
    }
    if (recordField != null) {
      return RecordFieldReadResolutionImpl(type: type);
    }
    return null;
  }

  NamedReadResolutionImpl _dotShorthandReadResolution(
    PropertyElementResolverResult result,
  ) {
    TypeImpl? readType(Element? element) {
      return switch (element) {
        InternalGetterElement() =>
          result.getType as TypeImpl? ?? element.returnType,
        InternalExecutableElement() => element.type,
        _ => _namedReadType(element),
      };
    }

    var requestedElement = result.readElementRequested2;
    var requestedResolution = _createNamedReadResolutionWithElement(
      requestedElement,
      type: readType(requestedElement),
    );
    if (requestedResolution != null) {
      return requestedResolution;
    }

    var recoveryElement = result.readElementRecovery2;
    return InvalidNamedReadResolutionImpl(
      recoveryElement: requestedElement ?? recoveryElement,
    );
  }

  NamedReadResolutionImpl? _functionCallTearOffResolution({
    required TypeImpl receiverType,
    required bool isCall,
    required FunctionTypeImpl? callFunctionType,
  }) {
    assert(callFunctionType == null || isCall);

    if (callFunctionType != null) {
      return FunctionCallTearOffResolutionImpl(
        type: receiverType,
        associatedFunctionType: callFunctionType,
      );
    }
    if (isCall) {
      var receiverTypeResolved = _typeSystem.resolveToBound(receiverType);
      if (receiverTypeResolved is InterfaceTypeImpl &&
          receiverTypeResolved.isDartCoreFunction) {
        return FunctionInterfaceCallTearOffResolutionImpl(type: receiverType);
      }
    }
    return null;
  }

  /// Returns [element] if it is accessible in [_definingLibrary], or `null`.
  T? _ifAccessible<T extends ExecutableElement>(T? element) {
    if (element != null && element.isAccessibleIn(_definingLibrary)) {
      return element;
    }
    return null;
  }

  TypeImpl? _namedReadType(Element? element) {
    return switch (element) {
      InternalVariableElement() => element.type,
      InternalGetterElement() => element.returnType,
      InternalExecutableElement() => element.type,
      _ => null,
    };
  }

  ({
    NamedReadResolutionImpl read,
    NamedWriteResolutionImpl write,
    ExpressionInfo? readExpressionInfo,
  })
  _propertyReadWriteTargetResult(PropertyElementResolverResult result) {
    var readElement = result.readElementRequested2;
    var writeElement = result.writeElementRequested2;
    var readResolution = _createPropertyReadResolution(
      element: readElement,
      recordField: result.recordField,
      type: result.getType as TypeImpl?,
    );
    readResolution ??= InvalidNamedReadResolutionImpl(
      recoveryElement:
          readElement ?? result.readElementRecovery2 ?? writeElement,
    );
    var writeResolution =
        _createNamedWriteResolutionWithElement(writeElement) ??
        InvalidNamedWriteResolutionImpl(
          recoveryElement:
              writeElement ?? result.writeElementRecovery2 ?? readElement,
        );
    return (
      read: readResolution,
      write: writeResolution,
      readExpressionInfo: result.readExpressionInfo,
    );
  }

  void _reportUnresolvedIndex(
    AstNode node,
    LocatableDiagnostic locatableDiagnostic,
  ) {
    var (leftBracket, rightBracket) = switch (node) {
      IndexAssignmentTarget(:var leftBracket, :var rightBracket) => (
        leftBracket,
        rightBracket,
      ),
      IndexExpression2(:var leftBracket, :var rightBracket) => (
        leftBracket,
        rightBracket,
      ),
      _ => throw StateError('Not an index node: ${node.runtimeType}'),
    };
    var offset = leftBracket.offset;
    var length = rightBracket.end - offset;

    diagnosticReporter.report(
      locatableDiagnostic.atOffset(offset: offset, length: length),
    );
  }

  PropertyElementResolverResult _resolve({
    required ExpressionImpl node,
    required ExpressionImpl target,
    required bool isCascaded,
    required bool isNullAware,
    required Token propertyName,
    required bool hasRead,
    required bool hasWrite,
  }) {
    var targetType = target.typeOrThrow;

    if (targetType is VoidType) {
      diagnosticReporter.report(diag.useOfVoidResult.at(propertyName));
      return PropertyElementResolverResult();
    }

    if (isNullAware) {
      targetType = _typeSystem.promoteToNonNull(targetType);
    }

    if (propertyName.lexeme == MethodElement.CALL_METHOD_NAME) {
      var targetTypeResolved = _typeSystem.resolveToBound(targetType);
      if (targetTypeResolved is FunctionTypeImpl) {
        return PropertyElementResolverResult(
          functionTypeCallType: targetType,
          callFunctionType: targetTypeResolved,
        );
      }
      if (targetTypeResolved.isDartCoreFunction) {
        return PropertyElementResolverResult(functionTypeCallType: targetType);
      }
    }

    if (target is TypeLiteralImpl && target.type.type is FunctionType) {
      // There is no possible resolution for a property access of a function
      // type literal (which can only be a type instantiation of a type alias
      // of a function type).
      if (hasRead) {
        _lookupFailureReporter.reportReadFailure(
          domain: FunctionTypeAliasLookupDomain(
            importPrefix: target.type.importPrefix,
            name: target.type.name,
          ),
          name: propertyName,
          syntax: ReadSyntax.reference,
          foundInstead: null,
        );
      } else {
        _lookupFailureReporter.reportWriteFailure(
          domain: FunctionTypeAliasLookupDomain(
            importPrefix: target.type.importPrefix,
            name: target.type.name,
          ),
          name: propertyName,
          foundInstead: null,
        );
      }
      return PropertyElementResolverResult();
    }

    var result = _typeAnalyzer.typePropertyResolver.resolve(
      receiver: target,
      receiverType: targetType,
      name: propertyName.lexeme,
      hasRead: hasRead,
      hasWrite: hasWrite,
      propertyErrorEntity: propertyName,
      nameErrorEntity: propertyName,
    );

    TypeImpl? getType;
    if (hasRead) {
      var unpromotedType = switch (result.getter2) {
        InternalMethodElement(:var type) => type,
        InternalPropertyAccessorElement(:var returnType) => returnType,
        _ => result.recordField?.type ?? _typeSystem.typeProvider.dynamicType,
      };
      if (_typeAnalyzer.flowAnalysis.flow case var flow?) {
        var (promotedType: wrappedPromotedType, :expressionInfo) = flow
            .propertyGet(
              isCascaded
                  ? CascadePropertyTarget.singleton
                        as PropertyTarget<ExpressionImpl>
                  : ExpressionPropertyTarget(
                      _typeAnalyzer.flowAnalysis.getExpressionInfo(target),
                    ),
              propertyName.lexeme,
              result.getter2,
              SharedTypeView(unpromotedType),
            );
        _typeAnalyzer.flowAnalysis.storeExpressionInfo(node, expressionInfo);
        getType = wrappedPromotedType?.unwrapTypeView();
      }
      getType ??= unpromotedType;

      _checkForStaticMember(target, propertyName, result.getter2);
      if (result.needsGetterError) {
        _lookupFailureReporter.reportReadFailure(
          domain: InstanceLookupDomain(targetType),
          name: propertyName,
          syntax: ReadSyntax.reference,
          foundInstead: null,
        );
      }
    }

    if (hasWrite) {
      _checkForStaticMember(target, propertyName, result.setter2);
      if (result.needsSetterError) {
        var readResult = _typeAnalyzer.typePropertyResolver.resolve(
          receiver: target,
          receiverType: targetType,
          name: propertyName.lexeme,
          hasRead: true,
          hasWrite: false,
          propertyErrorEntity: propertyName,
          nameErrorEntity: propertyName,
        );

        _lookupFailureReporter.reportWriteFailure(
          domain: InstanceLookupDomain(targetType),
          name: propertyName,
          foundInstead: readResult.getter2,
        );
      }
    }

    return PropertyElementResolverResult(
      readElementRequested2: result.getter2,
      readElementRecovery2: result.setter2,
      writeElementRequested2: result.setter2,
      writeElementRecovery2: result.getter2,
      atDynamicTarget: _typeSystem.isDynamicBounded(targetType),
      recordField: result.recordField,
      getType: getType,
    );
  }

  PropertyElementResolverResult _resolveStaticQualifier(
    StaticQualifierImpl receiver, {
    required Token name,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (receiver.scopeLookupResult case var lookupResult?) {
      reportDeprecatedExportUseGetter(
        scopeLookupResult: lookupResult,
        nameToken: receiver.name,
      );
    }
    var element = receiver.element;
    var interfaceElement = switch (element) {
      InterfaceElementImpl element => element,
      TypeAliasElementImpl(aliasedType: InterfaceTypeImpl(:var element)) =>
        element,
      _ => null,
    };
    if (interfaceElement != null) {
      return _resolveTargetInterfaceElement(
        typeReference: interfaceElement,
        isCascaded: false,
        propertyName: name,
        hasRead: hasRead,
        hasWrite: hasWrite,
        dotShorthandContext: null,
      );
    } else if (element is ExtensionElementImpl) {
      return _resolveTargetExtensionElement(
        extension: element,
        propertyName: name,
        hasRead: hasRead,
        hasWrite: hasWrite,
      );
    } else if (element case TypeAliasElement(aliasedType: FunctionType())) {
      if (hasRead) {
        _lookupFailureReporter.reportReadFailure(
          domain: FunctionTypeAliasLookupDomain(
            importPrefix: receiver.importPrefix,
            name: receiver.name,
          ),
          name: name,
          syntax: ReadSyntax.reference,
          foundInstead: null,
        );
      } else if (hasWrite) {
        _lookupFailureReporter.reportWriteFailure(
          domain: FunctionTypeAliasLookupDomain(
            importPrefix: receiver.importPrefix,
            name: receiver.name,
          ),
          name: name,
          foundInstead: null,
        );
      }
      return PropertyElementResolverResult();
    }
    throw StateError('Unexpected static qualifier element: $element');
  }

  PropertyElementResolverResult _resolveTargetExtensionElement({
    required ExtensionElementImpl extension,
    required Token propertyName,
    required bool hasRead,
    required bool hasWrite,
  }) {
    var memberName = propertyName.lexeme;

    ExecutableElement? readElement;
    ExecutableElement? readElementRecovery;
    DartType? getType;
    var isReadFailure = false;
    if (hasRead) {
      var element = _ifAccessible(
        extension.getGetter(memberName) ?? extension.getMethod(memberName),
      );
      if (element != null && element.isStatic) {
        readElement = element;
        getType = element.returnType;
      } else {
        // An instance member is reported as found instead.
        isReadFailure = true;
        readElementRecovery = element;
        _lookupFailureReporter.reportReadFailure(
          domain: StaticLookupDomain(extension),
          name: propertyName,
          syntax: ReadSyntax.reference,
          foundInstead:
              element ??
              extension.getMemberForFailedLookup(
                Name(_definingLibrary.uri, memberName),
              ),
        );
      }
    }

    ExecutableElement? writeElement;
    ExecutableElement? writeElementRecovery;
    if (hasWrite) {
      var element = _ifAccessible(extension.getSetter(memberName));
      if (element != null && element.isStatic) {
        writeElement = element;
      } else {
        // Recovery, use the instance setter, or try to use getter.
        writeElementRecovery =
            element ?? _ifAccessible(extension.getGetter(memberName));
        // The read is evaluated first, so a failed read takes precedence.
        if (!isReadFailure) {
          _lookupFailureReporter.reportWriteFailure(
            domain: StaticLookupDomain(extension),
            name: propertyName,
            foundInstead:
                element ??
                extension.getMemberForFailedLookup(
                  Name(_definingLibrary.uri, memberName).forSetter,
                ),
          );
        }
      }
    }

    return PropertyElementResolverResult(
      readElementRequested2: readElement,
      readElementRecovery2: readElementRecovery,
      writeElementRequested2: writeElement,
      writeElementRecovery2: writeElementRecovery,
      getType: getType,
    );
  }

  PropertyElementResolverResult _resolveTargetExtensionOverride({
    required ExtensionOverride2Impl target,
    required Token propertyName,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (target.parent2 case InvalidExtensionOverrideExpression(
      parent2: CascadeExpression(),
    )) {
      // Report this error and recover by treating it like a non-cascade.
      diagnosticReporter.report(
        diag.extensionOverrideWithCascade.at(target.name),
      );
    }

    var memberName = propertyName.lexeme;

    var result = _extensionResolver.getOverrideMember(target, memberName);

    ExecutableElement? readElement;
    DartType? getType;
    var isReadFailure = false;
    if (hasRead) {
      readElement = result.getter2;
      if (readElement == null) {
        isReadFailure = true;
        _lookupFailureReporter.reportReadFailure(
          domain: ExtensionOverrideLookupDomain(target.element),
          name: propertyName,
          syntax: ReadSyntax.reference,
          foundInstead: target.element.getMemberForFailedLookup(
            Name(_definingLibrary.uri, memberName),
          ),
        );
      } else {
        getType = readElement.returnType;
      }
      _checkForStaticMember(target, propertyName, readElement);
    }

    ExecutableElement? writeElement;
    if (hasWrite) {
      writeElement = result.setter2;
      // The read is evaluated first, so a failed read takes precedence.
      if (writeElement == null && !isReadFailure) {
        _lookupFailureReporter.reportWriteFailure(
          domain: ExtensionOverrideLookupDomain(target.element),
          name: propertyName,
          foundInstead: target.element.getMemberForFailedLookup(
            Name(_definingLibrary.uri, memberName).forSetter,
          ),
        );
      }
      _checkForStaticMember(target, propertyName, writeElement);
    }

    return PropertyElementResolverResult(
      readElementRequested2: readElement,
      writeElementRequested2: writeElement,
      getType: getType,
    );
  }

  PropertyElementResolverResult _resolveTargetInterfaceElement({
    required InterfaceElementImpl typeReference,
    required bool isCascaded,
    required Token propertyName,
    required bool hasRead,
    required bool hasWrite,
    required ValidDotShorthandContextResolutionImpl? dotShorthandContext,
  }) {
    if (isCascaded) {
      typeReference = _typeAnalyzer.typeProvider.typeType.element;
    }

    var memberName = propertyName.lexeme;

    ExecutableElement? readElement;
    ExecutableElement? readElementRecovery;
    DartType? getType;
    var isReadFailure = false;
    if (hasRead) {
      ExecutableElement? element =
          _ifAccessible(typeReference.getGetter(memberName)) ??
          _ifAccessible(typeReference.getMethod(memberName));

      if (element == null &&
          _definingLibrary.featureSet.isEnabled(Feature.static_extensions)) {
        // When direct lookups fail, try static extension resolution.
        var result = _typeAnalyzer.typePropertyResolver.resolveStaticExtension(
          declaration: typeReference,
          name: memberName,
          hasRead: hasRead,
          hasWrite: hasWrite,
          propertyErrorEntity: propertyName,
          nameErrorEntity: propertyName,
        );
        element = result.getter2;
      }

      if (element != null && element.isStatic) {
        readElement = element;
        getType = element.returnType;
      } else {
        // An instance member is reported as found instead, also for a dot
        // shorthand, so that the diagnostic says why it can't be used.
        isReadFailure = true;
        readElementRecovery = element;
        _lookupFailureReporter.reportReadFailure(
          domain: switch ((dotShorthandContext, element)) {
            (var context?, null) => DotShorthandLookupDomain.declaration(
              context,
            ),
            _ => StaticLookupDomain(typeReference),
          },
          name: propertyName,
          syntax: ReadSyntax.reference,
          foundInstead:
              element ??
              typeReference.getMemberForFailedLookup(
                Name(_definingLibrary.uri, memberName),
              ),
        );
      }
    }

    ExecutableElement? writeElement;
    ExecutableElement? writeElementRecovery;
    if (hasWrite) {
      ExecutableElement? element = _ifAccessible(
        typeReference.getSetter(memberName),
      );

      if (element == null &&
          _definingLibrary.featureSet.isEnabled(Feature.static_extensions)) {
        // When direct lookups fail, try static extension resolution.
        var result = _typeAnalyzer.typePropertyResolver.resolveStaticExtension(
          declaration: typeReference,
          name: memberName,
          hasRead: hasRead,
          hasWrite: hasWrite,
          propertyErrorEntity: propertyName,
          nameErrorEntity: propertyName,
        );
        element = result.setter2;
      }

      if (element != null && element.isStatic) {
        writeElement = element;
      } else {
        // Recovery, use the instance setter, or try to use getter.
        writeElementRecovery =
            element ?? _ifAccessible(typeReference.getGetter(memberName));
        // The read is evaluated first, so a failed read takes precedence.
        if (!isReadFailure) {
          _lookupFailureReporter.reportWriteFailure(
            domain: StaticLookupDomain(typeReference),
            name: propertyName,
            foundInstead:
                element ??
                typeReference.getMemberForFailedLookup(
                  Name(_definingLibrary.uri, memberName).forSetter,
                ),
          );
        }
      }
    }

    return PropertyElementResolverResult(
      readElementRequested2: readElement,
      readElementRecovery2: readElementRecovery,
      writeElementRequested2: writeElement,
      writeElementRecovery2: writeElementRecovery,
      getType: getType,
    );
  }

  PropertyElementResolverResult _resolveTargetPrefixElement({
    required PrefixElementImpl target,
    required Token nameToken,
    required bool hasRead,
    required bool hasWrite,
  }) {
    var name = nameToken.lexeme;
    var lookupResult = target.scope.lookup(name);
    reportDeprecatedExportUse(
      scopeLookupResult: lookupResult,
      nameToken: nameToken,
      hasRead: hasRead,
      hasWrite: hasWrite,
    );

    var readElement = lookupResult.getter;
    var writeElement = lookupResult.setter;
    DartType? getType;
    if (hasRead && readElement is PropertyAccessorElement) {
      getType = readElement.returnType;
    }

    var isReadFailure = hasRead && readElement == null;
    if (isReadFailure || hasWrite && writeElement == null) {
      if (nameToken.isSynthetic) {
        // The parser has already reported the missing name. But the prefix
        // is still used, so its imports must not be reported as unused.
        target.scope.notifyPrefixUsedWithoutName();
      }
      if (isReadFailure) {
        _lookupFailureReporter.reportReadFailure(
          domain: PrefixedLookupDomain(target),
          name: nameToken,
          syntax: ReadSyntax.reference,
          foundInstead: null,
        );
      } else {
        _lookupFailureReporter.reportWriteFailure(
          domain: PrefixedLookupDomain(target),
          name: nameToken,
          foundInstead: null,
        );
      }
    }

    return PropertyElementResolverResult(
      readElementRequested2: readElement,
      writeElementRequested2: writeElement,
      getType: getType,
    );
  }

  PropertyElementResolverResult _resolveTargetSuperReference({
    required AstNode node,
    required SuperReference target,
    required Token propertyName,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (SuperContext.of(target) != SuperContext.valid) {
      return PropertyElementResolverResult();
    }
    var targetType = _typeAnalyzer.superLookupType(target);

    InternalExecutableElement? readElement;
    InternalExecutableElement? writeElement;
    TypeImpl? getType;
    ExpressionInfo? readExpressionInfo;
    var isReadFailure = false;

    if (targetType is InterfaceTypeImpl) {
      var name = Name(_definingLibrary.uri, propertyName.lexeme);
      if (hasRead) {
        readElement = _typeAnalyzer.inheritance.getMember(
          targetType.element,
          name,
          forSuper: true,
        );

        if (readElement != null) {
          _checkForStaticMember(target, propertyName, readElement);
        } else {
          switch (_typeAnalyzer.inheritance.recoverFailedSuperLookup(
            targetType.element,
            name,
          )) {
            case AbstractMemberSuperLookupRecovery(:var member):
              // Give the user at least some resolution.
              readElement = member;
              diagnosticReporter.report(
                diag.abstractSuperMemberReference
                    .withArguments(
                      memberKind: member.kind.displayName,
                      name: propertyName.lexeme,
                    )
                    .at(propertyName),
              );
            case MissingMemberSuperLookupRecovery(:var foundInstead):
              isReadFailure = true;
              _lookupFailureReporter.reportReadFailure(
                domain: SuperLookupDomain(targetType),
                name: propertyName,
                syntax: ReadSyntax.reference,
                foundInstead: foundInstead,
              );
          }
        }
        var unpromotedType =
            readElement?.returnType ?? _typeSystem.typeProvider.dynamicType;
        if (_typeAnalyzer.flowAnalysis.flow case var flow?) {
          var (promotedType: wrappedPromotedType, :expressionInfo) = flow
              .propertyGet(
                SuperPropertyTarget.singleton,
                propertyName.lexeme,
                readElement,
                SharedTypeView(unpromotedType),
              );
          if (node is Expression) {
            _typeAnalyzer.flowAnalysis.storeExpressionInfo(
              node,
              expressionInfo,
            );
          }
          readExpressionInfo = expressionInfo;
          getType = wrappedPromotedType?.unwrapTypeView();
        }
        getType ??= unpromotedType;
      }

      if (hasWrite) {
        writeElement = _typeAnalyzer.inheritance.getMember3(
          targetType,
          name.forSetter,
          forSuper: true,
        );

        if (writeElement != null) {
          _checkForStaticMember(target, propertyName, writeElement);
        } else {
          switch (_typeAnalyzer.inheritance.recoverFailedSuperLookup(
            targetType.element,
            name.forSetter,
          )) {
            case AbstractMemberSuperLookupRecovery(:var member):
              // Give the user at least some resolution.
              writeElement = member;
              diagnosticReporter.report(
                diag.abstractSuperMemberReference
                    .withArguments(
                      memberKind: member.kind.displayName,
                      name: propertyName.lexeme,
                    )
                    .at(propertyName),
              );
            case MissingMemberSuperLookupRecovery(:var foundInstead):
              // The read is evaluated first, so a failed read takes
              // precedence.
              if (!isReadFailure) {
                _lookupFailureReporter.reportWriteFailure(
                  domain: SuperLookupDomain(targetType),
                  name: propertyName,
                  foundInstead: foundInstead,
                );
              }
          }
        }
      }
    }

    return PropertyElementResolverResult(
      readElementRequested2: readElement,
      writeElementRequested2: writeElement,
      getType: getType,
      readExpressionInfo: readExpressionInfo,
    );
  }

  ({NamedReadResolutionImpl resolution, ExpressionInfo? expressionInfo})
  _resolveUnqualifiedNameRead({
    required AstNode node,
    required Token name,
    required ScopeLookupResult scopeLookupResult,
  }) {
    var readLookup =
        LexicalLookup.resolveGetter(scopeLookupResult) ??
        _typeAnalyzer.thisLookupGetter2(node, name.lexeme);
    var readElementRequested = readLookup?.requested;
    var readElementRecovery = readLookup?.recovery;

    if (readElementRequested == null &&
        readLookup?.callFunctionType == null &&
        readLookup?.recordField == null) {
      if (name.lexeme == 'await' &&
          _typeAnalyzer.enclosingExecutableElement != null) {
        diagnosticReporter.report(diag.undefinedIdentifierAwait.at(node));
      } else {
        _lookupFailureReporter.reportReadFailure(
          domain: UnqualifiedLookupDomain(thisType: _typeAnalyzer.thisType),
          name: name,
          syntax: node.parent2 is FunctionInstantiationImpl
              ? ReadSyntax.typeInstantiation
              : ReadSyntax.reference,
          foundInstead: null,
        );
      }
    }

    _typeAnalyzer.checkReadOfNotAssignedLocalVariable2(
      node,
      name: name.lexeme,
      element: readElementRequested,
    );

    ExpressionInfo? expressionInfo;
    TypeImpl? readType;
    if (readElementRequested is InternalVariableElement) {
      readType = readElementRequested.type;
      var flow = _typeAnalyzer.flowAnalysis.flow;
      if (readElementRequested is PromotableElementImpl && flow != null) {
        SharedTypeView? promotedType;
        (:promotedType, :expressionInfo) = flow.variableRead(
          readElementRequested,
          offset: node.offset,
        );
        readType = promotedType?.unwrapTypeView<TypeImpl>() ?? readType;
      }
    } else if (readElementRequested is InternalGetterElement) {
      readType = readElementRequested.returnType;
      var flow = _typeAnalyzer.flowAnalysis.flow;
      if (!readElementRequested.isStatic && flow != null) {
        SharedTypeView? promotedType;
        (:promotedType, :expressionInfo) = flow.propertyGet(
          ThisPropertyTarget.singleton,
          name.lexeme,
          readElementRequested,
          SharedTypeView(readType),
        );
        readType = promotedType?.unwrapTypeView<TypeImpl>() ?? readType;
      }
    } else if (readElementRequested is InternalExecutableElement) {
      readType = readElementRequested.type;
    }

    NamedReadResolutionImpl? resolution;
    if (readLookup?.callFunctionType case FunctionTypeImpl callFunctionType) {
      resolution = FunctionCallTearOffResolutionImpl(
        type: callFunctionType,
        associatedFunctionType: callFunctionType,
      );
    } else if (readLookup?.recordField case var recordField?) {
      resolution = RecordFieldReadResolutionImpl(type: recordField.type);
    }
    resolution ??= _createNamedReadResolutionWithElement(
      readElementRequested,
      type: readType,
    );
    resolution ??= InvalidNamedReadResolutionImpl(
      recoveryElement: readElementRequested ?? readElementRecovery,
    );
    return (resolution: resolution, expressionInfo: expressionInfo);
  }

  NamedWriteResolutionImpl _resolveUnqualifiedNameWrite(
    UnqualifiedNameAssignmentTargetImpl node,
  ) {
    var name = node.name;
    var writeLookup =
        LexicalLookup.resolveSetter(node.scopeLookupResult!) ??
        ThisLookup.lookupSetter2(_typeAnalyzer, node: node, name: name.lexeme);
    var writeElementRequested = writeLookup?.requested;
    var writeElementRecovery = writeLookup?.recovery;

    var ambiguousElement =
        writeElementRequested.tryCast<MultiplyDefinedElementImpl>() ??
        writeElementRecovery.tryCast<MultiplyDefinedElementImpl>();
    if (ambiguousElement != null) {
      diagnosticReporter.report(
        DiagnosticFactory().ambiguousImport(
          name: name,
          element: ambiguousElement,
        ),
      );
    } else if (writeElementRequested == null ||
        writeElementRequested is VariableElement &&
            writeElementRequested.isConst) {
      _lookupFailureReporter.reportWriteFailure(
        domain: UnqualifiedLookupDomain(thisType: _typeAnalyzer.thisType),
        name: name,
        foundInstead: writeElementRequested ?? writeElementRecovery,
      );
    }

    var requestedResolution = _createNamedWriteResolutionWithElement(
      writeElementRequested,
    );
    if (requestedResolution != null) return requestedResolution;

    return InvalidNamedWriteResolutionImpl(
      recoveryElement: writeElementRequested ?? writeElementRecovery,
    );
  }
}

class PropertyElementResolverResult {
  final ExpressionInfo? readExpressionInfo;
  final Element? readElementRequested2;
  final Element? readElementRecovery2;
  final Element? writeElementRequested2;
  final Element? writeElementRecovery2;
  final bool atDynamicTarget;
  final DartType? functionTypeCallType;
  final FunctionTypeImpl? callFunctionType;
  final RecordTypeFieldImpl? recordField;
  final DartType? getType;

  /// If [IndexExpression] is resolved, the context type of the index.
  /// Might be `_` if `[]` or `[]=` are not resolved or invalid.
  final TypeImpl indexContextType;

  PropertyElementResolverResult({
    this.readExpressionInfo,
    this.readElementRequested2,
    this.readElementRecovery2,
    this.writeElementRequested2,
    this.writeElementRecovery2,
    this.atDynamicTarget = false,
    this.indexContextType = UnknownInferredType.instance,
    this.functionTypeCallType,
    this.callFunctionType,
    this.recordField,
    this.getType,
  });

  Element? get readElement2 {
    return readElementRequested2 ?? readElementRecovery2;
  }

  Element? get writeElement2 {
    return writeElementRequested2 ?? writeElementRecovery2;
  }
}
