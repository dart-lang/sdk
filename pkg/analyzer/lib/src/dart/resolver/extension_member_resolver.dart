// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/inference_log.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';

class ExtensionMemberResolver {
  final ResolverVisitor _resolver;

  ExtensionMemberResolver(this._resolver);

  DiagnosticReporter get _diagnosticReporter => _resolver.diagnosticReporter;

  bool get _genericMetadataIsEnabled =>
      _resolver.definingLibrary.featureSet.isEnabled(Feature.generic_metadata);

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  /// Set the type context for the receiver of the override.
  ///
  /// The context of the invocation that is made through the override does
  /// not affect the type inference of the override and the receiver.
  TypeImpl? computeOverrideReceiverContextType(ExtensionOverride node) {
    var element = node.element;
    var typeParameters = element.typeParameters;

    var arguments = node.argumentList.arguments;
    if (arguments.length != 1) {
      return null;
    }

    List<DartType> typeArgumentTypes;
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      var arguments = typeArguments.arguments;
      if (arguments.length == typeParameters.length) {
        typeArgumentTypes = arguments.map((a) => a.typeOrThrow).toList();
      } else {
        typeArgumentTypes = _listOfDynamic(typeParameters);
      }
    } else {
      typeArgumentTypes = List.filled(
        typeParameters.length,
        UnknownInferredType.instance,
      );
    }

