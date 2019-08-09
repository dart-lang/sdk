// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';

class ExtensionMemberResolver {
  final ResolverVisitor _resolver;

  ExtensionMemberResolver(this._resolver);

  DartType get _dynamicType => _typeProvider.dynamicType;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  Scope get _nameScope => _resolver.nameScope;

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystem get _typeSystem => _resolver.typeSystem;

  /// Return the most specific extension in the current scope for this [type],
  /// that defines the member with the the [name] and [kind].
  ///
  /// If no applicable extensions, return `null`.
  ///
  /// If the match is ambiguous, report an error and return `null`.
  ExtensionResolutionResult findExtension(
      DartType type, String name, Expression target, ElementKind kind) {
    var extensions = _getApplicable(type, name, kind);

    if (extensions.isEmpty) {
      return ExtensionResolutionResult.none;
    }

    if (extensions.length == 1) {
      return ExtensionResolutionResult(
          ExtensionResolutionState.single, extensions[0]);
    }

    var extension = _chooseMostSpecific(extensions);
    if (extension != null) {
      return ExtensionResolutionResult(
          ExtensionResolutionState.single, extension);
    }

    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.AMBIGUOUS_EXTENSION_METHOD_ACCESS,
      target,
      [
        name,
        extensions[0].element.name,
        extensions[1].element.name,
      ],
    );
    return ExtensionResolutionResult.ambiguous;
  }

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

    var typeArgumentTypes = _inferTypeArguments(
      element,
      receiverType,
      node.typeArguments,
    );

    nodeImpl.typeArgumentTypes = typeArgumentTypes;
    nodeImpl.extendedType = Substitution.fromPairs(
      typeParameters,
      typeArgumentTypes,
    ).substituteType(element.extendedType);

    if (!_typeSystem.isAssignableTo(receiverType, node.extendedType)) {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE,
        receiverExpression,
        [receiverType, node.extendedType],
      );
    }
  }

  /// Return the most specific extension or `null` if no single one can be
  /// identified.
  InstantiatedExtension _chooseMostSpecific(
      List<InstantiatedExtension> extensions) {
    //
    // https://github.com/dart-lang/language/blob/master/accepted/future-releases/static-extension-methods/feature-specification.md#extension-conflict-resolution:
    //
    // If more than one extension applies to a specific member invocation, then
    // we resort to a heuristic to choose one of the extensions to apply. If
    // exactly one of them is "more specific" than all the others, that one is
    // chosen. Otherwise it is a compile-time error.
    //
    // An extension with on type clause T1 is more specific than another
    // extension with on type clause T2 iff
    //
    // 1. T2 is declared in a platform library, and T1 is not, or
    // 2. they are both declared in platform libraries or both declared in
    //    non-platform libraries, and
    // 3. the instantiated type (the type after applying type inference from the
    //    receiver) of T1 is a subtype of the instantiated type of T2 and either
    //    not vice versa, or
    // 4. the instantiate-to-bounds type of T1 is a subtype of the
    //    instantiate-to-bounds type of T2 and not vice versa.
    //

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
  List<InstantiatedExtension> _getApplicable(
      DartType type, String name, ElementKind kind) {
    var candidates = _getExtensionsWithMember(name, kind);

    var instantiatedExtensions = <InstantiatedExtension>[];
    for (var candidate in candidates) {
      var typeParameters = candidate.extension.typeParameters;
      var inferrer = GenericInferrer(
        _typeProvider,
        _typeSystem,
        typeParameters,
      );
      inferrer.constrainArgument(
        type,
        candidate.extension.extendedType,
        'extendedType',
      );
      var typeArguments = inferrer.infer(typeParameters, failAtError: true);
      if (typeArguments == null) {
        continue;
      }

      var substitution = Substitution.fromPairs(
        typeParameters,
        typeArguments,
      );
      var extendedType = substitution.substituteType(
        candidate.extension.extendedType,
      );
      if (!_isSubtypeOf(type, extendedType)) {
        continue;
      }

      instantiatedExtensions.add(
        InstantiatedExtension(
          candidate.extension,
          extendedType,
          // TODO(scheglov) Hm... Maybe not use from3(), but identify null subst?
          ExecutableMember.from3(
            candidate.member,
            typeParameters,
            typeArguments,
          ),
        ),
      );
    }

    return instantiatedExtensions;
  }

  /// Return extensions from the current scope, that define a member with the
  /// given[name].
  List<_CandidateExtension> _getExtensionsWithMember(
    String name,
    ElementKind kind,
  ) {
    var candidates = <_CandidateExtension>[];

    /// Return `true` if the [elementName] matches the target [name], taking
    /// into account the `=` on the end of the names of setters.
    bool matchesName(String elementName) {
      if (elementName.endsWith('=') && !name.endsWith('=')) {
        elementName = elementName.substring(0, elementName.length - 1);
      }
      return elementName == name;
    }

    /// Add the given [extension] to the list of [candidates] if it defined a
    /// member whose name matches the target [name].
    void checkExtension(ExtensionElement extension) {
      if (kind == ElementKind.GETTER) {
        for (var accessor in extension.accessors) {
          if (accessor.isGetter && matchesName(accessor.name)) {
            candidates.add(_CandidateExtension(extension, accessor));
            return;
          }
        }
      } else if (kind == ElementKind.SETTER) {
        for (var accessor in extension.accessors) {
          if (accessor.isSetter && matchesName(accessor.name)) {
            candidates.add(_CandidateExtension(extension, accessor));
            return;
          }
        }
      } else if (kind == ElementKind.METHOD) {
        for (var method in extension.methods) {
          if (matchesName(method.name)) {
            candidates.add(_CandidateExtension(extension, method));
            return;
          }
        }
        // Check for a getter that matches a function type.
        for (var accessor in extension.accessors) {
          if (accessor.type is FunctionType &&
              accessor.isGetter &&
              matchesName(accessor.name)) {
            candidates.add(_CandidateExtension(extension, accessor));
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

  /// Given the generic [extension] element, either return types specified
  /// explicitly in [typeArguments], or infer type arguments from the given
  /// [receiverType].
  ///
  /// If the number of explicit type arguments is different than the number
  /// of extension's type parameters, or inference fails, return `dynamic`
  /// for all type parameters.
  List<DartType> _inferTypeArguments(
    ExtensionElement extension,
    DartType receiverType,
    TypeArgumentList typeArguments,
  ) {
    var typeParameters = extension.typeParameters;
    if (typeParameters.isEmpty) {
      return const <DartType>[];
    }

    if (typeArguments != null) {
      var arguments = typeArguments.arguments;
      if (arguments.length == typeParameters.length) {
        return arguments.map((a) => a.type).toList();
      } else {
        // TODO(scheglov) Report an error.
        return _listOfDynamic(typeParameters);
      }
    } else {
      if (receiverType != null) {
        var inferrer = GenericInferrer(
          _typeProvider,
          _typeSystem,
          typeParameters,
        );
        inferrer.constrainArgument(
          receiverType,
          extension.extendedType,
          'extendedType',
        );
        return inferrer.infer(typeParameters);
      } else {
        return _listOfDynamic(typeParameters);
      }
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

  bool _isMoreSpecific(InstantiatedExtension e1, InstantiatedExtension e2) {
    var t10 = e1.element.extendedType;
    var t20 = e2.element.extendedType;
    var t11 = e1._extendedType;
    var t21 = e2._extendedType;

    bool inSdk(DartType type) {
      if (type.isDynamic || type.isVoid) {
        return true;
      }
      return t20.element.library.isInSdk;
    }

    if (inSdk(t20)) {
      //  1. T2 is declared in a platform library, and T1 is not
      if (!inSdk(t10)) {
        return true;
      }
    } else if (inSdk(t10)) {
      return false;
    }

    // 2. they are both declared in platform libraries or both declared in
    //    non-platform libraries, and
    if (_isSubtypeAndNotViceVersa(t11, t21)) {
      // 3. the instantiated type (the type after applying type inference from the
      //    receiver) of T1 is a subtype of the instantiated type of T2 and either
      //    not vice versa
      return true;
    }

    // TODO(scheglov) store instantiated types
    var t12 = _instantiateToBounds(e1.element);
    var t22 = _instantiateToBounds(e2.element);
    if (_isSubtypeAndNotViceVersa(t12, t22)) {
      // or:
      // 4. the instantiate-to-bounds type of T1 is a subtype of the
      //    instantiate-to-bounds type of T2 and not vice versa.
      return true;
    }

    return false;
  }

  bool _isSubtypeAndNotViceVersa(DartType t1, DartType t2) {
    return _isSubtypeOf(t1, t2) && !_isSubtypeOf(t2, t1);
  }

  /// Ask the type system for a subtype check.
  bool _isSubtypeOf(DartType type1, DartType type2) =>
      _typeSystem.isSubtypeOf(type1, type2);

  List<DartType> _listOfDynamic(List<TypeParameterElement> parameters) {
    return List<DartType>.filled(parameters.length, _dynamicType);
  }

  /// Return `true` if the extension override [node] is being used as a target
  /// of an operation that might be accessing an instance member.
  static bool _isValidContext(ExtensionOverride node) {
    AstNode parent = node.parent;
    return parent is BinaryExpression && parent.leftOperand == node ||
        parent is FunctionExpressionInvocation && parent.function == node ||
        parent is IndexExpression && parent.target == node ||
        parent is MethodInvocation && parent.target == node ||
        parent is PrefixExpression ||
        parent is PropertyAccess && parent.target == node;
  }
}

/// The result of attempting to resolve an identifier to an extension member.
class ExtensionResolutionResult {
  /// An instance that can be used anywhere that no extension member was found.
  static const ExtensionResolutionResult none =
      ExtensionResolutionResult(ExtensionResolutionState.none, null);

  /// An instance that can be used anywhere that multiple ambiguous members were
  /// found.
  static const ExtensionResolutionResult ambiguous =
      ExtensionResolutionResult(ExtensionResolutionState.ambiguous, null);

  /// The state of the result.
  final ExtensionResolutionState state;

  /// The extension that was found, or `null` if the [state] is not
  /// [ExtensionResolutionState.single].
  final InstantiatedExtension extension;

  /// Initialize a newly created result.
  const ExtensionResolutionResult(this.state, this.extension);

  /// Return `true` if this result represents the case where no extension member
  /// was found.
  bool get isNone => state == ExtensionResolutionState.none;

  /// Return `true` if this result represents the case where a single extension
  /// member was found.
  bool get isSingle => extension != null;
}

/// The state of an [ExtensionResolutionResult].
enum ExtensionResolutionState {
  /// Indicates that no extension member was found.
  none,

  /// Indicates that a single extension member was found.
  single,

  /// Indicates that multiple ambiguous members were found.
  ambiguous
}

class InstantiatedExtension {
  final ExtensionElement element;
  final DartType _extendedType;
  final ExecutableElement instantiatedMember;

  InstantiatedExtension(
    this.element,
    this._extendedType,
    this.instantiatedMember,
  );
}

class _CandidateExtension {
  final ExtensionElement extension;
  final ExecutableElement member;

  _CandidateExtension(this.extension, this.member);
}
