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
        VoidType;

import 'package:kernel/transformations/flags.dart' show TransformerFlag;

import "package:kernel/type_algebra.dart" show Substitution;

import "../builder/class_builder.dart";

import "../problems.dart" show unhandled;

import "../type_inference/type_inference_engine.dart"
    show IncludesTypeParametersNonCovariantly, Variance;

import "../type_inference/type_inferrer.dart" show getNamedFormal;

import 'class_hierarchy_builder.dart';

class ForwardingNode {
  final ClassHierarchyBuilder hierarchy;

  final ClassBuilder parent;

  final ClassMember combinedMemberSignatureResult;

  final ProcedureKind kind;

  /// A list containing the directly implemented and directly inherited
  /// procedures of the class in question.
  final List<ClassMember> _candidates;

  ForwardingNode(this.hierarchy, this.parent,
      this.combinedMemberSignatureResult, this._candidates, this.kind);

  Name get name => combinedMemberSignatureResult.member.name;

  Class get enclosingClass => parent.cls;

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
    Substitution substitution =
        _substitutionFor(interfaceMember, enclosingClass);
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
        : _createForwardingStub(substitution, interfaceMember);

    FunctionNode interfaceFunction = interfaceMember.function;
    List<VariableDeclaration> interfacePositionalParameters =
        getPositionalParameters(interfaceMember);
    List<VariableDeclaration> interfaceNamedParameters =
        interfaceFunction?.namedParameters ?? [];
    List<TypeParameter> interfaceTypeParameters =
        interfaceFunction?.typeParameters ?? [];

    void createStubIfNeeded() {
      if (stub != interfaceMember) return;
      if (interfaceMember.enclosingClass == enclosingClass) return;
      stub = _createForwardingStub(substitution, interfaceMember);
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
    for (int i = 0; i < interfacePositionalParameters.length; i++) {
      VariableDeclaration parameter = interfacePositionalParameters[i];
      bool isGenericCovariantImpl =
          parameter.isGenericCovariantImpl || needsCheck(parameter.type);
      bool isCovariant = parameter.isCovariant;
      VariableDeclaration superParameter = parameter;
      for (int j = 0; j < _candidates.length; j++) {
        Member otherMember = getCandidateAt(j);
        if (otherMember is ForwardingNode) continue;
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
    }
    for (int i = 0; i < interfaceNamedParameters.length; i++) {
      VariableDeclaration parameter = interfaceNamedParameters[i];
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
        .map<DartType>((typeParameter) => new TypeParameterType(typeParameter))
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
  Procedure _createForwardingStub(Substitution substitution, Member target) {
    VariableDeclaration copyParameter(VariableDeclaration parameter) {
      return new VariableDeclaration(parameter.name,
          type: substitution.substituteType(parameter.type),
          isCovariant: parameter.isCovariant)
        ..isGenericCovariantImpl = parameter.isGenericCovariantImpl;
    }

    List<TypeParameter> targetTypeParameters =
        target.function?.typeParameters ?? [];
    List<TypeParameter> typeParameters;
    if (targetTypeParameters.isNotEmpty) {
      typeParameters =
          new List<TypeParameter>.filled(targetTypeParameters.length, null);
      Map<TypeParameter, DartType> additionalSubstitution =
          <TypeParameter, DartType>{};
      for (int i = 0; i < targetTypeParameters.length; i++) {
        TypeParameter targetTypeParameter = targetTypeParameters[i];
        TypeParameter typeParameter = new TypeParameter(
            targetTypeParameter.name, null)
          ..isGenericCovariantImpl = targetTypeParameter.isGenericCovariantImpl;
        typeParameters[i] = typeParameter;
        additionalSubstitution[targetTypeParameter] =
            new TypeParameterType(typeParameter);
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
    return new Procedure(name, kind, function,
        isAbstract: true,
        isForwardingStub: true,
        fileUri: enclosingClass.fileUri,
        forwardingStubInterfaceTarget: finalTarget)
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

  Substitution _substitutionFor(Member candidate, Class class_) {
    return Substitution.fromInterfaceType(hierarchy.getKernelTypeAsInstanceOf(
        class_.thisType, candidate.enclosingClass));
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
