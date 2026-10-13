// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart' show CloneVisitorNotMembers;
import 'package:kernel/type_algebra.dart' show Substitution;
import 'package:kernel/type_environment.dart';

import '../type_inference/context_allocation_strategy.dart';
import '../builder/library_builder.dart';
import '../source/stack_listener_impl.dart' show AsyncModifier;
import 'external_ast_helper.dart' as extern;

/// Data for clone default values for synthesized function nodes once the
/// original default values have been computed.
///
/// This is used for constructors in unnamed mixin application, which are
/// created from the constructors in the superclass, and for tear off lowerings
/// for redirecting factories, which are created from the effective target
/// constructor.
class DelayedDefaultValueCloner {
  /// The original constructor or procedure.
  final Member _source;

  /// The synthesized constructor or procedure.
  final Member _target;

  final ParameterMapping _parameterMapping;

  bool isOutlineNode;

  final LibraryBuilder _libraryBuilder;

  CloneVisitorNotMembers? _cloner;

  /// Set to `true` we default values have been cloned, ensuring that cloning
  /// isn't performed twice.
  bool _hasCloned = false;

  new({
    required this._source,
    required this._target,
    required this._parameterMapping,
    this.isOutlineNode = false,
    required LibraryBuilder libraryBuilder,
  }) : _libraryBuilder = libraryBuilder;

  /// The original constructor or procedure.
  TreeNode get source => _source;

  /// The synthesized constructor or procedure.
  TreeNode get target => _target;

  void cloneDefaultValues(TypeEnvironment typeEnvironment) {
    if (_hasCloned) return;

    // TODO(ahe): It is unclear if it is legal to use type parameters in
    // default values, but Fasta is currently allowing it, and the VM
    // accepts it. If it isn't legal, the we can speed this up by using a
    // single cloner without substitution.

    // For mixin application constructors, the argument count is the same, but
    // for redirecting tear off lowerings, the argument count of the tear off
    // can be less than that of the redirection target or, in errors cases, be
    // unrelated.

    FunctionNode sourceFunctionNode = _source.function!;
    FunctionNode targetFunctionNode = _target.function!;

    NamedParameterCache namedParameterCache = new NamedParameterCache(
      sourceFunctionNode,
    );
    for (
      int targetIndex = targetFunctionNode.requiredParameterCount;
      targetIndex < targetFunctionNode.positionalParameters.length;
      targetIndex++
    ) {
      PositionalParameter targetParameter =
          targetFunctionNode.positionalParameters[targetIndex];
      PositionalParameter? sourceParameter = _parameterMapping
          .getPositionalSourceParameter(
            source: sourceFunctionNode,
            target: targetFunctionNode,
            targetIndex: targetIndex,
          );
      if (sourceParameter != null) {
        if (_parameterMapping.checkTypes) {
          _cloneDefaultValueForSuperParameters(
            sourceParameter,
            targetParameter,
            typeEnvironment,
            isOptional: true,
          );
        } else {
          _cloneDefaultValue(sourceParameter, targetParameter);
        }
      } else
      // TODO(johnniwinther): Why do we have an explicit `null` default value
      // on super parameters without a declared defaultValue?
      if (!targetParameter.hasDeclaredDefaultValue) {
        // Error case: use `null` as default value.
        targetParameter.defaultValue = extern.createNullLiteral(
          fileOffset: TreeNode.noOffset,
        )..parent = targetParameter;
        if (targetParameter.type.nullability != Nullability.nullable) {
          // Coverage-ignore-block(suite): Not run.
          targetParameter.hasErroneousDefaultValue = true;
        }
      }
    }
    for (
      int targetIndex = 0;
      targetIndex < targetFunctionNode.namedParameters.length;
      targetIndex++
    ) {
      NamedParameter targetParameter =
          targetFunctionNode.namedParameters[targetIndex];
      if (targetParameter.isRequired) continue;
      NamedParameter? sourceParameter = _parameterMapping
          .getNamedSourceParameter(
            source: sourceFunctionNode,
            target: targetFunctionNode,
            targetIndex: targetIndex,
            namedParameterCache: namedParameterCache,
          );
      if (sourceParameter != null) {
        if (_parameterMapping.checkTypes) {
          _cloneDefaultValueForSuperParameters(
            sourceParameter,
            targetParameter,
            typeEnvironment,
            isOptional: !targetParameter.isRequired,
          );
        } else {
          _cloneDefaultValue(sourceParameter, targetParameter);
        }
      } else
      // TODO(johnniwinther): Why do we have an explicit `null` default value
      // on super parameters without a declared default value?
      if (!targetParameter.hasDeclaredDefaultValue) {
        // Error case: use `null` as default value.
        targetParameter.defaultValue = extern.createNullLiteral(
          fileOffset: TreeNode.noOffset,
        )..parent = targetParameter;
        if (targetParameter.type.nullability != Nullability.nullable) {
          targetParameter.hasErroneousDefaultValue = true;
        }
      }
    }
    _hasCloned = true;
    return;
  }

