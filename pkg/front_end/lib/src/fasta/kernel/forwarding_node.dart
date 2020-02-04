// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:kernel/ast.dart"
    show
        Arguments,
        Class,
        DartType,
        Expression,
        Field,
        FunctionNode,
        Member,
        Name,
        NamedExpression,
        Procedure,
        ProcedureKind,
        ReturnStatement,
        SuperMethodInvocation,
        SuperPropertyGet,
        SuperPropertySet,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration,
        VariableGet,
        Variance,
        VoidType;

import 'package:kernel/transformations/flags.dart' show TransformerFlag;

import "package:kernel/type_algebra.dart" show Substitution;

import "package:kernel/src/legacy_erasure.dart";
import "package:kernel/src/nnbd_top_merge.dart";

import "../source/source_class_builder.dart";

import "../problems.dart" show unhandled;

import "../type_inference/type_inference_engine.dart"
    show IncludesTypeParametersNonCovariantly;

import "../type_inference/type_inferrer.dart" show getNamedFormal;

import 'class_hierarchy_builder.dart';

class ForwardingNode {
  final ClassHierarchyBuilder hierarchy;

  final SourceClassBuilder classBuilder;

  final ClassMember combinedMemberSignatureResult;

  final ProcedureKind kind;

  /// A list containing the directly implemented and directly inherited
  /// procedures of the class in question.
  final List<ClassMember> _candidates;

  ForwardingNode(this.hierarchy, this.classBuilder,
      this.combinedMemberSignatureResult, this._candidates, this.kind);

  Name get name => combinedMemberSignatureResult.member.name;

  Class get enclosingClass => classBuilder.cls;

  /// Finishes handling of this node by propagating covariance and creating
  /// forwarding stubs if necessary.
  Member finalize() => _computeCovarianceFixes();

