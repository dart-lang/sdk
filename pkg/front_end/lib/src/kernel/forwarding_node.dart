// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:kernel/ast.dart";
import 'package:kernel/core_types.dart';
import 'package:kernel/names.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/type_algebra.dart';

import "../base/problems.dart" show unhandled;
import '../builder/declaration_builders.dart';
import '../source/source_library_builder.dart';
import 'combined_member_signature.dart';
import 'external_ast_helper.dart' as extern;
import 'hierarchy/class_member.dart';
import 'kernel_helper.dart';
import 'kernel_target.dart';

class ForwardingNode {
  /// The source library containing the [declarationBuilder].
  final SourceLibraryBuilder libraryBuilder;

  /// The class or extension type declaration builder for which the
  /// [_combinedMemberSignature] is computed.
  final DeclarationBuilder declarationBuilder;

  /// The class or extension type declaration node in which a stub is inserted.
  final TypeDeclaration typeDeclaration;

  /// The [IndexedContainer] for the [declarationBuilder].
  final IndexedContainer? indexedContainer;

  /// The combined member signature for all interface members implemented
  /// by the, possibly synthesized, member for which this [ForwardingNode] was
  /// created.
  final CombinedMemberSignatureBase _combinedMemberSignature;

  final ProcedureKind kind;

  /// The concrete member inherited from a superclass, if any.
  final ClassMember? _superClassMember;

  /// The member inherited from a mixin, if any.
  final ClassMember? _mixedInMember;

  /// The target `noSuchMethod` implementation for a noSuchMethod.
  ///
  /// If provided, a noSuchMethod forwarder must be created, unless the
  /// [_superClassMember] is a valid implementation of the interface.
  final ClassMember? _noSuchMethodTarget;

  final bool _declarationIsMixinApplication;

  new(
    this.libraryBuilder,
    this.declarationBuilder,
    this.typeDeclaration,
    this.indexedContainer,
    this._combinedMemberSignature,
    this.kind, {
    ClassMember? superClassMember,
    ClassMember? mixedInMember,
    ClassMember? noSuchMethodTarget,
    required bool declarationIsMixinApplication,
  }) : this._superClassMember = superClassMember,
       this._mixedInMember = mixedInMember,
       this._noSuchMethodTarget = noSuchMethodTarget,
       this._declarationIsMixinApplication = declarationIsMixinApplication;

