// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';

/// Helper for resolving types.
///
/// The client must set [nameScope] before calling [resolveTypeName].
class TypeNameResolver {
  final TypeSystemImpl typeSystem;
  final DartType dynamicType;
  final bool isNonNullableByDefault;
  final ErrorReporter errorReporter;

  Scope nameScope;

  /// If not `null`, the element of the [ClassDeclaration], or the
  /// [ClassTypeAlias] being resolved.
  ClassElement enclosingClass;

  /// If not `null`, a direct child of an [ExtendsClause], [WithClause],
  /// or [ImplementsClause].
  TypeName classHierarchy_typeName;

  /// If not `null`, a direct child the [WithClause] in the [enclosingClass].
  TypeName withClause_typeName;

  /// If not `null`, the [TypeName] of the redirected constructor being
  /// resolved, in the [enclosingClass].
  TypeName redirectedConstructor_typeName;

  /// If [resolveTypeName] finds out that the given [TypeName] with a
  /// [PrefixedIdentifier] name is actually the name of a class and the name of
  /// the constructor, it rewrites the [ConstructorName] to correctly represent
  /// the type and the constructor name, and set this field to the rewritten
  /// [ConstructorName]. Otherwise this field will be set `null`.
  ConstructorName rewriteResult;

  TypeNameResolver(this.typeSystem, TypeProvider typeProvider,
      this.isNonNullableByDefault, this.errorReporter)
      : dynamicType = typeProvider.dynamicType;

  NullabilitySuffix get _noneOrStarSuffix {
    return isNonNullableByDefault
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  /// Resolve the given [TypeName] - set its element and static type. Only the
  /// given [node] is resolved, all its children must be already resolved.
  ///
  /// The client must set [nameScope] before calling [resolveTypeName].
  void resolveTypeName(TypeName node) {
    rewriteResult = null;

    var typeIdentifier = node.name;
    if (typeIdentifier is PrefixedIdentifier) {
      var prefix = typeIdentifier.prefix;
      var prefixName = prefix.name;
      var prefixElement = nameScope.lookup(prefixName).getter;
      prefix.staticElement = prefixElement;

      if (prefixElement == null) {
        _resolveToElement(node, null);
        return;
      }

      if (prefixElement is ClassElement || prefixElement is TypeAliasElement) {
        _rewriteToConstructorName(node, typeIdentifier);
        return;
      }

      if (prefixElement is PrefixElement) {
        var nameNode = typeIdentifier.identifier;
        var name = nameNode.name;

        var element = prefixElement.scope.lookup(name).getter;
        nameNode.staticElement = element;
        _resolveToElement(node, element);
        return;
      }

      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.PREFIX_SHADOWED_BY_LOCAL_DECLARATION,
        prefix,
        [prefix.name],
      );
      node.type = dynamicType;
    } else {
      var nameNode = typeIdentifier as SimpleIdentifier;
      var name = nameNode.name;

      if (name == 'void') {
        node.type = VoidTypeImpl.instance;
        return;
      }

      var element = nameScope.lookup(name).getter;
      nameNode.staticElement = element;
      _resolveToElement(node, element);
    }
  }