  /// Tag the parameters of [interfaceMember] that need type checks
  ///
  /// Parameters can need type checks for calls coming from statically typed
  /// call sites, due to covariant generics and overrides with explicit
  /// `covariant` parameters.
  ///
  /// Tag parameters of [interfaceMember] that need such checks when the member
  /// occurs in [enclosingClass]'s interface.  If parameters need checks but
  /// they would not be checked in an inherited implementation, a forwarding
  /// stub is introduced as a place to put the checks.
  Member _computeCovarianceFixes() {
    Member interfaceMember = combinedMemberSignatureResult.member;

    List<TypeParameter> interfaceMemberTypeParameters =
        interfaceMember.function?.typeParameters ?? [];

    List<TypeParameter> stubTypeParameters;
    if (interfaceMember.enclosingClass != enclosingClass &&
        interfaceMemberTypeParameters.isNotEmpty) {
      // Create type parameters for the stub up front. These are needed to
      // ensure the [substitutions] are alpha renamed to the same type
      // parameters.
      stubTypeParameters = new List<TypeParameter>.filled(
          interfaceMemberTypeParameters.length, null);
      for (int i = 0; i < interfaceMemberTypeParameters.length; i++) {
        TypeParameter targetTypeParameter = interfaceMemberTypeParameters[i];
        TypeParameter typeParameter = new TypeParameter(
            targetTypeParameter.name, null)
          ..isGenericCovariantImpl = targetTypeParameter.isGenericCovariantImpl;
        stubTypeParameters[i] = typeParameter;
      }
    }

    List<Substitution> substitutions =
        new List<Substitution>(_candidates.length);
    Substitution substitution;
    for (int j = 0; j < _candidates.length; j++) {
      Member otherMember = getCandidateAt(j);
      substitutions[j] =
          _substitutionFor(stubTypeParameters, otherMember, enclosingClass);
      if (otherMember == interfaceMember) {
        substitution = substitutions[j];
      }
    }
    // We always create a forwarding stub when we've inherited a member from an
    // interface other than the first override candidate.  This is to work
    // around a bug in the Kernel type checker where it chooses the first
    // override candidate.
    //
    // TODO(kmillikin): Fix the Kernel type checker and stop creating these
    // extra stubs.
    Member stub = interfaceMember.enclosingClass == enclosingClass ||
            interfaceMember == getCandidateAt(0)
        ? interfaceMember
        : _createForwardingStub(
            stubTypeParameters, substitution, interfaceMember);

    FunctionNode interfaceFunction = interfaceMember.function;
    List<VariableDeclaration> interfacePositionalParameters =
        getPositionalParameters(interfaceMember);
    List<VariableDeclaration> interfaceNamedParameters =
        interfaceFunction?.namedParameters ?? [];
    List<TypeParameter> interfaceTypeParameters =
        interfaceFunction?.typeParameters ?? [];

    void createStubIfNeeded({bool forMemberSignature: false}) {
      if (stub != interfaceMember) {
        Procedure procedure = stub;
        if (forMemberSignature) {
          procedure.isMemberSignature = true;
        } else {
          procedure.isForwardingStub = true;
        }
        return;
      }
      if (interfaceMember.enclosingClass == enclosingClass) return;
      stub = _createForwardingStub(
          stubTypeParameters, substitution, interfaceMember,
          forMemberSignature: forMemberSignature);
    }

    bool isImplCreated = false;
    void createImplIfNeeded() {
      if (isImplCreated) return;
      createStubIfNeeded();
      _createForwardingImplIfNeeded(stub.function);
      isImplCreated = true;
    }

    IncludesTypeParametersNonCovariantly needsCheckVisitor =
        enclosingClass.typeParameters.isEmpty
            ? null
            // TODO(ahe): It may be necessary to cache this object.
            : new IncludesTypeParametersNonCovariantly(
                enclosingClass.typeParameters,
                // We are checking the parameter types and these are in a
                // contravariant position.
                initialVariance: Variance.contravariant);
    bool needsCheck(DartType type) => needsCheckVisitor == null
        ? false
        : substitution.substituteType(type).accept(needsCheckVisitor);
    bool isNonNullableByDefault = classBuilder.library.isNonNullableByDefault;

    DartType initialType(DartType a) {
      if (!isNonNullableByDefault) {
        a = legacyErasure(hierarchy.coreTypes, a);
      }
      return a;
    }

    DartType mergeTypes(DartType a, DartType b) {
      if (a == null) return null;
      if (!isNonNullableByDefault) {
        b = legacyErasure(hierarchy.coreTypes, b);
      }
      return nnbdTopMerge(hierarchy.coreTypes, a, b);
    }

    for (int i = 0; i < interfacePositionalParameters.length; i++) {
      VariableDeclaration parameter = interfacePositionalParameters[i];
      DartType parameterType = substitution.substituteType(parameter.type);
      DartType type = initialType(parameterType);
      bool isGenericCovariantImpl =
          parameter.isGenericCovariantImpl || needsCheck(parameter.type);
      bool isCovariant = parameter.isCovariant;
      VariableDeclaration superParameter = parameter;
      for (int j = 0; j < _candidates.length; j++) {
        Member otherMember = getCandidateAt(j);
        List<VariableDeclaration> otherPositionalParameters =
            getPositionalParameters(otherMember);
        if (otherPositionalParameters.length <= i) continue;
        VariableDeclaration otherParameter = otherPositionalParameters[i];
        if (j == 0) superParameter = otherParameter;
        if (identical(otherMember, interfaceMember)) continue;
        if (otherParameter.isGenericCovariantImpl) {
          isGenericCovariantImpl = true;
        }
        if (otherParameter.isCovariant) {
          isCovariant = true;
        }
        type = mergeTypes(
            type, substitutions[j].substituteType(otherParameter.type));
      }
      if (isGenericCovariantImpl) {
        if (!superParameter.isGenericCovariantImpl) {
          createImplIfNeeded();
        }
        if (!parameter.isGenericCovariantImpl) {
          createStubIfNeeded();
          stub.function.positionalParameters[i].isGenericCovariantImpl = true;
        }
      }
      if (isCovariant) {
        if (!superParameter.isCovariant) {
          createImplIfNeeded();
        }
        if (!parameter.isCovariant) {
          createStubIfNeeded();
          stub.function.positionalParameters[i].isCovariant = true;
        }
      }
      if (type != null && type != parameterType) {
        // TODO(johnniwinther): Report an error when [type] is null; this
        // means that nnbd-top-merge was not defined.
        createStubIfNeeded(forMemberSignature: true);
        stub.function.positionalParameters[i].type = type;
      }
    }
    for (int i = 0; i < interfaceNamedParameters.length; i++) {
      VariableDeclaration parameter = interfaceNamedParameters[i];
      DartType parameterType = substitution.substituteType(parameter.type);
      DartType type = initialType(parameterType);
      bool isGenericCovariantImpl =
          parameter.isGenericCovariantImpl || needsCheck(parameter.type);
      bool isCovariant = parameter.isCovariant;
      VariableDeclaration superParameter = parameter;
      for (int j = 0; j < _candidates.length; j++) {
        Member otherMember = getCandidateAt(j);
        if (otherMember is ForwardingNode) continue;
        VariableDeclaration otherParameter =
            getNamedFormal(otherMember.function, parameter.name);
        if (otherParameter == null) continue;
        if (j == 0) superParameter = otherParameter;
        if (identical(otherMember, interfaceMember)) continue;
        if (otherParameter.isGenericCovariantImpl) {
          isGenericCovariantImpl = true;
        }
        if (otherParameter.isCovariant) {
          isCovariant = true;
        }
        type = mergeTypes(
            type, substitutions[j].substituteType(otherParameter.type));
      }
      if (isGenericCovariantImpl) {
        if (!superParameter.isGenericCovariantImpl) {
          createImplIfNeeded();
        }
        if (!parameter.isGenericCovariantImpl) {
          createStubIfNeeded();
          stub.function.namedParameters[i].isGenericCovariantImpl = true;
        }
      }
      if (isCovariant) {
        if (!superParameter.isCovariant) {
          createImplIfNeeded();
        }
        if (!parameter.isCovariant) {
          createStubIfNeeded();
          stub.function.namedParameters[i].isCovariant = true;
        }
      }
      if (type != null && type != parameterType) {
        // TODO(johnniwinther): Report an error when [type] is null; this
        // means that nnbd-top-merge was not defined.
        createStubIfNeeded(forMemberSignature: true);
        stub.function.namedParameters[i].type = type;
      }
    }
    for (int i = 0; i < interfaceTypeParameters.length; i++) {
      TypeParameter typeParameter = interfaceTypeParameters[i];
      bool isGenericCovariantImpl = typeParameter.isGenericCovariantImpl ||
          needsCheck(typeParameter.bound);
      TypeParameter superTypeParameter = typeParameter;
      for (int j = 0; j < _candidates.length; j++) {
        Member otherMember = getCandidateAt(j);
        if (otherMember is ForwardingNode) continue;
        List<TypeParameter> otherTypeParameters =
            otherMember.function.typeParameters;
        if (otherTypeParameters.length <= i) continue;
        TypeParameter otherTypeParameter = otherTypeParameters[i];
        if (j == 0) superTypeParameter = otherTypeParameter;
        if (identical(otherMember, interfaceMember)) continue;
        if (otherTypeParameter.isGenericCovariantImpl) {
          isGenericCovariantImpl = true;
        }
      }
      if (isGenericCovariantImpl) {
        if (!superTypeParameter.isGenericCovariantImpl) {
          createImplIfNeeded();
        }
        if (!typeParameter.isGenericCovariantImpl) {
          createStubIfNeeded();
          stub.function.typeParameters[i].isGenericCovariantImpl = true;
        }
      }
    }
    DartType returnType =
        substitution.substituteType(getReturnType(interfaceMember));
    DartType type = initialType(returnType);
    for (int j = 0; j < _candidates.length; j++) {
      Member otherMember = getCandidateAt(j);
      type = mergeTypes(
          type, substitutions[j].substituteType(getReturnType(otherMember)));
    }
    if (type != null && type != returnType) {
      // TODO(johnniwinther): Report an error when [type] is null; this
      // means that nnbd-top-merge was not defined.
      createStubIfNeeded(forMemberSignature: true);
      stub.function.returnType = type;
    }
    return stub;
  }

