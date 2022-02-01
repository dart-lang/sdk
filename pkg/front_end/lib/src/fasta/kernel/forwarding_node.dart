// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:kernel/ast.dart";

import 'package:kernel/transformations/flags.dart' show TransformerFlag;
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import "../source/source_class_builder.dart";

import "../problems.dart" show unhandled;

import 'hierarchy/class_member.dart';
import 'combined_member_signature.dart';

class ForwardingNode {
  final CombinedClassMemberSignature _combinedMemberSignature;

  final ProcedureKind kind;

  final ClassMember? _superClassMember;

  final ClassMember? _mixedInMember;

  ForwardingNode(this._combinedMemberSignature, this.kind,
      this._superClassMember, this._mixedInMember);

  /// Finishes handling of this node by propagating covariance and creating
  /// forwarding stubs if necessary.
  ///
  /// If a stub is created, this is returned. Otherwise `null` is returned.
  Procedure? finalize() => _computeCovarianceFixes();

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
  ///
  /// If a stub is created, this is returned. Otherwise `null` is returned.
  Procedure? _computeCovarianceFixes() {
    SourceClassBuilder classBuilder = _combinedMemberSignature.classBuilder;
    ClassMember canonicalMember = _combinedMemberSignature.canonicalMember!;
    Member interfaceMember =
        canonicalMember.getMember(_combinedMemberSignature.membersBuilder);

    bool needMixinStub =
        classBuilder.isMixinApplication && _mixedInMember != null;

    if (_combinedMemberSignature.members.length == 1 && !needMixinStub) {
      // Covariance can only come from [interfaceMember] so we never need a
      // forwarding stub.
      if (_combinedMemberSignature.neededLegacyErasure) {
        return _combinedMemberSignature.createMemberFromSignature(
            // TODO(johnniwinther): Change member signatures to use location
            // of origin.
            copyLocation: false);
      } else {
        // Nothing to do.
        return null;
      }
    }

    // TODO(johnniwinther): Remove this. This relies upon the order of the
    // declarations matching the order in which members are returned from the
    // [ClassHierarchy].
    bool cannotReuseExistingMember =
        !(_combinedMemberSignature.isCanonicalMemberFirst ||
            _combinedMemberSignature.isCanonicalMemberDeclared);
    bool needsTypeOrCovarianceUpdate =
        _combinedMemberSignature.neededNnbdTopMerge ||
            _combinedMemberSignature.neededLegacyErasure ||
            _combinedMemberSignature.needsCovarianceMerging;
    bool stubNeeded = cannotReuseExistingMember ||
        (canonicalMember.classBuilder != classBuilder &&
            needsTypeOrCovarianceUpdate) ||
        needMixinStub;
    bool needsSuperImpl = false;
    Member? superTarget;
    if (_superClassMember != null) {
      superTarget =
          _superClassMember!.getMember(_combinedMemberSignature.membersBuilder);
      if (superTarget is Procedure &&
          interfaceMember is Procedure &&
          (superTarget.function.positionalParameters.length <
                  interfaceMember.function.positionalParameters.length ||
              superTarget.function.namedParameters.length <
                  interfaceMember.function.namedParameters.length)) {
        // [superTarget] is not a valid implementation for [interfaceMember]
        // since [interfaceMember] has more parameters than [superTarget].
        //
        // For instance
        //
        //    class A {
        //      void method() {}
        //    }
        //    abstract class B<T> extends A {
        //      void method({T? a});
        //    }
        //
        // Any concrete implementation of B must provide its own implementation
        // of `B.method` and cannot forward to `A.method`.
      } else {
        // [superTarget] is a valid implementation for [interfaceMember] so
        // we need to add concrete forwarding stub of the variances differ.
        needsSuperImpl = _superClassMember!
                .getCovariance(_combinedMemberSignature.membersBuilder) !=
            _combinedMemberSignature.combinedMemberSignatureCovariance;
      }
    }
    if (stubNeeded) {
      Procedure stub = _combinedMemberSignature.createMemberFromSignature(
          copyLocation: false)!;
      bool needsForwardingStub =
          _combinedMemberSignature.needsCovarianceMerging || needsSuperImpl;
      if (needsForwardingStub || needMixinStub) {
        ProcedureStubKind stubKind;
        Member finalTarget;
        if (needsForwardingStub) {
          stubKind = ProcedureStubKind.AbstractForwardingStub;
          if (interfaceMember is Procedure) {
            switch (interfaceMember.stubKind) {
              case ProcedureStubKind.Regular:
              case ProcedureStubKind.NoSuchMethodForwarder:
                finalTarget = interfaceMember;
                break;
              case ProcedureStubKind.AbstractForwardingStub:
              case ProcedureStubKind.ConcreteForwardingStub:
              case ProcedureStubKind.MemberSignature:
              case ProcedureStubKind.AbstractMixinStub:
              case ProcedureStubKind.ConcreteMixinStub:
                finalTarget = interfaceMember.stubTarget!;
                break;
            }
          } else {
            finalTarget = interfaceMember;
          }
        } else {
          stubKind = ProcedureStubKind.AbstractMixinStub;
          finalTarget = _mixedInMember!
              .getMember(_combinedMemberSignature.membersBuilder);
        }

        stub.stubKind = stubKind;
        stub.stubTarget = finalTarget;
        if (needsSuperImpl ||
            (needMixinStub && _superClassMember == _mixedInMember)) {
          _createForwardingImplIfNeeded(
              stub.function, stub.name, classBuilder.cls, superTarget,
              isForwardingStub: needsForwardingStub);
        }
      }

      return stub;
    } else {
      if (_combinedMemberSignature.needsCovarianceMerging) {
        _combinedMemberSignature.combinedMemberSignatureCovariance!
            .applyCovariance(interfaceMember);
      }
      if (needsSuperImpl) {
        _createForwardingImplIfNeeded(interfaceMember.function!,
            interfaceMember.name, classBuilder.cls, superTarget,
            isForwardingStub: true);
      }
      return null;
    }
  }