  /// Return type arguments, exactly [parameterCount].
  List<DartType> _buildTypeArguments(TypeName node, int parameterCount) {
    var arguments = node.typeArguments.arguments;
    var argumentCount = arguments.length;

    if (argumentCount != parameterCount) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
        node,
        [node.name.name, parameterCount, argumentCount],
      );
      return List.filled(parameterCount, DynamicTypeImpl.instance);
    }

    if (parameterCount == 0) {
      return const <DartType>[];
    }

    var typeArguments = List<DartType>.filled(parameterCount, null);
    for (var i = 0; i < parameterCount; i++) {
      typeArguments[i] = arguments[i].type;
    }

    return typeArguments;
  }

  NullabilitySuffix _getNullability(TypeName node) {
    if (isNonNullableByDefault) {
      if (node.question != null) {
        if (identical(node, classHierarchy_typeName)) {
          _reportInvalidNullableType(node);
          return NullabilitySuffix.none;
        } else {
          return NullabilitySuffix.question;
        }
      } else {
        return NullabilitySuffix.none;
      }
    }
    return NullabilitySuffix.star;
  }

  /// We are resolving the [TypeName] in a redirecting constructor of the
  /// [enclosingClass].
  InterfaceType _inferRedirectedConstructor(ClassElement element) {
    if (element == enclosingClass) {
      return element.thisType;
    } else {
      var typeParameters = element.typeParameters;
      if (typeParameters.isEmpty) {
        return element.thisType;
      } else {
        var typeArguments = typeSystem.inferGenericFunctionOrType(
          typeParameters: typeParameters,
          parameters: const [],
          declaredReturnType: element.thisType,
          argumentTypes: const [],
          contextReturnType: enclosingClass.thisType,
        );
        return element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: _noneOrStarSuffix,
        );
      }
    }
  }

  DartType _instantiateElement(TypeName node, Element element) {
    var nullability = _getNullability(node);

    var argumentList = node.typeArguments;
    if (argumentList != null) {
      if (element is ClassElement) {
        var typeArguments = _buildTypeArguments(
          node,
          element.typeParameters.length,
        );
        return element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: nullability,
        );
      } else if (element is TypeAliasElement) {
        var typeArguments = _buildTypeArguments(
          node,
          element.typeParameters.length,
        );
        var type = element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: nullability,
        );
        type = typeSystem.toLegacyType(type);
        return _verifyTypeAliasForContext(node, element, type);
      } else if (_isInstanceCreation(node)) {
        _ErrorHelper(errorReporter).reportNewWithNonType(node);
        return dynamicType;
      } else if (element is DynamicElementImpl) {
        _buildTypeArguments(node, 0);
        return DynamicTypeImpl.instance;
      } else if (element is NeverElementImpl) {
        _buildTypeArguments(node, 0);
        return _instantiateElementNever(nullability);
      } else if (element is TypeParameterElement) {
        _buildTypeArguments(node, 0);
        return element.instantiate(
          nullabilitySuffix: nullability,
        );
      } else {
        _ErrorHelper(errorReporter).reportNullOrNonTypeElement(node, element);
        return dynamicType;
      }
    }

    if (element is ClassElement) {
      if (identical(node, withClause_typeName)) {
        for (var mixin in enclosingClass.mixins) {
          if (mixin.element == element) {
            return mixin;
          }
        }
      }

      if (identical(node, redirectedConstructor_typeName)) {
        return _inferRedirectedConstructor(element);
      }

      return typeSystem.instantiateToBounds2(
        classElement: element,
        nullabilitySuffix: nullability,
      );
    } else if (element is TypeAliasElement) {
      var type = typeSystem.instantiateToBounds2(
        typeAliasElement: element,
        nullabilitySuffix: nullability,
      );
      return _verifyTypeAliasForContext(node, element, type);
    } else if (_isInstanceCreation(node)) {
      _ErrorHelper(errorReporter).reportNewWithNonType(node);
      return dynamicType;
    } else if (element is DynamicElementImpl) {
      return DynamicTypeImpl.instance;
    } else if (element is NeverElementImpl) {
      return _instantiateElementNever(nullability);
    } else if (element is TypeParameterElement) {
      return element.instantiate(
        nullabilitySuffix: nullability,
      );
    } else {
      _ErrorHelper(errorReporter).reportNullOrNonTypeElement(node, element);
      return dynamicType;
    }
  }

  DartType _instantiateElementNever(NullabilitySuffix nullability) {
    if (isNonNullableByDefault) {
      return NeverTypeImpl.instance.withNullability(nullability);
    } else {
      return typeSystem.typeProvider.nullType;
    }
  }

  /// Given a [typeName] that has a question mark, report an error and return
  /// `true` if it appears in a location where a nullable type is not allowed.
  void _reportInvalidNullableType(TypeName typeName) {
    AstNode parent = typeName.parent;
    if (parent is ExtendsClause || parent is ClassTypeAlias) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NULLABLE_TYPE_IN_EXTENDS_CLAUSE,
        typeName,
      );
    } else if (parent is ImplementsClause) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE,
        typeName,
      );
    } else if (parent is OnClause) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE,
        typeName,
      );
    } else if (parent is WithClause) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE,
        typeName,
      );
    }
  }

  void _resolveToElement(TypeName node, Element element) {
    if (element == null) {
      node.type = dynamicType;
      if (!nameScope.shouldIgnoreUndefined(node.name)) {
        _ErrorHelper(errorReporter).reportNullOrNonTypeElement(node, null);
      }
      return;
    }

    if (element is MultiplyDefinedElement) {
      node.type = dynamicType;
      return;
    }

    node.type = _instantiateElement(node, element);
  }

  /// We parse `foo.bar` as `prefix.Name` with the expectation that `prefix`
  /// will be a [PrefixElement]. But when we resolved the `prefix` it turned
  /// out to be a [ClassElement], so it is probably a `Class.constructor`.
  void _rewriteToConstructorName(
    TypeName node,
    PrefixedIdentifier typeIdentifier,
  ) {
    var constructorName = node.parent;
    if (constructorName is ConstructorName && constructorName.name == null) {
      var classIdentifier = typeIdentifier.prefix;
      var constructorIdentifier = typeIdentifier.identifier;

      var typeArguments = node.typeArguments;
      if (typeArguments != null) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
          typeArguments,
          [classIdentifier.name, constructorIdentifier.name],
        );
        var instanceCreation = constructorName.parent;
        if (instanceCreation is InstanceCreationExpressionImpl) {
          instanceCreation.typeArguments = typeArguments;
        }
      }

      node.name = classIdentifier;
      node.typeArguments = null;

      constructorName.period = typeIdentifier.period;
      constructorName.name = constructorIdentifier;

      rewriteResult = constructorName;
      return;
    }

    if (_isInstanceCreation(node)) {
      node.type = dynamicType;
      _ErrorHelper(errorReporter).reportNewWithNonType(node);
    } else {
      node.type = dynamicType;
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NOT_A_TYPE,
        typeIdentifier,
        [typeIdentifier.name],
      );
    }
  }

  DartType _verifyTypeAliasForContext(
    TypeName node,
    TypeAliasElement element,
    DartType type,
  ) {
    if (element.aliasedType is TypeParameterType) {
      var constructorName = node.parent;
      if (constructorName is ConstructorName) {
        _ErrorHelper(errorReporter)
            .reportTypeAliasExpandsToTypeParameter(constructorName, element);
        return dynamicType;
      }
    }
    if (type is! InterfaceType && _isInstanceCreation(node)) {
      _ErrorHelper(errorReporter).reportNewWithNonType(node);
      return dynamicType;
    }
    return type;
  }

  static bool _isInstanceCreation(TypeName node) {
    return node.parent is ConstructorName &&
        node.parent.parent is InstanceCreationExpression;
  }
}

