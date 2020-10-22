// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart' hide MapEntry;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchyBase;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_algebra.dart' show Substitution;
import 'package:kernel/type_environment.dart';

import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/src/nnbd_top_merge.dart';
import 'package:kernel/src/norm.dart';
import 'package:kernel/src/types.dart' show Types;

import '../problems.dart' show unhandled;

import '../source/source_class_builder.dart';

import 'class_hierarchy_builder.dart';

/// Class used for computing and inspecting the combined member signature for
/// a set of overridden/inherited members.
abstract class CombinedMemberSignatureBase<T> {
  ClassHierarchyBase get hierarchy;

  /// The target class for the combined member signature.
  ///
  /// The [_memberTypes] are computed in terms of each member is inherited into
  /// [classBuilder].
  ///
  /// [classBuilder] is also used for determining whether the combined member
  /// signature should be computed using nnbd or legacy semantics.
  final SourceClassBuilder classBuilder;

  /// The list of members from which the combined member signature is computed.
  List<T> get members;

  /// If `true` the combined member signature is for the setter aspect of the
  /// members. Otherwise it is for the getter/method aspect of the members.
  final bool forSetter;

  /// The index within [members] for the member whose type is the most specific
  /// among [members]. If `null`, the combined member signature is not defined
  /// for [members] in [classBuilder].
  ///
  /// For the legacy computation, the type of this member defines the combined
  /// member signature.
  ///
  /// For the nnbd computation, this is one of the members whose type define
  /// the combined member signature, and the indices of the remaining members
  /// are stored in [_mutualSubtypes].
  int _canonicalMemberIndex;

  /// For the nnbd computation, this maps each distinct but most specific member
  /// type to the index of one of the [members] with that type.
  ///
  /// If there is only one most specific member type, this is `null`.
  Map<DartType, int> _mutualSubtypes;

  /// Cache for the types of [members] as inherited into [classBuilder].
  List<DartType> _memberTypes;

  /// Cache for the this type of [classBuilder].
  DartType _thisType;

  /// If `true` the combined member signature type has been computed.
  ///
  /// Note that the combined member signature type might be undefined in which
  /// case [_combinedMemberSignatureType] is `null`.
  bool _isCombinedMemberSignatureTypeComputed = false;

  /// Cache the computed combined member signature type.
  ///
  /// If the combined member signature type is undefined this is set to `null`.
  DartType _combinedMemberSignatureType;

  /// Accumulated result for [neededLegacyErasure]. This is fully computed when
  /// [combinedMemberSignatureType] has been computed.
  bool _neededLegacyErasure = false;

  /// Creates a [CombinedClassMemberSignature] whose canonical member is already
  /// defined.
  CombinedMemberSignatureBase.internal(
      this.classBuilder, this._canonicalMemberIndex, this.forSetter)
      : assert(forSetter != null);

  /// Creates a [CombinedClassMemberSignature] for [members] inherited into
  /// [classBuilder].
  ///
  /// If [forSetter] is `true`, contravariance of the setter types is used to
  /// compute the most specific member type. Otherwise covariance of the getter
  /// types or function types is used.
  CombinedMemberSignatureBase(this.classBuilder, {this.forSetter}) {
    assert(forSetter != null);
    int bestSoFarIndex;
    if (members.length == 1) {
      bestSoFarIndex = 0;
    } else {
      bool isNonNullableByDefault = classBuilder.library.isNonNullableByDefault;

      DartType bestTypeSoFar;
      for (int candidateIndex = members.length - 1;
          candidateIndex >= 0;
          candidateIndex--) {
        DartType candidateType = getMemberType(candidateIndex);
        if (bestSoFarIndex == null) {
          bestTypeSoFar = candidateType;
          bestSoFarIndex = candidateIndex;
        } else {
          if (_isMoreSpecific(candidateType, bestTypeSoFar, forSetter)) {
            if (isNonNullableByDefault &&
                _isMoreSpecific(bestTypeSoFar, candidateType, forSetter)) {
              if (_mutualSubtypes == null) {
                _mutualSubtypes = {
                  bestTypeSoFar: bestSoFarIndex,
                  candidateType: candidateIndex
                };
              } else {
                _mutualSubtypes[candidateType] = candidateIndex;
              }
            } else {
              _mutualSubtypes = null;
            }
            bestSoFarIndex = candidateIndex;
            bestTypeSoFar = candidateType;
          }
        }
      }
      if (_mutualSubtypes?.length == 1) {
        /// If all mutual subtypes have the same type, the type should not
        /// be normalized.
        _mutualSubtypes = null;
      }
      if (bestSoFarIndex != null) {
        for (int candidateIndex = 0;
            candidateIndex < members.length;
            candidateIndex++) {
          DartType candidateType = getMemberType(candidateIndex);
          if (!_isMoreSpecific(bestTypeSoFar, candidateType, forSetter)) {
            if (!shouldOverrideProblemBeOverlooked(classBuilder)) {
              bestSoFarIndex = null;
              bestTypeSoFar = null;
              _mutualSubtypes = null;
            }
            break;
          }
        }
      }
    }

    _canonicalMemberIndex = bestSoFarIndex;
  }

