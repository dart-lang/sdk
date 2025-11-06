// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/scope_helpers.dart';

/// Helper for resolving types.
///
/// The client must set [nameScope] before calling [resolve].
class NamedTypeResolver with ScopeHelpers {
  final LibraryFragmentImpl _libraryFragment;
  final TypeSystemImpl typeSystem;
  final TypeSystemOperations typeSystemOperations;
  final bool strictCasts;
  final bool strictInference;

  @override
  final DiagnosticReporter diagnosticReporter;

  late Scope nameScope;

  /// If not `null`, the element of the [ClassDeclaration], or the
  /// [ClassTypeAlias] being resolved.
  InterfaceElementImpl? enclosingClass;

  /// If not `null`, a direct child of an [ExtendsClause], [WithClause],
  /// or [ImplementsClause].
  NamedType? classHierarchy_namedType;

  /// If not `null`, a direct child the [WithClause] in the [enclosingClass].
  NamedType? withClause_namedType;

  /// If [resolve] finds out that the given [NamedType] with a
  /// [PrefixedIdentifier] name is actually the name of a class and the name of
  /// the constructor, it rewrites the [ConstructorName] to correctly represent
  /// the type and the constructor name, and set this field to the rewritten
  /// [ConstructorName]. Otherwise this field will be set `null`.
  ConstructorName? rewriteResult;

  /// If [resolve] reported an error, this flag is set to `true`.
  bool hasErrorReported = false;

  NamedTypeResolver(
    LibraryElementImpl libraryElement,
    this._libraryFragment,
    this.diagnosticReporter, {
    required this.strictInference,
    required this.strictCasts,
    required this.typeSystemOperations,
  }) : typeSystem = libraryElement.typeSystem;

  bool get _genericMetadataIsEnabled =>
      enclosingClass!.library.featureSet.isEnabled(Feature.generic_metadata);

  bool get _inferenceUsingBoundsIsEnabled => enclosingClass!.library.featureSet
      .isEnabled(Feature.inference_using_bounds);

  /// Resolve the given [NamedType] - set its element and static type. Only the
  /// given [node] is resolved, all its children must be already resolved.
  ///
  /// The client must set [nameScope] before calling [resolve].
  void resolve(
    NamedTypeImpl node, {
    required TypeConstraintGenerationDataForTesting? dataForTesting,
  }) {
    rewriteResult = null;
    hasErrorReported = false;

    var importPrefix = node.importPrefix;
    if (importPrefix != null) {
      var prefixToken = importPrefix.name;
      var prefixName = prefixToken.lexeme;
      var prefixElement = nameScope.lookup(prefixName).getter;
      importPrefix.element = prefixElement;

      if (prefixElement == null) {
        _resolveToElement(node, null, dataForTesting: dataForTesting);
        return;
      }

      if (prefixElement is InterfaceElement ||
          prefixElement is TypeAliasElement) {
        _rewriteToConstructorName(
          node: node,
          importPrefix: importPrefix,
          importPrefixElement: prefixElement,
          nameToken: node.name,
        );
        return;
      }

      if (prefixElement is PrefixElement) {
        var nameToken = node.name;
        var element = _lookupGetter(prefixElement.scope, nameToken);
        _resolveToElement(node, element, dataForTesting: dataForTesting);
        return;
      }

      diagnosticReporter.atToken(
        prefixToken,
        CompileTimeErrorCode.prefixShadowedByLocalDeclaration,
        arguments: [prefixName],
      );
      node.type = InvalidTypeImpl.instance;
    } else {
      if (node.name.lexeme == 'void') {
        node.type = VoidTypeImpl.instance;
        return;
      }

      var element = _lookupGetter(nameScope, node.name);
      _resolveToElement(node, element, dataForTesting: dataForTesting);
    }
  }

  /// Return type arguments, exactly [parameterCount].
  List<TypeImpl> _buildTypeArguments(
    NamedType node,
    TypeArgumentList argumentList,
    int parameterCount,
  ) {
    var arguments = argumentList.arguments;
    var argumentCount = arguments.length;

    if (argumentCount != parameterCount) {
      diagnosticReporter.atNode(
        node,
        CompileTimeErrorCode.wrongNumberOfTypeArguments,
        arguments: [node.name.lexeme, parameterCount, argumentCount],
      );
      return List.filled(parameterCount, InvalidTypeImpl.instance);
    }

    if (parameterCount == 0) {
      return const <TypeImpl>[];
    }

    return List.generate(
      parameterCount,
      (i) => arguments[i].typeOrThrow,
      growable: false,
    );
  }