  void _createForwardingImplIfNeeded(FunctionNode function, Name name,
      Class enclosingClass, Member? superTarget,
      {required bool isForwardingStub}) {
    // ignore: unnecessary_null_comparison
    assert(isForwardingStub != null);
    if (function.body != null) {
      // There is already an implementation; nothing further needs to be done.
      return;
    }
    // If there is no concrete implementation in the superclass, then the method
    // is fully abstract and we don't need to do anything.
    if (superTarget == null) {
      return;
    }
    Procedure procedure = function.parent as Procedure;
    if (superTarget is Procedure && superTarget.isForwardingStub) {
      Procedure superProcedure = superTarget;
      superTarget = superProcedure.concreteForwardingStubTarget!;
    } else {
      superTarget = superTarget.memberSignatureOrigin ?? superTarget;
    }
    procedure.isAbstract = false;
    FunctionType signatureType = procedure.function
        .computeFunctionType(procedure.enclosingLibrary.nonNullable);
    bool isForwardingSemiStub = isForwardingStub && !procedure.isSynthetic;
    bool needsSignatureType = false;
    Expression superCall;
    // ignore: unnecessary_null_comparison
    assert(superTarget != null,
        "No super target found for '${name}' in ${enclosingClass}.");
    assert(
        !superTarget.isAbstract,
        "Abstract super target $superTarget found for '${name}' in "
        "${enclosingClass}.");
    switch (kind) {
      case ProcedureKind.Method:
      case ProcedureKind.Operator:
        FunctionType type = _combinedMemberSignature
            .getMemberTypeForTarget(superTarget) as FunctionType;
        if (type.typeParameters.isNotEmpty) {
          type = Substitution.fromPairs(
                  type.typeParameters,
                  function.typeParameters
                      .map((TypeParameter parameter) => new TypeParameterType
                              .withDefaultNullabilityForLibrary(
                          parameter, procedure.enclosingLibrary))
                      .toList())
              .substituteType(type.withoutTypeParameters) as FunctionType;
        }
        List<Expression> positionalArguments = new List.generate(
            function.positionalParameters.length, (int index) {
          VariableDeclaration parameter = function.positionalParameters[index];
          int fileOffset = parameter.fileOffset;
          Expression expression = new VariableGet(parameter)
            ..fileOffset = fileOffset;
          DartType superParameterType = type.positionalParameters[index];
          if (isForwardingSemiStub) {
            if (parameter.type != superParameterType) {
              parameter.type = superParameterType;
              needsSignatureType = true;
            }
          } else {
            if (!_combinedMemberSignature.hierarchy.types.isSubtypeOf(
                parameter.type,
                superParameterType,
                _combinedMemberSignature
                        .classBuilder.library.isNonNullableByDefault
                    ? SubtypeCheckMode.withNullabilities
                    : SubtypeCheckMode.ignoringNullabilities)) {
              expression = new AsExpression(expression, superParameterType)
                ..fileOffset = fileOffset;
            }
          }
          return expression;
        }, growable: true);
        List<NamedExpression> namedArguments =
            new List.generate(function.namedParameters.length, (int index) {
          VariableDeclaration parameter = function.namedParameters[index];
          int fileOffset = parameter.fileOffset;
          Expression expression = new VariableGet(parameter)
            ..fileOffset = fileOffset;
          DartType superParameterType = type.namedParameters
              .singleWhere(
                  (NamedType namedType) => namedType.name == parameter.name)
              .type;
          if (isForwardingSemiStub) {
            if (parameter.type != superParameterType) {
              parameter.type = superParameterType;
              needsSignatureType = true;
            }
          } else {
            if (!_combinedMemberSignature.hierarchy.types.isSubtypeOf(
                parameter.type,
                superParameterType,
                _combinedMemberSignature
                        .classBuilder.library.isNonNullableByDefault
                    ? SubtypeCheckMode.withNullabilities
                    : SubtypeCheckMode.ignoringNullabilities)) {
              expression = new AsExpression(expression, superParameterType)
                ..fileOffset = fileOffset;
            }
          }
          return new NamedExpression(parameter.name!, expression);
        }, growable: true);
        List<DartType> typeArguments = function.typeParameters
            .map<DartType>((typeParameter) =>
                new TypeParameterType.withDefaultNullabilityForLibrary(
                    typeParameter, enclosingClass.enclosingLibrary))
            .toList();
        Arguments arguments = new Arguments(positionalArguments,
            types: typeArguments, named: namedArguments);
        superCall = new SuperMethodInvocation(
            name, arguments, superTarget as Procedure);
        break;
      case ProcedureKind.Getter:
        superCall = new SuperPropertyGet(name, superTarget);
        break;
      case ProcedureKind.Setter:
        DartType superParameterType =
            _combinedMemberSignature.getMemberTypeForTarget(superTarget);
        VariableDeclaration parameter = function.positionalParameters[0];
        int fileOffset = parameter.fileOffset;
        Expression expression = new VariableGet(parameter)
          ..fileOffset = fileOffset;
        if (isForwardingSemiStub) {
          if (parameter.type != superParameterType) {
            parameter.type = superParameterType;
            needsSignatureType = true;
          }
        } else {
          if (!_combinedMemberSignature.hierarchy.types.isSubtypeOf(
              parameter.type,
              superParameterType,
              _combinedMemberSignature
                      .classBuilder.library.isNonNullableByDefault
                  ? SubtypeCheckMode.withNullabilities
                  : SubtypeCheckMode.ignoringNullabilities)) {
            expression = new AsExpression(expression, superParameterType)
              ..fileOffset = fileOffset;
          }
        }
        superCall = new SuperPropertySet(name, expression, superTarget);
        break;
      default:
        unhandled('$kind', '_createForwardingImplIfNeeded', -1, null);
    }
    function.body = new ReturnStatement(superCall)
      ..fileOffset = procedure.fileOffset
      ..parent = function;
    procedure.transformerFlags |= TransformerFlag.superCalls;
    procedure.stubKind = isForwardingStub
        ? ProcedureStubKind.ConcreteForwardingStub
        : ProcedureStubKind.ConcreteMixinStub;
    procedure.stubTarget = superTarget;
    if (needsSignatureType) {
      procedure.signatureType = signatureType;
    }
  }
}
