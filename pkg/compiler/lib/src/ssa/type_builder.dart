// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'builder.dart';
import 'nodes.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../js_model/class_type_variable_access.dart';
import '../js_model/js_world.dart' show JClosedWorld;
import '../js_model/type_recipe.dart';
import '../io/source_information.dart';
import '../options.dart';
import '../universe/use.dart' show TypeUse;

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
  AbstractValue? trustTypeMask(DartType type, {bool hasLateSentinel = false}) {
    type = builder.localsHandler.substInContext(type);
    if (_closedWorld.dartTypes.isTopType(type)) return null;
    bool includeNull =
        _closedWorld.dartTypes.useLegacySubtyping || type is NullableType;
    type = type.withoutNullability;
    if (type is! InterfaceType) return null;
    // The type element is either a class or the void element.
    ClassEntity element = type.element;
    AbstractValue mask = includeNull
        ? _abstractValueDomain.createNullableSubtype(element)
        : _abstractValueDomain.createNonNullSubtype(element);
    if (hasLateSentinel) mask = _abstractValueDomain.includeLateSentinel(mask);
    return mask;
  }

  /// Create an instruction to simply trust the provided type.
  HInstruction _trustType(HInstruction original, DartType type) {
    bool hasLateSentinel = _abstractValueDomain
        .isLateSentinel(original.instructionType)
        .isPotentiallyTrue;
    final mask = trustTypeMask(type, hasLateSentinel: hasLateSentinel);
    if (mask == null) return original;
    return HTypeKnown.pinned(mask, original);
  }

  /// Produces code that checks the runtime type is actually the type specified
  /// by attempting a type conversion.
  HInstruction _checkType(HInstruction original, DartType type) {
    type = builder.localsHandler.substInContext(type);
    HInstruction other = buildAsCheck(original, type, isTypeError: true);
    // TODO(johnniwinther): This operation on `registry` may be inconsistent.
    // If it is needed then it seems likely that similar invocations of
    // `buildAsCheck` in `SsaBuilder.visitAs` should also be followed by a
    // similar operation on `registry`; otherwise, this one might not be needed.
    builder.registry.registerTypeUse(TypeUse.isCheck(type));
    if (other is HAsCheck &&
        other.isRedundant(builder.closedWorld, builder.options)) {
      return original;
    }
    return other;
  }

  /// Produces code that checks the runtime type is actually the type specified
  /// by attempting a type conversion.
  HInstruction _checkBoolConversion(HInstruction original) {
    var checkInstruction =
        HBoolConversion(original, _abstractValueDomain.boolType);
    if (checkInstruction.isRedundant(_closedWorld)) {
      return original;
    }
    DartType boolType = _closedWorld.commonElements.boolType;
    builder.registry.registerTypeUse(TypeUse.isCheck(boolType));
    return checkInstruction;
  }

  HInstruction trustTypeOfParameter(
      MemberEntity memberContext, HInstruction original, DartType type) {
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
    HInstruction checkedOrTrusted = original;
    CheckPolicy parameterCheckPolicy = builder.closedWorld.annotationsData
        .getParameterCheckPolicy(memberContext);

    if (memberContext is FunctionEntity && memberContext.name == '==') {
      // Dart semantics for `a == b` check `a` and `b` against `null` outside
      // the method invocation. For code size reasons, dart2js implements the
      // null check on `a` by implementing `JSNull.==`, and the null check on
      // `b` by injecting the check into `==` methods, before any argument type
      // checks.
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
      checkedOrTrusted = _checkBoolConversion(original);
    }
    if (checkedOrTrusted == original) return original;
    builder.add(checkedOrTrusted);
    return checkedOrTrusted;
  }

  ClassTypeVariableAccess computeTypeVariableAccess(MemberEntity member);

  HInstruction analyzeTypeArgument(
      DartType argument, MemberEntity sourceElement,
      {SourceInformation? sourceInformation}) {
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
      {SourceInformation? sourceInformation}) {
    assert(type.containsTypeVariables);
    // Build the environment for each access, and hope GVN reduces the larger
    // number of expressions. Another option is to precompute the environment at
    // procedure entry and optimize early-exits by sinking the precomputed
    // environment.

    // Split the type variables into class-scope and function-scope(s).
    bool usesInstanceParameters = false;
    InterfaceType? interfaceType;
    Set<TypeVariableType> parameters = Set();

    void processTypeVariable(TypeVariableType type) {
      ClassTypeVariableAccess typeVariableAccess;
      if (type.element.typeDeclaration is ClassEntity) {
        typeVariableAccess = computeTypeVariableAccess(member);
        interfaceType = _closedWorld.elementEnvironment
            .getThisType(type.element.typeDeclaration as ClassEntity);
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
        case ClassTypeVariableAccess.none:
          builder.reporter.internalError(
              type.element, 'Unexpected type variable in static context.');
      }
    }

    type.forEachTypeVariable(processTypeVariable);

    HInstruction? environment;
    TypeEnvironmentStructure? structure;

    if (usesInstanceParameters) {
      HInstruction target =
          builder.localsHandler.readThis(sourceInformation: sourceInformation);
      // Add a HTypeKnown node to assert that 'this' is known to be a subtype of
      // the declared type at this point.
      //
      // The pinned asserted type prevents the HInstanceEnvironment being
      // hoisted to an illegal location. Consider:
      //
      //     class C<T> {
      //       method() => List<T>;
      //     }
      //
      //       final Object o = ...
      //       while (...) {
      //         if (o is C && something()) {
      //           o.method();
      //           // inlined, including:
      //           //     t1 = HTypeKnown(C, o);
      //           //     t2 = HInstanceEnvironment(t1)
      //         }
      //
      // The inlined `method` accesses the instance type parameter, o.(C.T). The
      // access would become illegal if hoisted out of the `if` statement. The
      // HTypeKnown is pinned in the if-then branch, preventing the hoisting.
      //
      // It is often the case that hoisting _is_ legal. When hoisting is legal,
      // the HTypeKnown is redundant (e.g. if the type of `o` is known to be `C`
      // by some means, or there is no guarding condition). The redundant pinned
      // HTypeKnown goes away (never inserted, or later optimized), no longer
      // preventing the rest of the type expression from being hoisted.

      HTypeKnown constrained =
          HTypeKnown.pinned(builder.localsHandler.getTypeOfThis(), target);
      if (!constrained.isRedundant(builder.closedWorld)) {
        builder.add(constrained);
        target = constrained;
      }

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

    return _EnvironmentExpressionAndStructure(environment!, structure!);
  }

  /// Build a [HAsCheck] for converting [original] to type [type].
  ///
  /// Invariant: [type] must be valid in the context.
  /// See [LocalsHandler.substInContext].
  HInstruction buildAsCheck(HInstruction original, DartType type,
      {required bool isTypeError, SourceInformation? sourceInformation}) {
    if (builder.options.experimentNullSafetyChecks) {
      if (_closedWorld.dartTypes.isStrongTopType(type)) return original;
    } else {
      if (_closedWorld.dartTypes.isTopType(type)) return original;
    }

    HInstruction reifiedType = analyzeTypeArgument(type, builder.sourceElement,
        sourceInformation: sourceInformation);
    AbstractValueWithPrecision checkedType =
        _abstractValueDomain.createFromStaticType(type, nullable: true);
    AbstractValue instructionType = _abstractValueDomain.intersection(
        original.instructionType, checkedType.abstractValue);
    return HAsCheck(
        checkedType, type, isTypeError, reifiedType, original, instructionType)
      ..sourceInformation = sourceInformation;
  }
}

class _EnvironmentExpressionAndStructure {
  final HInstruction expression;
  final TypeEnvironmentStructure structure;
  _EnvironmentExpressionAndStructure(this.expression, this.structure);
}
