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
    HInstruction other =
        buildTypeConversion(original, type, HTypeConversion.TYPE_CHECK);
    // TODO(johnniwinther): This operation on `registry` may be inconsistent.
    // If it is needed then it seems likely that similar invocations of
    // `buildTypeConversion` in `SsaBuilder.visitAs` should also be followed by
    // a similar operation on `registry`; otherwise, this one might not be
    // needed.
    builder.registry?.registerTypeUse(new TypeUse.isCheck(type));
    if (other is HTypeConversion && other.isRedundant(builder.closedWorld)) {
      return original;
    }
    if (other is HAsCheck && other.isRedundant(builder.closedWorld)) {
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
    if (builder.options.useNullSafety && memberContext.name == '==') {
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

    /// Dart semantics check against null outside the method definition,
    /// however dart2js moves the null check to the callee for performance
    /// reasons. As a result the body cannot trust or check that the type is not
    /// nullable.
    if (builder.options.useNullSafety && memberContext.name == '==') {
      type = _closedWorld.dartTypes.nullableType(type);
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

  /// Helper to create an instruction that gets the value of a type variable.
  HInstruction addTypeVariableReference(
      TypeVariableType type, MemberEntity member,
      {SourceInformation sourceInformation}) {
    Local typeVariableLocal =
        builder.localsHandler.getTypeVariableAsLocal(type);

    /// Read [typeVariable] as a property of on `this`.
    HInstruction readAsProperty() {
      return readTypeVariable(type, member,
          sourceInformation: sourceInformation);
    }

    /// Read [typeVariable] as a parameter.
    HInstruction readAsParameter() {
      return builder.localsHandler
          .readLocal(typeVariableLocal, sourceInformation: sourceInformation);
    }

    ClassTypeVariableAccess typeVariableAccess;
    if (type.element.typeDeclaration is ClassEntity) {
      typeVariableAccess = computeTypeVariableAccess(member);
    } else {
      typeVariableAccess = ClassTypeVariableAccess.parameter;
    }
    switch (typeVariableAccess) {
      case ClassTypeVariableAccess.parameter:
        return readAsParameter();
      case ClassTypeVariableAccess.instanceField:
        if (member != builder.targetElement) {
          // When [member] is a field, we can either be generating a checked
          // setter or inlining its initializer in a constructor. An initializer
          // is never built standalone, so in that case [target] is not the
          // [member] itself.
          return readAsParameter();
        }
        return readAsProperty();
      case ClassTypeVariableAccess.property:
        return readAsProperty();
      case ClassTypeVariableAccess.none:
        builder.reporter.internalError(
            type.element, 'Unexpected type variable in static context.');
    }
    builder.reporter.internalError(
        type.element, 'Unexpected type variable access: $typeVariableAccess.');
    return null;
  }

  /// Generate code to extract the type argument from the object.
  HInstruction readTypeVariable(TypeVariableType variable, MemberEntity member,
      {SourceInformation sourceInformation}) {
    assert(member.isInstanceMember);
    assert(variable.element.typeDeclaration is ClassEntity);
    HInstruction target =
        builder.localsHandler.readThis(sourceInformation: sourceInformation);
    HInstruction interceptor =
        new HInterceptor(target, _abstractValueDomain.nonNullType)
          ..sourceInformation = sourceInformation;
    builder.add(interceptor);
    builder.push(new HTypeInfoReadVariable.intercepted(
        variable, interceptor, target, _abstractValueDomain.dynamicType)
      ..sourceInformation = sourceInformation);
    return builder.pop();
  }

  HInstruction buildTypeArgumentRepresentations(
      DartType type, MemberEntity sourceElement,
      [SourceInformation sourceInformation]) {
    assert(type is! TypeVariableType);
    // Compute the representation of the type arguments, including access
    // to the runtime type information for type variables as instructions.
    assert(type is InterfaceType);
    InterfaceType interface = type;
    List<HInstruction> inputs = <HInstruction>[];
    for (DartType argument in interface.typeArguments) {
      inputs.add(analyzeTypeArgument(argument, sourceElement,
          sourceInformation: sourceInformation));
    }
    HInstruction representation = new HTypeInfoExpression(
        TypeInfoExpressionKind.INSTANCE,
        _closedWorld.elementEnvironment.getThisType(interface.element),
        inputs,
        _abstractValueDomain.dynamicType)
      ..sourceInformation = sourceInformation;
    return representation;
  }

  HInstruction analyzeTypeArgument(
      DartType argument, MemberEntity sourceElement,
      {SourceInformation sourceInformation}) {
    if (builder.options.useNewRti) {
      return analyzeTypeArgumentNewRti(argument, sourceElement,
          sourceInformation: sourceInformation);
    }
    if (argument is DynamicType) {
      // Represent [dynamic] as [null].
      return builder.graph.addConstantNull(_closedWorld);
    }

    if (argument is TypeVariableType) {
      return addTypeVariableReference(argument, sourceElement,
          sourceInformation: sourceInformation);
    }

    List<HInstruction> inputs = <HInstruction>[];
    argument.forEachTypeVariable((TypeVariableType variable) {
      // TODO(johnniwinther): Also make this conditional on whether we have
      // calculated we need that particular method signature.
      inputs.add(analyzeTypeArgument(variable, sourceElement));
    });
    HInstruction result = new HTypeInfoExpression(
        TypeInfoExpressionKind.COMPLETE,
        argument,
        inputs,
        _abstractValueDomain.dynamicType)
      ..sourceInformation = sourceInformation;
    builder.add(result);
    return result;
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

  /// Build a [HTypeConversion] for converting [original] to type [type].
  ///
  /// Invariant: [type] must be valid in the context.
  /// See [LocalsHandler.substInContext].
  HInstruction buildTypeConversion(
      HInstruction original, DartType type, int kind,
      {SourceInformation sourceInformation}) {
    if (builder.options.useNewRti) {
      return buildAsCheck(original, type,
          isTypeError: kind == HTypeConversion.TYPE_CHECK,
          sourceInformation: sourceInformation);
    }

    if (type == null) return original;
    if (type is InterfaceType && !_closedWorld.dartTypes.treatAsRawType(type)) {
      InterfaceType interfaceType = type;
      AbstractValue subtype =
          _abstractValueDomain.createNullableSubtype(interfaceType.element);
      HInstruction representations = buildTypeArgumentRepresentations(
          type, builder.sourceElement, sourceInformation);
      builder.add(representations);
      return new HTypeConversion.withTypeRepresentation(
          type, kind, subtype, original, representations)
        ..sourceInformation = sourceInformation;
    } else if (type is TypeVariableType) {
      AbstractValue subtype = original.instructionType;
      HInstruction typeVariable =
          addTypeVariableReference(type, builder.sourceElement);
      return new HTypeConversion.withTypeRepresentation(
          type, kind, subtype, original, typeVariable)
        ..sourceInformation = sourceInformation;
    } else if (type is FunctionType || type is FutureOrType) {
      HInstruction reifiedType =
          analyzeTypeArgument(type, builder.sourceElement);
      // TypeMasks don't encode function types or FutureOr types.
      AbstractValue refinedMask = original.instructionType;
      return new HTypeConversion.withTypeRepresentation(
          type, kind, refinedMask, original, reifiedType)
        ..sourceInformation = sourceInformation;
    } else {
      return original.convertType(_closedWorld, type, kind)
        ..sourceInformation = sourceInformation;
    }
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
