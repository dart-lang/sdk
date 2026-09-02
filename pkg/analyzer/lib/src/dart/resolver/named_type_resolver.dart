// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/type_info.dart'
    show isValidNonRecordTypeReference;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/scope_context.dart';
import 'package:analyzer/src/dart/type_instantiation_target.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart'
    show DiagnosticMessageImpl, LocatableDiagnostic;
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/scope_helpers.dart';

/// Helper for resolving types.
class NamedTypeResolver with ScopeHelpers {
  final LibraryFragmentImpl _libraryFragment;
  final ScopeContext _scopeContext;
  final TypeSystemImpl typeSystem;
  final TypeSystemOperations typeSystemOperations;
  final bool strictCasts;
  final bool strictInference;

  @override
  final DiagnosticReporter diagnosticReporter;

  /// If not `null`, the element of the [ClassDeclaration], or the
  /// [ClassTypeAlias] being resolved.
  InterfaceElementImpl? enclosingClass;

  /// If not `null`, a direct child of an [ExtendsClause], [WithClause],
  /// or [ImplementsClause].
  NamedType? classHierarchy_namedType;

  /// If not `null`, a direct child the [WithClause] in the [enclosingClass].
  NamedType? withClause_namedType;

  /// If [resolve] reported an error, this flag is set to `true`.
  bool hasErrorReported = false;

