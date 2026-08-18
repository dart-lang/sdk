// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/lexical_lookup.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/dart/resolver/this_lookup.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/assignment_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scope_helpers.dart';
import 'package:analyzer/src/generated/super_context.dart';

class PropertyElementResolver with ScopeHelpers {
  final ResolverVisitor _resolver;

  PropertyElementResolver(this._resolver);

  @override
  DiagnosticReporter get diagnosticReporter => _resolver.diagnosticReporter;

  LibraryElementImpl get _definingLibrary => _resolver.definingLibrary;

  ExtensionMemberResolver get _extensionResolver => _resolver.extensionResolver;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  ({IndexReadResolutionImpl? read, IndexWriteResolutionImpl? write})?
  resolveCascadeIndex({
    required AstNode node,
    required ExpressionImpl receiver,
    required bool isNullAware,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (receiver is ExtensionOverrideImpl) {
      var result = _extensionResolver.getOverrideMember(receiver, '[]');
      var readElement = result.getter2;
      var writeElement = result.setter2;
      if (result != ExtensionResolutionError.ambiguous) {
        if (hasRead && readElement == null) {
          _reportUnresolvedIndex(
            node,
            diag.undefinedExtensionOperator.withArguments(
              operator: '[]',
              extensionName: receiver.element.name!,
            ),
          );
        }
        if (hasWrite && writeElement == null) {
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

    var receiverType = _typeSystem.resolveToBound(receiver.typeOrThrow);
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
        read: hasRead ? InvalidIndexReadResolutionImpl(recovery: null) : null,
        write: hasWrite
            ? InvalidIndexWriteResolutionImpl(recovery: null)
            : null,
      );
    }

    var result = _resolver.typePropertyResolver.resolve(
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
        (receiver is SuperExpression
                ? diag.undefinedSuperOperator
                : diag.undefinedOperator)
            .withArguments(operator: '[]', type: receiverType),
      );
    }
    if (hasWrite && result.needsSetterError) {
      _reportUnresolvedIndex(
        node,
        (receiver is SuperExpression
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
    required ExpressionImpl receiver,
    required bool isNullAware,
    required Token propertyName,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (receiver is! ExtensionOverrideImpl) {
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

    var identifier = SimpleIdentifierImpl(token: propertyName);
    var result = switch (receiver) {
      ExtensionOverrideImpl() => _resolveTargetExtensionOverride(
        target: receiver,
        propertyName: identifier,
        hasRead: hasRead,
        hasWrite: hasWrite,
      ),
      SuperExpressionImpl() => _resolveTargetSuperExpression(
        node: node,
        target: receiver,
        propertyName: identifier,
        hasRead: hasRead,
        hasWrite: hasWrite,
      ),
      _ => _resolve(
        node: node,
        target: receiver,
        isCascaded: true,
        isNullAware: isNullAware,
        propertyName: identifier,
        hasRead: hasRead,
        hasWrite: hasWrite,
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
                      candidates: [
                        ?readElement,
                        ?result.readElementRecovery2,
                        ?writeElement,
                      ],
                      recovery: null,
                      type: InvalidTypeImpl.instance,
                    ));
    }

    NamedWriteResolutionImpl? write;
    if (hasWrite) {
      write = result.atDynamicTarget
          ? const DynamicPropertyWriteResolutionImpl()
          : _createNamedWriteResolutionWithElement(writeElement) ??
                InvalidNamedWriteResolutionImpl(
                  acceptedType: InvalidTypeImpl.instance,
                  candidates: [
                    ?writeElement,
                    ?result.writeElementRecovery2,
                    ?readElement,
                  ],
                  recovery: null,
                );
    }

    return (
      read: read,
      write: write,
      readExpressionInfo: hasRead
          ? _resolver.flowAnalysis.flow == null
                ? null
                : _resolver.flowAnalysis.getExpressionInfo(node)
          : null,
    );
  }

  PropertyElementResolverResult resolveDotShorthand(
    DotShorthandPropertyAccessImpl node, {
    required TypeImpl contextType,
  }) {
    if (_resolver.isDotShorthandContextEmpty) {
      assert(
        false,
        'DotShorthandPropertyAccessImpl is not enclosed in an expression for '
        'which DotShorthandMixin.isDotShorthand is true',
      );
    }

    TypeImpl context = _resolver
        .getDotShorthandContext()
        .unwrapTypeSchemaView();

    // The static namespace denoted by `S` is also the namespace denoted by
    // `FutureOr<S>`.
    context = _resolver.typeSystem.futureOrBase(context);

    if (context is InterfaceTypeImpl &&
        context.element.isAccessibleIn(_definingLibrary)) {
      var identifier = node.propertyName;
      // Find constructor tearoffs.
      var element = context.lookUpConstructor(
        identifier.name,
        _definingLibrary,
      );
      if (element != null) {
        if (!element.isFactory) {
          var enclosingElement = element.enclosingElement;
          if (enclosingElement is ClassElementImpl &&
              enclosingElement.isAbstract) {
            _resolver.diagnosticReporter.report(
              diag.tearoffOfGenerativeConstructorOfAbstractClass.at(node),
            );
          }
        }

        // Infer type parameters.
        var elementToInfer = _resolver.inferenceHelper
            .constructorElementToInfer(
              typeElement: context.element,
              constructorName: identifier.token,
              definingLibrary: _resolver.definingLibrary,
            );
        if (elementToInfer != null &&
            elementToInfer.typeParameters.isNotEmpty) {
          var inferred =
              _resolver.inferenceHelper.inferTearOff(
                    node,
                    identifier,
                    elementToInfer.asType,
                    contextType: contextType,
                  )
                  as FunctionType;
          var inferredType = inferred.returnType;
          var constructorElement = SubstitutedConstructorElementImpl.from2(
            elementToInfer.element.baseElement,
            inferredType as InterfaceType,
          );
          node.propertyName.element = constructorElement.baseElement;
          return PropertyElementResolverResult(
            readElementRequested2: node.propertyName.element,
            getType: inferred.returnType,
          );
        }

        return PropertyElementResolverResult(
          readElementRequested2: element,
          getType: element.returnType,
        );
      }

      // Didn't find any constructor tearoffs, look for static getters.
      var contextElement = context.element;
      return _resolveTargetInterfaceElement(
        typeReference: contextElement,
        isCascaded: false,
        propertyName: identifier,
        hasRead: true,
        hasWrite: false,
        resolvingDotShorthand: true,
      );
    }

    diagnosticReporter.report(diag.dotShorthandMissingContext.at(node));
    return PropertyElementResolverResult();
  }

  NamedWriteResolutionImpl resolveForEachPartsWithIdentifier(
    ForEachPartsWithIdentifierImpl node,
  ) {
    var scopeLookupResult = node.scopeLookupResult!;
    reportDeprecatedExportUse(
      scopeLookupResult: scopeLookupResult,
      nameToken: node.identifier2,
      hasRead: false,
      hasWrite: true,
    );

    return _resolveUnqualifiedNameWrite(
      node: node,
      name: node.identifier2,
      scopeLookupResult: scopeLookupResult,
    );
  }

  ({
    NamedReadResolutionImpl read,
    NamedWriteResolutionImpl write,
    ExpressionInfo? readExpressionInfo,
  })
  resolveImportPrefixedPropertyReadWriteTarget(
    ReceiverPropertyAssignmentTargetImpl node,
    PrefixElement prefix,
  ) {
    var result = _resolveTargetPrefixElement(
      target: prefix,
      identifier: SimpleIdentifierImpl(token: node.propertyName),
      hasRead: true,
      hasWrite: true,
      forAnnotation: false,
    );
    return _propertyReadWriteTargetResult(result);
  }

  IndexWriteResolutionImpl? resolveIndexDirectAssignmentTarget(
    IndexAssignmentTargetImpl node,
  ) {
    var receiver = node.receiver;

    if (receiver is ExtensionOverrideImpl) {
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

    var receiverType = _typeSystem.resolveToBound(receiver.typeOrThrow);
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
      return InvalidIndexWriteResolutionImpl(recovery: null);
    }

    var result = _resolver.typePropertyResolver.resolve(
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
        (receiver is SuperExpression
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

  PropertyElementResolverResult resolveIndexExpression({
    required IndexExpressionImpl node,
    required bool hasRead,
    required bool hasWrite,
  }) {
    var target = node.realTarget2;

    if (target is ExtensionOverrideImpl) {
      var result = _extensionResolver.getOverrideMember(target, '[]');

      // TODO(scheglov): Change ExtensionResolver to set `needsGetterError`.
      if (hasRead &&
          result.getter2 == null &&
          result != ExtensionResolutionError.ambiguous) {
        // Extension overrides can only refer to named extensions, so it is safe
        // to assume that `target.staticElement!.name` is non-`null`.
        _reportUnresolvedIndex(
          node,
          diag.undefinedExtensionOperator.withArguments(
            operator: '[]',
            extensionName: target.element.name!,
          ),
        );
      }

      if (hasWrite &&
          result.setter2 == null &&
          result != ExtensionResolutionError.ambiguous) {
        // Extension overrides can only refer to named extensions, so it is safe
        // to assume that `target.staticElement!.name` is non-`null`.
        _reportUnresolvedIndex(
          node,
          diag.undefinedExtensionOperator.withArguments(
            operator: '[]=',
            extensionName: target.element.name!,
          ),
        );
      }

      return _toIndexResult(
        result,
        atDynamicTarget: false,
        hasRead: hasRead,
        hasWrite: hasWrite,
      );
    }

    var targetType = target.typeOrThrow;
    targetType = _typeSystem.resolveToBound(targetType);

    if (targetType is VoidType) {
      // TODO(scheglov): Report directly in TypePropertyResolver?
      _reportUnresolvedIndex(node, diag.useOfVoidResult);
      return PropertyElementResolverResult();
    }

    if (identical(targetType, NeverTypeImpl.instance)) {
      // TODO(scheglov): Report directly in TypePropertyResolver?
      diagnosticReporter.report(diag.receiverOfTypeNever.at(target));
      return PropertyElementResolverResult();
    }

    if (node.isNullAware) {
      if (target is ExtensionOverride) {
        // https://github.com/dart-lang/language/pull/953
      } else {
        targetType = _typeSystem.promoteToNonNull(targetType);
      }
    }

    var result = _resolver.typePropertyResolver.resolve(
      receiver: target,
      receiverType: targetType,
      name: '[]',
      hasRead: hasRead,
      hasWrite: hasWrite,
      propertyErrorEntity: node.leftBracket,
      nameErrorEntity: target,
    );

    if (hasRead && result.needsGetterError) {
      _reportUnresolvedIndex(
        node,
        (target is SuperExpression
                ? diag.undefinedSuperOperator
                : diag.undefinedOperator)
            .withArguments(operator: '[]', type: targetType),
      );
    }

    if (hasWrite && result.needsSetterError) {
      _reportUnresolvedIndex(
        node,
        (target is SuperExpression
                ? diag.undefinedSuperOperator
                : diag.undefinedOperator)
            .withArguments(operator: '[]=', type: targetType),
      );
    }

    return _toIndexResult(
      result,
      atDynamicTarget: targetType is DynamicType,
      hasRead: hasRead,
      hasWrite: hasWrite,
    );
  }

  /// Resolves the read operation of an ordinary value-producing index
  /// expression.
  IndexReadResolutionImpl? resolveIndexExpression2(IndexExpression2Impl node) {
    var receiver = node.receiver;

    if (receiver is ExtensionOverrideImpl) {
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

    var receiverType = _typeSystem.resolveToBound(receiver.typeOrThrow);
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
      return InvalidIndexReadResolutionImpl(recovery: null);
    }

    var result = _resolver.typePropertyResolver.resolve(
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
        (receiver is SuperExpression
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

  ({IndexReadResolutionImpl read, IndexWriteResolutionImpl write})?
  resolveIndexReadWriteAssignmentTarget(IndexAssignmentTargetImpl node) {
    var receiver = node.receiver;

    if (receiver is ExtensionOverrideImpl) {
      var result = _extensionResolver.getOverrideMember(receiver, '[]');
      var readElement = result.getter2;
      var writeElement = result.setter2;
      var isReadInvalid = readElement == null;
      var isWriteInvalid = writeElement == null;
      if (result != ExtensionResolutionError.ambiguous) {
        if (isReadInvalid) {
          _reportUnresolvedIndex(
            node,
            diag.undefinedExtensionOperator.withArguments(
              operator: '[]',
              extensionName: receiver.element.name!,
            ),
          );
        }
        if (isWriteInvalid) {
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

    var receiverType = _typeSystem.resolveToBound(receiver.typeOrThrow);
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
        read: InvalidIndexReadResolutionImpl(recovery: null),
        write: InvalidIndexWriteResolutionImpl(recovery: null),
      );
    }

    var result = _resolver.typePropertyResolver.resolve(
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
        (receiver is SuperExpression
                ? diag.undefinedSuperOperator
                : diag.undefinedOperator)
            .withArguments(operator: '[]', type: receiverType),
      );
    }
    if (result.needsSetterError) {
      _reportUnresolvedIndex(
        node,
        (receiver is SuperExpression
                ? diag.undefinedSuperOperator
                : diag.undefinedOperator)
            .withArguments(operator: '[]=', type: receiverType),
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

  PropertyElementResolverResult resolvePrefixedIdentifier({
    required PrefixedIdentifierImpl node,
    required bool hasRead,
    required bool hasWrite,
    bool forAnnotation = false,
  }) {
    var prefix = node.prefix;
    var identifier = node.identifier;

    var prefixElement = prefix.element;
    if (prefixElement is PrefixElement) {
      return _resolveTargetPrefixElement(
        target: prefixElement,
        identifier: identifier,
        hasRead: hasRead,
        hasWrite: hasWrite,
        forAnnotation: forAnnotation,
      );
    }

    return _resolve(
      node: node,
      target: prefix,
      isCascaded: false,
      isNullAware: false,
      propertyName: identifier,
      hasRead: hasRead,
      hasWrite: hasWrite,
    );
  }

  PropertyElementResolverResult resolvePropertyAccess({
    required PropertyAccessImpl node,
    required bool hasRead,
    required bool hasWrite,
    PrefixedIdentifierImpl? originalNode,
  }) {
    var target = node.realTarget2;
    var propertyName = node.propertyName;

    if (target is ExtensionOverrideImpl) {
      return _resolveTargetExtensionOverride(
        target: target,
        propertyName: propertyName,
        hasRead: hasRead,
        hasWrite: hasWrite,
      );
    }

    if (target is SuperExpressionImpl) {
      return _resolveTargetSuperExpression(
        node: node,
        target: target,
        propertyName: propertyName,
        hasRead: hasRead,
        hasWrite: hasWrite,
      );
    }

    return _resolve(
      node: node,
      target: target,
      isCascaded: node.target2 == null,
      isNullAware: node.isNullAware,
      propertyName: propertyName,
      hasRead: hasRead,
      hasWrite: hasWrite,
      originalNode: originalNode,
    );
  }

  NamedWriteResolutionImpl? resolveReceiverPropertyDirectAssignmentTarget(
    ReceiverPropertyAssignmentTargetImpl node,
  ) {
    var receiver = node.receiver;
    var receiverType = receiver.typeOrThrow;

    if (receiverType is NeverType &&
        receiverType.nullabilitySuffix == NullabilitySuffix.none) {
      diagnosticReporter.report(diag.receiverOfTypeNever.at(receiver));
      return null;
    }

    if (node.operator.type == TokenType.QUESTION_PERIOD) {
      if (_typeSystem.isNull(receiverType)) {
        return null;
      }
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }

    if (receiverType is DynamicType) {
      return const DynamicPropertyWriteResolutionImpl();
    }

    if (receiverType is VoidType) {
      diagnosticReporter.report(diag.useOfVoidResult.at(node.propertyName));
      return InvalidNamedWriteResolutionImpl(
        acceptedType: InvalidTypeImpl.instance,
        candidates: const [],
        recovery: null,
      );
    }

    var result = _resolver.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: node.propertyName.lexeme,
      hasRead: false,
      hasWrite: true,
      propertyErrorEntity: node.propertyName,
      nameErrorEntity: node.propertyName,
      parentNode: node.parent2,
    );

    var writeElement = result.setter2;
    _checkForStaticMember2(
      target: receiver,
      propertyName: node.propertyName.lexeme,
      propertyNameEntity: node.propertyName,
      element: writeElement,
    );

    InternalExecutableElement? writeRecovery;
    if (result.needsSetterError) {
      var readResult = _resolver.typePropertyResolver.resolve(
        receiver: receiver,
        receiverType: receiverType,
        name: node.propertyName.lexeme,
        hasRead: true,
        hasWrite: false,
        propertyErrorEntity: node.propertyName,
        nameErrorEntity: node.propertyName,
        parentNode: node.parent2,
      );
      writeRecovery = readResult.getter2;
      AssignmentVerifier(diagnosticReporter).verifyPropertyAssignmentTarget(
        node: node,
        requested: null,
        recovery: writeRecovery,
        receiverType: receiverType,
      );
    }

    return _createNamedWriteResolutionWithElement(writeElement) ??
        InvalidNamedWriteResolutionImpl(
          acceptedType: InvalidTypeImpl.instance,
          candidates: [?writeElement, ?writeRecovery],
          recovery: null,
        );
  }

  ({
    ExpressionInfo? expressionInfo,
    NamedReadResolutionImpl? resolution,
    TypeImpl type,
  })
  resolveReceiverPropertyExtraction(ReceiverPropertyExtractionImpl node) {
    var receiver = node.receiver;
    var receiverType = receiver.typeOrThrow;

    if (receiverType is NeverType &&
        receiverType.nullabilitySuffix == NullabilitySuffix.none) {
      diagnosticReporter.report(diag.receiverOfTypeNever.at(receiver));
      return (expressionInfo: null, resolution: null, type: receiverType);
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
      diagnosticReporter.report(diag.useOfVoidResult.at(node.propertyName));
      var resolution = InvalidNamedReadResolutionImpl(
        candidates: const [],
        recovery: null,
        type: InvalidTypeImpl.instance,
      );
      return (
        expressionInfo: null,
        resolution: resolution,
        type: resolution.type,
      );
    }

    if (_typeSystem.isDynamicBounded(receiverType)) {
      var resolution = DynamicPropertyReadResolutionImpl();
      return (
        expressionInfo: null,
        resolution: resolution,
        type: resolution.type,
      );
    }

    var result = _resolver.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: node.propertyName.lexeme,
      hasRead: true,
      hasWrite: false,
      propertyErrorEntity: node.propertyName,
      nameErrorEntity: node.propertyName,
      parentNode: node.parent2,
    );

    var functionCallTearOffResolution = _functionCallTearOffResolution(
      receiverType: receiverType,
      isCall: node.propertyName.lexeme == MethodElement.CALL_METHOD_NAME,
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
    _checkForStaticMember2(
      target: receiver,
      propertyName: node.propertyName.lexeme,
      propertyNameEntity: node.propertyName,
      element: readElement,
    );

    if (result.needsGetterError) {
      diagnosticReporter.report(
        diag.undefinedGetter
            .withArguments(
              memberName: node.propertyName.lexeme,
              type: receiverType,
            )
            .at(node.propertyName),
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
      if (_resolver.flowAnalysis.flow case var flow?) {
        var (wrappedPromotedType, readExpressionInfo) = flow.propertyGet(
          ExpressionPropertyTarget(
            _resolver.flowAnalysis.getExpressionInfo(receiver),
          ),
          node.propertyName.lexeme,
          readElement,
          SharedTypeView(readType),
        );
        expressionInfo = readExpressionInfo;
        readType = wrappedPromotedType?.unwrapTypeView<TypeImpl>() ?? readType;
      }
    }

    var resolution = _createPropertyReadResolution(
      element: readElement,
      recordField: recordField,
      type: readType,
    );
    resolution ??= _typeSystem.isDynamicBounded(receiverType)
        ? DynamicPropertyReadResolutionImpl()
        : InvalidNamedReadResolutionImpl(
            candidates: [?readElement, ?result.setter2],
            recovery: null,
            type: InvalidTypeImpl.instance,
          );
    return (
      expressionInfo: expressionInfo,
      resolution: resolution,
      type: resolution.type,
    );
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

    if (receiver is ExtensionOverrideImpl) {
      var result = _resolveTargetExtensionOverride(
        target: receiver,
        propertyName: SimpleIdentifierImpl(token: node.propertyName),
        hasRead: true,
        hasWrite: true,
        assignmentToMethodOnMissingWrite:
            node.parent2 is IncrementOrDecrementExpression,
      );
      return _propertyReadWriteTargetResult(result);
    }

    if (receiver case TypeLiteralImpl(
      type: NamedTypeImpl(element: InterfaceElement typeReference),
    )) {
      var result = _resolveTargetInterfaceElement(
        typeReference: typeReference,
        isCascaded: false,
        propertyName: SimpleIdentifierImpl(token: node.propertyName),
        hasRead: true,
        hasWrite: true,
      );
      return _propertyReadWriteTargetResult(result);
    }

    if (receiver case SimpleIdentifierImpl(
      element: InterfaceElement typeReference,
    )) {
      var result = _resolveTargetInterfaceElement(
        typeReference: typeReference,
        isCascaded: false,
        propertyName: SimpleIdentifierImpl(token: node.propertyName),
        hasRead: true,
        hasWrite: true,
      );
      return _propertyReadWriteTargetResult(result);
    }

    var receiverType = receiver.typeOrThrow;

    if (receiverType is NeverType &&
        receiverType.nullabilitySuffix == NullabilitySuffix.none) {
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
      diagnosticReporter.report(diag.useOfVoidResult.at(node.propertyName));
      return (
        read: InvalidNamedReadResolutionImpl(
          candidates: const [],
          recovery: null,
          type: InvalidTypeImpl.instance,
        ),
        write: InvalidNamedWriteResolutionImpl(
          acceptedType: InvalidTypeImpl.instance,
          candidates: const [],
          recovery: null,
        ),
        readExpressionInfo: null,
      );
    }

    if (_typeSystem.isDynamicBounded(receiverType)) {
      return (
        read: DynamicPropertyReadResolutionImpl(),
        write: const DynamicPropertyWriteResolutionImpl(),
        readExpressionInfo: null,
      );
    }

    var result = _resolver.typePropertyResolver.resolve(
      receiver: receiver,
      receiverType: receiverType,
      name: node.propertyName.lexeme,
      hasRead: true,
      hasWrite: true,
      propertyErrorEntity: node.propertyName,
      nameErrorEntity: node.propertyName,
      parentNode: node.parent2,
    );

    var functionCallTearOffResolution = _functionCallTearOffResolution(
      receiverType: receiverType,
      isCall: node.propertyName.lexeme == MethodElement.CALL_METHOD_NAME,
      callFunctionType: result.callFunctionType,
    );

    var readElement = result.getter2;
    var writeElement = result.setter2;
    _checkForStaticMember2(
      target: receiver,
      propertyName: node.propertyName.lexeme,
      propertyNameEntity: node.propertyName,
      element: readElement,
    );
    _checkForStaticMember2(
      target: receiver,
      propertyName: node.propertyName.lexeme,
      propertyNameEntity: node.propertyName,
      element: writeElement,
    );

    if (result.needsGetterError) {
      diagnosticReporter.report(
        diag.undefinedGetter
            .withArguments(
              memberName: node.propertyName.lexeme,
              type: receiverType,
            )
            .at(node.propertyName),
      );
    }
    if (result.needsSetterError) {
      AssignmentVerifier(diagnosticReporter).verifyPropertyAssignmentTarget(
        node: node,
        requested: null,
        recovery: readElement,
        receiverType: receiverType,
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
      if (_resolver.flowAnalysis.flow case var flow?) {
        var (wrappedPromotedType, expressionInfo) = flow.propertyGet(
          ExpressionPropertyTarget(
            _resolver.flowAnalysis.getExpressionInfo(receiver),
          ),
          node.propertyName.lexeme,
          readElement,
          SharedTypeView(readType),
        );
        readExpressionInfo = expressionInfo;
        readType = wrappedPromotedType?.unwrapTypeView<TypeImpl>() ?? readType;
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
      candidates: [?readElement, ?writeElement],
      recovery: null,
      type: InvalidTypeImpl.instance,
    );
    NamedWriteResolutionImpl? writeResolution =
        _createNamedWriteResolutionWithElement(writeElement);
    writeResolution ??= InvalidNamedWriteResolutionImpl(
      acceptedType: InvalidTypeImpl.instance,
      candidates: [?writeElement, ?readElement],
      recovery: null,
    );

    return (
      read: readResolution,
      write: writeResolution,
      readExpressionInfo: readExpressionInfo,
    );
  }

  PropertyElementResolverResult resolveSimpleIdentifier({
    required SimpleIdentifierImpl node,
    required bool hasRead,
    required bool hasWrite,
  }) {
    var ancestorCascade = node.ancestorCascade;
    if (ancestorCascade != null) {
      return _resolve(
        node: node,
        target: ancestorCascade.target2,
        isCascaded: true,
        isNullAware: ancestorCascade.isNullAware,
        propertyName: node,
        hasRead: hasRead,
        hasWrite: hasWrite,
      );
    }

    var scopeLookupResult = node.scopeLookupResult!;
    reportDeprecatedExportUse(
      scopeLookupResult: scopeLookupResult,
      nameToken: node.token,
      hasRead: hasRead,
      hasWrite: hasWrite,
    );

    Element? readElementRequested;
    Element? readElementRecovery;
    TypeImpl? getType;
    if (hasRead) {
      var readLookup =
          LexicalLookup.resolveGetter(scopeLookupResult) ??
          _resolver.thisLookupGetter(node);

      var callFunctionType = readLookup?.callFunctionType;
      if (callFunctionType != null) {
        return PropertyElementResolverResult(
          functionTypeCallType: callFunctionType,
        );
      }

      var recordField = readLookup?.recordField;
      if (recordField != null) {
        return PropertyElementResolverResult(recordField: recordField);
      }

      readElementRequested = readLookup?.requested;
      if (readElementRequested is InternalPropertyAccessorElement &&
          !readElementRequested.isStatic) {
        var unpromotedType = readElementRequested.returnType;
        if (_resolver.flowAnalysis.flow case var flow?) {
          var (wrappedPromotedType, expressionInfo) = flow.propertyGet(
            ThisPropertyTarget.singleton,
            node.name,
            readElementRequested,
            SharedTypeView(unpromotedType),
          );
          _resolver.flowAnalysis.storeExpressionInfo(node, expressionInfo);
          getType = wrappedPromotedType?.unwrapTypeView();
        }
        getType ??= unpromotedType;
      }
      _resolver.checkReadOfNotAssignedLocalVariable(node, readElementRequested);
    }

    Element? writeElementRequested;
    Element? writeElementRecovery;
    if (hasWrite) {
      var writeLookup =
          LexicalLookup.resolveSetter(scopeLookupResult) ??
          _resolver.thisLookupSetter(node);
      writeElementRequested = writeLookup?.requested;
      writeElementRecovery = writeLookup?.recovery;

      AssignmentVerifier(diagnosticReporter).verify(
        node: node,
        requested: writeElementRequested,
        recovery: writeElementRecovery,
        receiverType: null,
      );
    }

    return PropertyElementResolverResult(
      readElementRequested2: readElementRequested,
      readElementRecovery2: readElementRecovery,
      writeElementRequested2: writeElementRequested,
      writeElementRecovery2: writeElementRecovery,
      getType: getType,
    );
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

    var writeResolution = _resolveUnqualifiedNameWrite(
      node: node,
      name: node.name,
      scopeLookupResult: scopeLookupResult,
    );
    return writeResolution;
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

    var readResult = _resolveUnqualifiedNameRead(node, scopeLookupResult);
    var writeResolution = _resolveUnqualifiedNameWrite(
      node: node,
      name: node.name,
      scopeLookupResult: scopeLookupResult,
    );
    return (
      read: readResult.resolution,
      write: writeResolution,
      readExpressionInfo: readResult.expressionInfo,
    );
  }

  /// If the [element] is not static, report the error on the [identifier].
  ///
  /// Returns `true` if an error was reported.
  bool _checkForStaticAccessToInstanceMember(
    SimpleIdentifier identifier,
    ExecutableElement element,
  ) {
    if (element.isStatic) return false;

    diagnosticReporter.report(
      diag.staticAccessToInstanceMember
          .withArguments(name: identifier.name)
          .at(identifier),
    );
    return true;
  }

  void _checkForStaticMember(
    Expression target,
    SimpleIdentifier propertyName,
    ExecutableElement? element,
  ) {
    _checkForStaticMember2(
      target: target,
      propertyName: propertyName.name,
      propertyNameEntity: propertyName,
      element: element,
    );
  }

  void _checkForStaticMember2({
    required Expression target,
    required String propertyName,
    required SyntacticEntity propertyNameEntity,
    required ExecutableElement? element,
  }) {
    if (element != null && element.isStatic) {
      if (target is ExtensionOverride) {
        diagnosticReporter.report(
          diag.extensionOverrideAccessToStaticMember.at(propertyNameEntity),
        );
      } else {
        var enclosingElement = element.enclosingElement;
        if (enclosingElement is ExtensionElement &&
            enclosingElement.name == null) {
          _resolver.diagnosticReporter.report(
            diag.instanceAccessToStaticMemberOfUnnamedExtension
                .withArguments(
                  name: propertyName,
                  kind: element.kind.displayName,
                )
                .at(propertyNameEntity),
          );
        } else {
          // It is safe to assume that `enclosingElement.name` is non-`null`
          // because it can only be `null` for extensions, and we handle that
          // case above.
          diagnosticReporter.report(
            diag.instanceAccessToStaticMember
                .withArguments(
                  memberName: propertyName,
                  memberKind: element.kind.displayName,
                  enclosingElementName: enclosingElement!.name!,
                  enclosingElementKind: enclosingElement is MixinElement
                      ? 'mixin'
                      : enclosingElement.kind.displayName,
                )
                .at(propertyNameEntity),
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
    MethodIndexReadResolutionImpl? methodResolution;
    if (element is InternalMethodElement &&
        element.formalParameters.length == 1) {
      methodResolution = MethodIndexReadResolutionImpl(
        element: element,
        type: element.returnType,
      );
    }
    if (isInvalid) {
      return InvalidIndexReadResolutionImpl(recovery: methodResolution);
    }
    if (methodResolution != null) return methodResolution;
    if (atDynamicTarget) return const DynamicIndexReadResolutionImpl();
    return InvalidIndexReadResolutionImpl(recovery: null);
  }

  IndexWriteResolutionImpl _createIndexWriteResolution(
    InternalExecutableElement? element, {
    required bool atDynamicTarget,
    required bool isInvalid,
  }) {
    MethodIndexWriteResolutionImpl? methodResolution;
    if (element is InternalMethodElement &&
        element.formalParameters.length == 2) {
      methodResolution = MethodIndexWriteResolutionImpl(element: element);
    }
    if (isInvalid) {
      return InvalidIndexWriteResolutionImpl(recovery: methodResolution);
    }
    if (methodResolution != null) return methodResolution;
    if (atDynamicTarget) return const DynamicIndexWriteResolutionImpl();
    return InvalidIndexWriteResolutionImpl(recovery: null);
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

  bool _isAccessible(ExecutableElement element) {
    return element.isAccessibleIn(_definingLibrary);
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
    var readElement = result.readElement2;
    var writeElement = result.writeElement2;
    var readResolution = _createPropertyReadResolution(
      element: readElement,
      recordField: result.recordField,
      type: result.getType as TypeImpl?,
    );
    readResolution ??= InvalidNamedReadResolutionImpl(
      candidates: [?readElement, ?result.readElementRecovery2, ?writeElement],
      recovery: null,
      type: InvalidTypeImpl.instance,
    );
    var writeResolution =
        _createNamedWriteResolutionWithElement(writeElement) ??
        InvalidNamedWriteResolutionImpl(
          acceptedType: InvalidTypeImpl.instance,
          candidates: [
            ?writeElement,
            ?result.writeElementRecovery2,
            ?readElement,
          ],
          recovery: null,
        );
    return (
      read: readResolution,
      write: writeResolution,
      readExpressionInfo: null,
    );
  }

  void _reportUnresolvedIndex(
    AstNode node,
    LocatableDiagnostic locatableDiagnostic,
  ) {
    var (leftBracket, rightBracket) = switch (node) {
      CascadeIndexAssignmentTarget(:var leftBracket, :var rightBracket) => (
        leftBracket,
        rightBracket,
      ),
      CascadeIndexExpression(:var leftBracket, :var rightBracket) => (
        leftBracket,
        rightBracket,
      ),
      IndexAssignmentTarget(:var leftBracket, :var rightBracket) => (
        leftBracket,
        rightBracket,
      ),
      IndexExpression2(:var leftBracket, :var rightBracket) => (
        leftBracket,
        rightBracket,
      ),
      IndexExpression(:var leftBracket, :var rightBracket) => (
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
    required SimpleIdentifier propertyName,
    required bool hasRead,
    required bool hasWrite,
    PrefixedIdentifierImpl? originalNode,
  }) {
    //
    // If this property access is of the form 'C.m' where 'C' is a class,
    // then we don't call resolveProperty(...) which walks up the class
    // hierarchy, instead we just look for the member in the type only.  This
    // does not apply to conditional property accesses (i.e. 'C?.m').
    //
    if (target is IdentifierImpl) {
      var targetElement = target.element;
      if (targetElement is InterfaceElement) {
        return _resolveTargetInterfaceElement(
          typeReference: targetElement,
          isCascaded: isCascaded,
          propertyName: propertyName,
          hasRead: hasRead,
          hasWrite: hasWrite,
        );
      } else if (targetElement is TypeAliasElement) {
        var aliasedType = targetElement.aliasedType;
        if (aliasedType is InterfaceType) {
          return _resolveTargetInterfaceElement(
            typeReference: aliasedType.element,
            isCascaded: isCascaded,
            propertyName: propertyName,
            hasRead: hasRead,
            hasWrite: hasWrite,
          );
        }
      }
    }

    //
    // If this property access is of the form 'E.m' where 'E' is an extension,
    // then look for the member in the extension. This does not apply to
    // conditional property accesses (i.e. 'C?.m').
    //
    if (target is IdentifierImpl) {
      var targetElement = target.element;
      if (targetElement is ExtensionElement) {
        return _resolveTargetExtensionElement(
          extension: targetElement,
          propertyName: propertyName,
          hasRead: hasRead,
          hasWrite: hasWrite,
        );
      }
    }

    var targetType = target.typeOrThrow;

    if (targetType is VoidType) {
      diagnosticReporter.report(diag.useOfVoidResult.at(propertyName));
      return PropertyElementResolverResult();
    }

    if (isNullAware) {
      targetType = _typeSystem.promoteToNonNull(targetType);
    }

    if (propertyName.name == MethodElement.CALL_METHOD_NAME) {
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
        diagnosticReporter.report(
          diag.undefinedGetterOnFunctionType
              .withArguments(
                getterName: propertyName.name,
                functionTypeAliasName: target.type.qualifiedName,
              )
              .at(propertyName),
        );
      } else {
        diagnosticReporter.report(
          diag.undefinedSetterOnFunctionType
              .withArguments(
                setterName: propertyName.name,
                functionTypeAliasName: target.type.qualifiedName,
              )
              .at(propertyName),
        );
      }
      return PropertyElementResolverResult();
    }

    var result = _resolver.typePropertyResolver.resolve(
      receiver: target,
      receiverType: targetType,
      name: propertyName.name,
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
      if (_resolver.flowAnalysis.flow case var flow?) {
        var (wrappedPromotedType, expressionInfo) = flow.propertyGet(
          isCascaded
              ? CascadePropertyTarget.singleton
                    as PropertyTarget<ExpressionImpl>
              : ExpressionPropertyTarget(
                  _resolver.flowAnalysis.getExpressionInfo(target),
                ),
          propertyName.name,
          result.getter2,
          SharedTypeView(unpromotedType),
        );
        _resolver.flowAnalysis.storeExpressionInfo(
          originalNode ?? node,
          expressionInfo,
        );
        getType = wrappedPromotedType?.unwrapTypeView();
      }
      getType ??= unpromotedType;

      _checkForStaticMember(target, propertyName, result.getter2);
      if (result.needsGetterError) {
        diagnosticReporter.report(
          diag.undefinedGetter
              .withArguments(memberName: propertyName.name, type: targetType)
              .at(propertyName),
        );
      }
    }

    if (hasWrite) {
      _checkForStaticMember(target, propertyName, result.setter2);
      if (result.needsSetterError) {
        var readResult = _resolver.typePropertyResolver.resolve(
          receiver: target,
          receiverType: targetType,
          name: propertyName.name,
          hasRead: true,
          hasWrite: false,
          propertyErrorEntity: propertyName,
          nameErrorEntity: propertyName,
        );

        AssignmentVerifier(diagnosticReporter).verify(
          node: propertyName,
          requested: null,
          recovery: readResult.getter2,
          receiverType: targetType,
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

  PropertyElementResolverResult _resolveTargetExtensionElement({
    required ExtensionElement extension,
    required SimpleIdentifier propertyName,
    required bool hasRead,
    required bool hasWrite,
  }) {
    var memberName = propertyName.name;

    ExecutableElement? readElement;
    ExecutableElement? readElementRecovery;
    DartType? getType;
    if (hasRead) {
      readElement ??= extension.getGetter(memberName);
      readElement ??= extension.getMethod(memberName);

      if (readElement == null) {
        // This method is only called for extension overrides, and extension
        // overrides can only refer to named extensions.  So it is safe to
        // assume that `extension.name` is non-`null`.
        diagnosticReporter.report(
          diag.undefinedExtensionGetter
              .withArguments(
                getterName: memberName,
                extensionName: extension.name!,
              )
              .at(propertyName),
        );
      } else {
        getType = readElement.returnType;
        if (_checkForStaticAccessToInstanceMember(propertyName, readElement)) {
          readElementRecovery = readElement;
          readElement = null;
        }
      }
    }

    ExecutableElement? writeElement;
    ExecutableElement? writeElementRecovery;
    if (hasWrite) {
      writeElement = extension.getSetter(memberName);

      if (writeElement == null) {
        diagnosticReporter.report(
          diag.undefinedExtensionSetter
              .withArguments(
                setterName: memberName,
                extensionName: extension.name!,
              )
              .at(propertyName),
        );
      } else {
        if (_checkForStaticAccessToInstanceMember(propertyName, writeElement)) {
          writeElementRecovery = writeElement;
          writeElement = null;
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
    required ExtensionOverrideImpl target,
    required SimpleIdentifier propertyName,
    required bool hasRead,
    required bool hasWrite,
    bool assignmentToMethodOnMissingWrite = false,
  }) {
    if (target.parent2 is CascadeExpression) {
      // Report this error and recover by treating it like a non-cascade.
      diagnosticReporter.report(
        diag.extensionOverrideWithCascade.at(target.name),
      );
    }

    var element = target.element;
    var memberName = propertyName.name;

    var result = _extensionResolver.getOverrideMember(target, memberName);

    ExecutableElement? readElement;
    DartType? getType;
    if (hasRead) {
      readElement = result.getter2;
      if (readElement == null) {
        // This method is only called for extension overrides, and extension
        // overrides can only refer to named extensions.  So it is safe to
        // assume that `element.name` is non-`null`.
        diagnosticReporter.report(
          diag.undefinedExtensionGetter
              .withArguments(
                getterName: memberName,
                extensionName: element.name!,
              )
              .at(propertyName),
        );
      } else {
        getType = readElement.returnType;
      }
      _checkForStaticMember(target, propertyName, readElement);
    }

    ExecutableElement? writeElement;
    if (hasWrite) {
      writeElement = result.setter2;
      if (writeElement == null) {
        if (assignmentToMethodOnMissingWrite && readElement is MethodElement) {
          diagnosticReporter.report(diag.assignmentToMethod.at(propertyName));
        } else {
          // This method is only called for extension overrides, and extension
          // overrides can only refer to named extensions.  So it is safe to
          // assume that `element.name` is non-`null`.
          diagnosticReporter.report(
            diag.undefinedExtensionSetter
                .withArguments(
                  setterName: memberName,
                  extensionName: element.name!,
                )
                .at(propertyName),
          );
        }
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
    required InterfaceElement typeReference,
    required bool isCascaded,
    required SimpleIdentifier propertyName,
    required bool hasRead,
    required bool hasWrite,
    bool resolvingDotShorthand = false,
  }) {
    if (isCascaded) {
      typeReference = _resolver.typeProvider.typeType.element;
    }

    ExecutableElement? readElement;
    ExecutableElement? readElementRecovery;
    DartType? getType;
    if (hasRead) {
      readElement = typeReference.getGetter(propertyName.name);
      if (readElement != null && !_isAccessible(readElement)) {
        readElement = null;
      }

      if (readElement == null) {
        readElement = typeReference.getMethod(propertyName.name);
        if (readElement != null && !_isAccessible(readElement)) {
          readElement = null;
        }
      }

      if (readElement == null) {
        if (_definingLibrary.featureSet.isEnabled(Feature.static_extensions)) {
          // When direct lookups fail, try static extension resolution.
          var result = _resolver.typePropertyResolver.resolveStaticExtension(
            declaration: typeReference,
            name: propertyName.name,
            hasRead: hasRead,
            hasWrite: hasWrite,
            propertyErrorEntity: propertyName,
            nameErrorEntity: propertyName,
          );
          if (result.getter2 != null) {
            readElement = result.getter2;
          }
        }
      }

      if (readElement != null) {
        getType = readElement.returnType;
        if (_checkForStaticAccessToInstanceMember(propertyName, readElement)) {
          readElementRecovery = readElement;
          readElement = null;
        }
      } else {
        if (resolvingDotShorthand) {
          // We didn't resolve to any static getter or static field using the
          // context type.
          diagnosticReporter.report(
            diag.dotShorthandUndefinedGetter
                .withArguments(
                  getterName: propertyName.name,
                  typeName: typeReference.name!,
                )
                .at(propertyName),
          );
        } else {
          var code = typeReference is EnumElement
              ? diag.undefinedEnumConstant
              : diag.undefinedGetter;
          diagnosticReporter.report(
            code
                .withArguments(
                  memberName: propertyName.name,
                  type: typeReference.thisType,
                )
                .at(propertyName),
          );
        }
      }
    }

    ExecutableElement? writeElement;
    ExecutableElement? writeElementRecovery;
    if (hasWrite) {
      writeElement = typeReference.getSetter(propertyName.name);
      if (writeElement != null) {
        if (!_isAccessible(writeElement)) {
          diagnosticReporter.report(
            diag.privateSetter
                .withArguments(name: propertyName.name)
                .at(propertyName),
          );
        }
        if (_checkForStaticAccessToInstanceMember(propertyName, writeElement)) {
          writeElementRecovery = writeElement;
          writeElement = null;
        }
      } else if (_definingLibrary.featureSet.isEnabled(
        Feature.static_extensions,
      )) {
        // When direct lookups fail, try static extension resolution.
        var result = _resolver.typePropertyResolver.resolveStaticExtension(
          declaration: typeReference,
          name: propertyName.name,
          hasRead: hasRead,
          hasWrite: hasWrite,
          propertyErrorEntity: propertyName,
          nameErrorEntity: propertyName,
        );
        if (result.setter2 != null) {
          writeElementRecovery = writeElement;
          writeElement = result.setter2;
        } else {
          // Recovery, try to use getter.
          writeElementRecovery = typeReference.getGetter(propertyName.name);
          AssignmentVerifier(diagnosticReporter).verify(
            node: propertyName,
            requested: null,
            recovery: writeElementRecovery,
            receiverType: typeReference.thisType,
          );
        }
      } else {
        // Recovery, try to use getter.
        writeElementRecovery = typeReference.getGetter(propertyName.name);
        AssignmentVerifier(diagnosticReporter).verify(
          node: propertyName,
          requested: null,
          recovery: writeElementRecovery,
          receiverType: typeReference.thisType,
        );
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
    required PrefixElement target,
    required SimpleIdentifier identifier,
    required bool hasRead,
    required bool hasWrite,
    required bool forAnnotation,
  }) {
    var lookupResult = target.scope.lookup(identifier.name);
    reportDeprecatedExportUse(
      scopeLookupResult: lookupResult,
      nameToken: identifier.token,
      hasRead: hasRead,
      hasWrite: hasWrite,
    );

    var readElement = lookupResult.getter;
    var writeElement = lookupResult.setter;
    DartType? getType;
    if (hasRead && readElement is PropertyAccessorElement) {
      getType = readElement.returnType;
    }

    if (hasRead && readElement == null || hasWrite && writeElement == null) {
      if (!forAnnotation &&
          !_resolver.libraryFragment.shouldIgnoreUndefined(
            prefix: target.name,
            name: identifier.name,
          )) {
        diagnosticReporter.report(
          diag.undefinedPrefixedName
              .withArguments(
                referenceName: identifier.name,
                prefixName: target.name!,
              )
              .at(identifier),
        );
      }
    }

    return PropertyElementResolverResult(
      readElementRequested2: readElement,
      writeElementRequested2: writeElement,
      getType: getType,
    );
  }

  PropertyElementResolverResult _resolveTargetSuperExpression({
    required ExpressionImpl node,
    required SuperExpression target,
    required SimpleIdentifier propertyName,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (SuperContext.of(target) != SuperContext.valid) {
      return PropertyElementResolverResult();
    }
    var targetType = target.staticType;

    InternalExecutableElement? readElement;
    InternalExecutableElement? writeElement;
    TypeImpl? getType;

    if (targetType is InterfaceTypeImpl) {
      if (hasRead) {
        var name = Name(_definingLibrary.uri, propertyName.name);
        readElement = _resolver.inheritance.getMember(
          targetType.element,
          name,
          forSuper: true,
        );

        if (readElement != null) {
          _checkForStaticMember(target, propertyName, readElement);
        } else {
          // We were not able to find the concrete dispatch target.
          // But we would like to give the user at least some resolution.
          // So, we retry simply looking for an inherited member.
          readElement = _resolver.inheritance.getInherited(
            targetType.element,
            name,
          );
          if (readElement != null) {
            diagnosticReporter.report(
              diag.abstractSuperMemberReference
                  .withArguments(
                    memberKind: readElement.kind.displayName,
                    name: propertyName.name,
                  )
                  .at(propertyName),
            );
          } else {
            diagnosticReporter.report(
              diag.undefinedSuperGetter
                  .withArguments(
                    getterName: propertyName.name,
                    type: targetType,
                  )
                  .at(propertyName),
            );
          }
        }
        var unpromotedType =
            readElement?.returnType ?? _typeSystem.typeProvider.dynamicType;
        if (_resolver.flowAnalysis.flow case var flow?) {
          var (wrappedPromotedType, expressionInfo) = flow.propertyGet(
            SuperPropertyTarget.singleton,
            propertyName.name,
            readElement,
            SharedTypeView(unpromotedType),
          );
          _resolver.flowAnalysis.storeExpressionInfo(node, expressionInfo);
          getType = wrappedPromotedType?.unwrapTypeView();
        }
        getType ??= unpromotedType;
      }

      if (hasWrite) {
        writeElement = targetType.lookUpSetter(
          propertyName.name,
          _definingLibrary,
          concrete: true,
          inherited: true,
        );

        if (writeElement != null) {
          _checkForStaticMember(target, propertyName, writeElement);
        } else {
          // We were not able to find the concrete dispatch target.
          // But we would like to give the user at least some resolution.
          // So, we retry without the "concrete" requirement.
          writeElement = targetType.lookUpSetter(
            propertyName.name,
            _definingLibrary,
            inherited: true,
          );
          if (writeElement != null) {
            diagnosticReporter.report(
              diag.abstractSuperMemberReference
                  .withArguments(
                    memberKind: writeElement.kind.displayName,
                    name: propertyName.name,
                  )
                  .at(propertyName),
            );
          } else {
            diagnosticReporter.report(
              diag.undefinedSuperSetter
                  .withArguments(
                    setterName: propertyName.name,
                    type: targetType,
                  )
                  .at(propertyName),
            );
          }
        }
      }
    }

    return PropertyElementResolverResult(
      readElementRequested2: readElement,
      writeElementRequested2: writeElement,
      getType: getType,
    );
  }

  ({NamedReadResolutionImpl resolution, ExpressionInfo? expressionInfo})
  _resolveUnqualifiedNameRead(
    UnqualifiedNameAssignmentTargetImpl node,
    ScopeLookupResult scopeLookupResult,
  ) {
    var readLookup =
        LexicalLookup.resolveGetter(scopeLookupResult) ??
        _resolver.thisLookupGetter2(node);
    var readElementRequested = readLookup?.requested;
    var readElementRecovery = readLookup?.recovery;

    if (readElementRequested == null) {
      diagnosticReporter.report(
        diag.undefinedIdentifier.withArguments(name: node.name.lexeme).at(node),
      );
    }

    _resolver.checkReadOfNotAssignedLocalVariable2(
      node,
      name: node.name.lexeme,
      element: readElementRequested,
    );

    ExpressionInfo? expressionInfo;
    TypeImpl? readType;
    if (readElementRequested is InternalVariableElement) {
      readType = readElementRequested.type;
      var flow = _resolver.flowAnalysis.flow;
      if (readElementRequested is PromotableElementImpl && flow != null) {
        SharedTypeView? promotedType;
        (promotedType, expressionInfo) = flow.variableRead(
          readElementRequested,
        );
        readType = promotedType?.unwrapTypeView<TypeImpl>() ?? readType;
      }
    } else if (readElementRequested is InternalGetterElement) {
      readType = readElementRequested.returnType;
      var flow = _resolver.flowAnalysis.flow;
      if (!readElementRequested.isStatic && flow != null) {
        SharedTypeView? promotedType;
        (promotedType, expressionInfo) = flow.propertyGet(
          ThisPropertyTarget.singleton,
          node.name.lexeme,
          readElementRequested,
          SharedTypeView(readType),
        );
        readType = promotedType?.unwrapTypeView<TypeImpl>() ?? readType;
      }
    } else if (readElementRequested is InternalExecutableElement) {
      readType = readElementRequested.type;
    }

    NamedReadResolutionImpl? resolution = _createNamedReadResolutionWithElement(
      readElementRequested,
      type: readType,
    );
    resolution ??= InvalidNamedReadResolutionImpl(
      candidates: [?readElementRequested, ?readElementRecovery],
      recovery: _createNamedReadResolutionWithElement(
        readElementRecovery,
        type: _namedReadType(readElementRecovery),
      ),
      type: InvalidTypeImpl.instance,
    );
    return (resolution: resolution, expressionInfo: expressionInfo);
  }

  NamedWriteResolutionImpl _resolveUnqualifiedNameWrite({
    required AstNode node,
    required Token name,
    required ScopeLookupResult scopeLookupResult,
  }) {
    var writeLookup =
        LexicalLookup.resolveSetter(scopeLookupResult) ??
        ThisLookup.lookupSetter2(_resolver, node: node, name: name.lexeme);
    var writeElementRequested = writeLookup?.requested;
    var writeElementRecovery = writeLookup?.recovery;

    var assignmentVerifier = AssignmentVerifier(diagnosticReporter);
    if (node is ForEachPartsWithIdentifier) {
      assignmentVerifier.verifyUnqualifiedName(
        node: node.identifier2,
        name: node.identifier2,
        requested: writeElementRequested,
        recovery: writeElementRecovery,
      );
    } else {
      var unqualifiedNode = node as UnqualifiedNameAssignmentTarget;
      assignmentVerifier.verifyUnqualifiedName(
        node: unqualifiedNode,
        name: unqualifiedNode.name,
        requested: writeElementRequested,
        recovery: writeElementRecovery,
      );
    }

    var requestedResolution = _createNamedWriteResolutionWithElement(
      writeElementRequested,
    );
    if (requestedResolution != null) return requestedResolution;

    return InvalidNamedWriteResolutionImpl(
      acceptedType: InvalidTypeImpl.instance,
      candidates: [?writeElementRequested, ?writeElementRecovery],
      recovery: _createNamedWriteResolutionWithElement(writeElementRecovery),
    );
  }

  PropertyElementResolverResult _toIndexResult(
    SimpleResolutionResult result, {
    required bool atDynamicTarget,
    required bool hasRead,
    required bool hasWrite,
  }) {
    var readElement = result.getter2;
    var writeElement = result.setter2;

    var contextType = hasRead
        ? readElement?.firstParameterType
        : writeElement?.firstParameterType;

    return PropertyElementResolverResult(
      atDynamicTarget: atDynamicTarget,
      readElementRequested2: readElement,
      writeElementRequested2: writeElement,
      indexContextType: contextType ?? UnknownInferredType.instance,
    );
  }
}

class PropertyElementResolverResult {
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