  /// The member within [members] type is the most specific among [members].
  /// If `null`, the combined member signature is not defined for [members] in
  /// [classBuilder].
  ///
  /// For the legacy computation, the type of this member defines the combined
  /// member signature.
  ///
  /// For the nnbd computation, this is one of the members whose type define
  /// the combined member signature, and the indices of the all members whose
  /// type define the combined member signature are in [mutualSubtypeIndices].
  T get canonicalMember =>
      _canonicalMemberIndex != null ? members[_canonicalMemberIndex] : null;

  /// The index within [members] for the member whose type is the most specific
  /// among [members]. If `null`, the combined member signature is not defined
  /// for [members] in [classBuilder].
  ///
  /// For the legacy computation, the type of this member defines the combined
  /// member signature.
  ///
  /// For the nnbd computation, this is one of the members whose type define
  /// the combined member signature, and the indices of the all members whose
  /// type define the combined member signature are in [mutualSubtypeIndices].
  int get canonicalMemberIndex => _canonicalMemberIndex;

  /// For the nnbd computation, the indices of the [members] with most specific
  /// member type.
  ///
  /// If there is only one most specific member type, this is `null`.
  Set<int> get mutualSubtypeIndices => _mutualSubtypes?.values?.toSet();

  Member _getMember(int index);

  CoreTypes get _coreTypes => hierarchy.coreTypes;

  Types get _types;

  /// Returns `true` if legacy erasure was needed to compute the combined
  /// member signature type.
  ///
  /// Legacy erasure is considered need of if the used of it resulted in a
  /// different type.
  bool get neededLegacyErasure {
    _ensureCombinedMemberSignatureType();
    return _neededLegacyErasure;
  }

  /// The this type of [classBuilder].
  DartType get thisType {
    return _thisType ??= _coreTypes.thisInterfaceType(
        classBuilder.cls, classBuilder.library.nonNullable);
  }

  /// Returns type of the [index]th member in [members] as inherited in
  /// [classBuilder].
  DartType getMemberType(int index) {
    _memberTypes ??= new List<DartType>(members.length);
    DartType candidateType = _memberTypes[index];
    if (candidateType == null) {
      Member target = _getMember(index);
      assert(target != null,
          "No member computed for index ${index} in ${members}");
      candidateType = _computeMemberType(thisType, target);
      if (!classBuilder.library.isNonNullableByDefault) {
        DartType legacyErasure = rawLegacyErasure(_coreTypes, candidateType);
        if (legacyErasure != null) {
          _neededLegacyErasure = true;
          candidateType = legacyErasure;
        }
      }
      _memberTypes[index] = candidateType;
    }
    return candidateType;
  }

