// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:kernel/ast.dart"
    show
        Arguments,
        Class,
        DartType,
        Expression,
        FunctionNode,
        Member,
        Name,
        NamedExpression,
        Procedure,
        ProcedureKind,
        ProcedureStubKind,
        ReturnStatement,
        SuperMethodInvocation,
        SuperPropertyGet,
        SuperPropertySet,
        TypeParameterType,
        VariableGet;

import 'package:kernel/transformations/flags.dart' show TransformerFlag;

import "../source/source_class_builder.dart";

import "../problems.dart" show unhandled;

import 'class_hierarchy_builder.dart';
import 'combined_member_signature.dart';

class ForwardingNode {
  final CombinedClassMemberSignature _combinedMemberSignature;

  final ProcedureKind kind;

  ForwardingNode(this._combinedMemberSignature, this.kind);

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
    SourceClassBuilder classBuilder = _combinedMemberSignature.classBuilder;
    ClassMember canonicalMember = _combinedMemberSignature.canonicalMember;
    Member interfaceMember =
        canonicalMember.getMember(_combinedMemberSignature.hierarchy);

    if (_combinedMemberSignature.members.length == 1) {
      // Covariance can only come from [interfaceMember] so we never need a
      // forwarding stub.
      if (_combinedMemberSignature.neededLegacyErasure) {
        return _combinedMemberSignature.createMemberFromSignature(
            // TODO(johnniwinther): Change member signatures to use location
            // of origin.
            copyLocation: false);
      } else {
        // Nothing to do.
        return interfaceMember;
      }
    }

    bool cannotReuseExistingMember =
        !(_combinedMemberSignature.isCanonicalMemberFirst ||
            _combinedMemberSignature.isCanonicalMemberDeclared);
    bool needsTypeOrCovarianceUpdate =
        _combinedMemberSignature.neededNnbdTopMerge ||
            _combinedMemberSignature.neededLegacyErasure ||
            _combinedMemberSignature.needsCovarianceMerging;
    bool stubNeeded = cannotReuseExistingMember ||
        (canonicalMember.classBuilder != classBuilder &&
            needsTypeOrCovarianceUpdate);
    if (stubNeeded) {
      Procedure stub = _combinedMemberSignature.createMemberFromSignature(
          copyLocation: false);
      if (_combinedMemberSignature.needsCovarianceMerging ||
          _combinedMemberSignature.needsSuperImpl) {
        // This is a forward stub.
        Member finalTarget;
        if (interfaceMember is Procedure && interfaceMember.isForwardingStub) {
          finalTarget = interfaceMember.forwardingStubInterfaceTarget;
        } else {
          finalTarget =
              interfaceMember.memberSignatureOrigin ?? interfaceMember;
        }
        stub.stubKind = ProcedureStubKind.ForwardingStub;
        stub.stubTarget = finalTarget;
        if (_combinedMemberSignature.needsSuperImpl) {
          _createForwardingImplIfNeeded(
              stub.function, stub.name, classBuilder.cls);
        }
      }
      return stub;
    } else {
      if (_combinedMemberSignature.needsCovarianceMerging) {
        _combinedMemberSignature.combinedMemberSignatureCovariance
            .applyCovariance(interfaceMember);
      }
      if (_combinedMemberSignature.needsSuperImpl) {
        _createForwardingImplIfNeeded(
            interfaceMember.function, interfaceMember.name, classBuilder.cls);
      }
      return interfaceMember;
    }
  }

  void _createForwardingImplIfNeeded(
      FunctionNode function, Name name, Class enclosingClass) {
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
    Member superTarget = _combinedMemberSignature.hierarchy
        .getDispatchTargetKernel(
            superclass, procedure.name, kind == ProcedureKind.Setter);
    if (superTarget == null) return;
    if (superTarget is Procedure && superTarget.isForwardingStub) {
      Procedure superProcedure = superTarget;
      superTarget = superProcedure.forwardingStubSuperTarget;
    } else {
      superTarget = superTarget.memberSignatureOrigin ?? superTarget;
    }
    procedure.isAbstract = false;
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
    assert(superTarget != null,
        "No super target found for '${name}' in ${enclosingClass}.");
    assert(
        !superTarget.isAbstract,
        "Abstract super target $superTarget found for '${name}' in "
        "${enclosingClass}.");
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
    procedure.stubKind = ProcedureStubKind.ForwardingSuperStub;
    procedure.stubTarget = superTarget;
  }
}