    return Substitution.fromPairs2(
      typeParameters,
      typeArgumentTypes,
    ).substituteType(element.extendedType);
  }

  /// Returns the most specific accessible extension, applicable to [type],
  /// that defines the member with the given [name].
  ///
  /// If no applicable extensions are found, returns
  /// [ExtensionResolutionError.none].
  ///
  /// If the match is ambiguous, reports an error on the [nameEntity], and
  /// returns [ExtensionResolutionError.ambiguous].
  ExtensionResolutionResult findExtension(
    TypeImpl type,
    SyntacticEntity nameEntity,
    Name name,
  ) {
    var extensions = _resolver.libraryFragment.accessibleExtensions
        .havingMemberWithBaseName(name)
        .toList()
        .applicableTo(
          targetLibrary: _resolver.definingLibrary,
          targetType: type,
        );

    if (extensions.isEmpty) {
      return ExtensionResolutionError.none;
    }

    if (extensions.length == 1) {
      var instantiated = extensions[0];
      _resolver.libraryFragment.scope.notifyExtensionUsed(
        instantiated.extension,
      );
      return instantiated.asResolutionResult;
    }

    var mostSpecific = _chooseMostSpecific(extensions);
    if (mostSpecific.length == 1) {
      var instantiated = mostSpecific.first;
      _resolver.libraryFragment.scope.notifyExtensionUsed(
        instantiated.extension,
      );
      return instantiated.asResolutionResult;
    }

    // The most specific extension is ambiguous.
    if (mostSpecific.length == 2) {
      _diagnosticReporter.atEntity(
        nameEntity,
        CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo,
        arguments: [
          name.name,
          mostSpecific[0].extension,
          mostSpecific[1].extension,
        ],
      );
    } else {
      var extensions = mostSpecific.map((e) => e.extension).toList();
      _diagnosticReporter.atEntity(
        nameEntity,
        CompileTimeErrorCode.ambiguousExtensionMemberAccessThreeOrMore,
        arguments: [
          name.name,
          mostSpecific.map((e) {
            var name = e.extension.name;
            if (name != null) {
              return "extension '$name'";
            }
            var type = e.extendedType.getDisplayString();
            return "unnamed extension on '$type'";
          }).commaSeparatedWithAnd,
        ],
        contextMessages: convertTypeNames(<Object>[...extensions]),
      );
    }
    return ExtensionResolutionError.ambiguous;
  }

  /// Resolve the [name] (without `=`) to the corresponding getter and setter
  /// members of the extension [node].
  ///
  /// The [node] is fully resolved, and its type arguments are set.
  ExtensionResolutionResult getOverrideMember(
    ExtensionOverrideImpl node,
    String name,
  ) {
    var element = node.element;

    ExecutableElementImpl? getter;
    ExecutableElementImpl? setter;
    if (name == '[]') {
      getter = element.getMethod('[]');
      setter = element.getMethod('[]=');
    } else {
      getter = element.getGetter(name) ?? element.getMethod(name);
      setter = element.getSetter(name);
    }

    if (getter == null && setter == null) {
      return ExtensionResolutionError.none;
    }

    var substitution = Substitution.fromPairs2(
      element.typeParameters,
      node.typeArgumentTypes!,
    );

    var getterMember = getter != null
        ? SubstitutedExecutableElementImpl.from(getter, substitution)
        : null;
    var setterMember = setter != null
        ? SubstitutedExecutableElementImpl.from(setter, substitution)
        : null;

    return SingleExtensionResolutionResult(
      getter2: getterMember,
      setter2: setterMember,
    );
  }

  /// Perform upward inference for the override.
  void resolveOverride(
    ExtensionOverride node,
    List<WhyNotPromotedGetter> whyNotPromotedArguments,
  ) {
    var nodeImpl = node as ExtensionOverrideImpl;
    var element = node.element;
    // TODO(paulberry): make this cast unnecessary by changing the type of
    // `ExtensionOverrideImpl.element2`.
    var typeParameters = element.typeParameters
        .cast<TypeParameterElementImpl>();

    if (!_isValidContext(node)) {
      if (!_isCascadeTarget(node)) {
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.extensionOverrideWithoutAccess,
        );
      }
      nodeImpl.setPseudoExpressionStaticType(DynamicTypeImpl.instance);
    }

    var arguments = node.argumentList.arguments;
    if (arguments.length != 1) {
      _diagnosticReporter.atNode(
        node.argumentList,
        CompileTimeErrorCode.invalidExtensionArgumentCount,
      );
      nodeImpl.typeArgumentTypes = _listOfDynamic(typeParameters);
      nodeImpl.extendedType = DynamicTypeImpl.instance;
      return;
    }

    var receiverExpression = arguments[0];
    var receiverType = receiverExpression.typeOrThrow;

    if (node.isNullAware) {
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }

    var typeArgumentTypes = _inferTypeArguments(
      node,
      receiverType,
      dataForTesting: _resolver.inferenceHelper.dataForTesting,
      nodeForTesting: node,
    )!;
    nodeImpl.typeArgumentTypes = typeArgumentTypes;

    var substitution = Substitution.fromPairs2(
      typeParameters,
      typeArgumentTypes,
    );

    var extendedType = nodeImpl.extendedType = substitution.substituteType(
      element.extendedType,
    );

    _checkTypeArgumentsMatchingBounds(
      typeParameters,
      node.typeArguments,
      typeArgumentTypes,
      substitution,
    );

    if (receiverType is VoidType) {
      _diagnosticReporter.atNode(
        receiverExpression,
        CompileTimeErrorCode.useOfVoidResult,
      );
    } else if (!_typeSystem.isAssignableTo(
      receiverType,
      extendedType,
      strictCasts: _resolver.analysisOptions.strictCasts,
    )) {
      var whyNotPromoted = whyNotPromotedArguments.isEmpty
          ? null
          : whyNotPromotedArguments[0];
      _diagnosticReporter.atNode(
        receiverExpression,
        CompileTimeErrorCode.extensionOverrideArgumentNotAssignable,
        arguments: [receiverType, extendedType],
        contextMessages: _resolver.computeWhyNotPromotedMessages(
          receiverExpression,
          whyNotPromoted?.call(),
        ),
      );
    }
  }

  void _checkTypeArgumentsMatchingBounds(
    List<TypeParameterElementImpl> typeParameters,
    TypeArgumentList? typeArgumentList,
    List<TypeImpl> typeArgumentTypes,
    Substitution substitution,
  ) {
    if (typeArgumentList != null) {
      for (var i = 0; i < typeArgumentTypes.length; i++) {
        var argument = typeArgumentTypes[i];
        var parameter = typeParameters[i];
        var name = parameter.name;
        var parameterBound = parameter.bound;
        if (name != null && parameterBound != null) {
          parameterBound = substitution.substituteType(parameterBound);
          if (!_typeSystem.isSubtypeOf(argument, parameterBound)) {
            _diagnosticReporter.atNode(
              typeArgumentList.arguments[i],
              CompileTimeErrorCode.typeArgumentNotMatchingBounds,
              arguments: [argument, name, parameterBound],
            );
          }
        }
      }
    }
  }

  /// Returns a list with either the most specific extension, or, if the most
  /// specific is ambiguous, then the extensions that are ambiguous.
  List<InstantiatedExtensionWithMember> _chooseMostSpecific(
    List<InstantiatedExtensionWithMember> extensions,
  ) {
    InstantiatedExtensionWithMember? bestSoFar;
    var noneMoreSpecific = <InstantiatedExtensionWithMember>[];
    for (var candidate in extensions) {
      if (noneMoreSpecific.isNotEmpty) {
        var isMostSpecific = true;
        var hasMoreSpecific = false;
        for (var other in noneMoreSpecific) {
          if (!_isMoreSpecific(candidate, other)) {
            isMostSpecific = false;
          }
          if (_isMoreSpecific(other, candidate)) {
            hasMoreSpecific = true;
          }
        }
        if (isMostSpecific) {
          bestSoFar = candidate;
          noneMoreSpecific.clear();
        } else if (!hasMoreSpecific) {
          noneMoreSpecific.add(candidate);
        }
      } else if (bestSoFar == null) {
        bestSoFar = candidate;
      } else if (_isMoreSpecific(bestSoFar, candidate)) {
        // already
      } else if (_isMoreSpecific(candidate, bestSoFar)) {
        bestSoFar = candidate;
      } else {
        noneMoreSpecific.add(bestSoFar);
        noneMoreSpecific.add(candidate);
        bestSoFar = null;
      }
    }

    if (bestSoFar != null) {
      return [bestSoFar];
    }

    return noneMoreSpecific;
  }

  /// Given the generic [node], either returns types specified explicitly in its
  /// type arguments, or infer type arguments from the given [receiverType].
  ///
  /// If the number of explicit type arguments is different than the number
  /// of extension's type parameters, or inference fails, returns `dynamic`
  /// for all type parameters.
  List<TypeImpl>? _inferTypeArguments(
    ExtensionOverrideImpl node,
    TypeImpl receiverType, {
    required TypeConstraintGenerationDataForTesting? dataForTesting,
    required AstNodeImpl? nodeForTesting,
  }) {
    var element = node.element;
    var typeParameters = element.typeParameters;
    var typeArguments = node.typeArguments;

    if (typeArguments != null) {
      var arguments = typeArguments.arguments;
      if (arguments.length == typeParameters.length) {
        if (typeParameters.isEmpty) {
          return const <TypeImpl>[];
        }
        return arguments.map((a) => a.typeOrThrow).toList();
      } else {
        // We can safely assume `element.name` is non-`null` because type
        // arguments can only be applied to explicit extension overrides, and
        // explicit extension overrides cannot refer to unnamed extensions.
        _diagnosticReporter.atNode(
          typeArguments,
          CompileTimeErrorCode.wrongNumberOfTypeArgumentsExtension,
          arguments: [element.name!, typeParameters.length, arguments.length],
        );
        return _listOfDynamic(typeParameters);
      }
    } else {
      inferenceLogWriter?.enterGenericInference(
        typeParameters,
        element.extendedType,
      );
      var inferrer = GenericInferrer(
        _typeSystem,
        typeParameters,
        diagnosticReporter: _diagnosticReporter,
        errorEntity: node.name,
        genericMetadataIsEnabled: _genericMetadataIsEnabled,
        inferenceUsingBoundsIsEnabled: _resolver.inferenceUsingBoundsIsEnabled,
        strictInference: _resolver.analysisOptions.strictInference,
        typeSystemOperations: _resolver.flowAnalysis.typeOperations,
        dataForTesting: dataForTesting,
      );
      inferrer.constrainArgument(
        receiverType,
        element.extendedType,
        'extendedType',
        nodeForTesting: nodeForTesting,
      );
      return inferrer.chooseFinalTypes();
    }
  }

  /// Instantiate the extended type of the [extension] to the bounds of the
  /// type formals of the extension.
  TypeImpl _instantiateToBounds(ExtensionElement extension) {
    extension as ExtensionElementImpl;
    var typeParameters = extension.typeParameters;
    return Substitution.fromPairs2(
      typeParameters,
      _typeSystem.instantiateTypeFormalsToBounds(typeParameters),
    ).substituteType(extension.extendedType);
  }

  /// Return `true` is [e1] is more specific than [e2].
  bool _isMoreSpecific(
    InstantiatedExtensionWithMember e1,
    InstantiatedExtensionWithMember e2,
  ) {
    // 1. The latter extension is declared in a platform library, and the
    //    former extension is not.
    // 2. They are both declared in platform libraries, or both declared in
    //    non-platform libraries.
    var e1_isInSdk = e1.extension.library.isInSdk;
    var e2_isInSdk = e2.extension.library.isInSdk;
    if (e1_isInSdk && !e2_isInSdk) {
      return false;
    } else if (!e1_isInSdk && e2_isInSdk) {
      return true;
    }

    var extendedType1 = e1.extendedType;
    var extendedType2 = e2.extendedType;

    // 3. The instantiated type (the type after applying type inference from
    //    the receiver) of T1 is a subtype of the instantiated type of T2,
    //    and either...
    if (!_isSubtypeOf(extendedType1, extendedType2)) {
      return false;
    }

    // 4. ...not vice versa, or...
    if (!_isSubtypeOf(extendedType2, extendedType1)) {
      return true;
    }

    // 5. ...the instantiate-to-bounds type of T1 is a subtype of the
    //    instantiate-to-bounds type of T2 and not vice versa.
    // TODO(scheglov): store instantiated types
    var extendedTypeBound1 = _instantiateToBounds(e1.extension);
    var extendedTypeBound2 = _instantiateToBounds(e2.extension);
    return _isSubtypeOf(extendedTypeBound1, extendedTypeBound2) &&
        !_isSubtypeOf(extendedTypeBound2, extendedTypeBound1);
  }

  /// Ask the type system for a subtype check.
  bool _isSubtypeOf(TypeImpl type1, TypeImpl type2) =>
      _typeSystem.isSubtypeOf(type1, type2);

  List<TypeImpl> _listOfDynamic(List<Object?> parameters) {
    return List<TypeImpl>.filled(parameters.length, DynamicTypeImpl.instance);
  }

  static bool _isCascadeTarget(ExtensionOverride node) {
    var parent = node.parent;
    return parent is CascadeExpression && parent.target == node;
  }

  /// Return `true` if the extension override [node] is being used as a target
  /// of an operation that might be accessing an instance member.
  static bool _isValidContext(ExtensionOverride node) {
    var parent = node.parent;
    return parent is BinaryExpression && parent.leftOperand == node ||
        parent is FunctionExpressionInvocation && parent.function == node ||
        parent is IndexExpression && parent.target == node ||
        parent is MethodInvocation && parent.target == node ||
        parent is PrefixExpression ||
        parent is PropertyAccess && parent.target == node;
  }
}

/// The result of a failed attempt to resolve an identifier to elements, where
/// the result is expected to come from an extension.
enum ExtensionResolutionError implements ExtensionResolutionResult {
  /// Resolution failed because no elements were found.
  none,

  /// Resolution failed because multiple elements were found.
  ambiguous;

  @override
  InternalExecutableElement? get getter2 => null;

  @override
  InternalExecutableElement? get setter2 => null;
}

/// The result of attempting to resolve an identifier to elements, where the
/// result (if any) is known to come from an extension.
sealed class ExtensionResolutionResult implements SimpleResolutionResult {}

/// The result of a successful attempt to resolve an identifier to elements,
/// where the result (if any) is known to come from an extension.
class SingleExtensionResolutionResult extends SimpleResolutionResult
    implements ExtensionResolutionResult {
  SingleExtensionResolutionResult({
    required super.getter2,
    required super.setter2,
  }) : assert(getter2 != null || setter2 != null);
}
