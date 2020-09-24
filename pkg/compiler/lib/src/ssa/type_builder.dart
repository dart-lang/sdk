// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'builder_kernel.dart';
import 'nodes.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../js_model/type_recipe.dart';
import '../io/source_information.dart';
import '../options.dart';
import '../universe/use.dart' show TypeUse;
import '../world.dart';

/// Enum that defines how a member has access to the current type variables.
enum ClassTypeVariableAccess {
  /// The member has no access to type variables.
  none,

  /// Type variables are accessible as a property on `this`.
  property,

  /// Type variables are accessible as parameters in the current context.
  parameter,

  /// If the current context is a generative constructor, type variables are
  /// accessible as parameters, otherwise type variables are accessible as
  /// a property on `this`.
  ///
  /// This is used for instance fields whose initializers are executed in the
  /// constructors.
  // TODO(johnniwinther): Avoid the need for this by adding a field-setter
  // to the J-model.
  instanceField,
}

/// Functions to insert type checking, coercion, and instruction insertion
/// depending on the environment for dart code.
abstract class TypeBuilder {
  final KernelSsaGraphBuilder builder;

  TypeBuilder(this.builder);

  JClosedWorld get _closedWorld => builder.closedWorld;

  AbstractValueDomain get _abstractValueDomain =>
      _closedWorld.abstractValueDomain;

  /// Create a type mask for 'trusting' a DartType. Returns `null` if there is
  /// no approximating type mask (i.e. the type mask would be `dynamic`).
  AbstractValue trustTypeMask(DartType type) {
    if (type == null) return null;
    type = builder.localsHandler.substInContext(type);
    if (_closedWorld.dartTypes.isTopType(type)) return null;
    bool includeNull =
        _closedWorld.dartTypes.useLegacySubtyping || type is NullableType;
    type = type.withoutNullability;
    if (type is! InterfaceType) return null;
    // The type element is either a class or the void element.
    ClassEntity element = (type as InterfaceType).element;
    return includeNull
        ? _abstractValueDomain.createNullableSubtype(element)
        : _abstractValueDomain.createNonNullSubtype(element);
  }

  /// Create an instruction to simply trust the provided type.
  HInstruction _trustType(HInstruction original, DartType type) {
    assert(type != null);
    AbstractValue mask = trustTypeMask(type);
    if (mask == null) return original;
    return new HTypeKnown.pinned(mask, original);
  }

  /// Produces code that checks the runtime type is actually the type specified
  /// by attempting a type conversion.
  HInstruction _checkType(HInstruction original, DartType type) {
    assert(type != null);
    type = builder.localsHandler.substInContext(type);
    HInstruction other = buildAsCheck(original, type, isTypeError: true);
    // TODO(johnniwinther): This operation on `registry` may be inconsistent.
    // If it is needed then it seems likely that similar invocations of
    // `buildAsCheck` in `SsaBuilder.visitAs` should also be followed by a
    // similar operation on `registry`; otherwise, this one might not be needed.
    builder.registry?.registerTypeUse(new TypeUse.isCheck(type));
    if (other is HAsCheck &&
        other.isRedundant(builder.closedWorld, builder.options)) {
      return original;
    }
    return other;
  }

  /// Produces code that checks the runtime type is actually the type specified
  /// by attempting a type conversion.
  HInstruction _checkBoolConverion(HInstruction original) {
    var checkInstruction =
        HBoolConversion(original, _abstractValueDomain.boolType);
    if (checkInstruction.isRedundant(_closedWorld)) {
      return original;
    }
    DartType boolType = _closedWorld.commonElements.boolType;
    builder.registry?.registerTypeUse(new TypeUse.isCheck(boolType));
    return checkInstruction;
  }

  HInstruction trustTypeOfParameter(
      MemberEntity memberContext, HInstruction original, DartType type) {
    if (type == null) return original;

    /// Dart semantics check against null outside the method definition,
    /// however dart2js moves the null check to the callee for performance
    /// reasons. As a result the body cannot trust or check that the type is not
    /// nullable.
    if (memberContext.name == '==') {
      type = _closedWorld.dartTypes.nullableType(type);
    }
    HInstruction trusted = _trustType(original, type);
    if (trusted == original) return original;
    if (trusted is HTypeKnown && trusted.isRedundant(builder.closedWorld)) {
      return original;
    }
    builder.add(trusted);
    return trusted;
  }