  void _ensureCombinedMemberSignatureType() {
    if (!_isCombinedMemberSignatureTypeComputed) {
      _isCombinedMemberSignatureTypeComputed = true;
      if (_canonicalMemberIndex == null) {
        return null;
      }
      if (classBuilder.library.isNonNullableByDefault) {
        _combinedMemberSignatureType = getMemberType(_canonicalMemberIndex);
        if (_mutualSubtypes != null) {
          _combinedMemberSignatureType =
              norm(_coreTypes, _combinedMemberSignatureType);
          for (int index in _mutualSubtypes.values) {
            if (_canonicalMemberIndex != index) {
              _combinedMemberSignatureType = nnbdTopMerge(
                  _coreTypes,
                  _combinedMemberSignatureType,
                  norm(_coreTypes, getMemberType(index)));
            }
          }
        }
      } else {
        _combinedMemberSignatureType = getMemberType(_canonicalMemberIndex);
      }
    }
  }

  /// Returns the type of the combined member signature, if defined.
  DartType get combinedMemberSignatureType {
    _ensureCombinedMemberSignatureType();
    return _combinedMemberSignatureType;
  }

  /// Returns the type of the combined member signature, if defined, with
  /// all method type parameters substituted with [typeParameters].
  ///
  /// This is used for inferring types on a declared member from the type of the
  /// combined member signature.
  DartType getCombinedSignatureTypeInContext(
      List<TypeParameter> typeParameters) {
    DartType type = combinedMemberSignatureType;
    if (type == null) {
      return null;
    }
    int typeParameterCount = typeParameters.length;
    if (type is FunctionType) {
      List<TypeParameter> signatureTypeParameters = type.typeParameters;
      if (typeParameterCount != signatureTypeParameters.length) {
        return null;
      }
      if (typeParameterCount == 0) {
        return type;
      }
      List<DartType> types = new List<DartType>(typeParameterCount);
      for (int i = 0; i < typeParameterCount; i++) {
        types[i] = new TypeParameterType.forAlphaRenaming(
            signatureTypeParameters[i], typeParameters[i]);
      }
      Substitution substitution =
          Substitution.fromPairs(signatureTypeParameters, types);
      for (int i = 0; i < typeParameterCount; i++) {
        DartType typeParameterBound = typeParameters[i].bound;
        DartType signatureTypeParameterBound =
            substitution.substituteType(signatureTypeParameters[i].bound);
        if (!_types
            .performNullabilityAwareMutualSubtypesCheck(
                typeParameterBound, signatureTypeParameterBound)
            .isSubtypeWhenUsingNullabilities()) {
          return null;
        }
      }
      return substitution.substituteType(type.withoutTypeParameters);
    } else if (typeParameterCount != 0) {
      return null;
    }
    return type;
  }

  /// Create a member signature with the [combinedMemberSignatureType] using the
  /// [canonicalMember] as member signature origin.
  Procedure createMemberFromSignature() {
    if (canonicalMemberIndex == null) {
      return null;
    }
    Member member = _getMember(canonicalMemberIndex);
    if (member is Procedure) {
      switch (member.kind) {
        case ProcedureKind.Getter:
          return _createGetterMemberSignature(
              member, combinedMemberSignatureType);
        case ProcedureKind.Setter:
          VariableDeclaration parameter =
              member.function.positionalParameters.first;
          return _createSetterMemberSignature(
              member, combinedMemberSignatureType,
              isGenericCovariantImpl: parameter.isGenericCovariantImpl,
              isCovariant: parameter.isCovariant,
              parameterName: parameter.name);
        case ProcedureKind.Method:
        case ProcedureKind.Operator:
          return _createMethodSignature(member, combinedMemberSignatureType);
        case ProcedureKind.Factory:
        default:
          throw new UnsupportedError(
              'Unexpected canonical member kind ${member.kind} for $member');
      }
    } else if (member is Field) {
      if (forSetter) {
        return _createSetterMemberSignature(member, combinedMemberSignatureType,
            isGenericCovariantImpl: member.isGenericCovariantImpl,
            isCovariant: member.isCovariant);
      } else {
        return _createGetterMemberSignature(
            member, combinedMemberSignatureType);
      }
    } else {
      throw new UnsupportedError(
          'Unexpected canonical member $member (${member.runtimeType})');
    }
  }

