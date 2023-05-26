// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/scope_helpers.dart';

/// Helper for resolving types.
///
/// The client must set [nameScope] before calling [resolve].
class NamedTypeResolver with ScopeHelpers {
  final LibraryElementImpl _libraryElement;
  final TypeSystemImpl typeSystem;
  final bool isNonNullableByDefault;

  @override
  final ErrorReporter errorReporter;

  late Scope nameScope;

  /// If not `null`, the element of the [ClassDeclaration], or the
  /// [ClassTypeAlias] being resolved.
  InterfaceElement? enclosingClass;

  /// If not `null`, a direct child of an [ExtendsClause], [WithClause],
  /// or [ImplementsClause].
  NamedType? classHierarchy_namedType;

  /// If not `null`, a direct child the [WithClause] in the [enclosingClass].
  NamedType? withClause_namedType;

  /// If not `null`, the [NamedType] of the redirected constructor being
  /// resolved, in the [enclosingClass].
  NamedType? redirectedConstructor_namedType;

  /// If [resolve] finds out that the given [NamedType] with a
  /// [PrefixedIdentifier] name is actually the name of a class and the name of
  /// the constructor, it rewrites the [ConstructorName] to correctly represent
  /// the type and the constructor name, and set this field to the rewritten
  /// [ConstructorName]. Otherwise this field will be set `null`.
  ConstructorName? rewriteResult;

  /// If [resolve] reported an error, this flag is set to `true`.
  bool hasErrorReported = false;

  NamedTypeResolver(
      this._libraryElement, this.isNonNullableByDefault, this.errorReporter)
      : typeSystem = _libraryElement.typeSystem;

  bool get _genericMetadataIsEnabled =>
      enclosingClass!.library.featureSet.isEnabled(Feature.generic_metadata);

  NullabilitySuffix get _noneOrStarSuffix {
    return isNonNullableByDefault
        ? NullabilitySuffix.none
        : NullabilitySuffix.star;
  }

  /// Resolve the given [NamedType] - set its element and static type. Only the
  /// given [node] is resolved, all its children must be already resolved.
  ///
  /// The client must set [nameScope] before calling [resolve].
  void resolve(NamedTypeImpl node) {
    rewriteResult = null;
    hasErrorReported = false;

    final importPrefix = node.importPrefix;
    if (importPrefix != null) {
      final prefixToken = importPrefix.name;
      final prefixName = prefixToken.lexeme;
      final prefixElement = nameScope.lookup(prefixName).getter;
      importPrefix.element = prefixElement;

      if (prefixElement == null) {
        _resolveToElement(node, null);
        return;
      }

      if (prefixElement is InterfaceElement ||
          prefixElement is TypeAliasElement) {
        _rewriteToConstructorName(
          node: node,
          importPrefix: importPrefix,
          importPrefixElement: prefixElement,
          nameToken: node.name2,
        );
        return;
      }

      if (prefixElement is PrefixElement) {
        final nameToken = node.name2;
        final element = _lookupGetter(prefixElement.scope, nameToken);
        _resolveToElement(node, element);
        return;
      }

      errorReporter.reportErrorForToken(
        CompileTimeErrorCode.PREFIX_SHADOWED_BY_LOCAL_DECLARATION,
        prefixToken,
        [prefixName],
      );
      node.type = InvalidTypeImpl.instance;
    } else {
      if (node.name2.lexeme == 'void') {
        node.type = VoidTypeImpl.instance;
        return;
      }

      final element = _lookupGetter(nameScope, node.name2);
      _resolveToElement(node, element);
    }
  }