  HInstruction potentiallyCheckOrTrustTypeOfParameter(
      MemberEntity memberContext, HInstruction original, DartType type) {
    if (type == null) return original;
    HInstruction checkedOrTrusted = original;
    CheckPolicy parameterCheckPolicy = builder.closedWorld.annotationsData
        .getParameterCheckPolicy(memberContext);

    if (memberContext.name == '==') {
      // Dart semantics for `a == b` check `a` and `b` against `null` outside
      // the method invocation. For code size reasons, dart2js implements the
      // null check on `a` by implementing `JSNull.==`, and the null check on
      // `b` by injecting the check into `==` methods, before any type checks.
      //
      // There are a small number of runtime library methods that do not have
      // the check injected. For these we need to widen the argument type to
      // avoid generating code that rejects `null`. In practice these are always
      // widened to TOP.
      if (_closedWorld.commonElements
          .operatorEqHandlesNullArgument(memberContext)) {
        type = _closedWorld.dartTypes.nullableType(type);
      }
    }
    if (parameterCheckPolicy.isTrusted) {
      checkedOrTrusted = _trustType(original, type);
    } else if (parameterCheckPolicy.isEmitted) {
      checkedOrTrusted = _checkType(original, type);
    }
    if (checkedOrTrusted == original) return original;
    builder.add(checkedOrTrusted);
    return checkedOrTrusted;
  }

  /// Depending on the context and the mode, wrap the given type in an
  /// instruction that checks the type is what we expect or automatically
  /// trusts the written type.
  HInstruction potentiallyCheckOrTrustTypeOfAssignment(
      MemberEntity memberContext, HInstruction original, DartType type) {
    if (type == null) return original;
    HInstruction checkedOrTrusted = _trustType(original, type);
    if (checkedOrTrusted == original) return original;
    builder.add(checkedOrTrusted);
    return checkedOrTrusted;
  }

  HInstruction potentiallyCheckOrTrustTypeOfCondition(
      MemberEntity memberContext, HInstruction original) {
    DartType boolType = _closedWorld.commonElements.boolType;
    HInstruction checkedOrTrusted = original;
    CheckPolicy conditionCheckPolicy = builder.closedWorld.annotationsData
        .getConditionCheckPolicy(memberContext);
    if (conditionCheckPolicy.isTrusted) {
      checkedOrTrusted = _trustType(original, boolType);
    } else if (conditionCheckPolicy.isEmitted) {
      checkedOrTrusted = _checkBoolConverion(original);
    }
    if (checkedOrTrusted == original) return original;
    builder.add(checkedOrTrusted);
    return checkedOrTrusted;
  }

  ClassTypeVariableAccess computeTypeVariableAccess(MemberEntity member);

  HInstruction analyzeTypeArgument(
      DartType argument, MemberEntity sourceElement,
      {SourceInformation sourceInformation}) {
    return analyzeTypeArgumentNewRti(argument, sourceElement,
        sourceInformation: sourceInformation);
  }

  HInstruction analyzeTypeArgumentNewRti(
      DartType argument, MemberEntity sourceElement,
      {SourceInformation sourceInformation}) {
    if (!argument.containsTypeVariables) {
      HInstruction rti =
          HLoadType.type(argument, _abstractValueDomain.dynamicType)
            ..sourceInformation = sourceInformation;
      builder.add(rti);
      return rti;
    }
    // TODO(sra): Locate type environment.
    _EnvironmentExpressionAndStructure environmentAccess =
        _buildEnvironmentForType(argument, sourceElement,
            sourceInformation: sourceInformation);

    HInstruction rti = HTypeEval(
        environmentAccess.expression,
        environmentAccess.structure,
        TypeExpressionRecipe(argument),
        _abstractValueDomain.dynamicType)
      ..sourceInformation = sourceInformation;
    builder.add(rti);
    return rti;
  }

