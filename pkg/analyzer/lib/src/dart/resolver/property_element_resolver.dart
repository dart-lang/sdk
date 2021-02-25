// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/assignment_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/super_context.dart';
import 'package:meta/meta.dart';

class PropertyElementResolver {
  final ResolverVisitor _resolver;

  PropertyElementResolver(this._resolver);

  LibraryElement get _definingLibrary => _resolver.definingLibrary;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  ExtensionMemberResolver get _extensionResolver => _resolver.extensionResolver;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  PropertyElementResolverResult resolveIndexExpression({
    @required IndexExpression node,
    @required bool hasRead,
    @required bool hasWrite,
  }) {
    var target = node.realTarget;
    var targetType = target.staticType;
    targetType = _resolveTypeParameter(targetType);

    if (target is ExtensionOverride) {
      var result = _extensionResolver.getOverrideMember(target, '[]');

      // TODO(scheglov) Change ExtensionResolver to set `needsGetterError`.
      if (hasRead && result.getter == null && !result.isAmbiguous) {
        _reportUnresolvedIndex(
          node,
          CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR,
          ['[]', target.staticElement.name],
        );
      }

      if (hasWrite && result.setter == null && !result.isAmbiguous) {
        _reportUnresolvedIndex(
          node,
          CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR,
          ['[]=', target.staticElement.name],
        );
      }

      return _toIndexResult(result);
    }

    if (targetType.isVoid) {
      // TODO(scheglov) Report directly in TypePropertyResolver?
      _reportUnresolvedIndex(
        node,
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
      );
      return PropertyElementResolverResult();
    }

    if (identical(targetType, NeverTypeImpl.instance)) {
      // TODO(scheglov) Report directly in TypePropertyResolver?
      _errorReporter.reportErrorForNode(
        HintCode.RECEIVER_OF_TYPE_NEVER,
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
      receiverErrorNode: target,
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

    return _toIndexResult(result);
  }

  PropertyElementResolverResult resolvePrefixedIdentifier({
    @required PrefixedIdentifier node,
    @required bool hasRead,
    @required bool hasWrite,
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
      target: prefix,
      isCascaded: false,
      isNullAware: false,
      propertyName: identifier,
      hasRead: hasRead,
      hasWrite: hasWrite,
    );
  }

  PropertyElementResolverResult resolvePropertyAccess({
    @required PropertyAccess node,
    @required bool hasRead,
    @required bool hasWrite,
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
        target: target,
        propertyName: propertyName,
        hasRead: hasRead,
        hasWrite: hasWrite,
      );
    }

    return _resolve(
      target: target,
      isCascaded: node.target == null,
      isNullAware: node.isNullAware,
      propertyName: propertyName,
      hasRead: hasRead,
      hasWrite: hasWrite,
    );
  }

  PropertyElementResolverResult resolveSimpleIdentifier({
    @required SimpleIdentifier node,
    @required bool hasRead,
    @required bool hasWrite,
  }) {
    Element readElementRequested;
    Element readElementRecovery;
    if (hasRead) {
      var readLookup = _resolver.lexicalLookup(node: node, setter: false);
      readElementRequested = readLookup.requested;
      _resolver.checkReadOfNotAssignedLocalVariable(node, readElementRequested);
    }

    Element writeElementRequested;
    Element writeElementRecovery;
    if (hasWrite) {
      var writeLookup = _resolver.lexicalLookup(node: node, setter: true);
      writeElementRequested = writeLookup.requested;
      writeElementRecovery = writeLookup.recovery;

      AssignmentVerifier(_resolver.definingLibrary, _errorReporter).verify(
        node: node,
        requested: writeElementRequested,
        recovery: writeElementRecovery,
        receiverTypeObject: null,
      );
    }

    return PropertyElementResolverResult(
      readElementRequested: readElementRequested,
      readElementRecovery: readElementRecovery,
      writeElementRequested: writeElementRequested,
      writeElementRecovery: writeElementRecovery,
    );
  }

  void _checkExtensionOverrideStaticMember(
    SimpleIdentifier propertyName,
    ExecutableElement element,
  ) {
    if (element != null && element.isStatic) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER,
        propertyName,
      );
    }
  }

  /// If the [element] is not static, report the error on the [identifier].
  void _checkForStaticAccessToInstanceMember(
    SimpleIdentifier identifier,
    ExecutableElement element,
  ) {
    if (element.isStatic) return;

    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER,
      identifier,
      [identifier.name],
    );
  }

  DartType _computeIndexContextType({
    @required ExecutableElement readElement,
    @required ExecutableElement writeElement,
  }) {
    var method = writeElement ?? readElement;
    var parameters = method is MethodElement ? method.parameters : null;

    if (parameters != null && parameters.isNotEmpty) {
      return parameters[0].type;
    }

    return null;
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

    _errorReporter.reportErrorForOffset(errorCode, offset, length, arguments);
  }

  PropertyElementResolverResult _resolve({
    @required Expression target,
    @required bool isCascaded,
    @required bool isNullAware,
    @required SimpleIdentifier propertyName,
    @required bool hasRead,
    @required bool hasWrite,
  }) {
    //
    // If this property access is of the form 'C.m' where 'C' is a class,
    // then we don't call resolveProperty(...) which walks up the class
    // hierarchy, instead we just look for the member in the type only.  This
    // does not apply to conditional property accesses (i.e. 'C?.m').
    //
    if (target is Identifier) {
      var targetElement = target.staticElement;
      if (targetElement is ClassElement) {
        return _resolveTargetClassElement(
          typeReference: targetElement,
          isCascaded: isCascaded,
          propertyName: propertyName,
          hasRead: hasRead,
          hasWrite: hasWrite,
        );
      } else if (targetElement is TypeAliasElement) {
        var aliasedType = targetElement.aliasedType;
        if (aliasedType is InterfaceType) {
          return _resolveTargetClassElement(
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

    var targetType = target.staticType;

    if (targetType is FunctionType && propertyName.name == 'call') {
      return PropertyElementResolverResult(
        functionTypeCallType: targetType,
      );
    }

    if (targetType.isVoid) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
        propertyName,
      );
      return PropertyElementResolverResult();
    }

    if (isNullAware) {
      targetType = _typeSystem.promoteToNonNull(targetType);
    }

    var result = _resolver.typePropertyResolver.resolve(
      receiver: target,
      receiverType: targetType,
      name: propertyName.name,
      receiverErrorNode: target,
      nameErrorEntity: propertyName,
    );

    if (hasRead && result.needsGetterError) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_GETTER,
        propertyName,
        [propertyName.name, targetType],
      );
    }

    if (hasWrite && result.needsSetterError) {
      AssignmentVerifier(_definingLibrary, _errorReporter).verify(
        node: propertyName,
        requested: null,
        recovery: result.getter,
        receiverTypeObject: targetType,
      );
    }

    return PropertyElementResolverResult(
      readElementRequested: result.getter,
      readElementRecovery: result.setter,
      writeElementRequested: result.setter,
      writeElementRecovery: result.getter,
    );
  }

  PropertyElementResolverResult _resolveTargetClassElement({
    @required ClassElement typeReference,
    @required bool isCascaded,
    @required SimpleIdentifier propertyName,
    @required bool hasRead,
    @required bool hasWrite,
  }) {
    if (isCascaded) {
      typeReference = _resolver.typeProvider.typeType.element;
    }

    ExecutableElement readElement;
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
        _checkForStaticAccessToInstanceMember(propertyName, readElement);
      } else {
        var code = typeReference.isEnum
            ? CompileTimeErrorCode.UNDEFINED_ENUM_CONSTANT
            : CompileTimeErrorCode.UNDEFINED_GETTER;
        _errorReporter.reportErrorForNode(
          code,
          propertyName,
          [propertyName.name, typeReference.name],
        );
      }
    }

    ExecutableElement writeElement;
    ExecutableElement writeElementRecovery;
    if (hasWrite) {
      writeElement = typeReference.getSetter(propertyName.name);
      if (writeElement != null) {
        writeElement = _resolver.toLegacyElement(writeElement);
        if (!_isAccessible(writeElement)) {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.PRIVATE_SETTER,
            propertyName,
            [propertyName.name, typeReference.name],
          );
        }
        _checkForStaticAccessToInstanceMember(propertyName, writeElement);
      } else {
        // Recovery, try to use getter.
        writeElementRecovery = typeReference.getGetter(propertyName.name);
        AssignmentVerifier(_definingLibrary, _errorReporter).verify(
          node: propertyName,
          requested: null,
          recovery: writeElementRecovery,
          receiverTypeObject: typeReference.displayName,
        );
      }
    }

    return PropertyElementResolverResult(
      readElementRequested: readElement,
      writeElementRequested: writeElement,
      writeElementRecovery: writeElementRecovery,
    );
  }

  PropertyElementResolverResult _resolveTargetExtensionElement({
    @required ExtensionElement extension,
    @required SimpleIdentifier propertyName,
    @required bool hasRead,
    @required bool hasWrite,
  }) {
    var memberName = propertyName.name;

    ExecutableElement readElement;
    if (hasRead) {
      readElement ??= extension.getGetter(memberName);
      readElement ??= extension.getMethod(memberName);

      if (readElement == null) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER,
          propertyName,
          [memberName, extension.name],
        );
      } else {
        readElement = _resolver.toLegacyElement(readElement);
        _checkForStaticAccessToInstanceMember(propertyName, readElement);
      }
    }

    ExecutableElement writeElement;
    if (hasWrite) {
      writeElement = extension.getSetter(memberName);

      if (writeElement == null) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER,
          propertyName,
          [memberName, extension.name],
        );
      } else {
        writeElement = _resolver.toLegacyElement(writeElement);
        _checkForStaticAccessToInstanceMember(propertyName, writeElement);
      }
    }

    return PropertyElementResolverResult(
      readElementRequested: readElement,
      writeElementRequested: writeElement,
    );
  }

  PropertyElementResolverResult _resolveTargetExtensionOverride({
    @required ExtensionOverride target,
    @required SimpleIdentifier propertyName,
    @required bool hasRead,
    @required bool hasWrite,
  }) {
    if (target.parent is CascadeExpression) {
      // Report this error and recover by treating it like a non-cascade.
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE,
        target.extensionName,
      );
    }

    ExtensionElement element = target.extensionName.staticElement;
    String memberName = propertyName.name;

    var result = _extensionResolver.getOverrideMember(target, memberName);

    ExecutableElement readElement;
    if (hasRead) {
      readElement = result.getter;
      if (readElement == null) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER,
          propertyName,
          [memberName, element.name],
        );
      }
      _checkExtensionOverrideStaticMember(propertyName, readElement);
    }

    ExecutableElement writeElement;
    if (hasWrite) {
      writeElement = result.setter;
      if (writeElement == null) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER,
          propertyName,
          [memberName, element.name],
        );
      }
      _checkExtensionOverrideStaticMember(propertyName, writeElement);
    }

    return PropertyElementResolverResult(
      readElementRequested: readElement,
      writeElementRequested: writeElement,
    );
  }

  PropertyElementResolverResult _resolveTargetPrefixElement({
    @required PrefixElement target,
    @required SimpleIdentifier identifier,
    @required bool hasRead,
    @required bool hasWrite,
    @required bool forAnnotation,
  }) {
    var lookupResult = target.scope.lookup(identifier.name);

    var readElement = _resolver.toLegacyElement(lookupResult.getter);
    var writeElement = _resolver.toLegacyElement(lookupResult.setter);

    if (hasRead && readElement == null || hasWrite && writeElement == null) {
      if (!forAnnotation &&
          !_resolver.nameScope.shouldIgnoreUndefined2(
            prefix: target.name,
            name: identifier.name,
          )) {
        _errorReporter.reportErrorForNode(
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
    );
  }

  PropertyElementResolverResult _resolveTargetSuperExpression({
    @required SuperExpression target,
    @required SimpleIdentifier propertyName,
    @required bool hasRead,
    @required bool hasWrite,
  }) {
    if (SuperContext.of(target) != SuperContext.valid) {
      return PropertyElementResolverResult();
    }
    var targetType = target.staticType;

    ExecutableElement readElement;
    ExecutableElement writeElement;

    if (targetType is InterfaceTypeImpl) {
      if (hasRead) {
        var name = Name(_definingLibrary.source.uri, propertyName.name);
        readElement = _resolver.inheritance
            .getMember2(targetType.element, name, forSuper: true);

        if (readElement != null) {
          readElement = _resolver.toLegacyElement(readElement);
        } else {
          // We were not able to find the concrete dispatch target.
          // But we would like to give the user at least some resolution.
          // So, we retry simply looking for an inherited member.
          readElement =
              _resolver.inheritance.getInherited2(targetType.element, name);
          if (readElement != null) {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
              propertyName,
              [readElement.kind.displayName, propertyName.name],
            );
          } else {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_SUPER_GETTER,
              propertyName,
              [propertyName.name, targetType],
            );
          }
        }
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
            ClassElementImpl receiverSuperClass =
                targetType.element.supertype.element;
            if (!receiverSuperClass.hasNoSuchMethod) {
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
                propertyName,
                [writeElement.kind.displayName, propertyName.name],
              );
            }
          } else {
            _errorReporter.reportErrorForNode(
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
    );
  }

  /// If the given [type] is a type parameter, replace with its bound.
  /// Otherwise, return the original type.
  DartType _resolveTypeParameter(DartType type) {
    if (type is TypeParameterType) {
      return type.resolveToBound(_resolver.typeProvider.objectType);
    }
    return type;
  }

  PropertyElementResolverResult _toIndexResult(ResolutionResult result) {
    var readElement = result.getter;
    var writeElement = result.setter;

    return PropertyElementResolverResult(
      readElementRequested: readElement,
      writeElementRequested: writeElement,
      indexContextType: _computeIndexContextType(
        readElement: readElement,
        writeElement: writeElement,
      ),
    );
  }
}

class PropertyElementResolverResult {
  final Element readElementRequested;
  final Element readElementRecovery;
  final Element writeElementRequested;
  final Element writeElementRecovery;
  final FunctionType functionTypeCallType;

  /// If [IndexExpression] is resolved, the context type of the index.
  /// Might be `null` if `[]` or `[]=` are not resolved or invalid.
  final DartType indexContextType;

  PropertyElementResolverResult({
    this.readElementRequested,
    this.readElementRecovery,
    this.writeElementRequested,
    this.writeElementRecovery,
    this.indexContextType,
    this.functionTypeCallType,
  });

  Element get readElement {
    return readElementRequested ?? readElementRecovery;
  }

  Element get writeElement {
    return writeElementRequested ?? writeElementRecovery;
  }
}
