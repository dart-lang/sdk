// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';

import '../class_hierarchy.dart' show ClassHierarchyBase;

import '../core_types.dart' show CoreTypes;

import '../type_algebra.dart'
    show FunctionTypeInstantiator, combineNullabilitiesForSubstitution;

import '../type_environment.dart' show IsSubtypeOf;

import '../src/standard_bounds.dart';

class Types with StandardBounds {
  @override
  final ClassHierarchyBase hierarchy;

  Types(this.hierarchy);

  @override
  CoreTypes get coreTypes => hierarchy.coreTypes;

  @override
  bool areMutualSubtypes(DartType s, DartType t) {
    return performMutualSubtypesCheck(s, t).isSuccess();
  }

  bool _isSubtypeFromMode(IsSubtypeOf isSubtypeOf) {
    return isSubtypeOf.isSuccess();
  }

  /// Returns true if [s] is a subtype of [t].
  @override
  bool isSubtypeOf(DartType s, DartType t) {
    IsSubtypeOf result = performSubtypeCheck(s, t);
    return _isSubtypeFromMode(result);
  }

  /// Can be use to collect type checks. To use:
  /// 1. Rename `performSubtypeCheck` to
  ///    `_performSubtypeCheck`.
  /// 2. Rename `_collect_performSubtypeCheck` to
  ///    `performSubtypeCheck`.
  /// 3. Comment out the call to `_performSubtypeCheck` below.
  // ignore:unused_element
  IsSubtypeOf _collect_performSubtypeCheck(
    DartType subtype,
    DartType supertype,
  ) {
    IsSubtypeOf result = const IsSubtypeOf.success();
    // result = _performSubtypeCheck(subtype, supertype);
    bool booleanResult = result.isSuccess();
    (typeChecksForTesting ??= <Object>[]).add([
      subtype,
      supertype,
      booleanResult,
    ]);
    return result;
  }

  IsSubtypeOf performSubtypeCheck(DartType s, DartType t) {
    switch ((s, t)) {
      // TODO(johnniwinther,cstefantsova): Ensure complete handling of
      // InvalidType in the subtype relation.
      case (InvalidType(), _):
      case (_, InvalidType()):
        return const IsSubtypeOf.success();

      // Rule 2.
      case (_, DynamicType()):
        return const IsSubtypeOf.success();

      // Rule 2.
      case (_, VoidType()):
        return const IsSubtypeOf.success();

      case (NeverType(), _):
        return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);

      // Rule 4.
      case (NullType(), _):
        return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);