  _EnvironmentExpressionAndStructure _buildEnvironmentForType(
      DartType type, MemberEntity member,
      {SourceInformation sourceInformation}) {
    assert(type.containsTypeVariables);
    // Build the environment for each access, and hope GVN reduces the larger
    // number of expressions. Another option is to precompute the environment at
    // procedure entry and optimize early-exits by sinking the precomputed
    // environment.

    // Split the type variables into class-scope and function-scope(s).
    bool usesInstanceParameters = false;
    InterfaceType interfaceType;
    Set<TypeVariableType> parameters = Set();

    void processTypeVariable(TypeVariableType type) {
      ClassTypeVariableAccess typeVariableAccess;
      if (type.element.typeDeclaration is ClassEntity) {
        typeVariableAccess = computeTypeVariableAccess(member);
        interfaceType = _closedWorld.elementEnvironment
            .getThisType(type.element.typeDeclaration);
      } else {
        typeVariableAccess = ClassTypeVariableAccess.parameter;
      }
      switch (typeVariableAccess) {
        case ClassTypeVariableAccess.parameter:
          parameters.add(type);
          return;
        case ClassTypeVariableAccess.instanceField:
          if (member != builder.targetElement) {
            // When [member] is a field, we can either be generating a checked
            // setter or inlining its initializer in a constructor. An
            // initializer is never built standalone, so in that case [target]
            // is not the [member] itself.
            parameters.add(type);
            return;
          }
          usesInstanceParameters = true;
          return;
        case ClassTypeVariableAccess.property:
          usesInstanceParameters = true;
          return;
        default:
          builder.reporter.internalError(
              type.element, 'Unexpected type variable in static context.');
      }
    }

    type.forEachTypeVariable(processTypeVariable);

    HInstruction environment;
    TypeEnvironmentStructure structure;

    if (usesInstanceParameters) {
      HInstruction target =
          builder.localsHandler.readThis(sourceInformation: sourceInformation);
      // TODO(sra): HInstanceEnvironment should probably take an interceptor to
      // allow the getInterceptor call to be reused.
      environment =
          HInstanceEnvironment(target, _abstractValueDomain.dynamicType)
            ..sourceInformation = sourceInformation;
      builder.add(environment);
      structure = FullTypeEnvironmentStructure(classType: interfaceType);
    }

    // TODO(sra): Visit parameters in source-order.
    for (TypeVariableType parameter in parameters) {
      Local typeVariableLocal =
          builder.localsHandler.getTypeVariableAsLocal(parameter);
      HInstruction access = builder.localsHandler
          .readLocal(typeVariableLocal, sourceInformation: sourceInformation);

      if (environment == null) {
        environment = access;
        structure = SingletonTypeEnvironmentStructure(parameter);
      } else if (structure is SingletonTypeEnvironmentStructure) {
        SingletonTypeEnvironmentStructure singletonStructure = structure;
        // Convert a singleton environment into a singleton tuple and extend it
        // via 'bind'. i.e. generate `env1._eval("@<0>")._bind(env2)` TODO(sra):
        // Have a bind1 instruction.
        // TODO(sra): Add a 'Rti._bind1' method to shorten and accelerate this
        // common case.
        HInstruction singletonTuple = HTypeEval(
            environment,
            structure,
            FullTypeEnvironmentRecipe(types: [singletonStructure.variable]),
            _abstractValueDomain.dynamicType)
          ..sourceInformation = sourceInformation;
        builder.add(singletonTuple);
        environment =
            HTypeBind(singletonTuple, access, _abstractValueDomain.dynamicType);
        builder.add(environment);
        structure = FullTypeEnvironmentStructure(
            bindings: [singletonStructure.variable, parameter]);
      } else if (structure is FullTypeEnvironmentStructure) {
        FullTypeEnvironmentStructure fullStructure = structure;
        environment =
            HTypeBind(environment, access, _abstractValueDomain.dynamicType);
        builder.add(environment);
        structure = FullTypeEnvironmentStructure(
            classType: fullStructure.classType,
            bindings: [...fullStructure.bindings, parameter]);
      } else {
        builder.reporter.internalError(parameter.element, 'Unexpected');
      }
    }

    return _EnvironmentExpressionAndStructure(environment, structure);
  }

  /// Build a [HAsCheck] for converting [original] to type [type].
  ///
  /// Invariant: [type] must be valid in the context.
  /// See [LocalsHandler.substInContext].
  HInstruction buildAsCheck(HInstruction original, DartType type,
      {bool isTypeError, SourceInformation sourceInformation}) {
    if (type == null) return original;
    if (_closedWorld.dartTypes.isTopType(type)) return original;

    HInstruction reifiedType = analyzeTypeArgumentNewRti(
        type, builder.sourceElement,
        sourceInformation: sourceInformation);
    AbstractValueWithPrecision checkedType =
        _abstractValueDomain.createFromStaticType(type, nullable: true);
    AbstractValue instructionType = _abstractValueDomain.intersection(
        original.instructionType, checkedType.abstractValue);
    return HAsCheck(
        original, reifiedType, checkedType, type, isTypeError, instructionType)
      ..sourceInformation = sourceInformation;
  }
}

class _EnvironmentExpressionAndStructure {
  final HInstruction expression;
  final TypeEnvironmentStructure structure;
  _EnvironmentExpressionAndStructure(this.expression, this.structure);
}