  void _cloneDefaultValue(
    FunctionParameter originalParameter,
    FunctionParameter clonedParameter,
  ) {
    if (originalParameter.defaultValue != null) {
      CloneVisitorNotMembers cloner = _cloner ??= new CloneVisitorNotMembers();
      clonedParameter.defaultValue = cloner.clone(
        originalParameter.defaultValue!,
      )..parent = clonedParameter;
    }
    clonedParameter.hasErroneousDefaultValue |=
        originalParameter.hasErroneousDefaultValue;
  }

  void _cloneDefaultValueForSuperParameters(
    FunctionParameter originalParameter,
    FunctionParameter synthesizedParameter,
    TypeEnvironment typeEnvironment, {
    required bool isOptional,
  }) {
    Expression? originalParameterDefaultValue = originalParameter.defaultValue;
    DartType? originalParameterDefaultValueType = originalParameterDefaultValue
        ?.getStaticType(new StaticTypeContext(_target, typeEnvironment));
    DartType synthesizedParameterType = synthesizedParameter.type;
    if (originalParameterDefaultValueType != null &&
        typeEnvironment.isSubtypeOf(
          originalParameterDefaultValueType,
          synthesizedParameterType,
        )) {
      _cloneDefaultValue(originalParameter, synthesizedParameter);
    } else if (originalParameterDefaultValue == null && isOptional) {
      synthesizedParameter.defaultValue = extern.createNullLiteral(
        fileOffset: TreeNode.noOffset,
      )..parent = synthesizedParameter;
    } else {
      synthesizedParameter.hasDeclaredDefaultValue = false;
      if (synthesizedParameterType.isPotentiallyNonNullable) {
        _libraryBuilder.addProblem(
          diag.optionalSuperParameterWithoutInitializer.withArguments(
            superParameterType: synthesizedParameter.type,
            superParameterName: synthesizedParameter.parameterName,
          ),
          synthesizedParameter.fileOffset,
          synthesizedParameter.parameterName.length,
          _target.fileUri,
        );
        synthesizedParameter.hasErroneousDefaultValue = true;
      }
    }
  }

  @override
  String toString() {
    return "DelayedDefaultValueCloner(original=${_source}, "
        "synthesized=${_target})";
  }
}

class NamedParameterCache(final FunctionNode _function) {
  late final Map<String, NamedParameter> _map = _computeMap();

  Map<String, NamedParameter> _computeMap() {
    Map<String, NamedParameter> map = {};
    for (NamedParameter parameter in _function.namedParameters) {
      map[parameter.parameterName] ??= parameter;
    }
    return map;
  }

  NamedParameter? operator [](String name) => _map[name];
}

/// Interface used by [DelayedDefaultValueCloner] to map target parameters to
/// source parameters from which default values should be cloned.
abstract class ParameterMapping {
  /// Whether the type of the cloned default value should be checked against the
  /// target parameter type.
  ///
  /// This is needed for super parameters where the super parameter can be
  /// declared with a type that doesn't support the default value. For instance
  ///
  ///     class Super {
  ///       new({num a = 3.14});
  ///     }
  ///     class Class {
  ///       new({int super.a});
  ///     }
  ///
  /// where the default value `3.14` is not valid for a parameter of type `int`.
  bool get checkTypes;

  /// Returns the [PositionalParameter] from [source] from which the default
  /// value for the [targetIndex]th positional parameter from [target] should be
  /// cloned, if any.
  PositionalParameter? getPositionalSourceParameter({
    required FunctionNode source,
    required FunctionNode target,
    required int targetIndex,
  });

  /// Returns the [NamedParameter] from [source] from which the default value
  /// for the [targetIndex]th named parameter from [target] should be cloned, if
  /// any.
  ///
  /// [namedParameterCache] can be used to lookup named parameters in [source]
  /// by name.
  NamedParameter? getNamedSourceParameter({
    required FunctionNode source,
    required FunctionNode target,
    required int targetIndex,
    required NamedParameterCache namedParameterCache,
  });
}

