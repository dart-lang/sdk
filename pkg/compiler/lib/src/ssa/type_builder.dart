// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'graph_builder.dart';
import 'nodes.dart';
import '../closure.dart';
import '../common.dart';
import '../dart_types.dart';
import '../types/types.dart';
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../universe/selector.dart' show Selector;
import '../universe/use.dart' show TypeUse;

/// Functions to insert type checking, coercion, and instruction insertion
/// depending on the environment for dart code.
class TypeBuilder {
  final GraphBuilder builder;
  TypeBuilder(this.builder);

  /// Create an instruction to simply trust the provided type.
  HInstruction _trustType(HInstruction original, DartType type) {
    assert(builder.compiler.options.trustTypeAnnotations);
    assert(type != null);
    type = builder.localsHandler.substInContext(type);
    type = type.unaliased;
    if (type.isDynamic) return original;
    if (!type.isInterfaceType) return original;
    if (type.isObject) return original;
    // The type element is either a class or the void element.
    Element element = type.element;
    TypeMask mask = new TypeMask.subtype(element, builder.compiler.closedWorld);
    return new HTypeKnown.pinned(mask, original);
  }

  /// Produces code that checks the runtime type is actually the type specified
  /// by attempting a type conversion.
  HInstruction _checkType(HInstruction original, DartType type, int kind) {
    assert(builder.compiler.options.enableTypeAssertions);
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

  /// Depending on the context and the mode, wrap the given type in an
  /// instruction that checks the type is what we expect or automatically
  /// trusts the written type.
  HInstruction potentiallyCheckOrTrustType(HInstruction original, DartType type,
      {int kind: HTypeConversion.CHECKED_MODE_CHECK}) {
    if (type == null) return original;
    HInstruction checkedOrTrusted = original;
    if (builder.compiler.options.trustTypeAnnotations) {
      checkedOrTrusted = _trustType(original, type);
    } else if (builder.compiler.options.enableTypeAssertions) {
      checkedOrTrusted = _checkType(original, type, kind);
    }
    if (checkedOrTrusted == original) return original;
    builder.add(checkedOrTrusted);
    return checkedOrTrusted;
  }

  /// Helper to create an instruction that gets the value of a type variable.
  HInstruction addTypeVariableReference(TypeVariableType type, Element member,
      {SourceInformation sourceInformation}) {
    assert(assertTypeInContext(type));
    if (type is MethodTypeVariableType) {
      return builder.graph.addConstantNull(builder.compiler);
    }
    bool isClosure = member.enclosingElement.isClosure;
    if (isClosure) {
      ClosureClassElement closureClass = member.enclosingElement;
      member = closureClass.methodElement;
      member = member.outermostEnclosingMemberOrTopLevel;
    }
    bool isInConstructorContext =
        member.isConstructor || member.isGenerativeConstructorBody;
    Local typeVariableLocal =
        builder.localsHandler.getTypeVariableAsLocal(type);
    if (isClosure) {
      if (member.isFactoryConstructor ||
          (isInConstructorContext &&
              builder.hasDirectLocal(typeVariableLocal))) {
        // The type variable is used from a closure in a factory constructor.
        // The value of the type argument is stored as a local on the closure
        // itself.
        return builder.localsHandler
            .readLocal(typeVariableLocal, sourceInformation: sourceInformation);
      } else if (member.isFunction ||
          member.isGetter ||
          member.isSetter ||
          isInConstructorContext) {
        // The type variable is stored on the "enclosing object" and needs to be
        // accessed using the this-reference in the closure.
        return readTypeVariable(type, member,
            sourceInformation: sourceInformation);
      } else {
        assert(member.isField);
        // The type variable is stored in a parameter of the method.
        return builder.localsHandler.readLocal(typeVariableLocal);
      }
    } else if (isInConstructorContext ||
        // When [member] is a field, we can be either
        // generating a checked setter or inlining its
        // initializer in a constructor. An initializer is
        // never built standalone, so in that case [target] is not
        // the [member] itself.
        (member.isField && member != builder.targetElement)) {
      // The type variable is stored in a parameter of the method.
      return builder.localsHandler
          .readLocal(typeVariableLocal, sourceInformation: sourceInformation);
    } else if (member.isInstanceMember) {
      // The type variable is stored on the object.
      return readTypeVariable(type, member,
          sourceInformation: sourceInformation);
    } else {
      builder.compiler.reporter.internalError(
          type.element, 'Unexpected type variable in static context.');
      return null;
    }
  }

  /// Generate code to extract the type argument from the object.
  HInstruction readTypeVariable(TypeVariableType variable, Element member,
      {SourceInformation sourceInformation}) {
    assert(member.isInstanceMember);
    assert(variable is! MethodTypeVariableType);
    HInstruction target = builder.localsHandler.readThis();
    builder.push(
        new HTypeInfoReadVariable(variable, target, builder.backend.dynamicType)
          ..sourceInformation = sourceInformation);
    return builder.pop();
  }

  HInstruction buildTypeArgumentRepresentations(
      DartType type, Element sourceElement) {
    assert(!type.isTypeVariable);
    // Compute the representation of the type arguments, including access
    // to the runtime type information for type variables as instructions.
    assert(type.element.isClass);
    InterfaceType interface = type;
    List<HInstruction> inputs = <HInstruction>[];
    for (DartType argument in interface.typeArguments) {
      inputs.add(analyzeTypeArgument(argument, sourceElement));
    }
    HInstruction representation = new HTypeInfoExpression(
        TypeInfoExpressionKind.INSTANCE,
        interface.element.thisType,
        inputs,
        builder.backend.dynamicType);
    return representation;
  }

  /// Check that [type] is valid in the context of `localsHandler.contextClass`.
  /// This should only be called in assertions.
  bool assertTypeInContext(DartType type, [Spannable spannable]) {
    return invariant(spannable == null ? CURRENT_ELEMENT_SPANNABLE : spannable,
        () {
      ClassElement contextClass = Types.getClassContext(type);
      return contextClass == null ||
          contextClass == builder.localsHandler.contextClass;
    },
        message: "Type '$type' is not valid context of "
            "${builder.localsHandler.contextClass}.");
  }

  HInstruction analyzeTypeArgument(DartType argument, Element sourceElement,
      {SourceInformation sourceInformation}) {
    assert(assertTypeInContext(argument));
    argument = argument.unaliased;
    if (argument.treatAsDynamic) {
      // Represent [dynamic] as [null].
      return builder.graph.addConstantNull(builder.compiler);
    }

    if (argument.isTypeVariable) {
      return addTypeVariableReference(argument, sourceElement,
          sourceInformation: sourceInformation);
    }

    List<HInstruction> inputs = <HInstruction>[];
    argument.forEachTypeVariable((variable) {
      if (variable is! MethodTypeVariableType) {
        inputs.add(analyzeTypeArgument(variable, sourceElement));
      }
    });
    HInstruction result = new HTypeInfoExpression(
        TypeInfoExpressionKind.COMPLETE,
        argument,
        inputs,
        builder.backend.dynamicType)..sourceInformation = sourceInformation;
    builder.add(result);
    return result;
  }

  /// In checked mode, generate type tests for the parameters of the inlined
  /// function.
  void potentiallyCheckInlinedParameterTypes(FunctionElement function) {
    if (!checkOrTrustTypes) return;

    FunctionSignature signature = function.functionSignature;
    signature.orderedForEachParameter((ParameterElement parameter) {
      HInstruction argument = builder.localsHandler.readLocal(parameter);
      potentiallyCheckOrTrustType(argument, parameter.type);
    });
  }

  bool get checkOrTrustTypes =>
      builder.compiler.options.enableTypeAssertions ||
      builder.compiler.options.trustTypeAnnotations;

  /// Build a [HTypeConversion] for converting [original] to type [type].
  ///
  /// Invariant: [type] must be valid in the context.
  /// See [LocalsHandler.substInContext].
  HInstruction buildTypeConversion(
      HInstruction original, DartType type, int kind) {
    if (type == null) return original;
    // GENERIC_METHODS: The following statement was added for parsing and
    // ignoring method type variables; must be generalized for full support of
    // generic methods.
    type = type.dynamifyMethodTypeVariableType;
    type = type.unaliased;
    assert(assertTypeInContext(type, original));
    if (type.isInterfaceType && !type.treatAsRaw) {
      TypeMask subtype =
          new TypeMask.subtype(type.element, builder.compiler.closedWorld);
      HInstruction representations =
          buildTypeArgumentRepresentations(type, builder.sourceElement);
      builder.add(representations);
      return new HTypeConversion.withTypeRepresentation(
          type, kind, subtype, original, representations);
    } else if (type.isTypeVariable) {
      TypeMask subtype = original.instructionType;
      HInstruction typeVariable =
          addTypeVariableReference(type, builder.sourceElement);
      return new HTypeConversion.withTypeRepresentation(
          type, kind, subtype, original, typeVariable);
    } else if (type.isFunctionType) {
      return builder.buildFunctionTypeConversion(original, type, kind);
    } else {
      return original.convertType(builder.compiler, type, kind);
    }
  }
}
