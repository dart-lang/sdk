// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class ExtensionMemberResolver {
  final ResolverVisitor _resolver;

  ExtensionMemberResolver(this._resolver);

  DartType get _dynamicType => _typeProvider.dynamicType;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  Scope get _nameScope => _resolver.nameScope;

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  /// Return the most specific extension in the current scope for this [type],
  /// that defines the member with the given [name].
  ///
  /// If no applicable extensions, return [ResolutionResult.none].
  ///
  /// If the match is ambiguous, report an error on the [nameEntity], and
  /// return [ResolutionResult.ambiguous].
  ResolutionResult findExtension(
    DartType type,
    SyntacticEntity nameEntity,
    String name,
  ) {
    var extensions = _getApplicable(type, name);

    if (extensions.isEmpty) {
      return ResolutionResult.none;
    }

    if (extensions.length == 1) {
      return extensions[0].asResolutionResult;
    }

    var extension = _chooseMostSpecific(extensions);
    if (extension != null) {
      return extension.asResolutionResult;
    }

    _errorReporter.reportErrorForOffset(
      CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS,
      nameEntity.offset,
      nameEntity.length,
      [
        name,
        extensions[0].extension.name,
        extensions[1].extension.name,
      ],
    );
    return ResolutionResult.ambiguous;
  }

  /// Resolve the [name] (without `=`) to the corresponding getter and setter
  /// members of the extension [node].
  ///
  /// The [node] is fully resolved, and its type arguments are set.
  ResolutionResult getOverrideMember(ExtensionOverride node, String name) {
    ExtensionElement element = node.extensionName.staticElement;

    ExecutableElement getter;
    ExecutableElement setter;
    if (name == '[]') {
      getter = element.getMethod('[]');
      setter = element.getMethod('[]=');
    } else {
      getter = element.getGetter(name) ?? element.getMethod(name);
      setter = element.getSetter(name);
    }

    if (getter == null && setter == null) {
      return ResolutionResult.none;
    }

    var substitution = Substitution.fromPairs(
      element.typeParameters,
      node.typeArgumentTypes,
    );

    var getterMember = ExecutableMember.from2(getter, substitution);
    var setterMember = ExecutableMember.from2(setter, substitution);

    getterMember = _resolver.toLegacyElement(getterMember);
    setterMember = _resolver.toLegacyElement(setterMember);

    return ResolutionResult(getter: getterMember, setter: setterMember);
  }

  /// Perform upward inference for the override.
  void resolveOverride(ExtensionOverride node) {
    var nodeImpl = node as ExtensionOverrideImpl;
    var element = node.staticElement;
    var typeParameters = element.typeParameters;

    if (!_isValidContext(node)) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_WITHOUT_ACCESS,
        node,
      );
      nodeImpl.staticType = _dynamicType;
    }

    var arguments = node.argumentList.arguments;
    if (arguments.length != 1) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_EXTENSION_ARGUMENT_COUNT,
        node.argumentList,
      );
      nodeImpl.typeArgumentTypes = _listOfDynamic(typeParameters);
      nodeImpl.extendedType = _dynamicType;
      return;
    }

    var receiverExpression = arguments[0];
    var receiverType = receiverExpression.staticType;

    if (node.isNullAware) {
      receiverType = _typeSystem.promoteToNonNull(receiverType);
    }

    var typeArgumentTypes = _inferTypeArguments(node, receiverType);
    nodeImpl.typeArgumentTypes = typeArgumentTypes;

    var substitution = Substitution.fromPairs(
      typeParameters,
      typeArgumentTypes,
    );

    nodeImpl.extendedType = substitution.substituteType(element.extendedType);

    _checkTypeArgumentsMatchingBounds(
      typeParameters,
      node.typeArguments,
      typeArgumentTypes,
      substitution,
    );

    if (receiverType.isVoid) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.USE_OF_VOID_RESULT, receiverExpression);
    } else if (!_typeSystem.isAssignableTo2(receiverType, node.extendedType)) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE,
        receiverExpression,
        [receiverType, node.extendedType],
      );
    }
  }

  /// Set the type context for the receiver of the override.
  ///
  /// The context of the invocation that is made through the override does
  /// not affect the type inference of the override and the receiver.
  void setOverrideReceiverContextType(ExtensionOverride node) {
    var element = node.staticElement;
    var typeParameters = element.typeParameters;

    var arguments = node.argumentList.arguments;
    if (arguments.length != 1) {
      return;
    }

    List<DartType> typeArgumentTypes;
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      var arguments = typeArguments.arguments;
      if (arguments.length == typeParameters.length) {
        typeArgumentTypes = arguments.map((a) => a.type).toList();
      } else {
        typeArgumentTypes = _listOfDynamic(typeParameters);
      }
    } else {
      typeArgumentTypes = List.filled(
        typeParameters.length,
        UnknownInferredType.instance,
      );
    }

    var extendedForDownward = Substitution.fromPairs(
      typeParameters,
      typeArgumentTypes,
    ).substituteType(element.extendedType);

    var receiver = arguments[0];
    InferenceContext.setType(receiver, extendedForDownward);
  }

  void _checkTypeArgumentsMatchingBounds(
    List<TypeParameterElement> typeParameters,
    TypeArgumentList typeArgumentList,
    List<DartType> typeArgumentTypes,
    Substitution substitution,
  ) {
    if (typeArgumentList != null) {
      for (var i = 0; i < typeArgumentTypes.length; i++) {
        var argType = typeArgumentTypes[i];
        var boundType = typeParameters[i].bound;
        if (boundType != null) {
          boundType = substitution.substituteType(boundType);
          if (!_typeSystem.isSubtypeOf2(argType, boundType)) {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
              typeArgumentList.arguments[i],
              [argType, boundType],
            );
          }
        }
      }
    }
  }

  /// Return the most specific extension or `null` if no single one can be
  /// identified.
  _InstantiatedExtension _chooseMostSpecific(
      List<_InstantiatedExtension> extensions) {
    for (var i = 0; i < extensions.length; i++) {
      var e1 = extensions[i];
      var isMoreSpecific = true;
      for (var j = 0; j < extensions.length; j++) {
        var e2 = extensions[j];
        if (i != j && !_isMoreSpecific(e1, e2)) {
          isMoreSpecific = false;
          break;
        }
      }
      if (isMoreSpecific) {
        return e1;
      }
    }

    // Otherwise fail.
    return null;
  }

  /// Return extensions for the [type] that match the given [name] in the
  /// current scope.
  List<_InstantiatedExtension> _getApplicable(DartType type, String name) {
    if (identical(type, NeverTypeImpl.instance)) {
      return const <_InstantiatedExtension>[];
    }

    var candidates = _getExtensionsWithMember(name);

    var instantiatedExtensions = <_InstantiatedExtension>[];
    for (var candidate in candidates) {
      var extension = candidate.extension;

      var freshTypes = getFreshTypeParameters(extension.typeParameters);
      var freshTypeParameters = freshTypes.freshTypeParameters;
      var rawExtendedType = freshTypes.substitute(extension.extendedType);

      var inferrer = GenericInferrer(_typeSystem, freshTypeParameters);
      inferrer.constrainArgument(
        type,
        rawExtendedType,
        'extendedType',
      );
      var typeArguments = inferrer.infer(
        freshTypeParameters,
        failAtError: true,
      );
      if (typeArguments == null) {
        continue;
      }

      var substitution = Substitution.fromPairs(
        extension.typeParameters,
        typeArguments,
      );
      var extendedType = substitution.substituteType(
        extension.extendedType,
      );
      if (!_isSubtypeOf(type, extendedType)) {
        continue;
      }

      instantiatedExtensions.add(
        _InstantiatedExtension(candidate, substitution, extendedType),
      );
    }

    return instantiatedExtensions;
  }

  /// Return extensions from the current scope, that define a member with the
  /// given [name].
  List<_CandidateExtension> _getExtensionsWithMember(String name) {
    var candidates = <_CandidateExtension>[];

    /// Add the given [extension] to the list of [candidates] if it defined a
    /// member whose name matches the target [name].
    void checkExtension(ExtensionElement extension) {
      for (var field in extension.fields) {
        if (field.name == name) {
          candidates.add(
            _CandidateExtension(
              extension,
              getter: field.getter,
              setter: field.setter,
            ),
          );
          return;
        }
      }
      if (name == '[]') {
        ExecutableElement getter;
        ExecutableElement setter;
        for (var method in extension.methods) {
          if (method.name == '[]') {
            getter = method;
          } else if (method.name == '[]=') {
            setter = method;
          }
        }
        if (getter != null || setter != null) {
          candidates.add(
            _CandidateExtension(extension, getter: getter, setter: setter),
          );
        }
      } else {
        for (var method in extension.methods) {
          if (method.name == name) {
            candidates.add(
              _CandidateExtension(extension, getter: method),
            );
            return;
          }
        }
      }
    }

    for (var extension in _nameScope.extensions) {
      checkExtension(extension);
    }
    return candidates;
  }

  /// Given the generic [element] element, either return types specified
  /// explicitly in [typeArguments], or infer type arguments from the given
  /// [receiverType].
  ///
  /// If the number of explicit type arguments is different than the number
  /// of extension's type parameters, or inference fails, return `dynamic`
  /// for all type parameters.
  List<DartType> _inferTypeArguments(
    ExtensionOverride node,
    DartType receiverType,
  ) {
    var element = node.staticElement;
    var typeParameters = element.typeParameters;
    var typeArguments = node.typeArguments;

    if (typeArguments != null) {
      var arguments = typeArguments.arguments;
      if (arguments.length == typeParameters.length) {
        if (typeParameters.isEmpty) {
          return const <DartType>[];
        }
        return arguments.map((a) => a.type).toList();
      } else {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION,
          typeArguments,
          [element.name, typeParameters.length, arguments.length],
        );
        return _listOfDynamic(typeParameters);
      }
    } else {
      var inferrer = GenericInferrer(_typeSystem, typeParameters);
      inferrer.constrainArgument(
        receiverType,
        element.extendedType,
        'extendedType',
      );
      return inferrer.infer(
        typeParameters,
        errorReporter: _errorReporter,
        errorNode: node.extensionName,
      );
    }
  }

  /// Instantiate the extended type of the [extension] to the bounds of the
  /// type formals of the extension.
  DartType _instantiateToBounds(ExtensionElement extension) {
    var typeParameters = extension.typeParameters;
    return Substitution.fromPairs(
      typeParameters,
      _typeSystem.instantiateTypeFormalsToBounds(typeParameters),
    ).substituteType(extension.extendedType);
  }

  /// Return `true` is [e1] is more specific than [e2].
  bool _isMoreSpecific(_InstantiatedExtension e1, _InstantiatedExtension e2) {
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
    // TODO(scheglov) store instantiated types
    var extendedTypeBound1 = _instantiateToBounds(e1.extension);
    var extendedTypeBound2 = _instantiateToBounds(e2.extension);
    return _isSubtypeOf(extendedTypeBound1, extendedTypeBound2) &&
        !_isSubtypeOf(extendedTypeBound2, extendedTypeBound1);
  }

  /// Ask the type system for a subtype check.
  bool _isSubtypeOf(DartType type1, DartType type2) =>
      _typeSystem.isSubtypeOf2(type1, type2);

  List<DartType> _listOfDynamic(List<TypeParameterElement> parameters) {
    return List<DartType>.filled(parameters.length, _dynamicType);
  }

  /// Return `true` if the extension override [node] is being used as a target
  /// of an operation that might be accessing an instance member.
  static bool _isValidContext(ExtensionOverride node) {
    AstNode parent = node.parent;
    return parent is BinaryExpression && parent.leftOperand == node ||
        parent is CascadeExpression && parent.target == node ||
        parent is FunctionExpressionInvocation && parent.function == node ||
        parent is IndexExpression && parent.target == node ||
        parent is MethodInvocation && parent.target == node ||
        parent is PrefixExpression ||
        parent is PropertyAccess && parent.target == node;
  }
}

class _CandidateExtension {
  final ExtensionElement extension;
  final ExecutableElement getter;
  final ExecutableElement setter;

  _CandidateExtension(this.extension, {this.getter, this.setter})
      : assert(getter != null || setter != null);
}

class _InstantiatedExtension {
  final _CandidateExtension candidate;
  final MapSubstitution substitution;
  final DartType extendedType;

  _InstantiatedExtension(this.candidate, this.substitution, this.extendedType);

  ResolutionResult get asResolutionResult {
    return ResolutionResult(getter: getter, setter: setter);
  }

  ExtensionElement get extension => candidate.extension;

  ExecutableElement get getter {
    if (candidate.getter == null) {
      return null;
    }
    return ExecutableMember.from2(candidate.getter, substitution);
  }

  ExecutableElement get setter {
    if (candidate.setter == null) {
      return null;
    }
    return ExecutableMember.from2(candidate.setter, substitution);
  }
}
