// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/lexical_lookup.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/error/assignment_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scope_helpers.dart';
import 'package:analyzer/src/generated/super_context.dart';

class PropertyElementResolver with ScopeHelpers {
  final ResolverVisitor _resolver;

  PropertyElementResolver(this._resolver);

  @override
  ErrorReporter get errorReporter => _resolver.errorReporter;

  LibraryElementImpl get _definingLibrary => _resolver.definingLibrary;

  ExtensionMemberResolver get _extensionResolver => _resolver.extensionResolver;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  PropertyElementResolverResult resolveDotShorthand(
      DotShorthandPropertyAccessImpl node) {
    if (_resolver.isDotShorthandContextEmpty) {
      // TODO(kallentu): Produce an error here for not being able to find a
      // context type.
      return PropertyElementResolverResult();
    }
    TypeImpl context =
        _resolver.getDotShorthandContext().unwrapTypeSchemaView();

    // The static namespace denoted by `S` is also the namespace denoted by
    // `FutureOr<S>`.
    context = _resolver.typeSystem.futureOrBase(context);

    // TODO(kallentu): Support other context types
    if (context is InterfaceTypeImpl) {
      var identifier = node.propertyName;
      if (identifier.name == 'new') {
        var element =
            context.lookUpConstructor2(identifier.name, _definingLibrary);
        if (element != null) {
          return PropertyElementResolverResult(
            readElementRequested2: element,
            getType: element.returnType,
          );
        }
      } else {
        var contextElement = context.element3;
        return _resolveTargetInterfaceElement(
          typeReference: contextElement,
          isCascaded: false,
          propertyName: identifier,
          hasRead: true,
          hasWrite: false,
        );
      }
    }

    // TODO(kallentu): Produce an error here for not being able to find a
    // property.
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
          CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR,
          ['[]', target.element2.name3!],
        );
      }

      if (hasWrite &&
          result.setter2 == null &&
          result != ExtensionResolutionError.ambiguous) {
        // Extension overrides can only refer to named extensions, so it is safe
        // to assume that `target.staticElement!.name` is non-`null`.
        _reportUnresolvedIndex(
          node,
          CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR,
          ['[]=', target.element2.name3!],
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
      _reportUnresolvedIndex(
        node,
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
      );
      return PropertyElementResolverResult();
    }

    if (identical(targetType, NeverTypeImpl.instance)) {
      // TODO(scheglov): Report directly in TypePropertyResolver?
      errorReporter.atNode(
        target,
        WarningCode.RECEIVER_OF_TYPE_NEVER,
      );
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
      propertyErrorEntity: node.leftBracket,
      nameErrorEntity: target,
    );

    if (hasRead && result.needsGetterError) {
      _reportUnresolvedIndex(
        node,
        target is SuperExpression
            ? CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR
            : CompileTimeErrorCode.UNDEFINED_OPERATOR,
        ['[]', targetType],
      );
    }

    if (hasWrite && result.needsSetterError) {
      _reportUnresolvedIndex(
        node,
        target is SuperExpression
            ? CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR
            : CompileTimeErrorCode.UNDEFINED_OPERATOR,
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
    if (prefixElement is PrefixElement2) {
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

    Element2? readElementRequested;
    Element2? readElementRecovery;
    TypeImpl? getType;
    if (hasRead) {
      var readLookup = LexicalLookup.resolveGetter(scopeLookupResult) ??
          _resolver.thisLookupGetter(node);

      var callFunctionType = readLookup?.callFunctionType;
      if (callFunctionType != null) {
        return PropertyElementResolverResult(
          functionTypeCallType: callFunctionType,
        );
      }

      var recordField = readLookup?.recordField;
      if (recordField != null) {
        return PropertyElementResolverResult(
          recordField: recordField,
        );
      }

      readElementRequested = readLookup?.requested;
      if (readElementRequested is PropertyAccessorElement2OrMember &&
          !readElementRequested.isStatic) {
        var unpromotedType = readElementRequested.returnType;
        getType = _resolver.flowAnalysis.flow
                ?.propertyGet(node, ThisPropertyTarget.singleton, node.name,
                    readElementRequested, SharedTypeView(unpromotedType))
                ?.unwrapTypeView() ??
            unpromotedType;
      }
      _resolver.checkReadOfNotAssignedLocalVariable(node, readElementRequested);
    }

    Element2? writeElementRequested;
    Element2? writeElementRecovery;
    if (hasWrite) {
      var writeLookup = LexicalLookup.resolveSetter(scopeLookupResult) ??
          _resolver.thisLookupSetter(node);
      writeElementRequested = writeLookup?.requested;
      writeElementRecovery = writeLookup?.recovery;

      AssignmentVerifier(errorReporter).verify(
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
    ExecutableElement2 element,
  ) {
    if (element.isStatic) return false;

    errorReporter.atNode(
      identifier,
      CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER,
      arguments: [identifier.name],
    );
    return true;
  }

  void _checkForStaticMember(
    Expression target,
    SimpleIdentifier propertyName,
    ExecutableElement2? element,
  ) {
    if (element != null && element.isStatic) {
      if (target is ExtensionOverride) {
        errorReporter.atNode(
          propertyName,
          CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER,
        );
      } else {
        var enclosingElement = element.enclosingElement2;
        if (enclosingElement is ExtensionElement2 &&
            enclosingElement.name3 == null) {
          _resolver.errorReporter.atNode(
            propertyName,
            CompileTimeErrorCode
                .INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION,
            arguments: [
              propertyName.name,
              element.kind.displayName,
            ],
          );
        } else {
          // It is safe to assume that `enclosingElement.name` is non-`null`
          // because it can only be `null` for extensions, and we handle that
          // case above.
          errorReporter.atNode(
            propertyName,
            CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER,
            arguments: [
              propertyName.name,
              element.kind.displayName,
              enclosingElement!.name3!,
              enclosingElement is MixinElement2
                  ? 'mixin'
                  : enclosingElement.kind.displayName,
            ],
          );
        }
      }
    }
  }

  bool _isAccessible(ExecutableElement2 element) {
    return element.isAccessibleIn2(_definingLibrary);
  }

  void _reportUnresolvedIndex(
    IndexExpression node,
    ErrorCode errorCode, [
    List<Object> arguments = const [],
  ]) {
    var leftBracket = node.leftBracket;
    var rightBracket = node.rightBracket;
    var offset = leftBracket.offset;
    var length = rightBracket.end - offset;

    errorReporter.atOffset(
      offset: offset,
      length: length,
      errorCode: errorCode,
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
      if (targetElement is InterfaceElement2) {
        return _resolveTargetInterfaceElement(
          typeReference: targetElement,
          isCascaded: isCascaded,
          propertyName: propertyName,
          hasRead: hasRead,
          hasWrite: hasWrite,
        );
      } else if (targetElement is TypeAliasElement2) {
        var aliasedType = targetElement.aliasedType;
        if (aliasedType is InterfaceType) {
          return _resolveTargetInterfaceElement(
            typeReference: aliasedType.element3,
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
      if (targetElement is ExtensionElement2) {
        return _resolveTargetExtensionElement(
          extension: targetElement,
          propertyName: propertyName,
          hasRead: hasRead,
          hasWrite: hasWrite,
        );
      }
    }

    var targetType = target.typeOrThrow;

    if (propertyName.name == MethodElement2.CALL_METHOD_NAME) {
      if (targetType is FunctionType || targetType.isDartCoreFunction) {
        return PropertyElementResolverResult(
          functionTypeCallType: targetType,
        );
      }
    }

    if (targetType is VoidType) {
      errorReporter.atNode(
        propertyName,
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
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
        errorReporter.atNode(
          propertyName,
          CompileTimeErrorCode.UNDEFINED_GETTER_ON_FUNCTION_TYPE,
          arguments: [propertyName.name, target.type.qualifiedName],
        );
      } else {
        errorReporter.atNode(
          propertyName,
          CompileTimeErrorCode.UNDEFINED_SETTER_ON_FUNCTION_TYPE,
          arguments: [propertyName.name, target.type.qualifiedName],
        );
      }
      return PropertyElementResolverResult();
    }

    var result = _resolver.typePropertyResolver.resolve(
      receiver: target,
      receiverType: targetType,
      name: propertyName.name,
      propertyErrorEntity: propertyName,
      nameErrorEntity: propertyName,
    );

    TypeImpl? getType;
    if (hasRead) {
      var unpromotedType = switch (result.getter2) {
        MethodElement2OrMember(:var type) => type,
        PropertyAccessorElement2OrMember(:var returnType) => returnType,
        _ => result.recordField?.type ?? _typeSystem.typeProvider.dynamicType
      };
      getType = _resolver.flowAnalysis.flow
              ?.propertyGet(
                  node,
                  isCascaded
                      ? CascadePropertyTarget.singleton
                          as PropertyTarget<ExpressionImpl>
                      : ExpressionPropertyTarget(target),
                  propertyName.name,
                  result.getter2,
                  SharedTypeView(unpromotedType))
              ?.unwrapTypeView() ??
          unpromotedType;

      _checkForStaticMember(target, propertyName, result.getter2);
      if (result.needsGetterError) {
        errorReporter.atNode(
          propertyName,
          CompileTimeErrorCode.UNDEFINED_GETTER,
          arguments: [propertyName.name, targetType],
        );
      }
    }

    if (hasWrite) {
      _checkForStaticMember(target, propertyName, result.setter2);
      if (result.needsSetterError) {
        AssignmentVerifier(errorReporter).verify(
          node: propertyName,
          requested: null,
          recovery: result.getter2,
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
    required ExtensionElement2 extension,
    required SimpleIdentifier propertyName,
    required bool hasRead,
    required bool hasWrite,
  }) {
    var memberName = propertyName.name;

    ExecutableElement2? readElement;
    ExecutableElement2? readElementRecovery;
    DartType? getType;
    if (hasRead) {
      readElement ??= extension.getGetter2(memberName);
      readElement ??= extension.getMethod2(memberName);

      if (readElement == null) {
        // This method is only called for extension overrides, and extension
        // overrides can only refer to named extensions.  So it is safe to
        // assume that `extension.name` is non-`null`.
        errorReporter.atNode(
          propertyName,
          CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER,
          arguments: [memberName, extension.name3!],
        );
      } else {
        getType = readElement.returnType;
        if (_checkForStaticAccessToInstanceMember(propertyName, readElement)) {
          readElementRecovery = readElement;
          readElement = null;
        }
      }
    }

    ExecutableElement2? writeElement;
    ExecutableElement2? writeElementRecovery;
    if (hasWrite) {
      writeElement = extension.getSetter2(memberName);

      if (writeElement == null) {
        errorReporter.atNode(
          propertyName,
          CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER,
          arguments: [memberName, extension.name3!],
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
      errorReporter.atToken(
        target.name,
        CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE,
      );
    }

    var element = target.element2;
    var memberName = propertyName.name;

    var result = _extensionResolver.getOverrideMember(target, memberName);

    ExecutableElement2? readElement;
    DartType? getType;
    if (hasRead) {
      readElement = result.getter2;
      if (readElement == null) {
        // This method is only called for extension overrides, and extension
        // overrides can only refer to named extensions.  So it is safe to
        // assume that `element.name` is non-`null`.
        errorReporter.atNode(
          propertyName,
          CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER,
          arguments: [memberName, element.name3!],
        );
      } else {
        getType = readElement.returnType;
      }
      _checkForStaticMember(target, propertyName, readElement);
    }

    ExecutableElement2? writeElement;
    if (hasWrite) {
      writeElement = result.setter2;
      if (writeElement == null) {
        // This method is only called for extension overrides, and extension
        // overrides can only refer to named extensions.  So it is safe to
        // assume that `element.name` is non-`null`.
        errorReporter.atNode(
          propertyName,
          CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER,
          arguments: [memberName, element.name3!],
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
    required InterfaceElement2 typeReference,
    required bool isCascaded,
    required SimpleIdentifier propertyName,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (isCascaded) {
      typeReference = _resolver.typeProvider.typeType.element3;
    }

    ExecutableElement2? readElement;
    ExecutableElement2? readElementRecovery;
    DartType? getType;
    if (hasRead) {
      readElement = typeReference.getGetter2(propertyName.name);
      if (readElement != null && !_isAccessible(readElement)) {
        readElement = null;
      }

      if (readElement == null) {
        readElement = typeReference.getMethod2(propertyName.name);
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
        var code = typeReference is EnumElement2
            ? CompileTimeErrorCode.UNDEFINED_ENUM_CONSTANT
            : CompileTimeErrorCode.UNDEFINED_GETTER;
        errorReporter.atNode(
          propertyName,
          code,
          arguments: [propertyName.name, typeReference.name3!],
        );
      }
    }

    ExecutableElement2? writeElement;
    ExecutableElement2? writeElementRecovery;
    if (hasWrite) {
      writeElement = typeReference.getSetter2(propertyName.name);
      if (writeElement != null) {
        if (!_isAccessible(writeElement)) {
          errorReporter.atNode(
            propertyName,
            CompileTimeErrorCode.PRIVATE_SETTER,
            arguments: [propertyName.name],
          );
        }
        if (_checkForStaticAccessToInstanceMember(propertyName, writeElement)) {
          writeElementRecovery = writeElement;
          writeElement = null;
        }
      } else {
        // Recovery, try to use getter.
        writeElementRecovery = typeReference.getGetter2(propertyName.name);
        AssignmentVerifier(errorReporter).verify(
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
    required PrefixElement2 target,
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

    var readElement = lookupResult.getter2;
    var writeElement = lookupResult.setter2;
    DartType? getType;
    if (hasRead && readElement is PropertyAccessorElement2) {
      getType = readElement.returnType;
    }

    if (hasRead && readElement == null || hasWrite && writeElement == null) {
      if (!forAnnotation &&
          !_resolver.libraryFragment.shouldIgnoreUndefined(
            prefix: target.name3,
            name: identifier.name,
          )) {
        errorReporter.atNode(
          identifier,
          CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME,
          arguments: [identifier.name, target.name3!],
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

    ExecutableElement2OrMember? readElement;
    ExecutableElement2OrMember? writeElement;
    TypeImpl? getType;

    if (targetType is InterfaceTypeImpl) {
      if (hasRead) {
        var name = Name(_definingLibrary.source.uri, propertyName.name);
        readElement = _resolver.inheritance
            .getMember4(targetType.element3, name, forSuper: true);

        if (readElement != null) {
          _checkForStaticMember(target, propertyName, readElement);
        } else {
          // We were not able to find the concrete dispatch target.
          // But we would like to give the user at least some resolution.
          // So, we retry simply looking for an inherited member.
          readElement =
              _resolver.inheritance.getInherited4(targetType.element3, name);
          if (readElement != null) {
            errorReporter.atNode(
              propertyName,
              CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
              arguments: [readElement.kind.displayName, propertyName.name],
            );
          } else {
            errorReporter.atNode(
              propertyName,
              CompileTimeErrorCode.UNDEFINED_SUPER_GETTER,
              arguments: [propertyName.name, targetType],
            );
          }
        }
        var unpromotedType =
            readElement?.returnType ?? _typeSystem.typeProvider.dynamicType;
        getType = _resolver.flowAnalysis.flow
                ?.propertyGet(
                    node,
                    SuperPropertyTarget.singleton,
                    propertyName.name,
                    readElement,
                    SharedTypeView(unpromotedType))
                ?.unwrapTypeView() ??
            unpromotedType;
      }

      if (hasWrite) {
        writeElement = targetType.lookUpSetter3(
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
          writeElement = targetType.lookUpSetter3(
            propertyName.name,
            _definingLibrary,
            inherited: true,
          );
          if (writeElement != null) {
            errorReporter.atNode(
              propertyName,
              CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
              arguments: [writeElement.kind.displayName, propertyName.name],
            );
          } else {
            errorReporter.atNode(
              propertyName,
              CompileTimeErrorCode.UNDEFINED_SUPER_SETTER,
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
  final Element2? readElementRequested2;
  final Element2? readElementRecovery2;
  final Element2? writeElementRequested2;
  final Element2? writeElementRecovery2;
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

  Element2? get readElement2 {
    return readElementRequested2 ?? readElementRecovery2;
  }

  Element2? get writeElement2 {
    return writeElementRequested2 ?? writeElementRecovery2;
  }
}