  void _createForwardingImplIfNeeded(FunctionNode function) {
    if (function.body != null) {
      // There is already an implementation; nothing further needs to be done.
      return;
    }
    // Find the concrete implementation in the superclass; this is what we need
    // to forward to.  If we can't find one, then the method is fully abstract
    // and we don't need to do anything.
    Class superclass = enclosingClass.superclass;
    if (superclass == null) return;
    Procedure procedure = function.parent;
    Member superTarget = hierarchy.getDispatchTargetKernel(
        superclass, procedure.name, kind == ProcedureKind.Setter);
    if (superTarget == null) return;
    if (superTarget is Procedure && superTarget.isForwardingStub) {
      superTarget = _getForwardingStubSuperTarget(superTarget);
    }
    procedure.isAbstract = false;
    if (!procedure.isForwardingStub) {
      // This procedure exists abstractly in the source code; we need to make it
      // concrete and give it a body that is a forwarding stub.  This situation
      // is called a "forwarding semi-stub".
      procedure.isForwardingStub = true;
      procedure.isForwardingSemiStub = true;
    }
    List<Expression> positionalArguments = function.positionalParameters
        .map<Expression>((parameter) => new VariableGet(parameter))
        .toList();
    List<NamedExpression> namedArguments = function.namedParameters
        .map((parameter) =>
            new NamedExpression(parameter.name, new VariableGet(parameter)))
        .toList();
    List<DartType> typeArguments = function.typeParameters
        .map<DartType>((typeParameter) =>
            new TypeParameterType.withDefaultNullabilityForLibrary(
                typeParameter, enclosingClass.enclosingLibrary))
        .toList();
    Arguments arguments = new Arguments(positionalArguments,
        types: typeArguments, named: namedArguments);
    Expression superCall;
    switch (kind) {
      case ProcedureKind.Method:
      case ProcedureKind.Operator:
        superCall = new SuperMethodInvocation(name, arguments, superTarget);
        break;
      case ProcedureKind.Getter:
        superCall = new SuperPropertyGet(name, superTarget);
        break;
      case ProcedureKind.Setter:
        superCall =
            new SuperPropertySet(name, positionalArguments[0], superTarget);
        break;
      default:
        unhandled('$kind', '_createForwardingImplIfNeeded', -1, null);
        break;
    }
    function.body = new ReturnStatement(superCall)..parent = function;
    procedure.transformerFlags |= TransformerFlag.superCalls;
    procedure.forwardingStubSuperTarget = superTarget;
  }

