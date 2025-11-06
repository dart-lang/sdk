// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
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

    if (context is InterfaceTypeImpl) {
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
            _resolver.diagnosticReporter.atNode(
              node,
              CompileTimeErrorCode
                  .tearoffOfGenerativeConstructorOfAbstractClass,
            );
          }
        }

        // Infer type parameters.
        var elementToInfer = _resolver.inferenceHelper
            .constructorElementToInfer(
              typeElement: context.element,
              constructorName: identifier,
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

    diagnosticReporter.atNode(
      node,
      CompileTimeErrorCode.dotShorthandMissingContext,
    );
    return PropertyElementResolverResult();
  }

  PropertyElementResolverResult resolveIndexExpression({
    required IndexExpressionImpl node,
    required bool hasRead,
    required bool hasWrite,
  }) {
    var target = node.realTarget;

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
          CompileTimeErrorCode.undefinedExtensionOperator,
          ['[]', target.element.name!],
        );
      }

      if (hasWrite &&
          result.setter2 == null &&
          result != ExtensionResolutionError.ambiguous) {
        // Extension overrides can only refer to named extensions, so it is safe
        // to assume that `target.staticElement!.name` is non-`null`.
        _reportUnresolvedIndex(
          node,
          CompileTimeErrorCode.undefinedExtensionOperator,
          ['[]=', target.element.name!],
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
      _reportUnresolvedIndex(node, CompileTimeErrorCode.useOfVoidResult);
      return PropertyElementResolverResult();
    }

    if (identical(targetType, NeverTypeImpl.instance)) {
      // TODO(scheglov): Report directly in TypePropertyResolver?
      diagnosticReporter.atNode(target, WarningCode.receiverOfTypeNever);
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
        target is SuperExpression
            ? CompileTimeErrorCode.undefinedSuperOperator
            : CompileTimeErrorCode.undefinedOperator,
        ['[]', targetType],
      );
    }

    if (hasWrite && result.needsSetterError) {
      _reportUnresolvedIndex(
        node,
        target is SuperExpression
            ? CompileTimeErrorCode.undefinedSuperOperator
            : CompileTimeErrorCode.undefinedOperator,
        ['[]=', targetType],
      );
    }

    return _toIndexResult(
      result,
      atDynamicTarget: targetType is DynamicType,
      hasRead: hasRead,
      hasWrite: hasWrite,
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
  }) {
    var target = node.realTarget;
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
      isCascaded: node.target == null,
      isNullAware: node.isNullAware,
      propertyName: propertyName,
      hasRead: hasRead,
      hasWrite: hasWrite,
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
        target: ancestorCascade.target,
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
        getType =
            _resolver.flowAnalysis.flow
                ?.propertyGet(
                  node,
                  ThisPropertyTarget.singleton,
                  node.name,
                  readElementRequested,
                  SharedTypeView(unpromotedType),
                )
                ?.unwrapTypeView() ??
            unpromotedType;
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

  /// If the [element] is not static, report the error on the [identifier].
  ///
  /// Returns `true` if an error was reported.
  bool _checkForStaticAccessToInstanceMember(
    SimpleIdentifier identifier,
    ExecutableElement element,
  ) {
    if (element.isStatic) return false;

    diagnosticReporter.atNode(
      identifier,
      CompileTimeErrorCode.staticAccessToInstanceMember,
      arguments: [identifier.name],
    );
    return true;
  }

  void _checkForStaticMember(
    Expression target,
    SimpleIdentifier propertyName,
    ExecutableElement? element,
  ) {
    if (element != null && element.isStatic) {
      if (target is ExtensionOverride) {
        diagnosticReporter.atNode(
          propertyName,
          CompileTimeErrorCode.extensionOverrideAccessToStaticMember,
        );
      } else {
        var enclosingElement = element.enclosingElement;
        if (enclosingElement is ExtensionElement &&
            enclosingElement.name == null) {
          _resolver.diagnosticReporter.atNode(
            propertyName,
            CompileTimeErrorCode.instanceAccessToStaticMemberOfUnnamedExtension,
            arguments: [propertyName.name, element.kind.displayName],
          );
        } else {
          // It is safe to assume that `enclosingElement.name` is non-`null`
          // because it can only be `null` for extensions, and we handle that
          // case above.
          diagnosticReporter.atNode(
            propertyName,
            CompileTimeErrorCode.instanceAccessToStaticMember,
            arguments: [
              propertyName.name,
              element.kind.displayName,
              enclosingElement!.name!,
              enclosingElement is MixinElement
                  ? 'mixin'
                  : enclosingElement.kind.displayName,
            ],
          );
        }
      }
    }
  }

  bool _isAccessible(ExecutableElement element) {
    return element.isAccessibleIn(_definingLibrary);
  }

  void _reportUnresolvedIndex(
    IndexExpression node,
    DiagnosticCode diagnosticCode, [
    List<Object> arguments = const [],
  ]) {
    var leftBracket = node.leftBracket;
    var rightBracket = node.rightBracket;
    var offset = leftBracket.offset;
    var length = rightBracket.end - offset;

    diagnosticReporter.atOffset(
      offset: offset,
      length: length,
      diagnosticCode: diagnosticCode,
      arguments: arguments,
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

    if (propertyName.name == MethodElement.CALL_METHOD_NAME) {
      if (targetType is FunctionType || targetType.isDartCoreFunction) {
        return PropertyElementResolverResult(functionTypeCallType: targetType);
      }
    }

    if (targetType is VoidType) {
      diagnosticReporter.atNode(
        propertyName,
        CompileTimeErrorCode.useOfVoidResult,
      );
      return PropertyElementResolverResult();
    }

    if (isNullAware) {
      targetType = _typeSystem.promoteToNonNull(targetType);
    }

    if (target is TypeLiteralImpl && target.type.type is FunctionType) {
      // There is no possible resolution for a property access of a function
      // type literal (which can only be a type instantiation of a type alias
      // of a function type).
      if (hasRead) {
        diagnosticReporter.atNode(
          propertyName,
          CompileTimeErrorCode.undefinedGetterOnFunctionType,
          arguments: [propertyName.name, target.type.qualifiedName],
        );
      } else {
        diagnosticReporter.atNode(
          propertyName,
          CompileTimeErrorCode.undefinedSetterOnFunctionType,
          arguments: [propertyName.name, target.type.qualifiedName],
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
      getType =
          _resolver.flowAnalysis.flow
              ?.propertyGet(
                node,
                isCascaded
                    ? CascadePropertyTarget.singleton
                          as PropertyTarget<ExpressionImpl>
                    : ExpressionPropertyTarget(target),
                propertyName.name,
                result.getter2,
                SharedTypeView(unpromotedType),
              )
              ?.unwrapTypeView() ??
          unpromotedType;

      _checkForStaticMember(target, propertyName, result.getter2);
      if (result.needsGetterError) {
        diagnosticReporter.atNode(
          propertyName,
          CompileTimeErrorCode.undefinedGetter,
          arguments: [propertyName.name, targetType],
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
        diagnosticReporter.atNode(
          propertyName,
          CompileTimeErrorCode.undefinedExtensionGetter,
          arguments: [memberName, extension.name!],
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
        diagnosticReporter.atNode(
          propertyName,
          CompileTimeErrorCode.undefinedExtensionSetter,
          arguments: [memberName, extension.name!],
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
  }) {
    if (target.parent is CascadeExpression) {
      // Report this error and recover by treating it like a non-cascade.
      diagnosticReporter.atToken(
        target.name,
        CompileTimeErrorCode.extensionOverrideWithCascade,
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
        diagnosticReporter.atNode(
          propertyName,
          CompileTimeErrorCode.undefinedExtensionGetter,
          arguments: [memberName, element.name!],
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
        // This method is only called for extension overrides, and extension
        // overrides can only refer to named extensions.  So it is safe to
        // assume that `element.name` is non-`null`.
        diagnosticReporter.atNode(
          propertyName,
          CompileTimeErrorCode.undefinedExtensionSetter,
          arguments: [memberName, element.name!],
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
          diagnosticReporter.atNode(
            propertyName,
            CompileTimeErrorCode.dotShorthandUndefinedGetter,
            arguments: [propertyName.name, typeReference.name!],
          );
        } else {
          var code = typeReference is EnumElement
              ? CompileTimeErrorCode.undefinedEnumConstant
              : CompileTimeErrorCode.undefinedGetter;
          diagnosticReporter.atNode(
            propertyName,
            code,
            arguments: [propertyName.name, typeReference.name!],
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
          diagnosticReporter.atNode(
            propertyName,
            CompileTimeErrorCode.privateSetter,
            arguments: [propertyName.name],
          );
        }
        if (_checkForStaticAccessToInstanceMember(propertyName, writeElement)) {
          writeElementRecovery = writeElement;
          writeElement = null;
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
        diagnosticReporter.atNode(
          identifier,
          CompileTimeErrorCode.undefinedPrefixedName,
          arguments: [identifier.name, target.name!],
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
              CompileTimeErrorCode.abstractSuperMemberReference
                  .withArguments(
                    memberKind: readElement.kind.displayName,
                    name: propertyName.name,
                  )
                  .at(propertyName),
            );
          } else {
            diagnosticReporter.atNode(
              propertyName,
              CompileTimeErrorCode.undefinedSuperGetter,
              arguments: [propertyName.name, targetType],
            );
          }
        }
        var unpromotedType =
            readElement?.returnType ?? _typeSystem.typeProvider.dynamicType;
        getType =
            _resolver.flowAnalysis.flow
                ?.propertyGet(
                  node,
                  SuperPropertyTarget.singleton,
                  propertyName.name,
                  readElement,
                  SharedTypeView(unpromotedType),
                )
                ?.unwrapTypeView() ??
            unpromotedType;
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
              CompileTimeErrorCode.abstractSuperMemberReference
                  .withArguments(
                    memberKind: writeElement.kind.displayName,
                    name: propertyName.name,
                  )
                  .at(propertyName),
            );
          } else {
            diagnosticReporter.atNode(
              propertyName,
              CompileTimeErrorCode.undefinedSuperSetter,
              arguments: [propertyName.name, targetType],
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