  NullabilitySuffix _getNullability(NamedType node) {
    if (node.question != null) {
      return NullabilitySuffix.question;
    } else {
      return NullabilitySuffix.none;
    }
  }

  /// We are resolving the [NamedType] in a redirecting constructor of the
  /// [enclosingClass].
  InterfaceTypeImpl _inferRedirectedConstructor(
    InterfaceElementImpl element, {
    required TypeConstraintGenerationDataForTesting? dataForTesting,
    required AstNodeImpl? nodeForTesting,
  }) {
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
          inferenceUsingBoundsIsEnabled: _inferenceUsingBoundsIsEnabled,
          strictInference: strictInference,
          strictCasts: strictCasts,
          typeSystemOperations: typeSystemOperations,
          dataForTesting: dataForTesting,
          nodeForTesting: nodeForTesting,
        );
        var typeArguments = inferrer.chooseFinalTypes();
        return element.instantiateImpl(
          typeArguments: typeArguments,
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
    }
  }

  TypeImpl _instantiateElement(
    NamedTypeImpl node,
    Element element, {
    required TypeConstraintGenerationDataForTesting? dataForTesting,
  }) {
    var nullability = _getNullability(node);

    var argumentList = node.typeArguments;
    if (argumentList != null) {
      if (element is InterfaceElementImpl) {
        var typeArguments = _buildTypeArguments(
          node,
          argumentList,
          element.typeParameters.length,
        );
        return element.instantiateImpl(
          typeArguments: typeArguments,
          nullabilitySuffix: nullability,
        );
      } else if (element is TypeAliasElementImpl) {
        var typeArguments = _buildTypeArguments(
          node,
          argumentList,
          element.typeParameters.length,
        );
        var type = element.instantiateImpl(
          typeArguments: typeArguments,
          nullabilitySuffix: nullability,
        );
        return _verifyTypeAliasForContext(node, element, type);
      } else if (_isInstanceCreation(node)) {
        _ErrorHelper(diagnosticReporter).reportNewWithNonType(node);
        return InvalidTypeImpl.instance;
      } else if (element is DynamicElementImpl) {
        _buildTypeArguments(node, argumentList, 0);
        return DynamicTypeImpl.instance;
      } else if (element is NeverElementImpl) {
        _buildTypeArguments(node, argumentList, 0);
        return _instantiateElementNever(nullability);
      } else if (element is TypeParameterElementImpl) {
        _buildTypeArguments(node, argumentList, 0);
        return element.instantiate(nullabilitySuffix: nullability);
      } else {
        _ErrorHelper(
          diagnosticReporter,
        ).reportNullOrNonTypeElement(node, element);
        return InvalidTypeImpl.instance;
      }
    }

    if (element is InterfaceElementImpl) {
      if (identical(node, withClause_namedType)) {
        for (var mixin in enclosingClass!.mixins) {
          if (mixin.element == element) {
            return mixin;
          }
        }
      }

      if (_ErrorHelper._isRedirectingConstructor(node)) {
        return _inferRedirectedConstructor(
          element,
          dataForTesting: dataForTesting,
          nodeForTesting: node,
        );
      }

      return typeSystem.instantiateInterfaceToBounds(
        element: element,
        nullabilitySuffix: nullability,
      );
    } else if (element is TypeAliasElementImpl) {
      var type = typeSystem.instantiateTypeAliasToBounds(
        element: element,
        nullabilitySuffix: nullability,
      );
      return _verifyTypeAliasForContext(node, element, type);
    } else if (_isInstanceCreation(node)) {
      _ErrorHelper(diagnosticReporter).reportNewWithNonType(node);
      return InvalidTypeImpl.instance;
    } else if (element is DynamicElementImpl) {
      return DynamicTypeImpl.instance;
    } else if (element is NeverElementImpl) {
      return _instantiateElementNever(nullability);
    } else if (element is TypeParameterElementImpl) {
      return element.instantiate(nullabilitySuffix: nullability);
    } else {
      _ErrorHelper(
        diagnosticReporter,
      ).reportNullOrNonTypeElement(node, element);
      return InvalidTypeImpl.instance;
    }
  }

  TypeImpl _instantiateElementNever(NullabilitySuffix nullability) {
    return NeverTypeImpl.instance.withNullability(nullability);
  }

  Element? _lookupGetter(Scope scope, Token nameToken) {
    var scopeLookupResult = scope.lookup(nameToken.lexeme);
    reportDeprecatedExportUseGetter(
      scopeLookupResult: scopeLookupResult,
      nameToken: nameToken,
    );
    return scopeLookupResult.getter;
  }

  void _resolveToElement(
    NamedTypeImpl node,
    Element? element, {
    required TypeConstraintGenerationDataForTesting? dataForTesting,
  }) {
    node.element = element;

    if (element == null) {
      node.type = InvalidTypeImpl.instance;
      if (!_libraryFragment.shouldIgnoreUndefinedNamedType(node)) {
        _ErrorHelper(diagnosticReporter).reportNullOrNonTypeElement(node, null);
      }
      return;
    }

    if (element is MultiplyDefinedElement) {
      node.type = InvalidTypeImpl.instance;
      return;
    }

    var type = _instantiateElement(
      node,
      element,
      dataForTesting: dataForTesting,
    );
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
        diagnosticReporter.atNode(
          typeArguments,
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsConstructor,
          arguments: [importPrefix.name.lexeme, nameToken.lexeme],
        );
        var instanceCreation = constructorName.parent;
        if (instanceCreation is InstanceCreationExpressionImpl) {
          instanceCreation.typeArguments = typeArguments;
        }
      }

      var namedType = NamedTypeImpl(
        importPrefix: null,
        name: importPrefix.name,
        typeArguments: null,
        question: null,
      )..element = importPrefixElement;

      constructorName.type = namedType;
      constructorName.period = importPrefix.period;
      constructorName.name = SimpleIdentifierImpl(token: nameToken);

      rewriteResult = constructorName;
      return;
    }

    if (_isInstanceCreation(node)) {
      node.type = InvalidTypeImpl.instance;
      _ErrorHelper(diagnosticReporter).reportNewWithNonType(node);
    } else {
      node.type = InvalidTypeImpl.instance;
      Element? element = importPrefixElement;
      String name = node.name.lexeme;
      if (importPrefixElement is InstanceElement) {
        if (importPrefixElement is InterfaceElement) {
          element = importPrefixElement.getNamedConstructor(name);
        }
        element ??=
            importPrefixElement.getField(name) ??
            importPrefixElement.getGetter(name) ??
            importPrefixElement.getMethod(name) ??
            importPrefixElement.getSetter(name);
      }
      var fragment = element?.firstFragment;
      var source = fragment?.libraryFragment?.source;
      var nameOffset = fragment?.nameOffset;
      diagnosticReporter.atOffset(
        offset: importPrefix.offset,
        length: nameToken.end - importPrefix.offset,
        diagnosticCode: CompileTimeErrorCode.notAType,
        arguments: ['${importPrefix.name.lexeme}.${nameToken.lexeme}'],
        contextMessages: [
          if (source != null && nameOffset != null)
            DiagnosticMessageImpl(
              filePath: source.fullName,
              message: "The declaration of '$name' is here.",
              offset: nameOffset,
              length: name.length,
              url: null,
            ),
        ],
      );
    }
  }

  /// If the [node] appears in a location where a nullable type is not allowed,
  /// but the [type] is nullable (because the question mark was specified,
  /// or the type alias is nullable), report an error, and return the
  /// corresponding non-nullable type.
  TypeImpl _verifyNullability(NamedType node, TypeImpl type) {
    if (identical(node, classHierarchy_namedType)) {
      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        var parent = node.parent;
        if (parent is ExtendsClause || parent is ClassTypeAlias) {
          diagnosticReporter.atNode(
            node,
            CompileTimeErrorCode.nullableTypeInExtendsClause,
          );
        } else if (parent is ImplementsClause) {
          diagnosticReporter.atNode(
            node,
            CompileTimeErrorCode.nullableTypeInImplementsClause,
          );
        } else if (parent is MixinOnClause) {
          diagnosticReporter.atNode(
            node,
            CompileTimeErrorCode.nullableTypeInOnClause,
          );
        } else if (parent is WithClause) {
          diagnosticReporter.atNode(
            node,
            CompileTimeErrorCode.nullableTypeInWithClause,
          );
        }
        return type.withNullability(NullabilitySuffix.none);
      }
    }

    return type;
  }

  TypeImpl _verifyTypeAliasForContext(
    NamedType node,
    TypeAliasElement element,
    TypeImpl type,
  ) {
    // If a type alias that expands to a type parameter.
    if (element.aliasedType is TypeParameterType) {
      var parent = node.parent;
      if (parent is ConstructorName) {
        var errorRange = _ErrorHelper._getErrorRange(node);
        var constructorUsage = parent.parent;
        if (constructorUsage is InstanceCreationExpression) {
          diagnosticReporter.atOffset(
            offset: errorRange.offset,
            length: errorRange.length,
            diagnosticCode:
                CompileTimeErrorCode.instantiateTypeAliasExpandsToTypeParameter,
          );
        } else if (constructorUsage is ConstructorDeclaration &&
            constructorUsage.redirectedConstructor == parent) {
          diagnosticReporter.atOffset(
            offset: errorRange.offset,
            length: errorRange.length,
            diagnosticCode:
                CompileTimeErrorCode.redirectToTypeAliasExpandsToTypeParameter,
          );
        } else {
          throw UnimplementedError('${constructorUsage.runtimeType}');
        }
        return InvalidTypeImpl.instance;
      }

      // Report if this type is used as a class in hierarchy.
      DiagnosticCode? diagnosticCode;
      if (parent is ExtendsClause) {
        diagnosticCode =
            CompileTimeErrorCode.extendsTypeAliasExpandsToTypeParameter;
      } else if (parent is ImplementsClause) {
        diagnosticCode =
            CompileTimeErrorCode.implementsTypeAliasExpandsToTypeParameter;
      } else if (parent is MixinOnClause) {
        diagnosticCode =
            CompileTimeErrorCode.mixinOnTypeAliasExpandsToTypeParameter;
      } else if (parent is WithClause) {
        diagnosticCode =
            CompileTimeErrorCode.mixinOfTypeAliasExpandsToTypeParameter;
      }
      if (diagnosticCode != null) {
        var errorRange = _ErrorHelper._getErrorRange(node);
        diagnosticReporter.atOffset(
          offset: errorRange.offset,
          length: errorRange.length,
          diagnosticCode: diagnosticCode,
        );
        hasErrorReported = true;
        return InvalidTypeImpl.instance;
      }
    }
    if (type is! InterfaceType && _isInstanceCreation(node)) {
      _ErrorHelper(diagnosticReporter).reportNewWithNonType(node);
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

/// Helper for reporting diagnostics during type name resolution.
class _ErrorHelper {
  final DiagnosticReporter diagnosticReporter;

  _ErrorHelper(this.diagnosticReporter);

  bool reportNewWithNonType(NamedType node) {
    var constructorName = node.parent;
    if (constructorName is ConstructorName) {
      var instanceCreation = constructorName.parent;
      if (instanceCreation is InstanceCreationExpression) {
        var errorRange = _getErrorRange(node, skipImportPrefix: true);
        var importPrefix = node.importPrefix;
        if (importPrefix != null && importPrefix.element == null) {
          // The constructor name is in two or three parts and the first part,
          // which is either a prefix or a class name, is unresolved. In this
          // case, report that the first name is undefined, instead of reporting
          // that the last name is not a class.
          // TODO(johnniwinther): We could report "Undefined prefix 'x'." when
          // we know it can only be a prefix, for instance in `x.y.z()`.
          String prefixOrClassName = importPrefix.name.lexeme;
          diagnosticReporter.atOffset(
            offset: errorRange.offset,
            length: errorRange.length,
            diagnosticCode: CompileTimeErrorCode.undefinedIdentifier,
            arguments: [prefixOrClassName],
          );
        } else {
          String className = node.name.lexeme;
          diagnosticReporter.atOffset(
            offset: errorRange.offset,
            length: errorRange.length,
            diagnosticCode: instanceCreation.isConst
                ? CompileTimeErrorCode.constWithNonType
                : CompileTimeErrorCode.newWithNonType,
            arguments: [className],
          );
        }
        return true;
      }
    }
    return false;
  }

  void reportNullOrNonTypeElement(NamedType node, Element? element) {
    if (node.name.isSynthetic) {
      return;
    }

    if (node.name.lexeme == 'boolean') {
      var errorRange = _getErrorRange(node, skipImportPrefix: true);
      diagnosticReporter.atOffset(
        offset: errorRange.offset,
        length: errorRange.length,
        diagnosticCode: CompileTimeErrorCode.undefinedClassBoolean,
        arguments: [node.name.lexeme],
      );
      return;
    }

    if (_isTypeInCatchClause(node)) {
      var errorRange = _getErrorRange(node);
      diagnosticReporter.atOffset(
        offset: errorRange.offset,
        length: errorRange.length,
        diagnosticCode: CompileTimeErrorCode.nonTypeInCatchClause,
        arguments: [node.name.lexeme],
      );
      return;
    }

    if (_isTypeInAsExpression(node)) {
      var errorRange = _getErrorRange(node);
      diagnosticReporter.atOffset(
        offset: errorRange.offset,
        length: errorRange.length,
        diagnosticCode: CompileTimeErrorCode.castToNonType,
        arguments: [node.name.lexeme],
      );
      return;
    }

    if (_isTypeInIsExpression(node)) {
      var errorRange = _getErrorRange(node);
      if (element != null) {
        diagnosticReporter.atOffset(
          offset: errorRange.offset,
          length: errorRange.length,
          diagnosticCode: CompileTimeErrorCode.typeTestWithNonType,
          arguments: [node.name.lexeme],
        );
      } else {
        diagnosticReporter.atOffset(
          offset: errorRange.offset,
          length: errorRange.length,
          diagnosticCode: CompileTimeErrorCode.typeTestWithUndefinedName,
          arguments: [node.name.lexeme],
        );
      }
      return;
    }

    if (_isRedirectingConstructor(node)) {
      var errorRange = _getErrorRange(node);
      diagnosticReporter.atOffset(
        offset: errorRange.offset,
        length: errorRange.length,
        diagnosticCode: CompileTimeErrorCode.redirectToNonClass,
        arguments: [node.name.lexeme],
      );
      return;
    }

    if (_isTypeInTypeArgumentList(node)) {
      var errorRange = _getErrorRange(node);
      diagnosticReporter.atOffset(
        offset: errorRange.offset,
        length: errorRange.length,
        diagnosticCode: CompileTimeErrorCode.nonTypeAsTypeArgument,
        arguments: [node.name.lexeme],
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

    if (element is LocalVariableElement || element is LocalFunctionElement) {
      diagnosticReporter.reportError(
        DiagnosticFactory().referencedBeforeDeclaration(
          diagnosticReporter.source,
          nameToken: node.name,
          element2: element!,
        ),
      );
      return;
    }

    if (element != null) {
      var errorRange = _getErrorRange(node);
      var name = node.name.lexeme;
      var fragment = element.firstFragment;
      var source = fragment.libraryFragment?.source;
      var nameOffset = fragment.nameOffset;
      diagnosticReporter.atOffset(
        offset: errorRange.offset,
        length: errorRange.length,
        diagnosticCode: CompileTimeErrorCode.notAType,
        arguments: [name],
        contextMessages: [
          if (source != null && nameOffset != null)
            DiagnosticMessageImpl(
              filePath: source.fullName,
              message: "The declaration of '$name' is here.",
              offset: nameOffset,
              length: name.length,
              url: null,
            ),
        ],
      );
      return;
    }

    if (node.importPrefix == null && node.name.lexeme == 'await') {
      diagnosticReporter.atNode(
        node,
        CompileTimeErrorCode.undefinedIdentifierAwait,
      );
      return;
    }

    var errorRange = _getErrorRange(node);
    diagnosticReporter.atOffset(
      offset: errorRange.offset,
      length: errorRange.length,
      diagnosticCode: CompileTimeErrorCode.undefinedClass,
      arguments: [node.name.lexeme],
    );
  }

  /// Returns the simple identifier of the given (maybe prefixed) identifier.
  static SourceRange _getErrorRange(
    NamedType node, {
    bool skipImportPrefix = false,
  }) {
    var firstToken = node.name;
    var importPrefix = node.importPrefix;
    if (importPrefix != null) {
      if (!skipImportPrefix || importPrefix.element is! PrefixElement) {
        firstToken = importPrefix.name;
      }
    }
    var end = node.name.end;
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