  /// Return type arguments, exactly [parameterCount].
  List<DartType> _buildTypeArguments(
      NamedType node, TypeArgumentList argumentList, int parameterCount) {
    var arguments = argumentList.arguments;
    var argumentCount = arguments.length;

    if (argumentCount != parameterCount) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
        node,
        [node.name2.lexeme, parameterCount, argumentCount],
      );
      return List.filled(parameterCount, InvalidTypeImpl.instance,
          growable: false);
    }

    if (parameterCount == 0) {
      return const <DartType>[];
    }

    return List.generate(
      parameterCount,
      (i) => arguments[i].typeOrThrow,
      growable: false,
    );
  }

  NullabilitySuffix _getNullability(NamedType node) {
    if (isNonNullableByDefault) {
      if (node.question != null) {
        return NullabilitySuffix.question;
      } else {
        return NullabilitySuffix.none;
      }
    }
    return NullabilitySuffix.star;
  }

  /// We are resolving the [NamedType] in a redirecting constructor of the
  /// [enclosingClass].
  InterfaceType _inferRedirectedConstructor(InterfaceElement element) {
    if (element == enclosingClass) {
      return element.thisType;
    } else {
      var typeParameters = element.typeParameters;
      if (typeParameters.isEmpty) {
        return element.thisType;
      } else {
        var inferrer = typeSystem.setupGenericTypeInference(
          typeParameters: typeParameters,
          declaredReturnType: element.thisType,
          contextReturnType: enclosingClass!.thisType,
          genericMetadataIsEnabled: _genericMetadataIsEnabled,
        );
        var typeArguments = inferrer.chooseFinalTypes();
        return element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: _noneOrStarSuffix,
        );
      }
    }
  }

  DartType _instantiateElement(NamedType node, Element element) {
    var nullability = _getNullability(node);

    var argumentList = node.typeArguments;
    if (argumentList != null) {
      if (element is InterfaceElement) {
        var typeArguments = _buildTypeArguments(
          node,
          argumentList,
          element.typeParameters.length,
        );
        return element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: nullability,
        );
      } else if (element is TypeAliasElement) {
        var typeArguments = _buildTypeArguments(
          node,
          argumentList,
          element.typeParameters.length,
        );
        var type = element.instantiate(
          typeArguments: typeArguments,
          nullabilitySuffix: nullability,
        );
        type = typeSystem.toLegacyTypeIfOptOut(type);
        return _verifyTypeAliasForContext(node, element, type);
      } else if (_isInstanceCreation(node)) {
        _ErrorHelper(errorReporter).reportNewWithNonType(node);
        return InvalidTypeImpl.instance;
      } else if (element is DynamicElementImpl) {
        _buildTypeArguments(node, argumentList, 0);
        return DynamicTypeImpl.instance;
      } else if (element is NeverElementImpl) {
        _buildTypeArguments(node, argumentList, 0);
        return _instantiateElementNever(nullability);
      } else if (element is TypeParameterElement) {
        _buildTypeArguments(node, argumentList, 0);
        return element.instantiate(
          nullabilitySuffix: nullability,
        );
      } else {
        _ErrorHelper(errorReporter).reportNullOrNonTypeElement(node, element);
        return InvalidTypeImpl.instance;
      }
    }

    if (element is InterfaceElement) {
      if (identical(node, withClause_namedType)) {
        for (var mixin in enclosingClass!.mixins) {
          if (mixin.element == element) {
            return mixin;
          }
        }
      }

      if (identical(node, redirectedConstructor_namedType)) {
        return _inferRedirectedConstructor(element);
      }

      return typeSystem.instantiateInterfaceToBounds(
        element: element,
        nullabilitySuffix: nullability,
      );
    } else if (element is TypeAliasElement) {
      var type = typeSystem.instantiateTypeAliasToBounds(
        element: element,
        nullabilitySuffix: nullability,
      );
      return _verifyTypeAliasForContext(node, element, type);
    } else if (_isInstanceCreation(node)) {
      _ErrorHelper(errorReporter).reportNewWithNonType(node);
      return InvalidTypeImpl.instance;
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
      return InvalidTypeImpl.instance;
    }
  }

  DartType _instantiateElementNever(NullabilitySuffix nullability) {
    if (isNonNullableByDefault) {
      return NeverTypeImpl.instance.withNullability(nullability);
    } else {
      return typeSystem.typeProvider.nullType;
    }
  }

  Element? _lookupGetter(Scope scope, Token nameToken) {
    final scopeLookupResult = scope.lookup(nameToken.lexeme);
    reportDeprecatedExportUseGetter(
      scopeLookupResult: scopeLookupResult,
      nameToken: nameToken,
    );
    return scopeLookupResult.getter;
  }

  void _resolveToElement(NamedTypeImpl node, Element? element) {
    node.element = element;

    if (element == null) {
      node.type = InvalidTypeImpl.instance;
      if (!_libraryElement.shouldIgnoreUndefinedNamedType(node)) {
        _ErrorHelper(errorReporter).reportNullOrNonTypeElement(node, null);
      }
      return;
    }

    if (element is MultiplyDefinedElement) {
      node.type = InvalidTypeImpl.instance;
      return;
    }

    var type = _instantiateElement(node, element);
    type = _verifyNullability(node, type);
    node.type = type;
  }

  /// We parse `foo.bar` as `prefix.Name` with the expectation that `prefix`
  /// will be a [PrefixElement]. But when we resolved the `prefix` it turned
  /// out to be a [ClassElement], so it is probably a `Class.constructor`.
  void _rewriteToConstructorName({
    required NamedTypeImpl node,
    required ImportPrefixReferenceImpl importPrefix,
    required Element importPrefixElement,
    required Token nameToken,
  }) {
    var constructorName = node.parent;
    if (constructorName is ConstructorNameImpl &&
        constructorName.name == null) {
      var typeArguments = node.typeArguments;
      if (typeArguments != null) {
        errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
          typeArguments,
          [importPrefix.name.lexeme, nameToken.lexeme],
        );
        var instanceCreation = constructorName.parent;
        if (instanceCreation is InstanceCreationExpressionImpl) {
          instanceCreation.typeArguments = typeArguments;
        }
      }

      final namedType = NamedTypeImpl(
        importPrefix: null,
        name2: importPrefix.name,
        typeArguments: null,
        question: null,
      )..element = importPrefixElement;
      if (identical(node, redirectedConstructor_namedType)) {
        redirectedConstructor_namedType = namedType;
      }

      constructorName.type = namedType;
      constructorName.period = importPrefix.period;
      constructorName.name = SimpleIdentifierImpl(nameToken);

      rewriteResult = constructorName;
      return;
    }

    if (_isInstanceCreation(node)) {
      node.type = InvalidTypeImpl.instance;
      _ErrorHelper(errorReporter).reportNewWithNonType(node);
    } else {
      node.type = InvalidTypeImpl.instance;
      errorReporter.reportErrorForOffset(
        CompileTimeErrorCode.NOT_A_TYPE,
        importPrefix.offset,
        nameToken.end - importPrefix.offset,
        ['${importPrefix.name.lexeme}.${nameToken.lexeme}'],
      );
    }
  }

  /// If the [node] appears in a location where a nullable type is not allowed,
  /// but the [type] is nullable (because the question mark was specified,
  /// or the type alias is nullable), report an error, and return the
  /// corresponding non-nullable type.
  DartType _verifyNullability(NamedType node, DartType type) {
    if (identical(node, classHierarchy_namedType)) {
      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        var parent = node.parent;
        if (parent is ExtendsClause || parent is ClassTypeAlias) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NULLABLE_TYPE_IN_EXTENDS_CLAUSE,
            node,
          );
        } else if (parent is ImplementsClause) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE,
            node,
          );
        } else if (parent is OnClause) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE,
            node,
          );
        } else if (parent is WithClause) {
          errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE,
            node,
          );
        }
        return (type as TypeImpl).withNullability(NullabilitySuffix.none);
      }
    }

    return type;
  }

  DartType _verifyTypeAliasForContext(
    NamedType node,
    TypeAliasElement element,
    DartType type,
  ) {
    // If a type alias that expands to a type parameter.
    if (element.aliasedType is TypeParameterType) {
      var parent = node.parent;
      if (parent is ConstructorName) {
        var errorRange = _ErrorHelper._getErrorRange(node);
        var constructorUsage = parent.parent;
        if (constructorUsage is InstanceCreationExpression) {
          errorReporter.reportErrorForOffset(
            CompileTimeErrorCode
                .INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER,
            errorRange.offset,
            errorRange.length,
          );
        } else if (constructorUsage is ConstructorDeclaration &&
            constructorUsage.redirectedConstructor == parent) {
          errorReporter.reportErrorForOffset(
            CompileTimeErrorCode
                .REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER,
            errorRange.offset,
            errorRange.length,
          );
        } else {
          throw UnimplementedError('${constructorUsage.runtimeType}');
        }
        return InvalidTypeImpl.instance;
      }

      // Report if this type is used as a class in hierarchy.
      ErrorCode? errorCode;
      if (parent is ExtendsClause) {
        errorCode =
            CompileTimeErrorCode.EXTENDS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER;
      } else if (parent is ImplementsClause) {
        errorCode = CompileTimeErrorCode
            .IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER;
      } else if (parent is OnClause) {
        errorCode =
            CompileTimeErrorCode.MIXIN_ON_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER;
      } else if (parent is WithClause) {
        errorCode =
            CompileTimeErrorCode.MIXIN_OF_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER;
      }
      if (errorCode != null) {
        var errorRange = _ErrorHelper._getErrorRange(node);
        errorReporter.reportErrorForOffset(
          errorCode,
          errorRange.offset,
          errorRange.length,
        );
        hasErrorReported = true;
        return InvalidTypeImpl.instance;
      }
    }
    if (type is! InterfaceType && _isInstanceCreation(node)) {
      _ErrorHelper(errorReporter).reportNewWithNonType(node);
      return InvalidTypeImpl.instance;
    }
    return type;
  }

  static bool _isInstanceCreation(NamedType node) {
    var parent = node.parent;
    return parent is ConstructorName &&
        parent.parent is InstanceCreationExpression;
  }
}