class SuperParameterMapping(
  final Map<int, int> positionalTargetToSourceMapping,
  final Map<int, String> namedTargetToSourceMapping,
) implements ParameterMapping {
  @override
  bool get checkTypes => true;

  @override
  NamedParameter? getNamedSourceParameter({
    required FunctionNode source,
    required FunctionNode target,
    required int targetIndex,
    required NamedParameterCache namedParameterCache,
  }) {
    String? sourceName = namedTargetToSourceMapping[targetIndex];
    return sourceName != null ? namedParameterCache[sourceName] : null;
  }

  @override
  PositionalParameter? getPositionalSourceParameter({
    required FunctionNode source,
    required FunctionNode target,
    required int targetIndex,
  }) {
    int? sourceIndex = positionalTargetToSourceMapping[targetIndex];
    return sourceIndex != null
        ? source.positionalParameters[sourceIndex]
        : null;
  }
}

class const DirectParameterMapping() implements ParameterMapping {
  @override
  bool get checkTypes => false;

  @override
  NamedParameter? getNamedSourceParameter({
    required FunctionNode source,
    required FunctionNode target,
    required int targetIndex,
    required NamedParameterCache namedParameterCache,
  }) {
    NamedParameter? sourceParameter =
        namedParameterCache[target.namedParameters[targetIndex].parameterName];
    return sourceParameter != null && !sourceParameter.isRequired
        ? sourceParameter
        : null;
  }

  @override
  PositionalParameter? getPositionalSourceParameter({
    required FunctionNode source,
    required FunctionNode target,
    required int targetIndex,
  }) {
    return targetIndex >= source.requiredParameterCount &&
            targetIndex < source.positionalParameters.length
        ? source.positionalParameters[targetIndex]
        : null;
  }
}

class TypeDependency {
  final Member synthesized;
  final Member original;
  final Substitution substitution;
  final bool copyReturnType;
  bool _hasBeenInferred = false;

  new(
    this.synthesized,
    this.original,
    this.substitution, {
    required this.copyReturnType,
  });

  void copyInferred() {
    if (_hasBeenInferred) return;
    for (int i = 0; i < original.function!.positionalParameters.length; i++) {
      PositionalParameter synthesizedParameter =
          synthesized.function!.positionalParameters[i];
      PositionalParameter originalParameter =
          original.function!.positionalParameters[i];
      synthesizedParameter.type = substitution.substituteType(
        originalParameter.type,
      );
      if (!synthesizedParameter.hasDeclaredDefaultValue) {
        synthesizedParameter.hasDeclaredDefaultValue =
            originalParameter.hasDeclaredDefaultValue;
      }
    }
    for (int i = 0; i < original.function!.namedParameters.length; i++) {
      NamedParameter synthesizedParameter =
          synthesized.function!.namedParameters[i];
      NamedParameter originalParameter = original.function!.namedParameters[i];
      synthesizedParameter.type = substitution.substituteType(
        originalParameter.type,
      );
      if (!synthesizedParameter.hasDeclaredDefaultValue) {
        synthesizedParameter.hasDeclaredDefaultValue =
            originalParameter.hasDeclaredDefaultValue;
      }
    }
    if (copyReturnType) {
      synthesized.function!.returnType = substitution.substituteType(
        original.function!.returnType,
      );
    }
    _hasBeenInferred = true;
  }
}

// Coverage-ignore(suite): Not run.
/// Copies properties, function parameters and body from the [augmentation]
/// procedure to its [origin].
void finishProcedureAugmentation(Procedure origin, Procedure augmentation) {
  origin.fileUri = augmentation.fileUri;
  origin.fileStartOffset = augmentation.fileStartOffset;
  origin.fileOffset = augmentation.fileOffset;
  origin.fileEndOffset = augmentation.fileEndOffset;

  origin.isAbstract = augmentation.isAbstract;
  origin.isExternal = augmentation.isExternal;
  origin.function = augmentation.function;
  origin.function.parent = origin;
}

extension FunctionNodeExtension on FunctionNode {
  void registerFunctionBody(
    Statement body, {
    AsyncModifier asyncModifier = AsyncModifier.implicitSync,
    DartType? emittedValueType = null,
  }) {
    assert(
      !(asyncModifier.kind == AsyncMarker.Sync && emittedValueType != null),
      "Unexpected emitted value type for sync function.",
    );
    assert(
      !(asyncModifier.kind != AsyncMarker.Sync && emittedValueType == null),
      "Missing emitted value type for non-sync function.",
    );
    this.body = body..parent = this;
    this.asyncMarker = asyncModifier.kind;
    this.dartAsyncMarker = asyncModifier.kind;
    this.emittedValueType = emittedValueType;
  }

  void registerScopeProviderInfo(ScopeProviderInfo? scopeProviderInfo) {
    if (scopeProviderInfo != null) {
      this.thisVariable = scopeProviderInfo.thisVariable?..parent = this;
      this.scope = scopeProviderInfo.scope;
    }
  }
}