      case (
            ExtensionType(),
            InterfaceType(classReference: Reference tClassReference),
          )
          when tClassReference == hierarchy.coreTypes.objectClass.reference &&
              s.extensionTypeErasure.isPotentiallyNullable &&
              !t.isPotentiallyNullable:
        return const IsSubtypeOf.failure();
      case (_, InterfaceType(classReference: Reference tClassReference))
          when tClassReference == hierarchy.coreTypes.objectClass.reference &&
              s is! FutureOrType:
        return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);

      case (DynamicType(), InterfaceType()):
        return const IsSubtypeOf.failure();

      case (VoidType(), InterfaceType()):
        return const IsSubtypeOf.failure();

      case (InterfaceType sInterfaceType, InterfaceType tInterfaceType):
        List<DartType>? asSupertypeArguments;
        if (sInterfaceType.classReference == tInterfaceType.classReference) {
          asSupertypeArguments = sInterfaceType.typeArguments;
        } else {
          asSupertypeArguments =
              hierarchy.getInterfaceTypeArgumentsAsInstanceOfClass(
            sInterfaceType,
            tInterfaceType.classNode,
          );
        }
        if (asSupertypeArguments == null) {
          return const IsSubtypeOf.failure();
        }
        if (asSupertypeArguments.isEmpty) {
          return const IsSubtypeOf.success().and(
            new IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(
              sInterfaceType,
              tInterfaceType,
            ),
          );
        }
        return areTypeArgumentsOfSubtypeKernel(
          asSupertypeArguments,
          tInterfaceType.typeArguments,
          tInterfaceType.classNode.typeParameters,
        ).and(
          new IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(
            sInterfaceType,
            tInterfaceType,
          ),
        );

      case (FunctionType sFunctionType, InterfaceType tInterfaceType):
        return tInterfaceType.classNode == hierarchy.coreTypes.functionClass
            ? new IsSubtypeOf.basedSolelyOnNullabilities(
                sFunctionType,
                tInterfaceType,
              )
            : const IsSubtypeOf.failure();

      case (TypeParameterType sTypeParameterType, InterfaceType tInterfaceType):
        return performSubtypeCheck(
          sTypeParameterType.parameter.bound,
          tInterfaceType,
        ).and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sTypeParameterType,
            tInterfaceType,
          ),
        );

      case (
          StructuralParameterType sStructuralParameterType,
          InterfaceType tInterfaceType,
        ):
        return performSubtypeCheck(
          sStructuralParameterType.parameter.bound,
          tInterfaceType,
        ).and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sStructuralParameterType,
            tInterfaceType,
          ),
        );

      case (IntersectionType sIntersectionType, InterfaceType tInterfaceType):
        return performSubtypeCheck(
          sIntersectionType.right,
          tInterfaceType,
        );

      case (TypedefType sTypedefType, InterfaceType tInterfaceType):
        return performSubtypeCheck(
          sTypedefType.unalias,
          tInterfaceType,
        ).and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sTypedefType,
            tInterfaceType,
          ),
        );

      case (FutureOrType sFutureOrType, InterfaceType tInterfaceType):
        return performSubtypeCheck(
          new InterfaceType(
            hierarchy.coreTypes.futureClass,
            Nullability.nonNullable,
            [sFutureOrType.typeArgument],
          ),
          tInterfaceType,
        )
            .andSubtypeCheckFor(
              sFutureOrType.typeArgument,
              tInterfaceType,
              this,
            )
            .and(
              new IsSubtypeOf.basedSolelyOnNullabilities(
                sFutureOrType,
                tInterfaceType,
              ),
            );

      case (RecordType sRecordType, InterfaceType tInterfaceType):
        return tInterfaceType.classNode == hierarchy.coreTypes.recordClass
            ? new IsSubtypeOf.basedSolelyOnNullabilities(
                sRecordType,
                tInterfaceType,
              )
            : const IsSubtypeOf.failure();

      case (ExtensionType sExtensionType, InterfaceType tInterfaceType):
        List<DartType>? asSupertypeArguments =
            hierarchy.getExtensionTypeArgumentsAsInstanceOfClass(
          sExtensionType,
          tInterfaceType.classNode,
        );
        if (asSupertypeArguments == null) {
          return const IsSubtypeOf.failure();
        }
        if (asSupertypeArguments.isEmpty) {
          return const IsSubtypeOf.success().and(
            new IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(s, t),
          );
        }
        return areTypeArgumentsOfSubtypeKernel(
          asSupertypeArguments,
          tInterfaceType.typeArguments,
          tInterfaceType.classNode.typeParameters,
        ).and(
          new IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(
            sExtensionType,
            tInterfaceType,
          ),
        );

      case (DynamicType(), FunctionType()):
        return const IsSubtypeOf.failure();

      case (VoidType(), FunctionType()):
        return const IsSubtypeOf.failure();

      case (InterfaceType(), FunctionType()):
        return const IsSubtypeOf.failure();

      case (FunctionType sFunctionType, FunctionType tFunctionType):
        List<StructuralParameter> sTypeVariables = sFunctionType.typeParameters;
        List<StructuralParameter> tTypeVariables = tFunctionType.typeParameters;
        if (sTypeVariables.length != tTypeVariables.length) {
          return const IsSubtypeOf.failure();
        }
        IsSubtypeOf result = const IsSubtypeOf.success();
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
            result = result.and(
              performMutualSubtypesCheck(
                sTypeVariable.bound,
                tTypeVariable.bound,
              ),
            );
            typeVariableSubstitution.add(
              new StructuralParameterType.withDefaultNullability(tTypeVariable),
            );
          }
          FunctionTypeInstantiator instantiator =
              FunctionTypeInstantiator.fromIterables(
            sTypeVariables,
            typeVariableSubstitution,
          );
          // If the bounds aren't the same, we need to try again after computing
          // the substitution of type variables.
          if (!result.isSuccess()) {
            result = const IsSubtypeOf.success();
            for (int i = 0; i < sTypeVariables.length; i++) {
              StructuralParameter sTypeVariable = sTypeVariables[i];
              StructuralParameter tTypeVariable = tTypeVariables[i];
              result = result.and(
                performMutualSubtypesCheck(
                  instantiator.substitute(sTypeVariable.bound),
                  tTypeVariable.bound,
                ),
              );
              if (!result.isSuccess()) {
                return const IsSubtypeOf.failure();
              }
            }
          }
          sFunctionType = instantiator
              .substitute(sFunctionType.withoutTypeParameters) as FunctionType;
        }
        result = result.and(
          performSubtypeCheck(
            sFunctionType.returnType,
            tFunctionType.returnType,
          ),
        );
        if (!result.isSuccess()) {
          return const IsSubtypeOf.failure();
        }
        List<DartType> sPositional = sFunctionType.positionalParameters;
        List<DartType> tPositional = tFunctionType.positionalParameters;
        if (sFunctionType.requiredParameterCount >
            tFunctionType.requiredParameterCount) {
          // Rule 15, n1 <= n2.
          return const IsSubtypeOf.failure();
        }
        if (sPositional.length < tPositional.length) {
          // Rule 15, n1 + k1 >= n2 + k2.
          return const IsSubtypeOf.failure();
        }
        for (int i = 0; i < tPositional.length; i++) {
          result = result.and(
            performSubtypeCheck(tPositional[i], sPositional[i]),
          );
          if (!result.isSuccess()) {
            // Rule 15, Tj <: Sj.
            return const IsSubtypeOf.failure();
          }
        }
        List<NamedType> sNamedParameters = sFunctionType.namedParameters;
        List<NamedType> tNamedParameters = tFunctionType.namedParameters;
        if (sNamedParameters.isNotEmpty || tNamedParameters.isNotEmpty) {
          // Rule 16, the number of positional parameters must be the same.
          if (sPositional.length != tPositional.length) {
            return const IsSubtypeOf.failure();
          }
          if (sFunctionType.requiredParameterCount !=
              tFunctionType.requiredParameterCount) {
            return const IsSubtypeOf.failure();
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
                result = const IsSubtypeOf.failure();
              }
            }
            if (sCount == sNamedParameters.length) {
              return const IsSubtypeOf.failure();
            }
            // Increment [sCount] so we don't check [sNamedParameter] again in
            // the loop above or below and assume it is an extra (unmatched)
            // parameter.
            sCount++;
            result = result.and(
              performSubtypeCheck(
                tNamedParameter.type,
                sNamedParameter!.type,
              ),
            );
            if (!result.isSuccess()) {
              return const IsSubtypeOf.failure();
            }

            /// From the NNBD spec: For each j such that r0j is required, then
            /// there exists an i in n+1...q such that xj = yi, and r1i is
            /// required
            if (sNamedParameter.isRequired && !tNamedParameter.isRequired) {
              result = const IsSubtypeOf.failure();
            }
          }
          for (; sCount < sNamedParameters.length; sCount++) {
            NamedType sNamedParameter = sNamedParameters[sCount];
            if (sNamedParameter.isRequired) {
              /// From the NNBD spec: For each j such that r0j is required, then
              /// there exists an i in n+1...q such that xj = yi, and r1i is
              /// required
              result = const IsSubtypeOf.failure();
            }
          }
        }
        return result.and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sFunctionType,
            tFunctionType,
          ),
        );

      case (TypeParameterType sTypeParameterType, FunctionType tFunctionType):
        return performSubtypeCheck(
          sTypeParameterType.parameter.bound,
          tFunctionType,
        ).and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sTypeParameterType,
            tFunctionType,
          ),
        );

      case (
          StructuralParameterType sStructuralParameterType,
          FunctionType tFunctionType,
        ):
        return performSubtypeCheck(
          sStructuralParameterType.parameter.bound,
          tFunctionType,
        ).and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sStructuralParameterType,
            tFunctionType,
          ),
        );

      case (IntersectionType sIntersectionType, FunctionType tFunctionType):
        return performSubtypeCheck(
          sIntersectionType.right,
          tFunctionType,
        );

      case (TypedefType sTypedefType, FunctionType tFunctionType):
        return performSubtypeCheck(
          sTypedefType.unalias,
          tFunctionType,
        );

      case (FutureOrType(), FunctionType()):
        return const IsSubtypeOf.failure();

      case (RecordType(), FunctionType()):
        return const IsSubtypeOf.failure();

      case (ExtensionType(), FunctionType()):
        return const IsSubtypeOf.failure();

      case (DynamicType(), TypeParameterType()):
        return const IsSubtypeOf.failure();

      case (VoidType(), TypeParameterType()):
        return const IsSubtypeOf.failure();

      case (InterfaceType(), TypeParameterType()):
        return const IsSubtypeOf.failure();

      case (FunctionType(), TypeParameterType()):
        return const IsSubtypeOf.failure();

      case (
          TypeParameterType sTypeParameterType,
          TypeParameterType tTypeParameterType,
        ):
        IsSubtypeOf result = const IsSubtypeOf.success();
        if (sTypeParameterType.parameter != tTypeParameterType.parameter) {
          result = performSubtypeCheck(
            sTypeParameterType.bound,
            t,
          );
        }
        if (sTypeParameterType.nullability == Nullability.undetermined &&
            tTypeParameterType.nullability == Nullability.undetermined) {
          // The two nullabilities are undetermined, but are connected via
          // additional constraint, namely that they will be equal at run time.
          return result;
        }
        return result.and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sTypeParameterType,
            tTypeParameterType,
          ),
        );

      case (
          StructuralParameterType sStructuralParameterType,
          TypeParameterType tTypeParameterType,
        ):
        IsSubtypeOf result = performSubtypeCheck(
          sStructuralParameterType.bound,
          t,
        );
        if (sStructuralParameterType.nullability == Nullability.undetermined &&
            tTypeParameterType.nullability == Nullability.undetermined) {
          // The two nullabilities are undetermined, but are connected via
          // additional constraint, namely that they will be equal at run time.
          return result;
        }
        return result.and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sStructuralParameterType,
            tTypeParameterType,
          ),
        );

      case (
          IntersectionType sIntersectionType,
          TypeParameterType tTypeParameterType,
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
            return const IsSubtypeOf.success();
          }
          return new IsSubtypeOf.basedSolelyOnNullabilities(
            sIntersectionType,
            t,
          );
        }

        // Rule 12.
        return performSubtypeCheck(
          sIntersectionType.right.withDeclaredNullability(
            sIntersectionType.nullability,
          ),
          t,
        );

      case (TypedefType sTypedefType, TypeParameterType tTypeParameterType):
        return performSubtypeCheck(
          sTypedefType.unalias,
          tTypeParameterType,
        );

      case (FutureOrType(), TypeParameterType()):
        return const IsSubtypeOf.failure();

      case (RecordType(), TypeParameterType()):
        return const IsSubtypeOf.failure();

      case (ExtensionType(), TypeParameterType()):
        return const IsSubtypeOf.failure();

      case (DynamicType(), StructuralParameterType()):
        return const IsSubtypeOf.failure();

      case (VoidType(), StructuralParameterType()):
        return const IsSubtypeOf.failure();

      case (InterfaceType(), StructuralParameterType()):
        return const IsSubtypeOf.failure();

      case (FunctionType(), StructuralParameterType()):
        return const IsSubtypeOf.failure();

      case (TypeParameterType(), StructuralParameterType()):
        return const IsSubtypeOf.failure();

      case (
          StructuralParameterType sStructuralParameterType,
          StructuralParameterType tStructuralParameterType,
        ):
        IsSubtypeOf result = const IsSubtypeOf.success();
        if (sStructuralParameterType.parameter !=
            tStructuralParameterType.parameter) {
          result = performSubtypeCheck(
            sStructuralParameterType.bound,
            t,
          );
        }
        if (sStructuralParameterType.nullability == Nullability.undetermined &&
            tStructuralParameterType.nullability == Nullability.undetermined) {
          // The two nullabilities are undetermined, but are connected via
          // additional constraint, namely that they will be equal at run time.
          return result;
        }
        return result.and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sStructuralParameterType,
            tStructuralParameterType,
          ),
        );

      case (IntersectionType(), StructuralParameterType()):
        return const IsSubtypeOf.failure();

      case (
          TypedefType sTypedefType,
          StructuralParameterType tStructuralParameterType,
        ):
        return performSubtypeCheck(
          sTypedefType.unalias,
          tStructuralParameterType,
        );

      case (FutureOrType(), StructuralParameterType()):
        return const IsSubtypeOf.failure();

      case (RecordType(), StructuralParameterType()):
        return const IsSubtypeOf.failure();

      case (ExtensionType(), StructuralParameterType()):
        return const IsSubtypeOf.failure();

      case (DynamicType(), IntersectionType()):
        return const IsSubtypeOf.failure();

      case (VoidType(), IntersectionType()):
        return const IsSubtypeOf.failure();

      case (InterfaceType(), IntersectionType()):
        return const IsSubtypeOf.failure();

      case (FunctionType(), IntersectionType()):
        return const IsSubtypeOf.failure();

      case (
          TypeParameterType sTypeParameterType,
          IntersectionType tIntersectionType,
        ):
        IsSubtypeOf result = const IsSubtypeOf.success();
        if (sTypeParameterType.parameter != tIntersectionType.left.parameter) {
          result = performSubtypeCheck(
            sTypeParameterType.bound,
            t,
          );
        }
        if (sTypeParameterType.nullability == Nullability.undetermined &&
            tIntersectionType.left.nullability == Nullability.undetermined) {
          // The two nullabilities are undetermined, but are connected via
          // additional constraint, namely that they will be equal at run time.
          return result.andSubtypeCheckFor(
            sTypeParameterType,
            tIntersectionType.right,
            this,
          );
        }
        return result
            .and(
              new IsSubtypeOf.basedSolelyOnNullabilities(
                sTypeParameterType,
                tIntersectionType.left,
              ),
            )
            .andSubtypeCheckFor(
              sTypeParameterType,
              tIntersectionType.right,
              this,
            );

      case (StructuralParameterType(), IntersectionType()):
        return const IsSubtypeOf.failure();

      case (
          IntersectionType sIntersectionType,
          IntersectionType tIntersectionType,
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
            tLeftResult = const IsSubtypeOf.success();
          } else {
            tLeftResult = new IsSubtypeOf.basedSolelyOnNullabilities(
              sIntersectionType,
              tIntersectionType.left,
            );
          }
        } else {
          // Rule 12.
          tLeftResult = performSubtypeCheck(
            sIntersectionType.right.withDeclaredNullability(
              sIntersectionType.nullability,
            ),
            tIntersectionType.left,
          );
        }
        return tLeftResult.andSubtypeCheckFor(
          sIntersectionType,
          tIntersectionType.right,
          this,
        );

      case (TypedefType sTypedefType, IntersectionType tIntersectionType):
        return performSubtypeCheck(
          sTypedefType.unalias,
          tIntersectionType,
        );

      case (FutureOrType(), IntersectionType()):
        return const IsSubtypeOf.failure();

      case (RecordType(), IntersectionType()):
        return const IsSubtypeOf.failure();

      case (ExtensionType(), IntersectionType()):
        return const IsSubtypeOf.failure();

      case (DynamicType sDynamicType, TypedefType tTypedefType):
        return performSubtypeCheck(
          sDynamicType,
          tTypedefType.unalias,
        );

      case (VoidType sVoidType, TypedefType tTypedefType):
        return performSubtypeCheck(
          sVoidType,
          tTypedefType.unalias,
        );

      case (InterfaceType sInterfaceType, TypedefType tTypedefType):
        return performSubtypeCheck(
          sInterfaceType,
          tTypedefType.unalias,
        );

      case (FunctionType sFunctionType, TypedefType tTypedefType):
        return performSubtypeCheck(
          sFunctionType,
          tTypedefType.unalias,
        );

      case (TypeParameterType sTypeParameterType, TypedefType tTypedefType):
        return performSubtypeCheck(
          sTypeParameterType,
          tTypedefType.unalias,
        );

      case (
          StructuralParameterType sStructuralParameterType,
          TypedefType tTypedefType,
        ):
        return performSubtypeCheck(
          sStructuralParameterType,
          tTypedefType.unalias,
        );

      case (IntersectionType sIntersectionType, TypedefType tTypedefType):
        return performSubtypeCheck(
          sIntersectionType,
          tTypedefType.unalias,
        );

      case (TypedefType sTypedefType, TypedefType tTypedefType):
        return performSubtypeCheck(
          sTypedefType.unalias,
          tTypedefType.unalias,
        );

      case (FutureOrType sFutureOrType, TypedefType tTypedefType):
        return performSubtypeCheck(
          sFutureOrType,
          tTypedefType.unalias,
        );

      case (RecordType sRecordType, TypedefType tTypedefType):
        return performMutualSubtypesCheck(
          sRecordType,
          tTypedefType.unalias,
        );

      case (ExtensionType sExtensionType, TypedefType tTypedefType):
        return performSubtypeCheck(
          sExtensionType,
          tTypedefType.unalias,
        );

      case (DynamicType sDynamicType, FutureOrType tFutureOr):
        return performSubtypeCheck(
          sDynamicType,
          tFutureOr.typeArgument.withDeclaredNullability(tFutureOr.nullability),
        );

      case (VoidType sVoidType, FutureOrType tFutureOr):
        return performSubtypeCheck(
          sVoidType,
          tFutureOr.typeArgument.withDeclaredNullability(tFutureOr.nullability),
        );

      case (InterfaceType sInterfaceType, FutureOrType tFutureOr):
        Nullability tFutureOrNullability = tFutureOr.nullability;
        return
            // Rule 11.
            performSubtypeCheck(
          sInterfaceType,
          tFutureOr.typeArgument.withDeclaredNullability(tFutureOrNullability),
        )
                // Rule 10.
                .orSubtypeCheckFor(
          sInterfaceType,
          new InterfaceType(
            this.hierarchy.coreTypes.futureClass,
            tFutureOrNullability,
            [tFutureOr.typeArgument],
          ),
          this,
        );

      case (FunctionType sFunctionType, FutureOrType tFutureOr):
        return performSubtypeCheck(
          sFunctionType,
          tFutureOr.typeArgument.withDeclaredNullability(tFutureOr.nullability),
        );

      case (TypeParameterType sTypeParameterType, FutureOrType tFutureOr):
        return
            // Rule 11.
            performSubtypeCheck(
          sTypeParameterType,
          tFutureOr.typeArgument.withDeclaredNullability(
            combineNullabilitiesForSubstitution(
              inner: tFutureOr.typeArgument.declaredNullability,
              outer: tFutureOr.declaredNullability,
            ),
          ),
        )
                // Rule 13.
                .orSubtypeCheckFor(
                  sTypeParameterType.parameter.bound.withDeclaredNullability(
                    combineNullabilitiesForSubstitution(
                      inner: sTypeParameterType
                          .parameter.bound.declaredNullability,
                      outer: sTypeParameterType.declaredNullability,
                    ),
                  ),
                  tFutureOr,
                  this,
                )
                // Rule 10.
                .orSubtypeCheckFor(
                  sTypeParameterType,
                  new InterfaceType(
                    this.hierarchy.coreTypes.futureClass,
                    tFutureOr.nullability,
                    [tFutureOr.typeArgument],
                  ),
                  this,
                );

      case (
          StructuralParameterType sStructuralParameterType,
          FutureOrType tFutureOr,
        ):
        Nullability tFutureOrNullability = tFutureOr.nullability;
        return
            // Rule 11.
            performSubtypeCheck(
          sStructuralParameterType,
          tFutureOr.typeArgument.withDeclaredNullability(
            tFutureOrNullability,
          ),
        )
                // Rule 13.
                .orSubtypeCheckFor(
                  sStructuralParameterType.parameter.bound
                      .withDeclaredNullability(
                    combineNullabilitiesForSubstitution(
                      inner:
                          sStructuralParameterType.parameter.bound.nullability,
                      outer: sStructuralParameterType.nullability,
                    ),
                  ),
                  tFutureOr,
                  this,
                )
                // Rule 10.
                .orSubtypeCheckFor(
                  sStructuralParameterType,
                  new InterfaceType(
                    this.hierarchy.coreTypes.futureClass,
                    tFutureOrNullability,
                    [tFutureOr.typeArgument],
                  ),
                  this,
                );

      case (IntersectionType sIntersectionType, FutureOrType tFutureOr):
        return
            // Rule 11.
            performSubtypeCheck(
          sIntersectionType.left,
          tFutureOr.typeArgument.withDeclaredNullability(
            combineNullabilitiesForSubstitution(
              inner: tFutureOr.typeArgument.declaredNullability,
              outer: tFutureOr.declaredNullability,
            ),
          ),
        )
                // Rule 13.
                .orSubtypeCheckFor(
                  sIntersectionType.left.parameter.bound
                      .withDeclaredNullability(
                    combineNullabilitiesForSubstitution(
                      inner: sIntersectionType
                          .left.parameter.bound.declaredNullability,
                      outer: sIntersectionType.left.declaredNullability,
                    ),
                  ),
                  tFutureOr,
                  this,
                )
                // Rule 10.
                .orSubtypeCheckFor(
                  sIntersectionType.left,
                  new InterfaceType(
                    this.hierarchy.coreTypes.futureClass,
                    tFutureOr.nullability,
                    [tFutureOr.typeArgument],
                  ),
                  this,
                ) // Rule 8.
                .orSubtypeCheckFor(sIntersectionType.right, tFutureOr, this);

      case (TypedefType sTypedefType, FutureOrType tFutureOr):
        return performSubtypeCheck(
          sTypedefType.unalias,
          tFutureOr,
        );

      case (FutureOrType sFutureOrType, FutureOrType tFutureOrType):
        // This follows from combining rules 7, 10, and 11.
        DartType sArgument = sFutureOrType.typeArgument;
        DartType tArgument = tFutureOrType.typeArgument;
        DartType sFutureOfArgument = new InterfaceType(
          hierarchy.coreTypes.futureClass,
          Nullability.nonNullable,
          [sArgument],
        );
        DartType tFutureOfArgument = new InterfaceType(
          hierarchy.coreTypes.futureClass,
          Nullability.nonNullable,
          [tArgument],
        );
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
        return performSubtypeCheck(sArgument, tArgument)
            .or(
              performSubtypeCheck(
                sArgument,
                tFutureOfArgument,
              ).andSubtypeCheckFor(sFutureOfArgument, tArgument, this),
            )
            .and(
              new IsSubtypeOf.basedSolelyOnNullabilities(
                sFutureOrType,
                tFutureOrType,
              ),
            );

      case (RecordType sRecordType, FutureOrType tFutureOr):
        return performSubtypeCheck(
          sRecordType,
          tFutureOr.typeArgument.withDeclaredNullability(tFutureOr.nullability),
        );

      case (ExtensionType sExtensionType, FutureOrType tFutureOr):
        Nullability tFutureOrNullability = tFutureOr.nullability;
        return
            // Rule 11.
            performSubtypeCheck(
          sExtensionType,
          tFutureOr.typeArgument.withDeclaredNullability(tFutureOrNullability),
        )
                // Rule 10.
                .orSubtypeCheckFor(
          sExtensionType,
          new InterfaceType(
            this.hierarchy.coreTypes.futureClass,
            tFutureOrNullability,
            [tFutureOr.typeArgument],
          ),
          this,
        );

      case (DynamicType(), NullType()):
        return const IsSubtypeOf.failure();

      case (VoidType(), NullType()):
        return const IsSubtypeOf.failure();

      case (InterfaceType(), NullType()):
        return const IsSubtypeOf.failure();

      case (FunctionType(), NullType()):
        return const IsSubtypeOf.failure();

      case (TypeParameterType sTypeParameterType, NullType tNullType):
        return performSubtypeCheck(
          sTypeParameterType.bound,
          tNullType,
        );

      case (
          StructuralParameterType sStructuralParameterType,
          NullType tNullType,
        ):
        return performSubtypeCheck(
          sStructuralParameterType.bound,
          tNullType,
        );

      case (IntersectionType sIntersectionType, NullType tNullType):
        return performMutualSubtypesCheck(
          sIntersectionType.right,
          tNullType,
        );

      case (TypedefType sTypedefType, NullType tNullType):
        return performSubtypeCheck(
          sTypedefType.unalias,
          tNullType,
        );

      case (FutureOrType(), NullType()):
        return const IsSubtypeOf.failure();

      case (RecordType(), NullType()):
        return const IsSubtypeOf.failure();

      case (ExtensionType(), NullType()):
        return const IsSubtypeOf.failure();

      case (DynamicType(), NeverType()):
        return const IsSubtypeOf.failure();

      case (VoidType(), NeverType()):
        return const IsSubtypeOf.failure();

      case (InterfaceType(), NeverType()):
        return const IsSubtypeOf.failure();

      case (FunctionType(), NeverType()):
        return const IsSubtypeOf.failure();

      case (TypeParameterType sTypeParameterType, NeverType tNeverType):
        return performSubtypeCheck(
          sTypeParameterType.bound,
          tNeverType,
        ).and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sTypeParameterType,
            tNeverType,
          ),
        );

      case (
          StructuralParameterType sStructuralParameterType,
          NeverType tNeverType,
        ):
        return performSubtypeCheck(
          sStructuralParameterType.bound,
          tNeverType,
        ).and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sStructuralParameterType,
            tNeverType,
          ),
        );

      case (IntersectionType sIntersectionType, NeverType tNeverType):
        return performSubtypeCheck(
          sIntersectionType.right,
          tNeverType,
        );

      case (TypedefType sTypedefType, NeverType tNeverType):
        return performSubtypeCheck(
          sTypedefType.unalias,
          tNeverType,
        );

      case (FutureOrType(), NeverType()):
        return const IsSubtypeOf.failure();

      case (RecordType(), NeverType()):
        return const IsSubtypeOf.failure();

      case (ExtensionType(), NeverType()):
        return const IsSubtypeOf.failure();

      case (DynamicType(), RecordType()):
        return const IsSubtypeOf.failure();

      case (VoidType(), RecordType()):
        return const IsSubtypeOf.failure();

      case (InterfaceType(), RecordType()):
        return const IsSubtypeOf.failure();

      case (FunctionType(), RecordType()):
        return const IsSubtypeOf.failure();

      case (
          StructuralParameterType sStructuralParameterType,
          RecordType tRecordType,
        ):
        return performSubtypeCheck(
          sStructuralParameterType.parameter.bound,
          tRecordType,
        ).and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sStructuralParameterType,
            tRecordType,
          ),
        );

      case (IntersectionType sIntersectionType, RecordType tRecordType):
        return performSubtypeCheck(
          sIntersectionType.right,
          tRecordType,
        );

      case (TypeParameterType sTypeParameterType, RecordType tRecordType):
        return performSubtypeCheck(
          sTypeParameterType.parameter.bound,
          tRecordType,
        ).and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sTypeParameterType,
            tRecordType,
          ),
        );

      case (TypedefType sTypedefType, RecordType tRecordType):
        return performSubtypeCheck(
          sTypedefType.unalias,
          tRecordType,
        );

      case (FutureOrType(), RecordType()):
        return const IsSubtypeOf.failure();

      case (RecordType sRecordType, RecordType tRecordType):
        if (sRecordType.positional.length != tRecordType.positional.length ||
            sRecordType.named.length != tRecordType.named.length) {
          return const IsSubtypeOf.failure();
        }
        for (int i = 0; i < sRecordType.named.length; i++) {
          if (sRecordType.named[i].name != tRecordType.named[i].name) {
            return const IsSubtypeOf.failure();
          }
        }

        IsSubtypeOf result = IsSubtypeOf.success();
        for (int i = 0; i < sRecordType.positional.length; i++) {
          result = result.and(
            performSubtypeCheck(
              sRecordType.positional[i],
              tRecordType.positional[i],
            ),
          );
          if (!result.isSuccess()) {
            return const IsSubtypeOf.failure();
          }
        }
        for (int i = 0; i < sRecordType.named.length; i++) {
          result = result.and(
            performSubtypeCheck(
              sRecordType.named[i].type,
              tRecordType.named[i].type,
            ),
          );
          if (!result.isSuccess()) {
            return const IsSubtypeOf.failure();
          }
        }
        return result.and(
          new IsSubtypeOf.basedSolelyOnNullabilities(sRecordType, tRecordType),
        );

      case (ExtensionType(), RecordType()):
        return const IsSubtypeOf.failure();

      case (DynamicType(), ExtensionType()):
        return const IsSubtypeOf.failure();

      case (VoidType(), ExtensionType()):
        return const IsSubtypeOf.failure();

      case (InterfaceType(), ExtensionType()):
        return const IsSubtypeOf.failure();

      case (FunctionType(), ExtensionType()):
        return const IsSubtypeOf.failure();

      case (TypeParameterType sTypeParameterType, ExtensionType tExtensionType):
        return performSubtypeCheck(
          sTypeParameterType.bound,
          tExtensionType,
        );

      case (
          StructuralParameterType sStructuralParameterType,
          ExtensionType tExtensionType,
        ):
        return performSubtypeCheck(
          sStructuralParameterType.bound,
          tExtensionType,
        );

      case (IntersectionType sIntersectionType, ExtensionType tExtensionType):
        return performSubtypeCheck(
          sIntersectionType.right,
          tExtensionType,
        );

      case (TypedefType sTypedefType, ExtensionType tExtensionType):
        return performSubtypeCheck(
          sTypedefType.unalias,
          tExtensionType,
        );

      case (FutureOrType(), ExtensionType()):
        return const IsSubtypeOf.failure();

      case (RecordType(), ExtensionType()):
        return const IsSubtypeOf.failure();

      case (ExtensionType sExtensionType, ExtensionType tExtensionType):
        List<DartType>? typeArguments = hierarchy
            .getExtensionTypeArgumentsAsInstanceOfExtensionTypeDeclaration(
          sExtensionType,
          tExtensionType.extensionTypeDeclaration,
        );
        if (typeArguments == null) {
          return const IsSubtypeOf.failure();
        }
        return areTypeArgumentsOfSubtypeKernel(
          typeArguments,
          tExtensionType.typeArguments,
          tExtensionType.extensionTypeDeclaration.typeParameters,
        ).and(
          new IsSubtypeOf.basedSolelyOnNullabilities(
            sExtensionType,
            tExtensionType,
          ),
        );

      case (AuxiliaryType(), _):
      case (_, AuxiliaryType()):
        throw "Unhandled type combination: "
            "${s.runtimeType} ${t.runtimeType}";

      case (FunctionTypeParameterType(), _):
      case (_, FunctionTypeParameterType()):
        throw "Unimplemented type combination: "
            "${s.runtimeType} ${t.runtimeType}";

      case (ClassTypeParameterType(), _):
      case (_, ClassTypeParameterType()):
        throw "Unimplemented type combination: "
            "${s.runtimeType} ${t.runtimeType}";
    }
  }

  /// Returns true if all type arguments in [s] and [t] pairwise are subtypes
  /// with respect to the variance of the corresponding [p] type parameter.
  IsSubtypeOf areTypeArgumentsOfSubtypeKernel(
    List<DartType> s,
    List<DartType> t,
    List<TypeParameter> p,
  ) {
    if (s.length != t.length || s.length != p.length) {
      throw "Numbers of type arguments don't match $s $t with parameters $p.";
    }
    IsSubtypeOf result = const IsSubtypeOf.success();
    for (int i = 0; i < s.length; i++) {
      Variance variance = p[i].variance;
      if (variance == Variance.contravariant) {
        result = result.and(performSubtypeCheck(t[i], s[i]));
        if (!result.isSuccess()) {
          return const IsSubtypeOf.failure();
        }
      } else if (variance == Variance.invariant) {
        result = result.and(
          performMutualSubtypesCheck(s[i], t[i]),
        );
        if (!result.isSuccess()) {
          return const IsSubtypeOf.failure();
        }
      } else {
        result = result.and(performSubtypeCheck(s[i], t[i]));
        if (!result.isSuccess()) {
          return const IsSubtypeOf.failure();
        }
      }
    }
    return result;
  }

  static List<Object>? typeChecksForTesting;

  TypeDeclarationType? getTypeAsInstanceOf(
    TypeDeclarationType type,
    TypeDeclaration typeDeclaration,
    CoreTypes coreTypes,
  ) {
    return hierarchy.getTypeAsInstanceOf(type, typeDeclaration);
  }

  List<DartType>? getTypeArgumentsAsInstanceOf(
    TypeDeclarationType type,
    TypeDeclaration typeDeclaration,
  ) {
    return hierarchy.getTypeArgumentsAsInstanceOf(type, typeDeclaration);
  }

  bool isTop(DartType type) {
    return type is DynamicType ||
        type is VoidType ||
        type == hierarchy.coreTypes.objectNullableRawType;
  }

  IsSubtypeOf performMutualSubtypesCheck(
    DartType type1,
    DartType type2,
  ) {
    return performSubtypeCheck(
      type1,
      type2,
    ).andSubtypeCheckFor(type2, type1, this);
  }
}