/// Helper for reporting errors during type name resolution.
class _ErrorHelper {
  final ErrorReporter errorReporter;

  _ErrorHelper(this.errorReporter);

  bool reportNewWithNonType(NamedType node) {
    var constructorName = node.parent;
    if (constructorName is ConstructorName) {
      var instanceCreation = constructorName.parent;
      if (instanceCreation is InstanceCreationExpression) {
        final errorRange = _getErrorRange(node, skipImportPrefix: true);
        errorReporter.reportErrorForOffset(
          instanceCreation.isConst
              ? CompileTimeErrorCode.CONST_WITH_NON_TYPE
              : CompileTimeErrorCode.NEW_WITH_NON_TYPE,
          errorRange.offset,
          errorRange.length,
          [node.name2.lexeme],
        );
        return true;
      }
    }
    return false;
  }

  void reportNullOrNonTypeElement(NamedType node, Element? element) {
    if (node.name2.isSynthetic) {
      return;
    }

    if (node.name2.lexeme == 'boolean') {
      final errorRange = _getErrorRange(node, skipImportPrefix: true);
      errorReporter.reportErrorForOffset(
        CompileTimeErrorCode.UNDEFINED_CLASS_BOOLEAN,
        errorRange.offset,
        errorRange.length,
        [node.name2.lexeme],
      );
      return;
    }

    if (_isTypeInCatchClause(node)) {
      final errorRange = _getErrorRange(node);
      errorReporter.reportErrorForOffset(
        CompileTimeErrorCode.NON_TYPE_IN_CATCH_CLAUSE,
        errorRange.offset,
        errorRange.length,
        [node.name2.lexeme],
      );
      return;
    }

    if (_isTypeInAsExpression(node)) {
      final errorRange = _getErrorRange(node);
      errorReporter.reportErrorForOffset(
        CompileTimeErrorCode.CAST_TO_NON_TYPE,
        errorRange.offset,
        errorRange.length,
        [node.name2.lexeme],
      );
      return;
    }

    if (_isTypeInIsExpression(node)) {
      final errorRange = _getErrorRange(node);
      if (element != null) {
        errorReporter.reportErrorForOffset(
          CompileTimeErrorCode.TYPE_TEST_WITH_NON_TYPE,
          errorRange.offset,
          errorRange.length,
          [node.name2.lexeme],
        );
      } else {
        errorReporter.reportErrorForOffset(
          CompileTimeErrorCode.TYPE_TEST_WITH_UNDEFINED_NAME,
          errorRange.offset,
          errorRange.length,
          [node.name2.lexeme],
        );
      }
      return;
    }

    if (_isRedirectingConstructor(node)) {
      final errorRange = _getErrorRange(node);
      errorReporter.reportErrorForOffset(
        CompileTimeErrorCode.REDIRECT_TO_NON_CLASS,
        errorRange.offset,
        errorRange.length,
        [node.name2.lexeme],
      );
      return;
    }

    if (_isTypeInTypeArgumentList(node)) {
      final errorRange = _getErrorRange(node);
      errorReporter.reportErrorForOffset(
        CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT,
        errorRange.offset,
        errorRange.length,
        [node.name2.lexeme],
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
          nameToken: node.name2,
          element: element!,
        ),
      );
      return;
    }