  /// Creates a getter member signature for [member] with the given
  /// [type].
  Member _createGetterMemberSignature(Member member, DartType type) {
    Class enclosingClass = classBuilder.cls;
    Procedure referenceFrom;
    if (classBuilder.referencesFromIndexed != null) {
      referenceFrom = classBuilder.referencesFromIndexed
          .lookupProcedureNotSetter(member.name.text);
    }
    Uri fileUri = member.fileUri;
    int startFileOffset =
        member is Procedure ? member.startFileOffset : member.fileOffset;
    int fileOffset = member.fileOffset;
    return new Procedure(member.name, ProcedureKind.Getter,
        new FunctionNode(null, returnType: type),
        isAbstract: true,
        isMemberSignature: true,
        fileUri: fileUri,
        memberSignatureOrigin: member.memberSignatureOrigin ?? member,
        reference: referenceFrom?.reference)
      ..startFileOffset = startFileOffset
      ..fileOffset = fileOffset
      ..parent = enclosingClass;
  }

  /// Creates a setter member signature for [member] with the given
  /// [type]. The flags of parameter is set according to [isCovariant] and
  /// [isGenericCovariantImpl] and the [parameterName] is used, if provided.
  Member _createSetterMemberSignature(Member member, DartType type,
      {bool isCovariant, bool isGenericCovariantImpl, String parameterName}) {
    assert(isCovariant != null);
    assert(isGenericCovariantImpl != null);
    Class enclosingClass = classBuilder.cls;
    Procedure referenceFrom;
    if (classBuilder.referencesFromIndexed != null) {
      referenceFrom = classBuilder.referencesFromIndexed
          .lookupProcedureSetter(member.name.text);
    }
    Uri fileUri = member.fileUri;
    int startFileOffset =
        member is Procedure ? member.startFileOffset : member.fileOffset;
    int fileOffset = member.fileOffset;
    return new Procedure(
        member.name,
        ProcedureKind.Setter,
        new FunctionNode(null,
            returnType: const VoidType(),
            positionalParameters: [
              new VariableDeclaration(parameterName ?? 'value',
                  type: type, isCovariant: isCovariant)
                ..isGenericCovariantImpl = isGenericCovariantImpl
            ]),
        isAbstract: true,
        isMemberSignature: true,
        fileUri: fileUri,
        memberSignatureOrigin: member.memberSignatureOrigin ?? member,
        reference: referenceFrom?.reference)
      ..startFileOffset = startFileOffset
      ..fileOffset = fileOffset
      ..parent = enclosingClass;
  }

