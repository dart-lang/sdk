// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';

import '../class_hierarchy.dart' show ClassHierarchyBase;

import '../core_types.dart' show CoreTypes;

import '../type_algebra.dart'
    show FunctionTypeInstantiator, combineNullabilitiesForSubstitution;

import '../type_environment.dart' show IsSubtypeOf, SubtypeCheckMode;

import '../src/standard_bounds.dart';

class Types with StandardBounds {
  @override
  final ClassHierarchyBase hierarchy;

  Types(this.hierarchy);

  @override
  CoreTypes get coreTypes => hierarchy.coreTypes;

  @override
  bool areMutualSubtypes(DartType s, DartType t, SubtypeCheckMode mode) {
    IsSubtypeOf result = performNullabilityAwareMutualSubtypesCheck(s, t);
    switch (mode) {
      case SubtypeCheckMode.ignoringNullabilities:
        return result.isSubtypeWhenIgnoringNullabilities();
      case SubtypeCheckMode.withNullabilities:
        return result.isSubtypeWhenUsingNullabilities();
    }
  }

  bool _isSubtypeFromMode(IsSubtypeOf isSubtypeOf, SubtypeCheckMode mode) {
    switch (mode) {
      case SubtypeCheckMode.withNullabilities:
        return isSubtypeOf.isSubtypeWhenUsingNullabilities();
      case SubtypeCheckMode.ignoringNullabilities:
        return isSubtypeOf.isSubtypeWhenIgnoringNullabilities();
    }
  }

  /// Returns true if [s] is a subtype of [t].
  @override
  bool isSubtypeOf(DartType s, DartType t, SubtypeCheckMode mode) {
    IsSubtypeOf result = performNullabilityAwareSubtypeCheck(s, t);
    return _isSubtypeFromMode(result, mode);
  }

  /// Can be use to collect type checks. To use:
  /// 1. Rename `performNullabilityAwareSubtypeCheck` to
  ///    `_performNullabilityAwareSubtypeCheck`.
  /// 2. Rename `_collect_performNullabilityAwareSubtypeCheck` to
  ///    `performNullabilityAwareSubtypeCheck`.
  /// 3. Comment out the call to `_performNullabilityAwareSubtypeCheck` below.
  // ignore:unused_element
  bool _collect_performNullabilityAwareSubtypeCheck(
      DartType subtype, DartType supertype, SubtypeCheckMode mode) {
    IsSubtypeOf result = const IsSubtypeOf.always();
    //result = _performNullabilityAwareSubtypeCheck(subtype, supertype, mode);
    bool booleanResult = _isSubtypeFromMode(result, mode);
    (typeChecksForTesting ??= <Object>[])
        .add([subtype, supertype, booleanResult]);
    return booleanResult;
  }

  IsSubtypeOf performNullabilityAwareSubtypeCheck(DartType s, DartType t) {
    switch ((s, t)) {
      // TODO(johnniwinther,cstefantsova): Ensure complete handling of
      // InvalidType in the subtype relation.
      case (InvalidType(), _):
      case (_, InvalidType()):
        return const IsSubtypeOf.always();

      // Rule 2.
      case (_, DynamicType()):
        return const IsSubtypeOf.always();

      // Rule 2.
      case (_, VoidType()):
        return const IsSubtypeOf.always();

      case (NeverType(), _):
        return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);

      // Rule 4.
      case (NullType(), _):
        return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);