  NamedTypeResolver(
    LibraryElementImpl libraryElement,
    this._libraryFragment,
    this._scopeContext,
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
  void resolve(
    NamedTypeImpl node, {
    required TypeConstraintGenerationDataForTesting? dataForTesting,
  }) {
    hasErrorReported = false;

    var importPrefix = node.importPrefix;
    if (importPrefix != null) {
      var prefixToken = importPrefix.name;
      var prefixName = prefixToken.lexeme;
      var prefixElement = _scopeContext.nameScope.lookup(prefixName).getter;

      // Might be shadowed by an instance member.
      // Look again to report `prefixShadowedByLocalDeclaration`.
      prefixElement ??=
          enclosingClass?.getMethod(prefixName) ??
          enclosingClass?.getGetter(prefixName) ??
          enclosingClass?.getSetter(prefixName);

      importPrefix.element = prefixElement;

      if (prefixElement == null) {
        _resolveToElement(node, null, dataForTesting: dataForTesting);
        return;
      }

      if (prefixElement is InterfaceElement ||
          prefixElement is TypeAliasElement) {
        _reportNotATypeForQualifiedName(
          node: node,
          qualifier: importPrefix,
          qualifierElement: prefixElement,
        );
        return;
      }

      if (prefixElement is PrefixElement) {
        var nameToken = node.name;
        var element = _lookupGetter(prefixElement.scope, nameToken);
        _resolveToElement(node, element, dataForTesting: dataForTesting);
        return;
      }

      diagnosticReporter.report(
        diag.prefixShadowedByLocalDeclaration
            .withArguments(prefix: prefixName)
            .at(prefixToken),
      );
      node.type = InvalidTypeImpl.instance;
    } else {
      if (node.name.lexeme == 'void') {
        node.type = VoidTypeImpl.instance;
        return;
      }

      var element = _lookupGetter(_scopeContext.nameScope, node.name);
      _resolveToElement(node, element, dataForTesting: dataForTesting);
    }
  }

  /// Resolves the type-shaped portion of a V2 constructor reference.
  TypeImpl resolveConstructorTypeReference(
    ConstructorTypeReferenceImpl node, {
    required TypeConstraintGenerationDataForTesting? dataForTesting,
  }) {
    Element? element;
    var importPrefix = node.importPrefix;
    if (importPrefix case var importPrefix?) {
      var prefixElement = _scopeContext.nameScope
          .lookup(importPrefix.name.lexeme)
          .getter;
      importPrefix.element = prefixElement;
      if (prefixElement is PrefixElement) {
        element = _lookupGetter(prefixElement.scope, node.name);
      } else if ((prefixElement is InterfaceElement ||
              prefixElement is TypeAliasElement) &&
          node.parent2 is ConstructorReference2Impl &&
          (node.parent2 as ConstructorReference2Impl).selector == null) {
        var reference = node.parent2 as ConstructorReference2Impl;
        var typeArguments = node.typeArguments;
        if (typeArguments != null) {
          diagnosticReporter.report(
            diag.wrongNumberOfTypeArgumentsConstructor
                .withArguments(
                  className: importPrefix.name.lexeme,
                  constructorName: node.name.lexeme,
                )
                .at(typeArguments),
          );
          node.typeArguments = null;
          if (reference.parent2 case ConstructorInvocationImpl invocation) {
            invocation.typeArguments = typeArguments;
          }
        }

        var rewrittenTypeReference = ConstructorTypeReferenceImpl(
          importPrefix: null,
          name: importPrefix.name,
          typeArguments: null,
        );
        reference
          ..typeReference = rewrittenTypeReference
          ..selector = ConstructorSelectorImpl.v2(
            period: importPrefix.period,
            name2: node.name,
          );
        return resolveConstructorTypeReference(
          rewrittenTypeReference,
          dataForTesting: dataForTesting,
        );
      } else if (prefixElement is InterfaceElement ||
          prefixElement is TypeAliasElement) {
        element = null;
      } else if (prefixElement != null) {
        diagnosticReporter.report(
          diag.prefixShadowedByLocalDeclaration
              .withArguments(prefix: importPrefix.name.lexeme)
              .at(importPrefix.name),
        );
        return node.type = InvalidTypeImpl.instance;
      } else {
        element = null;
      }
    } else {
      element = _lookupGetter(_scopeContext.nameScope, node.name);
    }
    node.element = element;

    if (element is MultiplyDefinedElement) {
      return node.type = InvalidTypeImpl.instance;
    }

    var typeArguments = node.typeArguments;
    if (element is InterfaceElementImpl) {
      if (typeArguments case var typeArguments?) {
        var arguments = _buildTypeArguments(
          node,
          typeArguments,
          element.typeParameters.length,
          target: TypeInstantiationTargetInterfaceElement(element),
        );
        return node.type = element.instantiateImpl(
          typeArguments: arguments,
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
      if (_isFactoryRedirectionTarget(node)) {
        return node.type = _inferRedirectedConstructor(
          element,
          dataForTesting: dataForTesting,
          nodeForTesting: node,
        );
      }
      return node.type = typeSystem.instantiateInterfaceToBounds(
        element: element,
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    if (element is TypeAliasElementImpl) {
      TypeImpl type;
      if (typeArguments case var typeArguments?) {
        var arguments = _buildTypeArguments(
          node,
          typeArguments,
          element.typeParameters.length,
          target: TypeInstantiationTargetTypeAliasElement(element),
        );
        type = element.instantiateImpl(
          typeArguments: arguments,
          nullabilitySuffix: NullabilitySuffix.none,
        );
      } else {
        type = typeSystem.instantiateTypeAliasToBounds(
          element: element,
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
      if (element.aliasedType is TypeParameterType) {
        var errorRange = _constructorTypeReferenceErrorRange(node);
        diagnosticReporter.report(
          (_isFactoryRedirectionTarget(node)
                  ? diag.redirectToTypeAliasExpandsToTypeParameter
                  : diag.instantiateTypeAliasExpandsToTypeParameter)
              .atOffset(offset: errorRange.offset, length: errorRange.length),
        );
        type = InvalidTypeImpl.instance;
      } else if (type is! InterfaceTypeImpl) {
        if (_isFactoryRedirectionTarget(node)) {
          _reportRedirectToNonClass(node);
        } else {
          var invocation = node.parent2?.parent2;
          var isConst = switch (invocation) {
            ConstructorInvocation(isConst: var isConst) => isConst,
            _ => false,
          };
          diagnosticReporter.report(
            (isConst ? diag.constWithNonType : diag.newWithNonType)
                .withArguments(name: node.name.lexeme)
                .at(node.name),
          );
        }
        type = InvalidTypeImpl.instance;
      }
      return node.type = type;
    }

    if (_isFactoryRedirectionTarget(node)) {
      _reportRedirectToNonClass(node);
      return node.type = InvalidTypeImpl.instance;
    }

    if (importPrefix != null && importPrefix.element == null) {
      diagnosticReporter.report(
        diag.undefinedIdentifier
            .withArguments(name: importPrefix.name.lexeme)
            .atOffset(
              offset: importPrefix.offset,
              length: node.name.end - importPrefix.offset,
            ),
      );
      return node.type = InvalidTypeImpl.instance;
    }

    if (!node.name.isSynthetic) {
      var invocation = node.parent2?.parent2;
      var isConst = switch (invocation) {
        ConstructorInvocation(isConst: var isConst) => isConst,
        _ => false,
      };
      var diagnostic = (isConst ? diag.constWithNonType : diag.newWithNonType)
          .withArguments(name: node.name.lexeme);
      var errorTarget = importPrefix;
      diagnosticReporter.report(
        errorTarget != null && errorTarget.element is! PrefixElement
            ? diagnostic.atOffset(
                offset: errorTarget.offset,
                length: node.name.end - errorTarget.offset,
              )
            : diagnostic.at(node.name),
      );
    }
    return node.type = InvalidTypeImpl.instance;
  }

  /// Return type arguments, exactly [parameterCount].
  List<TypeImpl> _buildTypeArguments(
    AstNode node,
    TypeArgumentList argumentList,
    int parameterCount, {
    required TypeInstantiationTarget target,
  }) {
    var arguments = argumentList.arguments;

    var argumentCount = arguments.length;

    if (argumentCount != parameterCount) {
      diagnosticReporter.report(
        target
            .wrongNumberOfTypeArgumentsError(
              typeParameterCount: parameterCount,
              typeArgumentCount: argumentCount,
            )
            .at(node),
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
          target: TypeInstantiationTargetInterfaceElement(element),
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
          target: TypeInstantiationTargetTypeAliasElement(element),
        );
        var type = element.instantiateImpl(
          typeArguments: typeArguments,
          nullabilitySuffix: nullability,
        );
        return _verifyTypeAliasForContext(node, element, type);
      } else if (element is DynamicElementImpl) {
        _buildTypeArguments(
          node,
          argumentList,
          0,
          target: const TypeInstantiationTargetDynamicTypeElement(),
        );
        return DynamicTypeImpl.instance;
      } else if (element is NeverElementImpl) {
        _buildTypeArguments(
          node,
          argumentList,
          0,
          target: const TypeInstantiationTargetNeverTypeElement(),
        );
        return _instantiateElementNever(nullability);
      } else if (element is TypeParameterElementImpl) {
        _buildTypeArguments(
          node,
          argumentList,
          0,
          target: TypeInstantiationTargetTypeParameterElement(element),
        );
        return InvalidTypeImpl.instance;
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
    } else if (element is DynamicElementImpl) {
      return DynamicTypeImpl.instance;
    } else if (element is NeverElementImpl) {
      return _instantiateElementNever(nullability);
    } else if (element is TypeParameterElementImpl) {
      return _scopeContext.instantiateTypeParameter(
        element: element,
        nullability: nullability,
      );
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

  /// Reports a qualified [NamedType], such as `A.foo`, when the qualifier
  /// resolves to a type instead of an import prefix.
  void _reportNotATypeForQualifiedName({
    required NamedTypeImpl node,
    required ImportPrefixReferenceImpl qualifier,
    required Element qualifierElement,
  }) {
    node.type = InvalidTypeImpl.instance;
    Element? element = qualifierElement;
    var nameToken = node.name;
    var name = nameToken.lexeme;
    if (qualifierElement is InstanceElement) {
      if (qualifierElement is InterfaceElement) {
        element = qualifierElement.getNamedConstructor(name);
      }
      element ??=
          qualifierElement.getField(name) ??
          qualifierElement.getGetter(name) ??
          qualifierElement.getMethod(name) ??
          qualifierElement.getSetter(name);
    }
    var fragment = element?.firstFragment;
    var source = fragment?.libraryFragment?.source;
    var nameOffset = fragment?.nameOffset;
    diagnosticReporter.report(
      diag.notAType
          .withArguments(name: '${qualifier.name.lexeme}.${nameToken.lexeme}')
          .withContextMessages([
            if (source != null && nameOffset != null)
              DiagnosticMessageImpl(
                filePath: source.fullName,
                message: "The declaration of '$name' is here.",
                offset: nameOffset,
                length: name.length,
                url: null,
              ),
          ])
          .atOffset(
            offset: qualifier.offset,
            length: nameToken.end - qualifier.offset,
          ),
    );
  }

  void _reportRedirectToNonClass(ConstructorTypeReferenceImpl node) {
    var errorRange = _constructorTypeReferenceErrorRange(node);
    diagnosticReporter.report(
      diag.redirectToNonClass
          .withArguments(name: node.name.lexeme)
          .atOffset(offset: errorRange.offset, length: errorRange.length),
    );
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

  /// If the [node] appears in a location where a nullable type is not allowed,
  /// but the [type] is nullable (because the question mark was specified,
  /// or the type alias is nullable), report an error, and return the
  /// corresponding non-nullable type.
  TypeImpl _verifyNullability(NamedType node, TypeImpl type) {
    if (identical(node, classHierarchy_namedType)) {
      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        var parent = node.parent2;
        if (parent is ExtendsClause || parent is ClassTypeAlias) {
          diagnosticReporter.report(diag.nullableTypeInExtendsClause.at(node));
        } else if (parent is ImplementsClause) {
          diagnosticReporter.report(
            diag.nullableTypeInImplementsClause.at(node),
          );
        } else if (parent is MixinOnClause) {
          diagnosticReporter.report(diag.nullableTypeInOnClause.at(node));
        } else if (parent is WithClause) {
          diagnosticReporter.report(diag.nullableTypeInWithClause.at(node));
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
      var parent = node.parent2;
      // Report if this type is used as a class in hierarchy.
      LocatableDiagnostic? diagnosticCode;
      if (parent is ExtendsClause) {
        diagnosticCode = diag.extendsTypeAliasExpandsToTypeParameter;
      } else if (parent is ImplementsClause) {
        diagnosticCode = diag.implementsTypeAliasExpandsToTypeParameter;
      } else if (parent is MixinOnClause) {
        diagnosticCode = diag.mixinOnTypeAliasExpandsToTypeParameter;
      } else if (parent is WithClause) {
        diagnosticCode = diag.mixinOfTypeAliasExpandsToTypeParameter;
      }
      if (diagnosticCode != null) {
        var errorRange = _ErrorHelper._getErrorRange(node);
        diagnosticReporter.report(
          diagnosticCode.atOffset(
            offset: errorRange.offset,
            length: errorRange.length,
          ),
        );
        hasErrorReported = true;
        return InvalidTypeImpl.instance;
      }
    }
    return type;
  }

  static SourceRange _constructorTypeReferenceErrorRange(
    ConstructorTypeReference node,
  ) {
    var firstToken = node.importPrefix?.name ?? node.name;
    return SourceRange(firstToken.offset, node.name.end - firstToken.offset);
  }

  static bool _isFactoryRedirectionTarget(ConstructorTypeReferenceImpl node) {
    var reference = node.parent2;
    if (reference is ConstructorReference2Impl) {
      var declaration = reference.parent2;
      return declaration is ConstructorDeclarationImpl &&
          identical(declaration.factoryRedirectionTarget, reference);
    }
    return false;
  }
}

/// Helper for reporting diagnostics during type name resolution.
class _ErrorHelper {
  final DiagnosticReporter diagnosticReporter;

  _ErrorHelper(this.diagnosticReporter);

  void reportNullOrNonTypeElement(NamedType node, Element? element) {
    if (node.name.isSynthetic) {
      return;
    }

    if (node.name.lexeme == 'boolean') {
      var errorRange = _getErrorRange(node, skipImportPrefix: true);
      diagnosticReporter.report(
        diag.undefinedClassBoolean
            .withArguments(name: node.name.lexeme)
            .atOffset(offset: errorRange.offset, length: errorRange.length),
      );
      return;
    }

    if (_isTypeInCatchClause(node)) {
      var errorRange = _getErrorRange(node);
      diagnosticReporter.report(
        diag.nonTypeInCatchClause
            .withArguments(name: node.name.lexeme)
            .atOffset(offset: errorRange.offset, length: errorRange.length),
      );
      return;
    }

    if (_isTypeInAsExpression(node)) {
      var errorRange = _getErrorRange(node);
      diagnosticReporter.report(
        diag.castToNonType
            .withArguments(name: node.name.lexeme)
            .atOffset(offset: errorRange.offset, length: errorRange.length),
      );
      return;
    }

    if (_isTypeInIsExpression(node)) {
      var errorRange = _getErrorRange(node);
      if (element != null) {
        diagnosticReporter.report(
          diag.typeTestWithNonType
              .withArguments(name: node.name.lexeme)
              .atOffset(offset: errorRange.offset, length: errorRange.length),
        );
      } else {
        diagnosticReporter.report(
          diag.typeTestWithUndefinedName
              .withArguments(name: node.name.lexeme)
              .atOffset(offset: errorRange.offset, length: errorRange.length),
        );
      }
      return;
    }

    if (_isTypeInTypeArgumentList(node)) {
      var errorRange = _getErrorRange(node);
      diagnosticReporter.report(
        diag.nonTypeAsTypeArgument
            .withArguments(name: node.name.lexeme)
            .atOffset(offset: errorRange.offset, length: errorRange.length),
      );
      return;
    }

    var parent = node.parent2;
    if (parent is ExtendsClause ||
        parent is ImplementsClause ||
        parent is WithClause ||
        parent is ClassTypeAlias) {
      // Ignored. The error will be reported elsewhere.
      return;
    }

    if (element is LocalVariableElement || element is LocalFunctionElement) {
      diagnosticReporter.report(
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
      diagnosticReporter.report(
        diag.notAType
            .withArguments(name: name)
            .withContextMessages([
              if (source != null && nameOffset != null)
                DiagnosticMessageImpl(
                  filePath: source.fullName,
                  message: "The declaration of '$name' is here.",
                  offset: nameOffset,
                  length: name.length,
                  url: null,
                ),
            ])
            .atOffset(offset: errorRange.offset, length: errorRange.length),
      );
      return;
    }

    if (node.importPrefix == null && node.name.lexeme == 'await') {
      diagnosticReporter.report(diag.undefinedIdentifierAwait.at(node));
      return;
    }

    if (!isValidNonRecordTypeReference(node.name)) {
      return;
    }

    var errorRange = _getErrorRange(node);
    diagnosticReporter.report(
      diag.undefinedClass
          .withArguments(name: node.name.lexeme)
          .atOffset(offset: errorRange.offset, length: errorRange.length),
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

  /// Checks if the [node] is the type in an `as` expression.
  static bool _isTypeInAsExpression(NamedType node) {
    var parent = node.parent2;
    if (parent is AsExpression) {
      return identical(parent.type, node);
    }
    return false;
  }

  /// Checks if the [node] is the exception type in a `catch` clause.
  static bool _isTypeInCatchClause(NamedType node) {
    var parent = node.parent2;
    if (parent is CatchClause) {
      return identical(parent.exceptionType, node);
    }
    return false;
  }

  /// Checks if the [node] is the type in an `is` expression.
  static bool _isTypeInIsExpression(NamedType node) {
    var parent = node.parent2;
    if (parent is IsExpression) {
      return identical(parent.type, node);
    }
    return false;
  }

  /// Checks if the [node] is an element in a type argument list.
  static bool _isTypeInTypeArgumentList(NamedType node) {
    return node.parent2 is TypeArgumentList;
  }
}