/// Helper for reporting errors during type name resolution.
class _ErrorHelper {
  final ErrorReporter errorReporter;

  _ErrorHelper(this.errorReporter);

  bool reportNewWithNonType(TypeName node) {
    var constructorName = node.parent;
    if (constructorName is ConstructorName) {
      var instanceCreation = constructorName.parent;
      if (instanceCreation is InstanceCreationExpression) {
        var identifier = node.name;
        var errorNode = _getErrorNode(node);
        errorReporter.reportErrorForNode(
          instanceCreation.isConst
              ? CompileTimeErrorCode.CONST_WITH_NON_TYPE
              : CompileTimeErrorCode.NEW_WITH_NON_TYPE,
          errorNode,
          [identifier.name],
        );
        return true;
      }
    }
    return false;
  }

  void reportNullOrNonTypeElement(TypeName node, Element element) {
    var identifier = node.name;
    var errorNode = _getErrorNode(node);

    if (errorNode.name == 'boolean') {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_CLASS_BOOLEAN,
        errorNode,
      );
      return;
    }

    if (_isTypeInCatchClause(node)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NON_TYPE_IN_CATCH_CLAUSE,
        identifier,
        [identifier.name],
      );
      return;
    }

    if (_isTypeInAsExpression(node)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.CAST_TO_NON_TYPE,
        identifier,
        [identifier.name],
      );
      return;
    }

    if (_isTypeInIsExpression(node)) {
      if (element != null) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.TYPE_TEST_WITH_NON_TYPE,
          identifier,
          [identifier.name],
        );
      } else {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.TYPE_TEST_WITH_UNDEFINED_NAME,
          identifier,
          [identifier.name],
        );
      }
      return;
    }

    if (_isRedirectingConstructor(node)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.REDIRECT_TO_NON_CLASS,
        identifier,
        [identifier.name],
      );
      return;
    }

    if (_isTypeInTypeArgumentList(node)) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT,
        identifier,
        [identifier.name],
      );
      return;
    }

    if (reportNewWithNonType(node)) {
      return;
    }

    var parent = node.parent;
    if (parent is ExtendsClause ||
        parent is ImplementsClause ||
        parent is WithClause ||
        parent is ClassTypeAlias) {
      // Ignored. The error will be reported elsewhere.
      return;
    }

    if (element is LocalVariableElement ||
        (element is FunctionElement &&
            element.enclosingElement is ExecutableElement)) {
      errorReporter.reportError(
        DiagnosticFactory().referencedBeforeDeclaration(
          errorReporter.source,
          identifier,
          element: element,
        ),
      );
      return;
    }

    if (element != null) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.NOT_A_TYPE,
        identifier,
        [identifier.name],
      );
      return;
    }

    if (identifier is SimpleIdentifier && identifier.name == 'await') {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT,
        node,
      );
      return;
    }

    errorReporter.reportErrorForNode(
      CompileTimeErrorCode.UNDEFINED_CLASS,
      identifier,
      [identifier.name],
    );
  }

  void reportTypeAliasExpandsToTypeParameter(
    ConstructorName constructorName,
    TypeAliasElement element,
  ) {
    var errorNode = _getErrorNode(constructorName.type);
    var constructorUsage = constructorName.parent;
    if (constructorUsage is InstanceCreationExpression) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER,
        errorNode,
      );
    } else if (constructorUsage is ConstructorDeclaration &&
        constructorUsage.redirectedConstructor == constructorName) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER,
        errorNode,
      );
    } else {
      throw UnimplementedError('${constructorUsage.runtimeType}');
    }
  }

  /// Returns the simple identifier of the given (maybe prefixed) identifier.
  static Identifier _getErrorNode(TypeName node) {
    Identifier identifier = node.name;
    if (identifier is PrefixedIdentifier) {
      // The prefixed identifier can be:
      // 1. new importPrefix.TypeName()
      // 2. new TypeName.constructorName()
      // 3. new unresolved.Unresolved()
      if (identifier.prefix.staticElement is PrefixElement) {
        return identifier.identifier;
      } else {
        return identifier;
      }
    } else {
      return identifier;
    }
  }

  /// Check if the [node] is the type in a redirected constructor name.
  static bool _isRedirectingConstructor(TypeName node) {
    var parent = node.parent;
    if (parent is ConstructorName) {
      var grandParent = parent.parent;
      if (grandParent is ConstructorDeclaration) {
        return identical(grandParent.redirectedConstructor, parent);
      }
    }
    return false;
  }

  /// Checks if the [node] is the type in an `as` expression.
  static bool _isTypeInAsExpression(TypeName node) {
    var parent = node.parent;
    if (parent is AsExpression) {
      return identical(parent.type, node);
    }
    return false;
  }

  /// Checks if the [node] is the exception type in a `catch` clause.
  static bool _isTypeInCatchClause(TypeName node) {
    var parent = node.parent;
    if (parent is CatchClause) {
      return identical(parent.exceptionType, node);
    }
    return false;
  }

  /// Checks if the [node] is the type in an `is` expression.
  static bool _isTypeInIsExpression(TypeName node) {
    var parent = node.parent;
    if (parent is IsExpression) {
      return identical(parent.type, node);
    }
    return false;
  }

  /// Checks if the [node] is an element in a type argument list.
  static bool _isTypeInTypeArgumentList(TypeName node) {
    return node.parent is TypeArgumentList;
  }
}
