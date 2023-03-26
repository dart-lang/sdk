// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
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

  LibraryElement get _definingLibrary => _resolver.definingLibrary;

  ExtensionMemberResolver get _extensionResolver => _resolver.extensionResolver;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  PropertyElementResolverResult resolveIndexExpression({
    required IndexExpression node,
    required bool hasRead,
    required bool hasWrite,
  }) {
    var target = node.realTarget;

    if (target is ExtensionOverride) {
      var result = _extensionResolver.getOverrideMember(target, '[]');

      // TODO(scheglov) Change ExtensionResolver to set `needsGetterError`.
      if (hasRead && result.getter == null && !result.isAmbiguous) {
        // Extension overrides can only refer to named extensions, so it is safe
        // to assume that `target.staticElement!.name` is non-`null`.
        _reportUnresolvedIndex(
          node,
          CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR,
          ['[]', target.staticElement!.name!],
        );
      }

      if (hasWrite && result.setter == null && !result.isAmbiguous) {
        // Extension overrides can only refer to named extensions, so it is safe
        // to assume that `target.staticElement!.name` is non-`null`.
        _reportUnresolvedIndex(
          node,
          CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR,
          ['[]=', target.staticElement!.name!],
        );
      }

      return _toIndexResult(
        result,
        hasRead: hasRead,
        hasWrite: hasWrite,
      );
    }

    var targetType = target.typeOrThrow;
    targetType = _typeSystem.resolveToBound(targetType);

    if (targetType is VoidType) {
      // TODO(scheglov) Report directly in TypePropertyResolver?
      _reportUnresolvedIndex(
        node,
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
      );
      return PropertyElementResolverResult();
    }

    if (identical(targetType, NeverTypeImpl.instance)) {
      // TODO(scheglov) Report directly in TypePropertyResolver?
      errorReporter.reportErrorForNode(
        WarningCode.RECEIVER_OF_TYPE_NEVER,
        target,
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
      hasRead: hasRead,
      hasWrite: hasWrite,
    );
  }

  PropertyElementResolverResult resolvePrefixedIdentifier({
    required PrefixedIdentifier node,
    required bool hasRead,
    required bool hasWrite,
    bool forAnnotation = false,
  }) {
    var prefix = node.prefix;
    var identifier = node.identifier;

    var prefixElement = prefix.staticElement;
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
    required PropertyAccess node,
    required bool hasRead,
    required bool hasWrite,
  }) {
    var target = node.realTarget;
    var propertyName = node.propertyName;

    if (target is ExtensionOverride) {
      return _resolveTargetExtensionOverride(
        target: target,
        propertyName: propertyName,
        hasRead: hasRead,
        hasWrite: hasWrite,
      );
    }

    if (target is SuperExpression) {
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

    final scopeLookupResult = node.scopeLookupResult!;
    reportDeprecatedExportUse(
      scopeLookupResult: scopeLookupResult,
      node: node,
      hasRead: hasRead,
      hasWrite: hasWrite,
    );

    Element? readElementRequested;
    Element? readElementRecovery;
    DartType? getType;
    if (hasRead) {
      var readLookup = LexicalLookup.resolveGetter(scopeLookupResult) ??
          _resolver.thisLookupGetter(node);

      final callFunctionType = readLookup?.callFunctionType;
      if (callFunctionType != null) {
        return PropertyElementResolverResult(
          functionTypeCallType: callFunctionType,
        );
      }

      final recordField = readLookup?.recordField;
      if (recordField != null) {
        return PropertyElementResolverResult(
          recordField: recordField,
        );
      }

      readElementRequested = _resolver.toLegacyElement(readLookup?.requested);
      if (readElementRequested is PropertyAccessorElement &&
          !readElementRequested.isStatic) {
        var unpromotedType = readElementRequested.returnType;
        getType = _resolver.flowAnalysis.flow?.thisOrSuperPropertyGet(
                node, node.name, readElementRequested, unpromotedType) ??
            unpromotedType;
      }
      _resolver.checkReadOfNotAssignedLocalVariable(node, readElementRequested);
    }

    Element? writeElementRequested;
    Element? writeElementRecovery;
    if (hasWrite) {
      var writeLookup = LexicalLookup.resolveSetter(scopeLookupResult) ??
          _resolver.thisLookupSetter(node);
      writeElementRequested = _resolver.toLegacyElement(writeLookup?.requested);
      writeElementRecovery = _resolver.toLegacyElement(writeLookup?.recovery);

      AssignmentVerifier(_resolver.definingLibrary, errorReporter).verify(
        node: node,
        requested: writeElementRequested,
        recovery: writeElementRecovery,
        receiverType: null,
      );
    }

    return PropertyElementResolverResult(
      readElementRequested: readElementRequested,
      readElementRecovery: readElementRecovery,
      writeElementRequested: writeElementRequested,
      writeElementRecovery: writeElementRecovery,
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

    errorReporter.reportErrorForNode(
      CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER,
      identifier,
      [identifier.name],
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
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER,
          propertyName,
        );
      } else {
        var enclosingElement = element.enclosingElement;
        if (enclosingElement is ExtensionElement &&
            enclosingElement.name == null) {
          _resolver.errorReporter.reportErrorForNode(
              CompileTimeErrorCode
                  .INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION,
              propertyName,
              [
                propertyName.name,
                element.kind.displayName,
              ]);
        } else {
          // It is safe to assume that `enclosingElement.name` is non-`null`
          // because it can only be `null` for extensions, and we handle that
          // case above.
          errorReporter.reportErrorForNode(
              CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER,
              propertyName, [
            propertyName.name,
            element.kind.displayName,
            enclosingElement.name!,
            enclosingElement is MixinElement
                ? 'mixin'
                : enclosingElement.kind.displayName,
          ]);
        }
      }
    }
  }

  bool _isAccessible(ExecutableElement element) {
    return element.isAccessibleIn(_definingLibrary);
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

    errorReporter.reportErrorForOffset(errorCode, offset, length, arguments);
  }

  PropertyElementResolverResult _resolve({
    required Expression node,
    required Expression target,
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
    if (target is Identifier) {
      var targetElement = target.staticElement;
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
    if (target is Identifier) {
      var targetElement = target.staticElement;
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

    if (targetType is FunctionType &&
        propertyName.name == FunctionElement.CALL_METHOD_NAME) {
      return PropertyElementResolverResult(
        functionTypeCallType: targetType,
      );
    }

    if (targetType is VoidType) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
        propertyName,
      );
      return PropertyElementResolverResult();
    }

    if (isNullAware) {
      targetType = _typeSystem.promoteToNonNull(targetType);
    }

    if (target is TypeLiteral && target.type.type is FunctionType) {
      // There is no possible resolution for a property access of a function
      // type literal (which can only be a type instantiation of a type alias
      // of a function type).
      if (hasRead) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_GETTER_ON_FUNCTION_TYPE,
          propertyName,
          [propertyName.name, target.type.name.name],
        );
      } else {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_SETTER_ON_FUNCTION_TYPE,
          propertyName,
          [propertyName.name, target.type.name.name],
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

    DartType? getType;
    if (hasRead) {
      var unpromotedType =
          result.getter?.returnType ?? _typeSystem.typeProvider.dynamicType;
      getType = _resolver.flowAnalysis.flow?.propertyGet(
              node, target, propertyName.name, result.getter, unpromotedType) ??
          unpromotedType;

      _checkForStaticMember(target, propertyName, result.getter);
      if (result.needsGetterError) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_GETTER,
          propertyName,
          [propertyName.name, targetType],
        );
      }
    }

    if (hasWrite) {
      _checkForStaticMember(target, propertyName, result.setter);
      if (result.needsSetterError) {
        AssignmentVerifier(_definingLibrary, errorReporter).verify(
          node: propertyName,
          requested: null,
          recovery: result.getter,
          receiverType: targetType,
        );
      }
    }

    return PropertyElementResolverResult(
      readElementRequested: result.getter,
      readElementRecovery: result.setter,
      writeElementRequested: result.setter,
      writeElementRecovery: result.getter,
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
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER,
          propertyName,
          [memberName, extension.name!],
        );
      } else {
        readElement = _resolver.toLegacyElement(readElement);
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
        errorReporter.reportErrorForNode(
          // This method is only called for extension overrides, and extension
          // overrides can only refer to named extensions.  So it is safe to
          // assume that `extension.name` is non-`null`.
          CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER,
          propertyName,
          [memberName, extension.name!],
        );
      } else {
        writeElement = _resolver.toLegacyElement(writeElement);
        if (_checkForStaticAccessToInstanceMember(propertyName, writeElement)) {
          writeElementRecovery = writeElement;
          writeElement = null;
        }
      }
    }

    return PropertyElementResolverResult(
      readElementRequested: readElement,
      readElementRecovery: readElementRecovery,
      writeElementRequested: writeElement,
      writeElementRecovery: writeElementRecovery,
      getType: getType,
    );
  }

  PropertyElementResolverResult _resolveTargetExtensionOverride({
    required ExtensionOverride target,
    required SimpleIdentifier propertyName,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (target.parent is CascadeExpression) {
      // Report this error and recover by treating it like a non-cascade.
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE,
        target.extensionName,
      );
    }

    var element = target.extensionName.staticElement!;
    var memberName = propertyName.name;

    var result = _extensionResolver.getOverrideMember(target, memberName);

    ExecutableElement? readElement;
    DartType? getType;
    if (hasRead) {
      readElement = result.getter;
      if (readElement == null) {
        // This method is only called for extension overrides, and extension
        // overrides can only refer to named extensions.  So it is safe to
        // assume that `element.name` is non-`null`.
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER,
          propertyName,
          [memberName, element.name!],
        );
      } else {
        getType = readElement.returnType;
      }
      _checkForStaticMember(target, propertyName, readElement);
    }

    ExecutableElement? writeElement;
    if (hasWrite) {
      writeElement = result.setter;
      if (writeElement == null) {
        // This method is only called for extension overrides, and extension
        // overrides can only refer to named extensions.  So it is safe to
        // assume that `element.name` is non-`null`.
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER,
          propertyName,
          [memberName, element.name!],
        );
      }
      _checkForStaticMember(target, propertyName, writeElement);
    }

    return PropertyElementResolverResult(
      readElementRequested: readElement,
      writeElementRequested: writeElement,
      getType: getType,
    );
  }

  PropertyElementResolverResult _resolveTargetInterfaceElement({
    required InterfaceElement typeReference,
    required bool isCascaded,
    required SimpleIdentifier propertyName,
    required bool hasRead,
    required bool hasWrite,
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
        readElement = _resolver.toLegacyElement(readElement);
        getType = readElement.returnType;
        if (_checkForStaticAccessToInstanceMember(propertyName, readElement)) {
          readElementRecovery = readElement;
          readElement = null;
        }
      } else {
        var code = typeReference is EnumElement
            ? CompileTimeErrorCode.UNDEFINED_ENUM_CONSTANT
            : CompileTimeErrorCode.UNDEFINED_GETTER;
        errorReporter.reportErrorForNode(
          code,
          propertyName,
          [propertyName.name, typeReference.name],
        );
      }
    }

    ExecutableElement? writeElement;
    ExecutableElement? writeElementRecovery;
    if (hasWrite) {
      writeElement = typeReference.getSetter(propertyName.name);
      if (writeElement != null) {
        writeElement = _resolver.toLegacyElement(writeElement);
        if (!_isAccessible(writeElement)) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.PRIVATE_SETTER,
            propertyName,
            [propertyName.name],
          );
        }
        if (_checkForStaticAccessToInstanceMember(propertyName, writeElement)) {
          writeElementRecovery = writeElement;
          writeElement = null;
        }
      } else {
        // Recovery, try to use getter.
        writeElementRecovery = typeReference.getGetter(propertyName.name);
        AssignmentVerifier(_definingLibrary, errorReporter).verify(
          node: propertyName,
          requested: null,
          recovery: writeElementRecovery,
          receiverType: typeReference.thisType,
        );
      }
    }

    return PropertyElementResolverResult(
      readElementRequested: readElement,
      readElementRecovery: readElementRecovery,
      writeElementRequested: writeElement,
      writeElementRecovery: writeElementRecovery,
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
      node: identifier,
      hasRead: hasRead,
      hasWrite: hasWrite,
    );

    var readElement = _resolver.toLegacyElement(lookupResult.getter);
    var writeElement = _resolver.toLegacyElement(lookupResult.setter);
    DartType? getType;
    if (hasRead && readElement is PropertyAccessorElement) {
      getType = readElement.returnType;
    }

    if (hasRead && readElement == null || hasWrite && writeElement == null) {
      if (!forAnnotation &&
          !_resolver.definingLibrary.shouldIgnoreUndefined(
            prefix: target.name,
            name: identifier.name,
          )) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME,
          identifier,
          [identifier.name, target.name],
        );
      }
    }

    return PropertyElementResolverResult(
      readElementRequested: readElement,
      readElementRecovery: null,
      writeElementRequested: writeElement,
      writeElementRecovery: null,
      getType: getType,
    );
  }

  PropertyElementResolverResult _resolveTargetSuperExpression({
    required Expression node,
    required SuperExpression target,
    required SimpleIdentifier propertyName,
    required bool hasRead,
    required bool hasWrite,
  }) {
    if (SuperContext.of(target) != SuperContext.valid) {
      return PropertyElementResolverResult();
    }
    var targetType = target.staticType;

    ExecutableElement? readElement;
    ExecutableElement? writeElement;
    DartType? getType;

    if (targetType is InterfaceTypeImpl) {
      if (hasRead) {
        var name = Name(_definingLibrary.source.uri, propertyName.name);
        readElement = _resolver.inheritance
            .getMember2(targetType.element, name, forSuper: true);

        if (readElement != null) {
          readElement = _resolver.toLegacyElement(readElement);
          _checkForStaticMember(target, propertyName, readElement);
        } else {
          // We were not able to find the concrete dispatch target.
          // But we would like to give the user at least some resolution.
          // So, we retry simply looking for an inherited member.
          readElement =
              _resolver.inheritance.getInherited2(targetType.element, name);
          if (readElement != null) {
            errorReporter.reportErrorForNode(
              CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
              propertyName,
              [readElement.kind.displayName, propertyName.name],
            );
          } else {
            errorReporter.reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_SUPER_GETTER,
              propertyName,
              [propertyName.name, targetType],
            );
          }
        }
        var unpromotedType =
            readElement?.returnType ?? _typeSystem.typeProvider.dynamicType;
        getType = _resolver.flowAnalysis.flow?.propertyGet(
                node, target, propertyName.name, readElement, unpromotedType) ??
            unpromotedType;
      }

      if (hasWrite) {
        writeElement = targetType.lookUpSetter2(
          propertyName.name,
          _definingLibrary,
          concrete: true,
          inherited: true,
        );

        if (writeElement != null) {
          writeElement = _resolver.toLegacyElement(writeElement);
          _checkForStaticMember(target, propertyName, writeElement);
        } else {
          // We were not able to find the concrete dispatch target.
          // But we would like to give the user at least some resolution.
          // So, we retry without the "concrete" requirement.
          writeElement = targetType.lookUpSetter2(
            propertyName.name,
            _definingLibrary,
            inherited: true,
          );
          if (writeElement != null) {
            errorReporter.reportErrorForNode(
              CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
              propertyName,
              [writeElement.kind.displayName, propertyName.name],
            );
          } else {
            errorReporter.reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_SUPER_SETTER,
              propertyName,
              [propertyName.name, targetType],
            );
          }
        }
      }
    }

    return PropertyElementResolverResult(
      readElementRequested: readElement,
      writeElementRequested: writeElement,
      getType: getType,
    );
  }

  PropertyElementResolverResult _toIndexResult(
    ResolutionResult result, {
    required bool hasRead,
    required bool hasWrite,
  }) {
    var readElement = result.getter;
    var writeElement = result.setter;

    final contextType = hasRead
        ? readElement.firstParameterType
        : writeElement.firstParameterType;

    return PropertyElementResolverResult(
      readElementRequested: readElement,
      writeElementRequested: writeElement,
      indexContextType: contextType,
    );
  }
}

class PropertyElementResolverResult {
  final Element? readElementRequested;
  final Element? readElementRecovery;
  final Element? writeElementRequested;
  final Element? writeElementRecovery;
  final FunctionType? functionTypeCallType;
  final RecordTypeField? recordField;
  final DartType? getType;

  /// If [IndexExpression] is resolved, the context type of the index.
  /// Might be `null` if `[]` or `[]=` are not resolved or invalid.
  final DartType? indexContextType;

  PropertyElementResolverResult({
    this.readElementRequested,
    this.readElementRecovery,
    this.writeElementRequested,
    this.writeElementRecovery,
    this.indexContextType,
    this.functionTypeCallType,
    this.recordField,
    this.getType,
  });

  Element? get readElement {
    return readElementRequested ?? readElementRecovery;
  }

  Element? get writeElement {
    return writeElementRequested ?? writeElementRecovery;
  }
}
