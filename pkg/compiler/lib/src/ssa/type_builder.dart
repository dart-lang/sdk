// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'graph_builder.dart';
import 'nodes.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../io/source_information.dart';
import '../types/types.dart';
import '../universe/use.dart' show TypeUse;

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
  final GraphBuilder builder;
  TypeBuilder(this.builder);

  /// Create a type mask for 'trusting' a DartType. Returns `null` if there is
  /// no approximating type mask (i.e. the type mask would be `dynamic`).
  TypeMask trustTypeMask(DartType type) {
    if (type == null) return null;
    type = builder.localsHandler.substInContext(type);
    type = type.unaliased;
    if (type.isDynamic) return null;
    if (!type.isInterfaceType) return null;
    if (type == builder.commonElements.objectType) return null;
    // The type element is either a class or the void element.
    ClassEntity element = (type as InterfaceType).element;
    return new TypeMask.subtype(element, builder.closedWorld);
  }

  /// Create an instruction to simply trust the provided type.
  HInstruction _trustType(HInstruction original, DartType type) {
    assert(type != null);
    TypeMask mask = trustTypeMask(type);
    if (mask == null) return original;
    return new HTypeKnown.pinned(mask, original);
  }

  /// Produces code that checks the runtime type is actually the type specified
  /// by attempting a type conversion.
  HInstruction _checkType(HInstruction original, DartType type, int kind) {
    assert(type != null);
    type = builder.localsHandler.substInContext(type);
    HInstruction other = buildTypeConversion(original, type, kind);
    // TODO(johnniwinther): This operation on `registry` may be inconsistent.
    // If it is needed then it seems likely that similar invocations of
    // `buildTypeConversion` in `SsaBuilder.visitAs` should also be followed by
    // a similar operation on `registry`; otherwise, this one might not be
    // needed.
    builder.registry?.registerTypeUse(new TypeUse.isCheck(type));
    return other;
  }

  HInstruction potentiallyCheckOrTrustTypeOfParameter(
      HInstruction original, DartType type) {
    if (type == null) return original;
    HInstruction checkedOrTrusted = original;
    if (builder.options.parameterCheckPolicy.isTrusted) {
      checkedOrTrusted = _trustType(original, type);
    } else if (builder.options.parameterCheckPolicy.isEmitted) {
      checkedOrTrusted =
          _checkType(original, type, HTypeConversion.CHECKED_MODE_CHECK);
    }
    if (checkedOrTrusted == original) return original;
    builder.add(checkedOrTrusted);
    return checkedOrTrusted;
  }

  /// Depending on the context and the mode, wrap the given type in an
  /// instruction that checks the type is what we expect or automatically
  /// trusts the written type.
  HInstruction potentiallyCheckOrTrustTypeOfAssignment(
      HInstruction original, DartType type,
      {int kind: HTypeConversion.CHECKED_MODE_CHECK}) {
    if (type == null) return original;
    HInstruction checkedOrTrusted = original;
    if (builder.options.assignmentCheckPolicy.isTrusted) {
      checkedOrTrusted = _trustType(original, type);
    } else if (builder.options.assignmentCheckPolicy.isEmitted) {
      checkedOrTrusted = _checkType(original, type, kind);
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
    if (type.element.typeDeclaration is! ClassEntity &&
        !builder.options.strongMode) {
      // GENERIC_METHODS:  We currently don't reify method type variables.
      return builder.graph.addConstantNull(builder.closedWorld);
    }
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
        new HInterceptor(target, builder.abstractValueDomain.nonNullType)
          ..sourceInformation = sourceInformation;
    builder.add(interceptor);
    builder.push(new HTypeInfoReadVariable.intercepted(
        variable, interceptor, target, builder.abstractValueDomain.dynamicType)
      ..sourceInformation = sourceInformation);
    return builder.pop();
  }

  HInstruction buildTypeArgumentRepresentations(
      DartType type, MemberEntity sourceElement,
      [SourceInformation sourceInformation]) {
    assert(!type.isTypeVariable);
    // Compute the representation of the type arguments, including access
    // to the runtime type information for type variables as instructions.
    assert(type.isInterfaceType);
    InterfaceType interface = type;
    List<HInstruction> inputs = <HInstruction>[];
    for (DartType argument in interface.typeArguments) {
      inputs.add(analyzeTypeArgument(argument, sourceElement,
          sourceInformation: sourceInformation));
    }
    HInstruction representation = new HTypeInfoExpression(
        TypeInfoExpressionKind.INSTANCE,
        builder.closedWorld.elementEnvironment.getThisType(interface.element),
        inputs,
        builder.abstractValueDomain.dynamicType)
      ..sourceInformation = sourceInformation;
    return representation;
  }

  HInstruction analyzeTypeArgument(
      DartType argument, MemberEntity sourceElement,
      {SourceInformation sourceInformation}) {
    argument = argument.unaliased;
    if (argument.treatAsDynamic) {
      // Represent [dynamic] as [null].
      return builder.graph.addConstantNull(builder.closedWorld);
    }

    if (argument.isTypeVariable) {
      return addTypeVariableReference(argument, sourceElement,
          sourceInformation: sourceInformation);
    }

    List<HInstruction> inputs = <HInstruction>[];
    argument.forEachTypeVariable((TypeVariableType variable) {
      if (variable.element.typeDeclaration is ClassEntity ||
          builder.options.strongMode) {
        // TODO(johnniwinther): Also make this conditional on whether we have
        // calculated we need that particular method signature.
        inputs.add(analyzeTypeArgument(variable, sourceElement));
      }
    });
    HInstruction result = new HTypeInfoExpression(
        TypeInfoExpressionKind.COMPLETE,
        argument,
        inputs,
        builder.abstractValueDomain.dynamicType)
      ..sourceInformation = sourceInformation;
    builder.add(result);
    return result;
  }

  bool get checkOrTrustTypes =>
      builder.options.strongMode ||
      builder.options.enableTypeAssertions ||
      builder.options.trustTypeAnnotations;

  /// Build a [HTypeConversion] for converting [original] to type [type].
  ///
  /// Invariant: [type] must be valid in the context.
  /// See [LocalsHandler.substInContext].
  HInstruction buildTypeConversion(
      HInstruction original, DartType type, int kind,
      {SourceInformation sourceInformation}) {
    if (type == null) return original;
    if (type.isTypeVariable) {
      TypeVariableType typeVariable = type;
      // GENERIC_METHODS: The following statement was added for parsing and
      // ignoring method type variables; must be generalized for full support of
      // generic methods.
      if (typeVariable.element.typeDeclaration is! ClassEntity) {
        type = const DynamicType();
      }
    }
    type = type.unaliased;
    if (type.isInterfaceType && !type.treatAsRaw) {
      InterfaceType interfaceType = type;
      TypeMask subtype =
          new TypeMask.subtype(interfaceType.element, builder.closedWorld);
      HInstruction representations = buildTypeArgumentRepresentations(
          type, builder.sourceElement, sourceInformation);
      builder.add(representations);
      return new HTypeConversion.withTypeRepresentation(
          type, kind, subtype, original, representations)
        ..sourceInformation = sourceInformation;
    } else if (type.isTypeVariable) {
      TypeMask subtype = original.instructionType;
      HInstruction typeVariable =
          addTypeVariableReference(type, builder.sourceElement);
      return new HTypeConversion.withTypeRepresentation(
          type, kind, subtype, original, typeVariable)
        ..sourceInformation = sourceInformation;
    } else if (type.isFunctionType || type.isFutureOr) {
      HInstruction reifiedType =
          analyzeTypeArgument(type, builder.sourceElement);
      // TypeMasks don't encode function types or FutureOr types.
      TypeMask refinedMask = original.instructionType;
      return new HTypeConversion.withTypeRepresentation(
          type, kind, refinedMask, original, reifiedType)
        ..sourceInformation = sourceInformation;
    } else {
      return original.convertType(builder.closedWorld, type, kind)
        ..sourceInformation = sourceInformation;
    }
  }
}
