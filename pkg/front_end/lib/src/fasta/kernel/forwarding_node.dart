// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:kernel/ast.dart"
    show
        Arguments,
        Class,
        DartType,
        DynamicType,
        Expression,
        Field,
        FunctionNode,
        FunctionType,
        Member,
        Name,
        NamedExpression,
        NamedType,
        Nullability,
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
import "package:kernel/src/norm.dart";

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

  /// The index of [combinedMemberSignatureResult] in [_candidates].
  final int _combinedMemberIndex;

  final ProcedureKind kind;

  /// A list containing the directly implemented and directly inherited
  /// procedures of the class in question.
  final List<ClassMember> _candidates;

  /// The indices of the [_candidates] whose types need to be merged to compute
  /// the resulting member type.
  final Set<int> _mergeIndices;

  ForwardingNode(
      this.hierarchy,
      this.classBuilder,
      this.combinedMemberSignatureResult,
      this._combinedMemberIndex,
      this._candidates,
      this.kind,
      this._mergeIndices);

  Name get name => combinedMemberSignatureResult.name;

  Class get enclosingClass => classBuilder.cls;

  /// Finishes handling of this node by propagating covariance and creating
  /// forwarding stubs if necessary.
  Member finalize() => _computeCovarianceFixes();

  /// Creates a getter member signature for [interfaceMember] with the given
  /// [type].
  Member _createGetterMemberSignature(Member interfaceMember, DartType type) {
    Procedure referenceFrom;
    if (classBuilder.referencesFromIndexed != null) {
      referenceFrom = classBuilder.referencesFromIndexed
          .lookupProcedureNotSetter(name.text);
    }
    return new Procedure(name, kind, new FunctionNode(null, returnType: type),
        isAbstract: true,
        isMemberSignature: true,
        fileUri: enclosingClass.fileUri,
        memberSignatureOrigin: interfaceMember,
        reference: referenceFrom?.reference)
      ..startFileOffset = enclosingClass.fileOffset
      ..fileOffset = enclosingClass.fileOffset
      ..parent = enclosingClass;
  }

  /// Creates a setter member signature for [interfaceMember] with the given
  /// [type]. The flags of parameter is set according to [isCovariant] and
  /// [isGenericCovariantImpl] and the [parameterName] is used, if provided.
  Member _createSetterMemberSignature(Member interfaceMember, DartType type,
      {bool isCovariant, bool isGenericCovariantImpl, String parameterName}) {
    assert(isCovariant != null);
    assert(isGenericCovariantImpl != null);
    Procedure referenceFrom;
    if (classBuilder.referencesFromIndexed != null) {
      referenceFrom =
          classBuilder.referencesFromIndexed.lookupProcedureSetter(name.text);
    }
    return new Procedure(
        name,
        kind,
        new FunctionNode(null,
            returnType: const VoidType(),
            positionalParameters: [
              new VariableDeclaration(parameterName ?? '_',
                  type: type, isCovariant: isCovariant)
                ..isGenericCovariantImpl = isGenericCovariantImpl
            ]),
        isAbstract: true,
        isMemberSignature: true,
        fileUri: enclosingClass.fileUri,
        memberSignatureOrigin: interfaceMember,
        reference: referenceFrom?.reference)
      ..startFileOffset = enclosingClass.fileOffset
      ..fileOffset = enclosingClass.fileOffset
      ..parent = enclosingClass;
  }

  /// Creates a legacy member signature for the field [interfaceMember] if the
  /// type of [interfaceMember] contains non-legacy nullabilities.
  Member _createLegacyMemberSignatureForField(Field interfaceMember) {
    DartType type = interfaceMember.type;
    if (interfaceMember.enclosingClass.typeParameters.isNotEmpty) {
      Substitution substitution =
          _substitutionFor(null, interfaceMember, enclosingClass);
      type = substitution.substituteType(type);
    }
    DartType legacyType = rawLegacyErasure(hierarchy.coreTypes, type);
    if (legacyType == null) {
      return interfaceMember;
    } else {
      // We base the decision to add a member signature on whether the legacy
      // erasure of the declared type is different from the declared type, i.e.
      // whether the declared type contained non-legacy nullabilities.
      //
      // This is slightly different from checking whether the legacy erasure of
      // the inherited type is different from the
      if (kind == ProcedureKind.Getter) {
        return _createGetterMemberSignature(interfaceMember, legacyType);
      } else {
        assert(kind == ProcedureKind.Setter);
        return _createSetterMemberSignature(interfaceMember, legacyType,
            isCovariant: interfaceMember.isCovariant,
            isGenericCovariantImpl: interfaceMember.isGenericCovariantImpl);
      }
    }
  }

  /// Creates a legacy member signature for procedure [interfaceMember] if the
  /// type of [interfaceMember] contains non-legacy nullabilities.
  Member _createLegacyMemberSignatureForProcedure(Procedure interfaceMember) {
    if (interfaceMember.kind == ProcedureKind.Getter) {
      DartType type = interfaceMember.getterType;
      if (interfaceMember.enclosingClass.typeParameters.isNotEmpty) {
        Substitution substitution =
            _substitutionFor(null, interfaceMember, enclosingClass);
        type = substitution.substituteType(type);
      }
      DartType legacyType = rawLegacyErasure(hierarchy.coreTypes, type);
      if (legacyType == null) {
        return interfaceMember;
      } else {
        return _createGetterMemberSignature(interfaceMember, legacyType);
      }
    } else if (interfaceMember.kind == ProcedureKind.Setter) {
      DartType type = interfaceMember.setterType;
      if (interfaceMember.enclosingClass.typeParameters.isNotEmpty) {
        Substitution substitution =
            _substitutionFor(null, interfaceMember, enclosingClass);
        type = substitution.substituteType(type);
      }
      DartType legacyType = rawLegacyErasure(hierarchy.coreTypes, type);
      if (legacyType == null) {
        return interfaceMember;
      } else {
        VariableDeclaration parameter =
            interfaceMember.function.positionalParameters.first;
        return _createSetterMemberSignature(interfaceMember, legacyType,
            isCovariant: parameter.isCovariant,
            isGenericCovariantImpl: parameter.isGenericCovariantImpl,
            parameterName: parameter.name);
      }
    } else {
      FunctionNode function = interfaceMember.function;
      FunctionType type = function.computeFunctionType(Nullability.legacy);
      if (interfaceMember.enclosingClass.typeParameters.isNotEmpty) {
        Substitution substitution =
            _substitutionFor(null, interfaceMember, enclosingClass);
        type = substitution.substituteType(type);
      }
      FunctionType legacyType = rawLegacyErasure(hierarchy.coreTypes, type);
      if (legacyType == null) {
        return interfaceMember;
      }
      Procedure referenceFrom;
      if (classBuilder.referencesFromIndexed != null) {
        referenceFrom = classBuilder.referencesFromIndexed
            .lookupProcedureNotSetter(name.text);
      }
      List<VariableDeclaration> positionalParameters = [];
      for (int i = 0; i < function.positionalParameters.length; i++) {
        VariableDeclaration parameter = function.positionalParameters[i];
        DartType parameterType = legacyType.positionalParameters[i];
        if (i == 0 && interfaceMember == hierarchy.coreTypes.objectEquals) {
          // In legacy code we special case `Object.==` to infer `dynamic`
          // instead `Object!`.
          parameterType = const DynamicType();
        }
        positionalParameters.add(new VariableDeclaration(parameter.name,
            type: parameterType, isCovariant: parameter.isCovariant)
          ..isGenericCovariantImpl = parameter.isGenericCovariantImpl);
      }
      List<VariableDeclaration> namedParameters = [];
      int namedParameterCount = function.namedParameters.length;
      if (namedParameterCount == 1) {
        NamedType namedType = legacyType.namedParameters.first;
        VariableDeclaration parameter = function.namedParameters.first;
        namedParameters.add(new VariableDeclaration(parameter.name,
            type: namedType.type, isCovariant: parameter.isCovariant)
          ..isGenericCovariantImpl = parameter.isGenericCovariantImpl);
      } else if (namedParameterCount > 1) {
        Map<String, DartType> namedTypes = {};
        for (NamedType namedType in legacyType.namedParameters) {
          namedTypes[namedType.name] = namedType.type;
        }
        for (int i = 0; i < namedParameterCount; i++) {
          VariableDeclaration parameter = function.namedParameters[i];
          DartType parameterType = namedTypes[parameter.name];
          namedParameters.add(new VariableDeclaration(parameter.name,
              type: parameterType, isCovariant: parameter.isCovariant)
            ..isGenericCovariantImpl = parameter.isGenericCovariantImpl);
        }
      }
      return new Procedure(
          name,
          kind,
          new FunctionNode(null,
              typeParameters: legacyType.typeParameters,
              returnType: legacyType.returnType,
              positionalParameters: positionalParameters,
              namedParameters: namedParameters,
              requiredParameterCount: function.requiredParameterCount),
          isAbstract: true,
          isMemberSignature: true,
          fileUri: enclosingClass.fileUri,
          memberSignatureOrigin: interfaceMember,
          reference: referenceFrom?.reference)
        ..startFileOffset = enclosingClass.fileOffset
        ..fileOffset = enclosingClass.fileOffset
        ..parent = enclosingClass;
    }
  }

  /// Creates a legacy member signature for [interfaceMember] if the type of
  /// [interfaceMember] contains non-legacy nullabilities.
  Member _createLegacyMemberSignature(Member interfaceMember) {
    if (interfaceMember is Field) {
      return _createLegacyMemberSignatureForField(interfaceMember);
    } else {
      assert(interfaceMember is Procedure);
      return _createLegacyMemberSignatureForProcedure(interfaceMember);
    }
  }

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
    Member interfaceMember = combinedMemberSignatureResult.getMember(hierarchy);
    if (_candidates.length == 1) {
      // Covariance can only come from [interfaceMember] so we never need a
      // forwarding stub.
      if (interfaceMember.isNonNullableByDefault &&
          !classBuilder.library.isNonNullableByDefault) {
        // Create a member signature with the legacy erasure type.
        return _createLegacyMemberSignature(interfaceMember);
      } else {
        // Nothing to do.
        return interfaceMember;
      }
    }

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
          procedure.memberSignatureOrigin =
              interfaceMember.memberSignatureOrigin ?? interfaceMember;
        } else {
          procedure.isForwardingStub = true;
        }
        return;
      }
      if (interfaceMember.enclosingClass == enclosingClass) return;
      stub = _createForwardingStub(
          stubTypeParameters, substitution, interfaceMember,
          memberSignatureTarget: forMemberSignature
              ? interfaceMember.memberSignatureOrigin ?? interfaceMember
              : null);
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

    DartType initialType(int candidateIndex, DartType a) {
      if (isNonNullableByDefault) {
        if (_mergeIndices != null && _mergeIndices.contains(candidateIndex)) {
          return norm(hierarchy.coreTypes, a);
        } else {
          return a;
        }
      } else {
        return legacyErasure(hierarchy.coreTypes, a);
      }
    }

    DartType mergeTypes(int index, DartType a, DartType b) {
      if (a == null) return null;
      if (isNonNullableByDefault &&
          _mergeIndices != null &&
          _mergeIndices.contains(index)) {
        return nnbdTopMerge(
            hierarchy.coreTypes, a, norm(hierarchy.coreTypes, b));
      } else {
        return a;
      }
    }

    for (int parameterIndex = 0;
        parameterIndex < interfacePositionalParameters.length;
        parameterIndex++) {
      VariableDeclaration parameter =
          interfacePositionalParameters[parameterIndex];
      DartType parameterType = substitution.substituteType(parameter.type);
      DartType type = initialType(_combinedMemberIndex, parameterType);
      if (parameterIndex == 0 &&
          hierarchy
              .coreTypes.objectClass.enclosingLibrary.isNonNullableByDefault &&
          !classBuilder.library.isNonNullableByDefault &&
          interfaceMember == hierarchy.coreTypes.objectEquals) {
        // In legacy code we special case `Object.==` to infer `dynamic`
        // instead `Object!`.
        type = const DynamicType();
      }
      bool isGenericCovariantImpl =
          parameter.isGenericCovariantImpl || needsCheck(parameter.type);
      bool isCovariant = parameter.isCovariant;
      VariableDeclaration superParameter = parameter;
      for (int candidateIndex = 0;
          candidateIndex < _candidates.length;
          candidateIndex++) {
        Member otherMember = getCandidateAt(candidateIndex);
        List<VariableDeclaration> otherPositionalParameters =
            getPositionalParameters(otherMember);
        if (otherPositionalParameters.length <= parameterIndex) continue;
        VariableDeclaration otherParameter =
            otherPositionalParameters[parameterIndex];
        if (candidateIndex == 0) superParameter = otherParameter;
        if (identical(otherMember, interfaceMember)) continue;
        if (otherParameter.isGenericCovariantImpl) {
          isGenericCovariantImpl = true;
        }
        if (otherParameter.isCovariant) {
          isCovariant = true;
        }
        DartType candidateType =
            substitutions[candidateIndex].substituteType(otherParameter.type);
        if (parameterIndex == 0 &&
            hierarchy.coreTypes.objectClass.enclosingLibrary
                .isNonNullableByDefault &&
            !classBuilder.library.isNonNullableByDefault &&
            otherMember == hierarchy.coreTypes.objectEquals) {
          // In legacy code we special case `Object.==` to infer `dynamic`
          // instead `Object!`.
          candidateType = const DynamicType();
        }

        type = mergeTypes(candidateIndex, type, candidateType);
      }
      if (isGenericCovariantImpl) {
        if (!superParameter.isGenericCovariantImpl) {
          createImplIfNeeded();
        }
        if (!parameter.isGenericCovariantImpl) {
          createStubIfNeeded();
          stub.function.positionalParameters[parameterIndex]
              .isGenericCovariantImpl = true;
        }
      }
      if (isCovariant) {
        if (!superParameter.isCovariant) {
          createImplIfNeeded();
        }
        if (!parameter.isCovariant) {
          createStubIfNeeded();
          stub.function.positionalParameters[parameterIndex].isCovariant = true;
        }
      }
      if (type != null && type != parameterType) {
        // TODO(johnniwinther): Report an error when [type] is null; this
        // means that nnbd-top-merge was not defined.
        createStubIfNeeded(forMemberSignature: true);
        stub.function.positionalParameters[parameterIndex].type = type;
      }
    }
    for (int parameterIndex = 0;
        parameterIndex < interfaceNamedParameters.length;
        parameterIndex++) {
      VariableDeclaration parameter = interfaceNamedParameters[parameterIndex];
      DartType parameterType = substitution.substituteType(parameter.type);
      DartType type = initialType(_combinedMemberIndex, parameterType);
      bool isGenericCovariantImpl =
          parameter.isGenericCovariantImpl || needsCheck(parameter.type);
      bool isCovariant = parameter.isCovariant;
      VariableDeclaration superParameter = parameter;
      for (int candidateIndex = 0;
          candidateIndex < _candidates.length;
          candidateIndex++) {
        Member otherMember = getCandidateAt(candidateIndex);
        if (otherMember is ForwardingNode) continue;
        VariableDeclaration otherParameter =
            getNamedFormal(otherMember.function, parameter.name);
        if (otherParameter == null) continue;
        if (candidateIndex == 0) superParameter = otherParameter;
        if (identical(otherMember, interfaceMember)) continue;
        if (otherParameter.isGenericCovariantImpl) {
          isGenericCovariantImpl = true;
        }
        if (otherParameter.isCovariant) {
          isCovariant = true;
        }
        type = mergeTypes(candidateIndex, type,
            substitutions[candidateIndex].substituteType(otherParameter.type));
      }
      if (isGenericCovariantImpl) {
        if (!superParameter.isGenericCovariantImpl) {
          createImplIfNeeded();
        }
        if (!parameter.isGenericCovariantImpl) {
          createStubIfNeeded();
          stub.function.namedParameters[parameterIndex].isGenericCovariantImpl =
              true;
        }
      }
      if (isCovariant) {
        if (!superParameter.isCovariant) {
          createImplIfNeeded();
        }
        if (!parameter.isCovariant) {
          createStubIfNeeded();
          stub.function.namedParameters[parameterIndex].isCovariant = true;
        }
      }
      if (type != null && type != parameterType) {
        // TODO(johnniwinther): Report an error when [type] is null; this
        // means that nnbd-top-merge was not defined.
        createStubIfNeeded(forMemberSignature: true);
        stub.function.namedParameters[parameterIndex].type = type;
      }
    }
    for (int parameterIndex = 0;
        parameterIndex < interfaceTypeParameters.length;
        parameterIndex++) {
      TypeParameter typeParameter = interfaceTypeParameters[parameterIndex];
      DartType parameterBound =
          substitution.substituteType(typeParameter.bound);
      DartType bound = initialType(_combinedMemberIndex, parameterBound);
      DartType parameterDefaultType =
          substitution.substituteType(typeParameter.defaultType);
      DartType defaultType =
          initialType(_combinedMemberIndex, parameterDefaultType);
      bool isGenericCovariantImpl =
          typeParameter.isGenericCovariantImpl || needsCheck(parameterBound);
      TypeParameter superTypeParameter = typeParameter;
      for (int candidateIndex = 0;
          candidateIndex < _candidates.length;
          candidateIndex++) {
        Member otherMember = getCandidateAt(candidateIndex);
        if (otherMember is ForwardingNode) continue;
        List<TypeParameter> otherTypeParameters =
            otherMember.function.typeParameters;
        if (otherTypeParameters.length <= parameterIndex) continue;
        TypeParameter otherTypeParameter = otherTypeParameters[parameterIndex];
        if (candidateIndex == 0) superTypeParameter = otherTypeParameter;
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
          stub.function.typeParameters[parameterIndex].isGenericCovariantImpl =
              true;
        }
      }
      if (bound != null && bound != parameterBound) {
        createStubIfNeeded(forMemberSignature: true);
        stub.function.typeParameters[parameterIndex].bound = bound;
      }
      if (defaultType != null && defaultType != parameterDefaultType) {
        createStubIfNeeded(forMemberSignature: true);
        stub.function.typeParameters[parameterIndex].defaultType = defaultType;
      }
    }
    DartType returnType =
        substitution.substituteType(getReturnType(interfaceMember));
    DartType type = initialType(_combinedMemberIndex, returnType);
    for (int candidateIndex = 0;
        candidateIndex < _candidates.length;
        candidateIndex++) {
      Member otherMember = getCandidateAt(candidateIndex);
      type = mergeTypes(
          candidateIndex,
          type,
          substitutions[candidateIndex]
              .substituteType(getReturnType(otherMember)));
    }
    if (type != null && type != returnType) {
      // TODO(johnniwinther): Report an error when [type] is null; this
      // means that nnbd-top-merge was not defined.
      createStubIfNeeded(forMemberSignature: true);
      stub.function.returnType = type;
    }
    assert(
        !(stub is Procedure &&
            (stub as Procedure).isMemberSignature &&
            stub.memberSignatureOrigin == null),
        "No member signature origin for member signature $stub.");
    if (stub != interfaceMember && stub is Procedure) {
      Procedure procedure = stub;
      if (procedure.isForwardingStub || procedure.isForwardingSemiStub) {
        procedure.isMemberSignature = false;
        procedure.memberSignatureOrigin = null;
      } else {
        procedure.forwardingStubInterfaceTarget = null;
        procedure.forwardingStubSuperTarget = null;
      }
      assert(
          !(procedure.isMemberSignature && procedure.isForwardingStub),
          "Procedure is both member signature and forwarding stub: "
          "$procedure.");
      assert(
          !(procedure.isMemberSignature && procedure.isForwardingSemiStub),
          "Procedure is both member signature and forwarding semi stub: "
          "$procedure.");
      assert(
          !(procedure.forwardingStubInterfaceTarget is Procedure &&
              (procedure.forwardingStubInterfaceTarget as Procedure)
                  .isMemberSignature),
          "Forwarding stub interface target is member signature: $procedure.");
      assert(
          !(procedure.forwardingStubSuperTarget is Procedure &&
              (procedure.forwardingStubSuperTarget as Procedure)
                  .isMemberSignature),
          "Forwarding stub super target is member signature: $procedure.");
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
      Procedure superProcedure = superTarget;
      superTarget = superProcedure.forwardingStubSuperTarget;
    } else {
      superTarget = superTarget.memberSignatureOrigin ?? superTarget;
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
      {Member memberSignatureTarget}) {
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
        typeParameters[i].defaultType =
            substitution.substituteType(targetTypeParameters[i].defaultType);
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
      finalTarget = target.memberSignatureOrigin ?? target;
    }
    Procedure referenceFrom;
    if (classBuilder.referencesFromIndexed != null) {
      if (kind == ProcedureKind.Setter) {
        referenceFrom =
            classBuilder.referencesFromIndexed.lookupProcedureSetter(name.text);
      } else {
        referenceFrom = classBuilder.referencesFromIndexed
            .lookupProcedureNotSetter(name.text);
      }
    }
    return new Procedure(name, kind, function,
        isAbstract: true,
        isForwardingStub: memberSignatureTarget == null,
        isMemberSignature: memberSignatureTarget != null,
        fileUri: enclosingClass.fileUri,
        forwardingStubInterfaceTarget: finalTarget,
        reference: referenceFrom?.reference,
        memberSignatureOrigin: memberSignatureTarget)
      ..startFileOffset = enclosingClass.fileOffset
      ..fileOffset = enclosingClass.fileOffset
      ..parent = enclosingClass
      ..isNonNullableByDefault =
          enclosingClass.enclosingLibrary.isNonNullableByDefault;
  }

  /// Returns the [i]th element of [_candidates], finalizing it if necessary.
  Member getCandidateAt(int i) {
    ClassMember candidate = _candidates[i];
    return candidate.getMember(hierarchy);
  }

  Substitution _substitutionFor(
      List<TypeParameter> stubTypeParameters, Member candidate, Class class_) {
    Substitution substitution = Substitution.fromInterfaceType(
        hierarchy.getTypeAsInstanceOf(
            hierarchy.coreTypes
                .thisInterfaceType(class_, class_.enclosingLibrary.nonNullable),
            candidate.enclosingClass,
            class_.enclosingLibrary,
            hierarchy.coreTypes));
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