      case (
            ExtensionType(),
            InterfaceType(classReference: Reference tClassReference)
          )
          when tClassReference == hierarchy.coreTypes.objectClass.reference &&
              s.extensionTypeErasure.isPotentiallyNullable &&
              !t.isPotentiallyNullable:
        return new IsSubtypeOf.onlyIfIgnoringNullabilities(
            subtype: s, supertype: t);
      case (_, InterfaceType(classReference: Reference tClassReference))
          when tClassReference == hierarchy.coreTypes.objectClass.reference &&
              s is! FutureOrType:
        return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);

      case (DynamicType(), InterfaceType()):
        return const IsSubtypeOf.never();

      case (VoidType(), InterfaceType()):
        return const IsSubtypeOf.never();

      case (InterfaceType sInterfaceType, InterfaceType tInterfaceType):
        List<DartType>? asSupertypeArguments;
        if (sInterfaceType.classReference == tInterfaceType.classReference) {
          asSupertypeArguments = sInterfaceType.typeArguments;
        } else {
          asSupertypeArguments =
              hierarchy.getInterfaceTypeArgumentsAsInstanceOfClass(
                  sInterfaceType, tInterfaceType.classNode);
        }
        if (asSupertypeArguments == null) {
          return const IsSubtypeOf.never();
        }
        if (asSupertypeArguments.isEmpty) {
          return const IsSubtypeOf.always().and(
              new IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(
                  sInterfaceType, tInterfaceType));
        }
        return areTypeArgumentsOfSubtypeKernel(
                asSupertypeArguments,
                tInterfaceType.typeArguments,
                tInterfaceType.classNode.typeParameters)
            .and(new IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(
                sInterfaceType, tInterfaceType));

      case (FunctionType sFunctionType, InterfaceType tInterfaceType):
        return tInterfaceType.classNode == hierarchy.coreTypes.functionClass
            ? new IsSubtypeOf.basedSolelyOnNullabilities(
                sFunctionType, tInterfaceType)
            : const IsSubtypeOf.never();

      case (TypeParameterType sTypeParameterType, InterfaceType tInterfaceType):
        return performNullabilityAwareSubtypeCheck(
                sTypeParameterType.parameter.bound, tInterfaceType)
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sTypeParameterType, tInterfaceType));

      case (
          StructuralParameterType sStructuralParameterType,
          InterfaceType tInterfaceType
        ):
        return performNullabilityAwareSubtypeCheck(
                sStructuralParameterType.parameter.bound, tInterfaceType)
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sStructuralParameterType, tInterfaceType));

      case (IntersectionType sIntersectionType, InterfaceType tInterfaceType):
        return performNullabilityAwareSubtypeCheck(
            sIntersectionType.right, tInterfaceType);

      case (TypedefType sTypedefType, InterfaceType tInterfaceType):
        return performNullabilityAwareSubtypeCheck(
                sTypedefType.unalias, tInterfaceType)
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sTypedefType, tInterfaceType));

      case (FutureOrType sFutureOrType, InterfaceType tInterfaceType):
        return performNullabilityAwareSubtypeCheck(
                new InterfaceType(hierarchy.coreTypes.futureClass,
                    Nullability.nonNullable, [sFutureOrType.typeArgument]),
                tInterfaceType)
            .andSubtypeCheckFor(
                sFutureOrType.typeArgument, tInterfaceType, this)
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sFutureOrType, tInterfaceType));

      case (RecordType sRecordType, InterfaceType tInterfaceType):
        return tInterfaceType.classNode == hierarchy.coreTypes.recordClass
            ? new IsSubtypeOf.basedSolelyOnNullabilities(
                sRecordType, tInterfaceType)
            : const IsSubtypeOf.never();

      case (ExtensionType sExtensionType, InterfaceType tInterfaceType):
        List<DartType>? asSupertypeArguments =
            hierarchy.getExtensionTypeArgumentsAsInstanceOfClass(
                sExtensionType, tInterfaceType.classNode);
        if (asSupertypeArguments == null) {
          return const IsSubtypeOf.never();
        }
        if (asSupertypeArguments.isEmpty) {
          return const IsSubtypeOf.always().and(
              new IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(s, t));
        }
        return areTypeArgumentsOfSubtypeKernel(
                asSupertypeArguments,
                tInterfaceType.typeArguments,
                tInterfaceType.classNode.typeParameters)
            .and(new IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(
                sExtensionType, tInterfaceType));

      case (DynamicType(), FunctionType()):
        return const IsSubtypeOf.never();

      case (VoidType(), FunctionType()):
        return const IsSubtypeOf.never();

      case (InterfaceType(), FunctionType()):
        return const IsSubtypeOf.never();

      case (FunctionType sFunctionType, FunctionType tFunctionType):
        List<StructuralParameter> sTypeVariables = sFunctionType.typeParameters;
        List<StructuralParameter> tTypeVariables = tFunctionType.typeParameters;
        if (sTypeVariables.length != tTypeVariables.length) {
          return const IsSubtypeOf.never();
        }
        IsSubtypeOf result = const IsSubtypeOf.always();
        if (sTypeVariables.isNotEmpty) {
          // If the function types have type variables, we alpha-rename the type
          // variables of [s] to use those of [t].

          // As an optimization, we first check if the bounds of the type
          // variables of the two types on the same positions are mutual
          // subtypes without alpha-renaming them.
          List<DartType> typeVariableSubstitution = <DartType>[];
          for (int i = 0; i < sTypeVariables.length; i++) {
            StructuralParameter sTypeVariable = sTypeVariables[i];
            StructuralParameter tTypeVariable = tTypeVariables[i];
            result = result.and(performNullabilityAwareMutualSubtypesCheck(
                sTypeVariable.bound, tTypeVariable.bound));
            typeVariableSubstitution.add(
                new StructuralParameterType.forAlphaRenaming(
                    sTypeVariable, tTypeVariable));
          }
          FunctionTypeInstantiator instantiator =
              FunctionTypeInstantiator.fromIterables(
                  sTypeVariables, typeVariableSubstitution);
          // If the bounds aren't the same, we need to try again after computing
          // the substitution of type variables.
          if (!result.isSubtypeWhenIgnoringNullabilities()) {
            result = const IsSubtypeOf.always();
            for (int i = 0; i < sTypeVariables.length; i++) {
              StructuralParameter sTypeVariable = sTypeVariables[i];
              StructuralParameter tTypeVariable = tTypeVariables[i];
              result = result.and(performNullabilityAwareMutualSubtypesCheck(
                  instantiator.substitute(sTypeVariable.bound),
                  tTypeVariable.bound));
              if (!result.isSubtypeWhenIgnoringNullabilities()) {
                return const IsSubtypeOf.never();
              }
            }
          }
          sFunctionType = instantiator
              .substitute(sFunctionType.withoutTypeParameters) as FunctionType;
        }
        result = result.and(performNullabilityAwareSubtypeCheck(
            sFunctionType.returnType, tFunctionType.returnType));
        if (!result.isSubtypeWhenIgnoringNullabilities()) {
          return const IsSubtypeOf.never();
        }
        List<DartType> sPositional = sFunctionType.positionalParameters;
        List<DartType> tPositional = tFunctionType.positionalParameters;
        if (sFunctionType.requiredParameterCount >
            tFunctionType.requiredParameterCount) {
          // Rule 15, n1 <= n2.
          return const IsSubtypeOf.never();
        }
        if (sPositional.length < tPositional.length) {
          // Rule 15, n1 + k1 >= n2 + k2.
          return const IsSubtypeOf.never();
        }
        for (int i = 0; i < tPositional.length; i++) {
          result = result.and(performNullabilityAwareSubtypeCheck(
              tPositional[i], sPositional[i]));
          if (!result.isSubtypeWhenIgnoringNullabilities()) {
            // Rule 15, Tj <: Sj.
            return const IsSubtypeOf.never();
          }
        }
        List<NamedType> sNamedParameters = sFunctionType.namedParameters;
        List<NamedType> tNamedParameters = tFunctionType.namedParameters;
        if (sNamedParameters.isNotEmpty || tNamedParameters.isNotEmpty) {
          // Rule 16, the number of positional parameters must be the same.
          if (sPositional.length != tPositional.length) {
            return const IsSubtypeOf.never();
          }
          if (sFunctionType.requiredParameterCount !=
              tFunctionType.requiredParameterCount) {
            return const IsSubtypeOf.never();
          }

          // Rule 16, the parameter names of [t] must be a subset of those of
          // [s]. Also, for the intersection, the type of the parameter of [t]
          // must be a subtype of the type of the parameter of [s].
          int sCount = 0;
          for (int tCount = 0; tCount < tNamedParameters.length; tCount++) {
            NamedType tNamedParameter = tNamedParameters[tCount];
            String name = tNamedParameter.name;
            NamedType? sNamedParameter;
            for (; sCount < sNamedParameters.length; sCount++) {
              sNamedParameter = sNamedParameters[sCount];
              if (sNamedParameter.name == name) {
                break;
              } else if (sNamedParameter.isRequired) {
                /// From the NNBD spec: For each j such that r0j is required,
                /// then there exists an i in n+1...q such that xj = yi, and r1i
                /// is required
                result = result.and(new IsSubtypeOf.onlyIfIgnoringNullabilities(
                    subtype: sFunctionType, supertype: tFunctionType));
              }
            }
            if (sCount == sNamedParameters.length) {
              return const IsSubtypeOf.never();
            }
            // Increment [sCount] so we don't check [sNamedParameter] again in
            // the loop above or below and assume it is an extra (unmatched)
            // parameter.
            sCount++;
            result = result.and(performNullabilityAwareSubtypeCheck(
                tNamedParameter.type, sNamedParameter!.type));
            if (!result.isSubtypeWhenIgnoringNullabilities()) {
              return const IsSubtypeOf.never();
            }

            /// From the NNBD spec: For each j such that r0j is required, then
            /// there exists an i in n+1...q such that xj = yi, and r1i is
            /// required
            if (sNamedParameter.isRequired && !tNamedParameter.isRequired) {
              result = result.and(new IsSubtypeOf.onlyIfIgnoringNullabilities(
                  subtype: sFunctionType, supertype: tFunctionType));
            }
          }
          for (; sCount < sNamedParameters.length; sCount++) {
            NamedType sNamedParameter = sNamedParameters[sCount];
            if (sNamedParameter.isRequired) {
              /// From the NNBD spec: For each j such that r0j is required, then
              /// there exists an i in n+1...q such that xj = yi, and r1i is
              /// required
              result = result.and(new IsSubtypeOf.onlyIfIgnoringNullabilities(
                  subtype: sFunctionType, supertype: tFunctionType));
            }
          }
        }
        return result.and(new IsSubtypeOf.basedSolelyOnNullabilities(
            sFunctionType, tFunctionType));

      case (TypeParameterType sTypeParameterType, FunctionType tFunctionType):
        return performNullabilityAwareSubtypeCheck(
                sTypeParameterType.parameter.bound, tFunctionType)
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sTypeParameterType, tFunctionType));

      case (
          StructuralParameterType sStructuralParameterType,
          FunctionType tFunctionType
        ):
        return performNullabilityAwareSubtypeCheck(
                sStructuralParameterType.parameter.bound, tFunctionType)
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sStructuralParameterType, tFunctionType));

      case (IntersectionType sIntersectionType, FunctionType tFunctionType):
        return performNullabilityAwareSubtypeCheck(
            sIntersectionType.right, tFunctionType);

      case (TypedefType sTypedefType, FunctionType tFunctionType):
        return performNullabilityAwareSubtypeCheck(
            sTypedefType.unalias, tFunctionType);

      case (FutureOrType(), FunctionType()):
        return const IsSubtypeOf.never();

      case (RecordType(), FunctionType()):
        return const IsSubtypeOf.never();

      case (ExtensionType(), FunctionType()):
        return const IsSubtypeOf.never();

      case (DynamicType(), TypeParameterType()):
        return const IsSubtypeOf.never();

      case (VoidType(), TypeParameterType()):
        return const IsSubtypeOf.never();

      case (InterfaceType(), TypeParameterType()):
        return const IsSubtypeOf.never();

      case (FunctionType(), TypeParameterType()):
        return const IsSubtypeOf.never();

      case (
          TypeParameterType sTypeParameterType,
          TypeParameterType tTypeParameterType
        ):
        IsSubtypeOf result = const IsSubtypeOf.always();
        if (sTypeParameterType.parameter != tTypeParameterType.parameter) {
          result =
              performNullabilityAwareSubtypeCheck(sTypeParameterType.bound, t);
        }
        if (sTypeParameterType.nullability == Nullability.undetermined &&
            tTypeParameterType.nullability == Nullability.undetermined) {
          // The two nullabilities are undetermined, but are connected via
          // additional constraint, namely that they will be equal at run time.
          return result;
        }
        return result.and(new IsSubtypeOf.basedSolelyOnNullabilities(
            sTypeParameterType, tTypeParameterType));

      case (
          StructuralParameterType sStructuralParameterType,
          TypeParameterType tTypeParameterType
        ):
        IsSubtypeOf result = performNullabilityAwareSubtypeCheck(
            sStructuralParameterType.bound, t);
        if (sStructuralParameterType.nullability == Nullability.undetermined &&
            tTypeParameterType.nullability == Nullability.undetermined) {
          // The two nullabilities are undetermined, but are connected via
          // additional constraint, namely that they will be equal at run time.
          return result;
        }
        return result.and(new IsSubtypeOf.basedSolelyOnNullabilities(
            sStructuralParameterType, tTypeParameterType));

      case (
          IntersectionType sIntersectionType,
          TypeParameterType tTypeParameterType
        ):
        // Nullable types aren't promoted to intersection types.
        // TODO(cstefantsova): Uncomment the following when the inference is
        // updated.
        //assert(
        //  intersection.typeParameterTypeNullability != Nullability.nullable);

        // Rule 8.
        if (sIntersectionType.left.parameter == tTypeParameterType.parameter) {
          if (sIntersectionType.nullability == Nullability.undetermined &&
              t.nullability == Nullability.undetermined) {
            // The two nullabilities are undetermined, but are connected via
            // additional constraint, namely that they will be equal at run
            // time.
            return const IsSubtypeOf.always();
          }
          return new IsSubtypeOf.basedSolelyOnNullabilities(
              sIntersectionType, t);
        }

        // Rule 12.
        return performNullabilityAwareSubtypeCheck(
            sIntersectionType.right
                .withDeclaredNullability(sIntersectionType.nullability),
            t);

      case (TypedefType sTypedefType, TypeParameterType tTypeParameterType):
        return performNullabilityAwareSubtypeCheck(
            sTypedefType.unalias, tTypeParameterType);

      case (FutureOrType(), TypeParameterType()):
        return const IsSubtypeOf.never();

      case (RecordType(), TypeParameterType()):
        return const IsSubtypeOf.never();

      case (ExtensionType(), TypeParameterType()):
        return const IsSubtypeOf.never();

      case (DynamicType(), StructuralParameterType()):
        return const IsSubtypeOf.never();

      case (VoidType(), StructuralParameterType()):
        return const IsSubtypeOf.never();

      case (InterfaceType(), StructuralParameterType()):
        return const IsSubtypeOf.never();

      case (FunctionType(), StructuralParameterType()):
        return const IsSubtypeOf.never();

      case (TypeParameterType(), StructuralParameterType()):
        return const IsSubtypeOf.never();

      case (
          StructuralParameterType sStructuralParameterType,
          StructuralParameterType tStructuralParameterType
        ):
        IsSubtypeOf result = const IsSubtypeOf.always();
        if (sStructuralParameterType.parameter !=
            tStructuralParameterType.parameter) {
          result = performNullabilityAwareSubtypeCheck(
              sStructuralParameterType.bound, t);
        }
        if (sStructuralParameterType.nullability == Nullability.undetermined &&
            tStructuralParameterType.nullability == Nullability.undetermined) {
          // The two nullabilities are undetermined, but are connected via
          // additional constraint, namely that they will be equal at run time.
          return result;
        }
        return result.and(new IsSubtypeOf.basedSolelyOnNullabilities(
            sStructuralParameterType, tStructuralParameterType));

      case (IntersectionType(), StructuralParameterType()):
        return const IsSubtypeOf.never();

      case (
          TypedefType sTypedefType,
          StructuralParameterType tStructuralParameterType
        ):
        return performNullabilityAwareSubtypeCheck(
            sTypedefType.unalias, tStructuralParameterType);

      case (FutureOrType(), StructuralParameterType()):
        return const IsSubtypeOf.never();

      case (RecordType(), StructuralParameterType()):
        return const IsSubtypeOf.never();

      case (ExtensionType(), StructuralParameterType()):
        return const IsSubtypeOf.never();

      case (DynamicType(), IntersectionType()):
        return const IsSubtypeOf.never();

      case (VoidType(), IntersectionType()):
        return const IsSubtypeOf.never();

      case (InterfaceType(), IntersectionType()):
        return const IsSubtypeOf.never();

      case (FunctionType(), IntersectionType()):
        return const IsSubtypeOf.never();

      case (
          TypeParameterType sTypeParameterType,
          IntersectionType tIntersectionType
        ):
        IsSubtypeOf result = const IsSubtypeOf.always();
        if (sTypeParameterType.parameter != tIntersectionType.left.parameter) {
          result =
              performNullabilityAwareSubtypeCheck(sTypeParameterType.bound, t);
        }
        if (sTypeParameterType.nullability == Nullability.undetermined &&
            tIntersectionType.left.nullability == Nullability.undetermined) {
          // The two nullabilities are undetermined, but are connected via
          // additional constraint, namely that they will be equal at run time.
          return result.andSubtypeCheckFor(
              sTypeParameterType, tIntersectionType.right, this);
        }
        return result
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sTypeParameterType, tIntersectionType.left))
            .andSubtypeCheckFor(
                sTypeParameterType, tIntersectionType.right, this);

      case (StructuralParameterType(), IntersectionType()):
        return const IsSubtypeOf.never();

      case (
          IntersectionType sIntersectionType,
          IntersectionType tIntersectionType
        ):
        // Nullable types aren't promoted to intersection types.
        // TODO(cstefantsova): Uncomment the following when the inference is
        // updated.
        //assert(
        //  intersection.typeParameterTypeNullability != Nullability.nullable);
        IsSubtypeOf tLeftResult;

        // Rule 8.
        if (sIntersectionType.left.parameter ==
            tIntersectionType.left.parameter) {
          if (sIntersectionType.nullability == Nullability.undetermined &&
              tIntersectionType.left.nullability == Nullability.undetermined) {
            // The two nullabilities are undetermined, but are connected via
            // additional constraint, namely that they will be equal at run
            // time.
            tLeftResult = const IsSubtypeOf.always();
          } else {
            tLeftResult = new IsSubtypeOf.basedSolelyOnNullabilities(
                sIntersectionType, tIntersectionType.left);
          }
        } else {
          // Rule 12.
          tLeftResult = performNullabilityAwareSubtypeCheck(
              sIntersectionType.right
                  .withDeclaredNullability(sIntersectionType.nullability),
              tIntersectionType.left);
        }
        return tLeftResult.andSubtypeCheckFor(
            sIntersectionType, tIntersectionType.right, this);

      case (TypedefType sTypedefType, IntersectionType tIntersectionType):
        return performNullabilityAwareSubtypeCheck(
            sTypedefType.unalias, tIntersectionType);

      case (FutureOrType(), IntersectionType()):
        return const IsSubtypeOf.never();

      case (RecordType(), IntersectionType()):
        return const IsSubtypeOf.never();

      case (ExtensionType(), IntersectionType()):
        return const IsSubtypeOf.never();

      case (DynamicType sDynamicType, TypedefType tTypedefType):
        return performNullabilityAwareSubtypeCheck(
            sDynamicType, tTypedefType.unalias);

      case (VoidType sVoidType, TypedefType tTypedefType):
        return performNullabilityAwareSubtypeCheck(
            sVoidType, tTypedefType.unalias);

      case (InterfaceType sInterfaceType, TypedefType tTypedefType):
        return performNullabilityAwareSubtypeCheck(
            sInterfaceType, tTypedefType.unalias);

      case (FunctionType sFunctionType, TypedefType tTypedefType):
        return performNullabilityAwareSubtypeCheck(
            sFunctionType, tTypedefType.unalias);

      case (TypeParameterType sTypeParameterType, TypedefType tTypedefType):
        return performNullabilityAwareSubtypeCheck(
            sTypeParameterType, tTypedefType.unalias);

      case (
          StructuralParameterType sStructuralParameterType,
          TypedefType tTypedefType
        ):
        return performNullabilityAwareSubtypeCheck(
            sStructuralParameterType, tTypedefType.unalias);

      case (IntersectionType sIntersectionType, TypedefType tTypedefType):
        return performNullabilityAwareSubtypeCheck(
            sIntersectionType, tTypedefType.unalias);

      case (TypedefType sTypedefType, TypedefType tTypedefType):
        return performNullabilityAwareSubtypeCheck(
            sTypedefType.unalias, tTypedefType.unalias);

      case (FutureOrType sFutureOrType, TypedefType tTypedefType):
        return performNullabilityAwareSubtypeCheck(
            sFutureOrType, tTypedefType.unalias);

      case (RecordType sRecordType, TypedefType tTypedefType):
        return performNullabilityAwareMutualSubtypesCheck(
            sRecordType, tTypedefType.unalias);

      case (ExtensionType sExtensionType, TypedefType tTypedefType):
        return performNullabilityAwareSubtypeCheck(
            sExtensionType, tTypedefType.unalias);

      case (DynamicType sDynamicType, FutureOrType tFutureOr):
        return performNullabilityAwareSubtypeCheck(
            sDynamicType,
            tFutureOr.typeArgument
                .withDeclaredNullability(tFutureOr.nullability));

      case (VoidType sVoidType, FutureOrType tFutureOr):
        return performNullabilityAwareSubtypeCheck(
            sVoidType,
            tFutureOr.typeArgument
                .withDeclaredNullability(tFutureOr.nullability));

      case (InterfaceType sInterfaceType, FutureOrType tFutureOr):
        Nullability tFutureOrNullability = tFutureOr.nullability;
        return
            // Rule 11.
            performNullabilityAwareSubtypeCheck(
                    sInterfaceType,
                    tFutureOr.typeArgument
                        .withDeclaredNullability(tFutureOrNullability))
                // Rule 10.
                .orSubtypeCheckFor(
                    sInterfaceType,
                    new InterfaceType(this.hierarchy.coreTypes.futureClass,
                        tFutureOrNullability, [tFutureOr.typeArgument]),
                    this);

      case (FunctionType sFunctionType, FutureOrType tFutureOr):
        return performNullabilityAwareSubtypeCheck(
            sFunctionType,
            tFutureOr.typeArgument
                .withDeclaredNullability(tFutureOr.nullability));

      case (TypeParameterType sTypeParameterType, FutureOrType tFutureOr):
        return
            // Rule 11.
            performNullabilityAwareSubtypeCheck(
                    sTypeParameterType,
                    tFutureOr.typeArgument.withDeclaredNullability(
                        combineNullabilitiesForSubstitution(
                            inner: tFutureOr.typeArgument.declaredNullability,
                            outer: tFutureOr.declaredNullability)))
                // Rule 13.
                .orSubtypeCheckFor(
                    sTypeParameterType.parameter.bound.withDeclaredNullability(
                        combineNullabilitiesForSubstitution(
                            inner: sTypeParameterType
                                .parameter.bound.declaredNullability,
                            outer: sTypeParameterType.declaredNullability)),
                    tFutureOr,
                    this)
                // Rule 10.
                .orSubtypeCheckFor(
                    sTypeParameterType,
                    new InterfaceType(this.hierarchy.coreTypes.futureClass,
                        tFutureOr.nullability, [tFutureOr.typeArgument]),
                    this);

      case (
          StructuralParameterType sStructuralParameterType,
          FutureOrType tFutureOr
        ):
        Nullability tFutureOrNullability = tFutureOr.nullability;
        return
            // Rule 11.
            performNullabilityAwareSubtypeCheck(
                    sStructuralParameterType,
                    tFutureOr.typeArgument
                        .withDeclaredNullability(tFutureOrNullability))
                // Rule 13.
                .orSubtypeCheckFor(
                    sStructuralParameterType.parameter.bound
                        .withDeclaredNullability(
                            combineNullabilitiesForSubstitution(
                                inner: sStructuralParameterType
                                    .parameter.bound.nullability,
                                outer: sStructuralParameterType.nullability)),
                    tFutureOr,
                    this)
                // Rule 10.
                .orSubtypeCheckFor(
                    sStructuralParameterType,
                    new InterfaceType(this.hierarchy.coreTypes.futureClass,
                        tFutureOrNullability, [tFutureOr.typeArgument]),
                    this);

      case (IntersectionType sIntersectionType, FutureOrType tFutureOr):
        return
            // Rule 11.
            performNullabilityAwareSubtypeCheck(
                    sIntersectionType.left,
                    tFutureOr.typeArgument.withDeclaredNullability(
                        combineNullabilitiesForSubstitution(
                            inner: tFutureOr.typeArgument.declaredNullability,
                            outer: tFutureOr.declaredNullability)))
                // Rule 13.
                .orSubtypeCheckFor(
                    sIntersectionType.left.parameter.bound
                        .withDeclaredNullability(
                            combineNullabilitiesForSubstitution(
                                inner: sIntersectionType
                                    .left.parameter.bound.declaredNullability,
                                outer: sIntersectionType
                                    .left.declaredNullability)),
                    tFutureOr,
                    this)
                // Rule 10.
                .orSubtypeCheckFor(
                    sIntersectionType.left,
                    new InterfaceType(this.hierarchy.coreTypes.futureClass,
                        tFutureOr.nullability, [tFutureOr.typeArgument]),
                    this) // Rule 8.
                .orSubtypeCheckFor(sIntersectionType.right, tFutureOr, this);

      case (TypedefType sTypedefType, FutureOrType tFutureOr):
        return performNullabilityAwareSubtypeCheck(
            sTypedefType.unalias, tFutureOr);

      case (FutureOrType sFutureOrType, FutureOrType tFutureOrType):
        // This follows from combining rules 7, 10, and 11.
        DartType sArgument = sFutureOrType.typeArgument;
        DartType tArgument = tFutureOrType.typeArgument;
        DartType sFutureOfArgument = new InterfaceType(
            hierarchy.coreTypes.futureClass,
            Nullability.nonNullable,
            [sArgument]);
        DartType tFutureOfArgument = new InterfaceType(
            hierarchy.coreTypes.futureClass,
            Nullability.nonNullable,
            [tArgument]);
        // The following is an optimized is-subtype-of test for the case where
        // both LHS and RHS are FutureOrs.  It's based on the following:
        // FutureOr<X> <: FutureOr<Y> iff X <: Y OR (X <: Future<Y> AND
        // Future<X> <: Y).
        //
        // The correctness of that can be shown as follows:
        //   1. FutureOr<X> <: FutureOr<Y> iff
        //
        //          X <: FutureOr<Y> AND Future<X> <: FutureOr<Y>
        //
        //   2a. X <: FutureOr<Y> iff
        //
        //          X <: Y OR X <: Future<Y>
        //
        //   2b. Future<X> <: FutureOr<Y> iff
        //
        //          Future<X> <: Y OR Future<X> <: Future<Y>
        //
        //   3. 1,2a,2b => FutureOr<X> <: FutureOr<Y> iff
        //
        //          (X <: Y OR X <: Future<Y>) AND
        //            (Future<X> <: Y OR Future<X> <: Future<Y>)
        //
        //   4. X <: Y iff Future<X> <: Future<Y>
        //
        //   5. 3,4 => FutureOr<X> <: FutureOr<Y> iff
        //
        //          (X <: Y OR X <: Future<Y>) AND
        //            (X <: Y OR Future<X> <: Y) iff
        //
        //          X <: Y OR (X <: Future<Y> AND Future<X> <: Y)
        //
        return performNullabilityAwareSubtypeCheck(sArgument, tArgument)
            .or(performNullabilityAwareSubtypeCheck(
                    sArgument, tFutureOfArgument)
                .andSubtypeCheckFor(sFutureOfArgument, tArgument, this))
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sFutureOrType, tFutureOrType));

      case (RecordType sRecordType, FutureOrType tFutureOr):
        return performNullabilityAwareSubtypeCheck(
            sRecordType,
            tFutureOr.typeArgument
                .withDeclaredNullability(tFutureOr.nullability));

      case (ExtensionType sExtensionType, FutureOrType tFutureOr):
        Nullability tFutureOrNullability = tFutureOr.nullability;
        return
            // Rule 11.
            performNullabilityAwareSubtypeCheck(
                    sExtensionType,
                    tFutureOr.typeArgument
                        .withDeclaredNullability(tFutureOrNullability))
                // Rule 10.
                .orSubtypeCheckFor(
                    sExtensionType,
                    new InterfaceType(this.hierarchy.coreTypes.futureClass,
                        tFutureOrNullability, [tFutureOr.typeArgument]),
                    this);

      case (DynamicType(), NullType()):
        return const IsSubtypeOf.never();

      case (VoidType(), NullType()):
        return const IsSubtypeOf.never();

      case (InterfaceType(), NullType()):
        return const IsSubtypeOf.never();

      case (FunctionType(), NullType()):
        return const IsSubtypeOf.never();

      case (TypeParameterType sTypeParameterType, NullType tNullType):
        return performNullabilityAwareSubtypeCheck(
            sTypeParameterType.bound, tNullType);

      case (
          StructuralParameterType sStructuralParameterType,
          NullType tNullType
        ):
        return performNullabilityAwareSubtypeCheck(
            sStructuralParameterType.bound, tNullType);

      case (IntersectionType sIntersectionType, NullType tNullType):
        return performNullabilityAwareMutualSubtypesCheck(
            sIntersectionType.right, tNullType);

      case (TypedefType sTypedefType, NullType tNullType):
        return performNullabilityAwareSubtypeCheck(
            sTypedefType.unalias, tNullType);

      case (FutureOrType(), NullType()):
        return const IsSubtypeOf.never();

      case (RecordType(), NullType()):
        return const IsSubtypeOf.never();

      case (ExtensionType(), NullType()):
        return const IsSubtypeOf.never();

      case (DynamicType(), NeverType()):
        return const IsSubtypeOf.never();

      case (VoidType(), NeverType()):
        return const IsSubtypeOf.never();

      case (InterfaceType(), NeverType()):
        return const IsSubtypeOf.never();

      case (FunctionType(), NeverType()):
        return const IsSubtypeOf.never();

      case (TypeParameterType sTypeParameterType, NeverType tNeverType):
        return performNullabilityAwareSubtypeCheck(
                sTypeParameterType.bound, tNeverType)
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sTypeParameterType, tNeverType));

      case (
          StructuralParameterType sStructuralParameterType,
          NeverType tNeverType
        ):
        return performNullabilityAwareSubtypeCheck(
                sStructuralParameterType.bound, tNeverType)
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sStructuralParameterType, tNeverType));

      case (IntersectionType sIntersectionType, NeverType tNeverType):
        return performNullabilityAwareSubtypeCheck(
            sIntersectionType.right, tNeverType);

      case (TypedefType sTypedefType, NeverType tNeverType):
        return performNullabilityAwareSubtypeCheck(
            sTypedefType.unalias, tNeverType);

      case (FutureOrType(), NeverType()):
        return const IsSubtypeOf.never();

      case (RecordType(), NeverType()):
        return const IsSubtypeOf.never();

      case (ExtensionType(), NeverType()):
        return const IsSubtypeOf.never();

      case (DynamicType(), RecordType()):
        return const IsSubtypeOf.never();

      case (VoidType(), RecordType()):
        return const IsSubtypeOf.never();

      case (InterfaceType(), RecordType()):
        return const IsSubtypeOf.never();

      case (FunctionType(), RecordType()):
        return const IsSubtypeOf.never();

      case (
          StructuralParameterType sStructuralParameterType,
          RecordType tRecordType
        ):
        return performNullabilityAwareSubtypeCheck(
                sStructuralParameterType.parameter.bound, tRecordType)
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sStructuralParameterType, tRecordType));

      case (IntersectionType sIntersectionType, RecordType tRecordType):
        return performNullabilityAwareSubtypeCheck(
            sIntersectionType.right, tRecordType);

      case (TypeParameterType sTypeParameterType, RecordType tRecordType):
        return performNullabilityAwareSubtypeCheck(
                sTypeParameterType.parameter.bound, tRecordType)
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sTypeParameterType, tRecordType));

      case (TypedefType sTypedefType, RecordType tRecordType):
        return performNullabilityAwareSubtypeCheck(
            sTypedefType.unalias, tRecordType);

      case (FutureOrType(), RecordType()):
        return const IsSubtypeOf.never();

      case (RecordType sRecordType, RecordType tRecordType):
        if (sRecordType.positional.length != tRecordType.positional.length ||
            sRecordType.named.length != tRecordType.named.length) {
          return const IsSubtypeOf.never();
        }
        for (int i = 0; i < sRecordType.named.length; i++) {
          if (sRecordType.named[i].name != tRecordType.named[i].name) {
            return const IsSubtypeOf.never();
          }
        }

        IsSubtypeOf result = IsSubtypeOf.always();
        for (int i = 0; i < sRecordType.positional.length; i++) {
          result = result.and(performNullabilityAwareSubtypeCheck(
              sRecordType.positional[i], tRecordType.positional[i]));
          if (!result.isSubtypeWhenIgnoringNullabilities()) {
            return const IsSubtypeOf.never();
          }
        }
        for (int i = 0; i < sRecordType.named.length; i++) {
          result = result.and(performNullabilityAwareSubtypeCheck(
              sRecordType.named[i].type, tRecordType.named[i].type));
          if (!result.isSubtypeWhenIgnoringNullabilities()) {
            return const IsSubtypeOf.never();
          }
        }
        return result.and(new IsSubtypeOf.basedSolelyOnNullabilities(
            sRecordType, tRecordType));

      case (ExtensionType(), RecordType()):
        return const IsSubtypeOf.never();

      case (DynamicType(), ExtensionType()):
        return const IsSubtypeOf.never();

      case (VoidType(), ExtensionType()):
        return const IsSubtypeOf.never();

      case (InterfaceType(), ExtensionType()):
        return const IsSubtypeOf.never();

      case (FunctionType(), ExtensionType()):
        return const IsSubtypeOf.never();

      case (TypeParameterType sTypeParameterType, ExtensionType tExtensionType):
        return performNullabilityAwareSubtypeCheck(
            sTypeParameterType.bound, tExtensionType);

      case (
          StructuralParameterType sStructuralParameterType,
          ExtensionType tExtensionType
        ):
        return performNullabilityAwareSubtypeCheck(
            sStructuralParameterType.bound, tExtensionType);

      case (IntersectionType sIntersectionType, ExtensionType tExtensionType):
        return performNullabilityAwareSubtypeCheck(
            sIntersectionType.right, tExtensionType);

      case (TypedefType sTypedefType, ExtensionType tExtensionType):
        return performNullabilityAwareSubtypeCheck(
            sTypedefType.unalias, tExtensionType);

      case (FutureOrType(), ExtensionType()):
        return const IsSubtypeOf.never();

      case (RecordType(), ExtensionType()):
        return const IsSubtypeOf.never();

      case (ExtensionType sExtensionType, ExtensionType tExtensionType):
        List<DartType>? typeArguments = hierarchy
            .getExtensionTypeArgumentsAsInstanceOfExtensionTypeDeclaration(
                sExtensionType, tExtensionType.extensionTypeDeclaration);
        if (typeArguments == null) {
          return const IsSubtypeOf.never();
        }
        return areTypeArgumentsOfSubtypeKernel(
                typeArguments,
                tExtensionType.typeArguments,
                tExtensionType.extensionTypeDeclaration.typeParameters)
            .and(new IsSubtypeOf.basedSolelyOnNullabilities(
                sExtensionType, tExtensionType));

      case (AuxiliaryType(), _):
      case (_, AuxiliaryType()):
        throw "Unhandled type: ${t.runtimeType}";
    }
  }

  /// Returns true if all type arguments in [s] and [t] pairwise are subtypes
  /// with respect to the variance of the corresponding [p] type parameter.
  IsSubtypeOf areTypeArgumentsOfSubtypeKernel(
      List<DartType> s, List<DartType> t, List<TypeParameter> p) {
    if (s.length != t.length || s.length != p.length) {
      throw "Numbers of type arguments don't match $s $t with parameters $p.";
    }
    IsSubtypeOf result = const IsSubtypeOf.always();
    for (int i = 0; i < s.length; i++) {
      Variance variance = p[i].variance;
      if (variance == Variance.contravariant) {
        result = result.and(performNullabilityAwareSubtypeCheck(t[i], s[i]));
        if (!result.isSubtypeWhenIgnoringNullabilities()) {
          return const IsSubtypeOf.never();
        }
      } else if (variance == Variance.invariant) {
        result =
            result.and(performNullabilityAwareMutualSubtypesCheck(s[i], t[i]));
        if (!result.isSubtypeWhenIgnoringNullabilities()) {
          return const IsSubtypeOf.never();
        }
      } else {
        result = result.and(performNullabilityAwareSubtypeCheck(s[i], t[i]));
        if (!result.isSubtypeWhenIgnoringNullabilities()) {
          return const IsSubtypeOf.never();
        }
      }
    }
    return result;
  }

  static List<Object>? typeChecksForTesting;

  TypeDeclarationType? getTypeAsInstanceOf(TypeDeclarationType type,
      TypeDeclaration typeDeclaration, CoreTypes coreTypes) {
    return hierarchy.getTypeAsInstanceOf(type, typeDeclaration);
  }

  List<DartType>? getTypeArgumentsAsInstanceOf(
      TypeDeclarationType type, TypeDeclaration typeDeclaration) {
    return hierarchy.getTypeArgumentsAsInstanceOf(type, typeDeclaration);
  }

  bool isTop(DartType type) {
    return type is DynamicType ||
        type is VoidType ||
        type == hierarchy.coreTypes.objectLegacyRawType ||
        type == hierarchy.coreTypes.objectNullableRawType;
  }

  IsSubtypeOf performNullabilityAwareMutualSubtypesCheck(
      DartType type1, DartType type2) {
    return performNullabilityAwareSubtypeCheck(type1, type2)
        .andSubtypeCheckFor(type2, type1, this);
  }
}