  Member _createMethodSignature(
      Procedure procedure, FunctionType functionType) {
    Class enclosingClass = classBuilder.cls;
    Procedure referenceFrom;
    if (classBuilder.referencesFromIndexed != null) {
      referenceFrom = classBuilder.referencesFromIndexed
          .lookupProcedureNotSetter(procedure.name.text);
    }
    Uri fileUri = procedure.fileUri;
    int startFileOffset = procedure.startFileOffset;
    int fileOffset = procedure.fileOffset;
    FunctionNode function = procedure.function;
    List<VariableDeclaration> positionalParameters = [];
    for (int i = 0; i < function.positionalParameters.length; i++) {
      VariableDeclaration parameter = function.positionalParameters[i];
      DartType parameterType = functionType.positionalParameters[i];
      if (i == 0 && procedure == hierarchy.coreTypes.objectEquals) {
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
      NamedType namedType = functionType.namedParameters.first;
      VariableDeclaration parameter = function.namedParameters.first;
      namedParameters.add(new VariableDeclaration(parameter.name,
          type: namedType.type, isCovariant: parameter.isCovariant)
        ..isGenericCovariantImpl = parameter.isGenericCovariantImpl);
    } else if (namedParameterCount > 1) {
      Map<String, DartType> namedTypes = {};
      for (NamedType namedType in functionType.namedParameters) {
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
        procedure.name,
        procedure.kind,
        new FunctionNode(null,
            typeParameters: functionType.typeParameters,
            returnType: functionType.returnType,
            positionalParameters: positionalParameters,
            namedParameters: namedParameters,
            requiredParameterCount: function.requiredParameterCount),
        isAbstract: true,
        isMemberSignature: true,
        fileUri: fileUri,
        memberSignatureOrigin: procedure.memberSignatureOrigin ?? procedure,
        reference: referenceFrom?.reference)
      ..startFileOffset = startFileOffset
      ..fileOffset = fileOffset
      ..parent = enclosingClass;
  }

  DartType _computeMemberType(DartType thisType, Member member) {
    DartType type;
    if (member is Procedure) {
      if (member.isGetter) {
        type = member.getterType;
      } else if (member.isSetter) {
        type = member.setterType;
      } else {
        type = member.function
            .computeFunctionType(classBuilder.cls.enclosingLibrary.nonNullable);
      }
    } else if (member is Field) {
      type = member.type;
    } else {
      unhandled("${member.runtimeType}", "$member", classBuilder.charOffset,
          classBuilder.fileUri);
    }
    if (member.enclosingClass.typeParameters.isEmpty) {
      return type;
    }
    InterfaceType instance = hierarchy.getTypeAsInstanceOf(
        thisType,
        member.enclosingClass,
        classBuilder.library.library,
        hierarchy.coreTypes);
    assert(
        instance != null,
        "No instance of $thisType as ${member.enclosingClass} found for "
        "$member.");
    return Substitution.fromInterfaceType(instance).substituteType(type);
  }

  bool _isMoreSpecific(DartType a, DartType b, bool forSetter) {
    if (forSetter) {
      return _types.isSubtypeOf(b, a, SubtypeCheckMode.withNullabilities);
    } else {
      return _types.isSubtypeOf(a, b, SubtypeCheckMode.withNullabilities);
    }
  }
}

/// Class used for computing and inspecting the combined member signature for
/// a set of overridden/inherited [ClassMember]s.
class CombinedClassMemberSignature
    extends CombinedMemberSignatureBase<ClassMember> {
  /// The class hierarchy builder used for building this class.
  final ClassHierarchyBuilder hierarchy;

  /// The list of the members inherited into or overridden in [classBuilder].
  final List<ClassMember> members;

  /// Creates a [CombinedClassMemberSignature] whose canonical member is already
  /// defined.
  CombinedClassMemberSignature.internal(this.hierarchy,
      SourceClassBuilder classBuilder, int canonicalMemberIndex, this.members,
      {bool forSetter})
      : super.internal(classBuilder, canonicalMemberIndex, forSetter);

  /// Creates a [CombinedClassMemberSignature] for [members] inherited into
  /// [classBuilder].
  ///
  /// If [forSetter] is `true`, contravariance of the setter types is used to
  /// compute the most specific member type. Otherwise covariance of the getter
  /// types or function types is used.
  CombinedClassMemberSignature(
      this.hierarchy, SourceClassBuilder classBuilder, this.members,
      {bool forSetter})
      : super(classBuilder, forSetter: forSetter);

  Types get _types => hierarchy.types;

  Member _getMember(int index) {
    ClassMember candidate = members[index];
    Member target = candidate.getMember(hierarchy);
    assert(target != null,
        "No member computed for ${candidate} (${candidate.runtimeType})");
    return target;
  }
}

/// Class used for computing and inspecting the combined member signature for
/// a set of overridden/inherited [Member]s.
class CombinedMemberSignatureBuilder
    extends CombinedMemberSignatureBase<Member> {
  @override
  final ClassHierarchyBase hierarchy;

  @override
  final Types _types;

  @override
  final List<Member> members;

  CombinedMemberSignatureBuilder(
      this.hierarchy, SourceClassBuilder classBuilder, this.members,
      {bool forSetter})
      : _types = new Types(hierarchy),
        super(classBuilder, forSetter: forSetter);

  @override
  Member _getMember(int index) => members[index];
}