    if (element != null) {
      final errorRange = _getErrorRange(node);
      errorReporter.reportErrorForOffset(
        CompileTimeErrorCode.NOT_A_TYPE,
        errorRange.offset,
        errorRange.length,
        [node.name2.lexeme],
      );
      return;
    }

    if (node.importPrefix == null && node.name2.lexeme == 'await') {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT,
        node,
      );
      return;
    }

    final errorRange = _getErrorRange(node);
    errorReporter.reportErrorForOffset(
      CompileTimeErrorCode.UNDEFINED_CLASS,
      errorRange.offset,
      errorRange.length,
      [node.name2.lexeme],
    );
  }

  /// Returns the simple identifier of the given (maybe prefixed) identifier.
  static SourceRange _getErrorRange(
    NamedType node, {
    bool skipImportPrefix = false,
  }) {
    var firstToken = node.name2;
    final importPrefix = node.importPrefix;
    if (importPrefix != null) {
      if (!skipImportPrefix || importPrefix.element is! PrefixElement) {
        firstToken = importPrefix.name;
      }
    }
    final end = node.name2.end;
    return SourceRange(firstToken.offset, end - firstToken.offset);
  }

  /// Check if the [node] is the type in a redirected constructor name.
  static bool _isRedirectingConstructor(NamedType node) {
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
  static bool _isTypeInAsExpression(NamedType node) {
    var parent = node.parent;
    if (parent is AsExpression) {
      return identical(parent.type, node);
    }
    return false;
  }

  /// Checks if the [node] is the exception type in a `catch` clause.
  static bool _isTypeInCatchClause(NamedType node) {
    var parent = node.parent;
    if (parent is CatchClause) {
      return identical(parent.exceptionType, node);
    }
    return false;
  }

  /// Checks if the [node] is the type in an `is` expression.
  static bool _isTypeInIsExpression(NamedType node) {
    var parent = node.parent;
    if (parent is IsExpression) {
      return identical(parent.type, node);
    }
    return false;
  }

  /// Checks if the [node] is an element in a type argument list.
  static bool _isTypeInTypeArgumentList(NamedType node) {
    return node.parent is TypeArgumentList;
  }
}