  /// Finishes handling of this node by propagating covariance and creating
  /// forwarding stubs, mixin stubs, member signature or noSuchMethod forwarders
  /// if necessary.
  ///
  /// If a new member is created, this is returned. Otherwise `null` is
  /// returned.
  Procedure? finalize() {
    ClassMember canonicalMember = _combinedMemberSignature.canonicalMember!;
    Member interfaceMember = canonicalMember.getMember(
      _combinedMemberSignature.membersBuilder,
    );

    // If the class is a mixin application and the member is declared in the
    // mixin, we insert a mixin stub for the member:
    //
    //    class Super { void superMethod() {} }
    //    mixin Mixin { void mixinMethod() {} }
    //    class NamedMixinApplication = Object with Mixin /*
    //      mixin-stub mixinMethod(); // mixin in stub
    //    */;
    bool needMixinStub =
        _declarationIsMixinApplication && _mixedInMember != null;

    // If [_noSuchMethodTarget] is provided, a noSuchMethod forwarder must
    // be created, unless the [_superClassTarget] is a valid implementation.
    bool hasNoSuchMethodTarget = _noSuchMethodTarget != null;

    if (_combinedMemberSignature.members.length == 1 &&
        !needMixinStub &&
        !hasNoSuchMethodTarget) {
      // Coverage-ignore-block(suite): Not run.
      // Optimization: Avoid complex computation for simple scenarios.

      // Covariance can only come from [interfaceMember] so we never need a
      // forwarding stub.
      if (_combinedMemberSignature.neededLegacyErasure) {
        return _combinedMemberSignature.createMemberFromSignature(
          typeDeclaration,
          indexedContainer,
          // TODO(johnniwinther): Change member signatures to use location
          // of origin.
          copyLocation: false,
        );
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
    bool needsSuperImpl = false;
    Member? superTarget;
    bool hasValidImplementation = false;
    if (_superClassMember != null) {
      superTarget = _superClassMember.getMember(
        _combinedMemberSignature.membersBuilder,
      );
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
        if (hasNoSuchMethodTarget) {
          // A noSuchMethod forwarder is needed it the type of the super member
          // differs from the interface member.
          //
          // For instance
          //
          //     class Super {
          //       noSuchMethod(_) => null;
          //       method1(); // noSuchMethod forwarder created for this.
          //       method2(int i); // noSuchMethod forwarder created for this.
          //     }
          //     class Class extends Super {
          //       method1(); // noSuchMethod forwarder from Super is valid.
          //       method2(num i); // A new noSuchMethod forwarder is needed.
          //     }
          //
          DartType superTargetType = _combinedMemberSignature
              .getMemberTypeForTarget(superTarget);
          DartType interfaceMemberType = _combinedMemberSignature
              .getMemberTypeForTarget(interfaceMember);
          hasValidImplementation = superTargetType == interfaceMemberType;
        } else {
          // [superTarget] is a valid implementation for [interfaceMember] so
          // we need to add concrete forwarding stub of the variances differ.
          needsSuperImpl =
              _superClassMember.getCovariance(
                _combinedMemberSignature.membersBuilder,
              ) !=
              _combinedMemberSignature.combinedMemberSignatureCovariance;
          hasValidImplementation = true;
        }
      }
    }
    bool needsNoSuchMethodForwarder =
        hasNoSuchMethodTarget && !hasValidImplementation;
    bool stubNeeded =
        cannotReuseExistingMember ||
        (canonicalMember.declarationBuilder != declarationBuilder &&
            (needsTypeOrCovarianceUpdate || needsNoSuchMethodForwarder)) ||
        needMixinStub;
    if (stubNeeded) {
      Procedure stub = _combinedMemberSignature.createMemberFromSignature(
        typeDeclaration,
        indexedContainer,
        copyLocation: false,
      )!;
      bool needsForwardingStub =
          _combinedMemberSignature.needsCovarianceMerging || needsSuperImpl;
      if (needsForwardingStub || needMixinStub || needsNoSuchMethodForwarder) {
        ProcedureStubKind stubKind;
        Member? finalTarget;
        if (needsNoSuchMethodForwarder) {
          stubKind = ProcedureStubKind.NoSuchMethodForwarder;
          finalTarget = null;
        } else if (needsForwardingStub) {
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
              // Coverage-ignore(suite): Not run.
              case ProcedureStubKind.RepresentationField:
                assert(
                  false,
                  "Unexpected representation field as forwarding stub target "
                  "$interfaceMember.",
                );
                finalTarget = interfaceMember;
                break;
            }
          } else {
            finalTarget = interfaceMember;
          }
        } else {
          stubKind = ProcedureStubKind.AbstractMixinStub;
          finalTarget = _mixedInMember!.getMember(
            _combinedMemberSignature.membersBuilder,
          );
        }

        stub.stubKind = stubKind;
        stub.stubTarget = finalTarget;
        if (needsNoSuchMethodForwarder) {
          _createNoSuchMethodForwarder(
            _noSuchMethodTarget.getMember(
              _combinedMemberSignature.membersBuilder,
            ) as Procedure,
            stub,
          );
        } else if (needsSuperImpl ||
            (needMixinStub && _superClassMember == _mixedInMember)) {
          _createForwardingImplIfNeeded(
            stub.function,
            stub.name,
            superTarget,
            isForwardingStub: needsForwardingStub,
          );
        }
      }

      return stub;
    } else {
      if (_combinedMemberSignature.needsCovarianceMerging) {
        // Coverage-ignore-block(suite): Not run.
        _combinedMemberSignature.combinedMemberSignatureCovariance!
            .applyCovariance(interfaceMember);
      }
      if (needsNoSuchMethodForwarder) {
        assert(
          interfaceMember is Procedure,
          "Unexpected abstract member: ${interfaceMember}",
        );
        (interfaceMember as Procedure).stubKind =
            ProcedureStubKind.NoSuchMethodForwarder;
        interfaceMember.stubTarget = null;
        _createNoSuchMethodForwarder(
          _noSuchMethodTarget.getMember(_combinedMemberSignature.membersBuilder)
              as Procedure,
          interfaceMember,
        );
      } else if (needsSuperImpl) {
        _createForwardingImplIfNeeded(
          interfaceMember.function!,
          interfaceMember.name,
          superTarget,
          isForwardingStub: true,
        );
      }
      return null;
    }
  }

  void _createForwardingImplIfNeeded(
    FunctionNode function,
    Name name,
    Member? superTarget, {
    required bool isForwardingStub,
  }) {
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
    FunctionType signatureType = procedure.function.computeFunctionType(
      procedure.enclosingLibrary.nonNullable,
    );
    bool isForwardingSemiStub = isForwardingStub && !procedure.isSynthetic;
    bool needsSignatureType = false;
    Expression superCall;
    assert(
      !superTarget.isAbstract,
      "Abstract super target $superTarget found for '${name}' in "
      "${typeDeclaration}.",
    );
    switch (kind) {
      case ProcedureKind.Method:
      case ProcedureKind.Operator:
        FunctionType type = _combinedMemberSignature.getMemberTypeForTarget(
          superTarget,
        ) as FunctionType;
        if (type.typeParameters.isNotEmpty) {
          type = FunctionTypeInstantiator.instantiate(
            type,
            function.typeParameters
                .map(
                  (TypeParameter parameter) =>
                      new TypeParameterType.withDefaultNullability(parameter),
                )
                .toList(),
          );
        }
        List<Expression> positionalArguments = new List.generate(
          function.positionalParameters.length,
          (int index) {
            PositionalParameter parameter =
                function.positionalParameters[index];
            int fileOffset = parameter.fileOffset;
            Expression expression = extern.createVariableGet(parameter);
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
              )) {
                expression = extern.createAsExpression(
                  expression,
                  superParameterType,
                  fileOffset: fileOffset,
                );
              }
            }
            return expression;
          },
          growable: true,
        );
        List<NamedExpression> namedArguments = new List.generate(
          function.namedParameters.length,
          (int index) {
            NamedParameter parameter = function.namedParameters[index];
            int fileOffset = parameter.fileOffset;
            Expression expression = extern.createVariableGet(parameter);
            DartType superParameterType = type.namedParameters
                .singleWhere(
                  (NamedType namedType) =>
                      namedType.name == parameter.parameterName,
                )
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
              )) {
                expression = extern.createAsExpression(
                  expression,
                  superParameterType,
                  fileOffset: fileOffset,
                );
              }
            }
            return extern.createNamedExpression(
              parameter.parameterName,
              expression,
            );
          },
          growable: true,
        );
        List<DartType> typeArguments = function.typeParameters
            .map<DartType>(
              (typeParameter) =>
                  new TypeParameterType.withDefaultNullability(typeParameter),
            )
            .toList();
        Arguments arguments = extern.createArguments(
          positionalArguments,
          types: typeArguments,
          named: namedArguments,
          fileOffset: procedure.fileOffset,
        );
        superCall = extern.createSuperMethodInvocation(
          extern.createThisExpression(fileOffset: procedure.fileOffset),
          name,
          superTarget as Procedure,
          arguments,
          fileOffset: procedure.fileOffset,
        );
        break;
      case ProcedureKind.Getter:
        superCall = extern.createSuperPropertyGet(
          extern.createThisExpression(fileOffset: procedure.fileOffset),
          name,
          superTarget,
          fileOffset: procedure.fileOffset,
        );
        break;
      case ProcedureKind.Setter:
        DartType superParameterType = _combinedMemberSignature
            .getMemberTypeForTarget(superTarget);
        Variable parameter = function.positionalParameters[0];
        int fileOffset = parameter.fileOffset;
        Expression expression = extern.createVariableGet(parameter);
        if (isForwardingSemiStub) {
          if (parameter.type != superParameterType) {
            parameter.type = superParameterType;
            needsSignatureType = true;
          }
        } else {
          if (!_combinedMemberSignature.hierarchy.types.isSubtypeOf(
            parameter.type,
            superParameterType,
          )) {
            expression = extern.createAsExpression(
              expression,
              superParameterType,
              fileOffset: fileOffset,
            );
          }
        }
        superCall = extern.createSuperPropertySet(
          extern.createThisExpression(fileOffset: fileOffset),
          name,
          superTarget,
          expression,
          fileOffset: fileOffset,
        );
        break;
      // Coverage-ignore(suite): Not run.
      default:
        unhandled('$kind', '_createForwardingImplIfNeeded', -1, null);
    }
    function.registerFunctionBody(
      extern.createReturnStatement(superCall, fileOffset: procedure.fileOffset),
    );
    procedure.containsSuperCalls = true;
    procedure.stubKind = isForwardingStub
        ? ProcedureStubKind.ConcreteForwardingStub
        : ProcedureStubKind.ConcreteMixinStub;
    procedure.stubTarget = superTarget;
    if (needsSignatureType) {
      procedure.signatureType = signatureType;
    }
  }

  void _createNoSuchMethodForwarder(
    Procedure noSuchMethodInterface,
    Procedure procedure,
  ) {
    bool shouldThrow = false;
    Name procedureName = procedure.name;
    if (procedureName.isPrivate) {
      Library procedureNameLibrary = procedureName.library!;
      // If the name is defined in a different library than the library we're
      // synthesizing a forwarder for, then the forwarder must throw.  This
      // avoids surprising users by ensuring that all non-throwing
      // implementations of a private name can be found solely by looking at the
      // library in which the name is defined; it also avoids soundness holes in
      // field promotion.
      if (procedureNameLibrary.compareTo(procedure.enclosingLibrary) != 0) {
        shouldThrow = true;
      }
    }
    Expression result;
    String prefix = procedure.isGetter
        ? 'get:'
        : procedure.isSetter
        ? 'set:'
        : '';
    String invocationName = prefix + procedureName.text;
    if (procedure.isSetter) invocationName += '=';
    KernelTarget target = libraryBuilder.loader.target;
    CoreTypes coreTypes = target.loader.coreTypes;
    Expression invocation = target.backendTarget.instantiateInvocation(
      coreTypes,
      extern.createThisExpression(fileOffset: procedure.fileOffset),
      invocationName,
      extern.createArgumentsForwarded(
        procedure.function,
        fileOffset: procedure.fileOffset,
      ),
      procedure.fileOffset,
      /*isSuper=*/ false,
    );
    if (shouldThrow) {
      // Build `throw new NoSuchMethodError(this, invocation)`.
      result = extern.createThrow(
        extern.createStaticInvocation(
          coreTypes.noSuchMethodErrorDefaultConstructor,
          extern.createArguments([
            extern.createThisExpression(fileOffset: procedure.fileOffset),
            invocation,
          ], fileOffset: procedure.fileOffset),
          fileOffset: procedure.fileOffset,
        ),
        fileOffset: procedure.fileOffset,
        forErrorHandling: true,
      );
    } else {
      // Build `this.noSuchMethod(invocation)`.
      result = extern.createInstanceInvocation(
        InstanceAccessKind.Instance,
        extern.createThisExpression(fileOffset: procedure.fileOffset),
        noSuchMethodName,
        extern.createArguments([invocation], fileOffset: procedure.fileOffset),
        functionType: noSuchMethodInterface.getterType as FunctionType,
        interfaceTarget: noSuchMethodInterface,
        fileOffset: procedure.fileOffset,
      );
      if (procedure.function.returnType is! VoidType) {
        result = extern.createAsExpression(
          result,
          procedure.function.returnType,
          isTypeError: true,
          isForDynamic: true,
          fileOffset: procedure.fileOffset,
        );
      }
    }

    FunctionType signatureType = procedure.function.computeFunctionType(
      procedure.enclosingLibrary.nonNullable,
    );
    List<PositionalParameter> positionalParameters =
        procedure.function.positionalParameters;
    List<NamedParameter> namedParameters = procedure.function.namedParameters;
    int requiredParameterCount = procedure.function.requiredParameterCount;
    bool hasUpdate = false;
    bool updateNullability(
      FunctionParameter parameter, {
      required bool isRequired,
    }) {
      // Parameters in nnbd libraries that backends might not be able to pass
      // a non-null value for must be nullable. This allows backends to do the
      // appropriate parameter checks in the forwarder stub for null placeholder
      // arguments. Covariance indicates the type must stay the same.
      return !(isRequired ||
              parameter.hasDeclaredDefaultValue ||
              parameter.isCovariantByDeclaration ||
              parameter.isCovariantByClass) &&
          parameter.type.nullability != Nullability.nullable;
    }

    for (int i = 0; i < positionalParameters.length; i++) {
      PositionalParameter parameter = positionalParameters[i];
      bool isRequired = i < requiredParameterCount;
      if (updateNullability(parameter, isRequired: isRequired)) {
        parameter.type = parameter.type.withDeclaredNullability(
          Nullability.nullable,
        );
        hasUpdate = true;
      }
    }

    for (NamedParameter parameter in namedParameters) {
      if (updateNullability(parameter, isRequired: parameter.isRequired)) {
        parameter.type = parameter.type.withDeclaredNullability(
          Nullability.nullable,
        );
        hasUpdate = true;
      }
    }
    if (hasUpdate) {
      procedure.signatureType = signatureType;
    }
    procedure.function.registerFunctionBody(
      extern.createReturnStatement(result, fileOffset: procedure.fileOffset),
    );

    procedure.isAbstract = false;
    procedure.stubKind = ProcedureStubKind.NoSuchMethodForwarder;
    procedure.stubTarget = null;
  }
}