  /// Creates a forwarding stub based on the given [target].
  Procedure _createForwardingStub(List<TypeParameter> typeParameters,
      Substitution substitution, Member target,
      {bool forMemberSignature: false}) {
    VariableDeclaration copyParameter(VariableDeclaration parameter) {
      return new VariableDeclaration(parameter.name,
          type: substitution.substituteType(parameter.type),
          isCovariant: parameter.isCovariant)
        ..isGenericCovariantImpl = parameter.isGenericCovariantImpl;
    }

    List<TypeParameter> targetTypeParameters =
        target.function?.typeParameters ?? [];
    if (typeParameters != null) {
      Map<TypeParameter, DartType> additionalSubstitution =
          <TypeParameter, DartType>{};
      for (int i = 0; i < targetTypeParameters.length; i++) {
        TypeParameter targetTypeParameter = targetTypeParameters[i];
        additionalSubstitution[targetTypeParameter] =
            new TypeParameterType.forAlphaRenaming(
                targetTypeParameter, typeParameters[i]);
      }
      substitution = Substitution.combine(
          substitution, Substitution.fromMap(additionalSubstitution));
      for (int i = 0; i < typeParameters.length; i++) {
        typeParameters[i].bound =
            substitution.substituteType(targetTypeParameters[i].bound);
      }
    }
    List<VariableDeclaration> positionalParameters =
        getPositionalParameters(target).map(copyParameter).toList();
    List<VariableDeclaration> namedParameters =
        target.function?.namedParameters?.map(copyParameter)?.toList() ?? [];
    FunctionNode function = new FunctionNode(null,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        typeParameters: typeParameters,
        requiredParameterCount: getRequiredParameterCount(target),
        returnType: substitution.substituteType(getReturnType(target)));
    Member finalTarget;
    if (target is Procedure && target.isForwardingStub) {
      finalTarget = target.forwardingStubInterfaceTarget;
    } else {
      finalTarget = target;
    }
    Procedure referenceFrom;
    if (classBuilder.referencesFromIndexed != null) {
      if (kind == ProcedureKind.Setter) {
        referenceFrom =
            classBuilder.referencesFromIndexed.lookupProcedureSetter(name.name);
      } else {
        referenceFrom = classBuilder.referencesFromIndexed
            .lookupProcedureNotSetter(name.name);
      }
    }
    return new Procedure(name, kind, function,
        isAbstract: true,
        isForwardingStub: !forMemberSignature,
        isMemberSignature: forMemberSignature,
        fileUri: enclosingClass.fileUri,
        forwardingStubInterfaceTarget: finalTarget,
        reference: referenceFrom?.reference)
      ..startFileOffset = enclosingClass.fileOffset
      ..fileOffset = enclosingClass.fileOffset
      ..parent = enclosingClass;
  }

  /// Returns the [i]th element of [_candidates], finalizing it if necessary.
  Member getCandidateAt(int i) {
    ClassMember candidate = _candidates[i];
    assert(candidate is! DelayedMember);
    return candidate.member;
  }

  static Member _getForwardingStubSuperTarget(Procedure forwardingStub) {
    // TODO(paulberry): when dartbug.com/31562 is fixed, this should become
    // easier.
    ReturnStatement body = forwardingStub.function.body;
    Expression expression = body.expression;
    if (expression is SuperMethodInvocation) {
      return expression.interfaceTarget;
    } else if (expression is SuperPropertySet) {
      return expression.interfaceTarget;
    } else {
      return unhandled('${expression.runtimeType}',
          '_getForwardingStubSuperTarget', -1, null);
    }
  }

  Substitution _substitutionFor(
      List<TypeParameter> stubTypeParameters, Member candidate, Class class_) {
    Substitution substitution = Substitution.fromInterfaceType(
        hierarchy.getKernelTypeAsInstanceOf(
            hierarchy.coreTypes
                .thisInterfaceType(class_, class_.enclosingLibrary.nonNullable),
            candidate.enclosingClass,
            class_.enclosingLibrary));
    if (stubTypeParameters != null) {
      // If the stub is generic ensure that type parameters are alpha renamed
      // to the [stubTypeParameters].
      Map<TypeParameter, TypeParameterType> map = {};
      for (int i = 0; i < stubTypeParameters.length; i++) {
        TypeParameter typeParameter = candidate.function.typeParameters[i];
        map[typeParameter] = new TypeParameterType.forAlphaRenaming(
            typeParameter, stubTypeParameters[i]);
      }
      substitution =
          Substitution.combine(substitution, Substitution.fromMap(map));
    }
    return substitution;
  }

  List<VariableDeclaration> getPositionalParameters(Member member) {
    if (member is Field) {
      if (kind == ProcedureKind.Setter) {
        return <VariableDeclaration>[
          new VariableDeclaration("_",
              type: member.type, isCovariant: member.isCovariant)
            ..isGenericCovariantImpl = member.isGenericCovariantImpl
        ];
      } else {
        return <VariableDeclaration>[];
      }
    } else {
      return member.function.positionalParameters;
    }
  }

  int getRequiredParameterCount(Member member) {
    switch (kind) {
      case ProcedureKind.Getter:
        return 0;
      case ProcedureKind.Setter:
        return 1;
      default:
        return member.function.requiredParameterCount;
    }
  }

  DartType getReturnType(Member member) {
    switch (kind) {
      case ProcedureKind.Getter:
        return member is Field ? member.type : member.function.returnType;
      case ProcedureKind.Setter:
        return const VoidType();
      default:
        return member.function.returnType;
    }
  }
}
