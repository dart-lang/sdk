// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart'
    show
        BottomType,
        Class,
        DartType,
        DynamicType,
        FunctionType,
        FutureOrType,
        InterfaceType,
        InvalidType,
        Library,
        NamedType,
        NeverType,
        NullType,
        Nullability,
        TypeParameter,
        TypeParameterType,
        TypedefType,
        Variance,
        VoidType;

import '../class_hierarchy.dart' show ClassHierarchyBase;

import '../core_types.dart' show CoreTypes;

import '../type_algebra.dart'
    show Substitution, combineNullabilitiesForSubstitution;

import '../type_environment.dart' show IsSubtypeOf, SubtypeCheckMode;

import '../src/standard_bounds.dart';

class Types with StandardBounds {
  @override
  final ClassHierarchyBase hierarchy;

  Types(this.hierarchy);

  @override
  CoreTypes get coreTypes => hierarchy.coreTypes;

  bool areMutualSubtypes(DartType s, DartType t, SubtypeCheckMode mode) {
    IsSubtypeOf result = performNullabilityAwareMutualSubtypesCheck(s, t);
    switch (mode) {
      case SubtypeCheckMode.ignoringNullabilities:
        return result.isSubtypeWhenIgnoringNullabilities();
      case SubtypeCheckMode.withNullabilities:
        return result.isSubtypeWhenUsingNullabilities();
    }
    return throw new StateError("Unhandled subtype check mode '$mode'.");
  }

  bool _isSubtypeFromMode(IsSubtypeOf isSubtypeOf, SubtypeCheckMode mode) {
    switch (mode) {
      case SubtypeCheckMode.withNullabilities:
        return isSubtypeOf.isSubtypeWhenUsingNullabilities();
      case SubtypeCheckMode.ignoringNullabilities:
        return isSubtypeOf.isSubtypeWhenIgnoringNullabilities();
      default:
        throw new StateError("Unhandled subtype checking mode '$mode'");
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
    typeChecksForTesting ??= <Object>[];
    typeChecksForTesting.add([subtype, supertype, booleanResult]);
    return booleanResult;
  }

  IsSubtypeOf performNullabilityAwareSubtypeCheck(DartType s, DartType t) {
    // TODO(johnniwinther,dmitryas): Ensure complete handling of InvalidType in
    // the subtype relation.
    if (s is InvalidType || t is InvalidType) {
      return const IsSubtypeOf.always();
    }

    if (s is BottomType) {
      return const IsSubtypeOf.always(); // Rule 3.
    }
    if (t is DynamicType) {
      return const IsSubtypeOf.always(); // Rule 2.
    }
    if (t is VoidType) {
      return const IsSubtypeOf.always(); // Rule 2.
    }
    if (t is BottomType) {
      return const IsSubtypeOf.never();
    }
    if (s is NeverType) {
      return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);
    }
    if (s is NullType) {
      // Rule 4.
      return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);
    }

    if (t is InterfaceType) {
      Class cls = t.classNode;
      if (cls == hierarchy.coreTypes.objectClass && s is! FutureOrType) {
        return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);
      }
      const IsInterfaceSubtypeOf relation = const IsInterfaceSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return s.promotedBound == null
            ? relation.isTypeParameterRelated(s, t, this)
            : relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      }
    } else if (t is FunctionType) {
      const IsFunctionSubtypeOf relation = const IsFunctionSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return s.promotedBound == null
            ? relation.isTypeParameterRelated(s, t, this)
            : relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      }
    } else if (t is TypeParameterType) {
      if (t.promotedBound == null) {
        const IsTypeParameterSubtypeOf relation =
            const IsTypeParameterSubtypeOf();
        if (s is DynamicType) {
          return relation.isDynamicRelated(s, t, this);
        } else if (s is VoidType) {
          return relation.isVoidRelated(s, t, this);
        } else if (s is InterfaceType) {
          return relation.isInterfaceRelated(s, t, this);
        } else if (s is FunctionType) {
          return relation.isFunctionRelated(s, t, this);
        } else if (s is TypeParameterType) {
          return s.promotedBound == null
              ? relation.isTypeParameterRelated(s, t, this)
              : relation.isIntersectionRelated(s, t, this);
        } else if (s is TypedefType) {
          return relation.isTypedefRelated(s, t, this);
        } else if (s is FutureOrType) {
          return relation.isFutureOrRelated(s, t, this);
        }
      } else {
        const IsIntersectionSubtypeOf relation =
            const IsIntersectionSubtypeOf();
        if (s is DynamicType) {
          return relation.isDynamicRelated(s, t, this);
        } else if (s is VoidType) {
          return relation.isVoidRelated(s, t, this);
        } else if (s is InterfaceType) {
          return relation.isInterfaceRelated(s, t, this);
        } else if (s is FunctionType) {
          return relation.isFunctionRelated(s, t, this);
        } else if (s is TypeParameterType) {
          return s.promotedBound == null
              ? relation.isTypeParameterRelated(s, t, this)
              : relation.isIntersectionRelated(s, t, this);
        } else if (s is TypedefType) {
          return relation.isTypedefRelated(s, t, this);
        } else if (s is FutureOrType) {
          return relation.isFutureOrRelated(s, t, this);
        }
      }
    } else if (t is TypedefType) {
      const IsTypedefSubtypeOf relation = const IsTypedefSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return s.promotedBound == null
            ? relation.isTypeParameterRelated(s, t, this)
            : relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      }
    } else if (t is FutureOrType) {
      const IsFutureOrSubtypeOf relation = const IsFutureOrSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return s.promotedBound == null
            ? relation.isTypeParameterRelated(s, t, this)
            : relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      }
    } else if (t is NullType) {
      const IsNullTypeSubtypeOf relation = const IsNullTypeSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return s.promotedBound == null
            ? relation.isTypeParameterRelated(s, t, this)
            : relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      }
    } else if (t is NeverType) {
      const IsNeverTypeSubtypeOf relation = const IsNeverTypeSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return s.promotedBound == null
            ? relation.isTypeParameterRelated(s, t, this)
            : relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      }
    } else {
      throw "Unhandled type: ${t.runtimeType}";
    }
    throw "Unhandled type combination: ${t.runtimeType} ${s.runtimeType}";
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
      int variance = p[i].variance;
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

  static List<Object> typeChecksForTesting;

  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass,
      Library clientLibrary, CoreTypes coreTypes) {
    return hierarchy.getTypeAsInstanceOf(type, superclass, clientLibrary);
  }

  List<DartType> getTypeArgumentsAsInstanceOf(
      InterfaceType type, Class superclass) {
    return hierarchy.getTypeArgumentsAsInstanceOf(type, superclass);
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

abstract class TypeRelation<T extends DartType> {
  const TypeRelation();

  IsSubtypeOf isDynamicRelated(DynamicType s, T t, Types types);

  IsSubtypeOf isVoidRelated(VoidType s, T t, Types types);

  IsSubtypeOf isInterfaceRelated(InterfaceType s, T t, Types types);

  IsSubtypeOf isIntersectionRelated(
      TypeParameterType intersection, T t, Types types);

  IsSubtypeOf isFunctionRelated(FunctionType s, T t, Types types);

  IsSubtypeOf isFutureOrRelated(FutureOrType s, T t, Types types);

  IsSubtypeOf isTypeParameterRelated(TypeParameterType s, T t, Types types);

  IsSubtypeOf isTypedefRelated(TypedefType s, T t, Types types);
}

class IsInterfaceSubtypeOf extends TypeRelation<InterfaceType> {
  const IsInterfaceSubtypeOf();

  @override
  IsSubtypeOf isInterfaceRelated(
      InterfaceType s, InterfaceType t, Types types) {
    List<DartType> asSupertypeArguments =
        types.hierarchy.getTypeArgumentsAsInstanceOf(s, t.classNode);
    if (asSupertypeArguments == null) {
      return const IsSubtypeOf.never();
    }
    return types
        .areTypeArgumentsOfSubtypeKernel(
            asSupertypeArguments, t.typeArguments, t.classNode.typeParameters)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, InterfaceType t, Types types) {
    return types
        .performNullabilityAwareSubtypeCheck(s.parameter.bound, t)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isFutureOrRelated(FutureOrType s, InterfaceType t, Types types) {
    // Rules 7.1 and 7.2.
    return types
        .performNullabilityAwareSubtypeCheck(s.typeArgument, t)
        .andSubtypeCheckFor(
            new InterfaceType(types.hierarchy.coreTypes.futureClass,
                Nullability.nonNullable, [s.typeArgument]),
            t,
            types)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      TypeParameterType intersection, InterfaceType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(
        intersection.promotedBound, t); // Rule 12.
  }

  @override
  IsSubtypeOf isDynamicRelated(DynamicType s, InterfaceType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFunctionRelated(FunctionType s, InterfaceType t, Types types) {
    return t.classNode == types.hierarchy.coreTypes.functionClass
        ? new IsSubtypeOf.basedSolelyOnNullabilities(s, t)
        : const IsSubtypeOf.never(); // Rule 14.
  }

  @override
  IsSubtypeOf isTypedefRelated(TypedefType s, InterfaceType t, Types types) {
    // Rule 5.
    return types
        .performNullabilityAwareSubtypeCheck(s.unalias, t)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isVoidRelated(VoidType s, InterfaceType t, Types types) {
    return const IsSubtypeOf.never();
  }
}

class IsFunctionSubtypeOf extends TypeRelation<FunctionType> {
  const IsFunctionSubtypeOf();

  @override
  IsSubtypeOf isFunctionRelated(FunctionType s, FunctionType t, Types types) {
    List<TypeParameter> sTypeVariables = s.typeParameters;
    List<TypeParameter> tTypeVariables = t.typeParameters;
    if (sTypeVariables.length != tTypeVariables.length) {
      return const IsSubtypeOf.never();
    }
    IsSubtypeOf result = const IsSubtypeOf.always();
    if (sTypeVariables.isNotEmpty) {
      // If the function types have type variables, we alpha-rename the type
      // variables of [s] to use those of [t].

      // As an optimization, we first check if the bounds of the type variables
      // of the two types on the same positions are mutual subtypes without
      // alpha-renaming them.
      List<DartType> typeVariableSubstitution = <DartType>[];
      for (int i = 0; i < sTypeVariables.length; i++) {
        TypeParameter sTypeVariable = sTypeVariables[i];
        TypeParameter tTypeVariable = tTypeVariables[i];
        result = result.and(types.performNullabilityAwareMutualSubtypesCheck(
            sTypeVariable.bound, tTypeVariable.bound));
        typeVariableSubstitution.add(new TypeParameterType.forAlphaRenaming(
            sTypeVariable, tTypeVariable));
      }
      Substitution substitution =
          Substitution.fromPairs(sTypeVariables, typeVariableSubstitution);
      // If the bounds aren't the same, we need to try again after computing the
      // substitution of type variables.
      if (!result.isSubtypeWhenIgnoringNullabilities()) {
        result = const IsSubtypeOf.always();
        for (int i = 0; i < sTypeVariables.length; i++) {
          TypeParameter sTypeVariable = sTypeVariables[i];
          TypeParameter tTypeVariable = tTypeVariables[i];
          result = result.and(types.performNullabilityAwareMutualSubtypesCheck(
              substitution.substituteType(sTypeVariable.bound),
              tTypeVariable.bound));
          if (!result.isSubtypeWhenIgnoringNullabilities()) {
            return const IsSubtypeOf.never();
          }
        }
      }
      s = substitution.substituteType(s.withoutTypeParameters);
    }
    result = result.and(
        types.performNullabilityAwareSubtypeCheck(s.returnType, t.returnType));
    if (!result.isSubtypeWhenIgnoringNullabilities()) {
      return const IsSubtypeOf.never();
    }
    List<DartType> sPositional = s.positionalParameters;
    List<DartType> tPositional = t.positionalParameters;
    if (s.requiredParameterCount > t.requiredParameterCount) {
      // Rule 15, n1 <= n2.
      return const IsSubtypeOf.never();
    }
    if (sPositional.length < tPositional.length) {
      // Rule 15, n1 + k1 >= n2 + k2.
      return const IsSubtypeOf.never();
    }
    for (int i = 0; i < tPositional.length; i++) {
      result = result.and(types.performNullabilityAwareSubtypeCheck(
          tPositional[i], sPositional[i]));
      if (!result.isSubtypeWhenIgnoringNullabilities()) {
        // Rule 15, Tj <: Sj.
        return const IsSubtypeOf.never();
      }
    }
    List<NamedType> sNamedParameters = s.namedParameters;
    List<NamedType> tNamedParameters = t.namedParameters;
    if (sNamedParameters.isNotEmpty || tNamedParameters.isNotEmpty) {
      // Rule 16, the number of positional parameters must be the same.
      if (sPositional.length != tPositional.length) {
        return const IsSubtypeOf.never();
      }
      if (s.requiredParameterCount != t.requiredParameterCount) {
        return const IsSubtypeOf.never();
      }

      // Rule 16, the parameter names of [t] must be a subset of those of
      // [s]. Also, for the intersection, the type of the parameter of [t] must
      // be a subtype of the type of the parameter of [s].
      int sCount = 0;
      for (int tCount = 0; tCount < tNamedParameters.length; tCount++) {
        NamedType tNamedParameter = tNamedParameters[tCount];
        String name = tNamedParameter.name;
        NamedType sNamedParameter;
        for (; sCount < sNamedParameters.length; sCount++) {
          sNamedParameter = sNamedParameters[sCount];
          if (sNamedParameter.name == name) {
            break;
          } else if (sNamedParameter.isRequired) {
            /// From the NNBD spec: For each j such that r0j is required, then
            /// there exists an i in n+1...q such that xj = yi, and r1i is
            /// required
            result = result.and(new IsSubtypeOf.onlyIfIgnoringNullabilities(
                subtype: s, supertype: t));
          }
        }
        if (sCount == sNamedParameters.length) return const IsSubtypeOf.never();
        // Increment [sCount] so we don't check [sNamedParameter] again in the
        // loop above or below and assume it is an extra (unmatched) parameter.
        sCount++;
        result = result.and(types.performNullabilityAwareSubtypeCheck(
            tNamedParameter.type, sNamedParameter.type));
        if (!result.isSubtypeWhenIgnoringNullabilities()) {
          return const IsSubtypeOf.never();
        }

        /// From the NNBD spec: For each j such that r0j is required, then there
        /// exists an i in n+1...q such that xj = yi, and r1i is required
        if (sNamedParameter.isRequired && !tNamedParameter.isRequired) {
          result = result.and(new IsSubtypeOf.onlyIfIgnoringNullabilities(
              subtype: s, supertype: t));
        }
      }
      for (; sCount < sNamedParameters.length; sCount++) {
        NamedType sNamedParameter = sNamedParameters[sCount];
        if (sNamedParameter.isRequired) {
          /// From the NNBD spec: For each j such that r0j is required, then
          /// there exists an i in n+1...q such that xj = yi, and r1i is
          /// required
          result = result.and(new IsSubtypeOf.onlyIfIgnoringNullabilities(
              subtype: s, supertype: t));
        }
      }
    }
    return result.and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isInterfaceRelated(InterfaceType s, FunctionType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isDynamicRelated(DynamicType s, FunctionType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFutureOrRelated(FutureOrType s, FunctionType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      TypeParameterType intersection, FunctionType t, Types types) {
    // Rule 12.
    return types.performNullabilityAwareSubtypeCheck(
        intersection.promotedBound, t);
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, FunctionType t, Types types) {
    // Rule 13.
    return types
        .performNullabilityAwareSubtypeCheck(s.parameter.bound, t)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isTypedefRelated(TypedefType s, FunctionType t, Types types) {
    // Rule 5.
    return types.performNullabilityAwareSubtypeCheck(s.unalias, t);
  }

  @override
  IsSubtypeOf isVoidRelated(VoidType s, FunctionType t, Types types) {
    return const IsSubtypeOf.never();
  }
}

class IsTypeParameterSubtypeOf extends TypeRelation<TypeParameterType> {
  const IsTypeParameterSubtypeOf();

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, TypeParameterType t, Types types) {
    IsSubtypeOf result = const IsSubtypeOf.always();
    if (s.parameter != t.parameter) {
      result = types.performNullabilityAwareSubtypeCheck(s.bound, t);
    }
    if (s.nullability == Nullability.undetermined &&
        t.nullability == Nullability.undetermined) {
      // The two nullabilities are undetermined, but are connected via
      // additional constraint, namely that they will be equal at run time.
      return result;
    }
    return result.and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      TypeParameterType intersection, TypeParameterType t, Types types) {
    // Nullable types aren't promoted to intersection types.
    // TODO(dmitryas): Uncomment the following when the inference is updated.
    //assert(intersection.typeParameterTypeNullability != Nullability.nullable);

    // Rule 8.
    if (intersection.parameter == t.parameter) {
      if (intersection.nullability == Nullability.undetermined &&
          t.nullability == Nullability.undetermined) {
        // The two nullabilities are undetermined, but are connected via
        // additional constraint, namely that they will be equal at run time.
        return const IsSubtypeOf.always();
      }
      return new IsSubtypeOf.basedSolelyOnNullabilities(intersection, t);
    }

    // Rule 12.
    return types.performNullabilityAwareSubtypeCheck(
        intersection.promotedBound
            .withDeclaredNullability(intersection.nullability),
        t);
  }

  @override
  IsSubtypeOf isInterfaceRelated(
      InterfaceType s, TypeParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isDynamicRelated(
      DynamicType s, TypeParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFunctionRelated(
      FunctionType s, TypeParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFutureOrRelated(
      FutureOrType s, TypeParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isTypedefRelated(
      TypedefType s, TypeParameterType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.unalias, t);
  }

  @override
  IsSubtypeOf isVoidRelated(VoidType s, TypeParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }
}

class IsTypedefSubtypeOf extends TypeRelation<TypedefType> {
  const IsTypedefSubtypeOf();

  @override
  IsSubtypeOf isInterfaceRelated(InterfaceType s, TypedefType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s, t.unalias);
  }

  @override
  IsSubtypeOf isDynamicRelated(DynamicType s, TypedefType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s, t.unalias);
  }

  @override
  IsSubtypeOf isFunctionRelated(FunctionType s, TypedefType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s, t.unalias);
  }

  @override
  IsSubtypeOf isFutureOrRelated(FutureOrType s, TypedefType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s, t.unalias);
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      TypeParameterType intersection, TypedefType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(intersection, t.unalias);
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, TypedefType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s, t.unalias);
  }

  @override
  IsSubtypeOf isTypedefRelated(TypedefType s, TypedefType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.unalias, t.unalias);
  }

  @override
  IsSubtypeOf isVoidRelated(VoidType s, TypedefType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s, t.unalias);
  }
}

class IsFutureOrSubtypeOf extends TypeRelation<FutureOrType> {
  const IsFutureOrSubtypeOf();

  @override
  IsSubtypeOf isInterfaceRelated(InterfaceType s, FutureOrType t, Types types) {
    return types
        // Rule 11.
        .performNullabilityAwareSubtypeCheck(
            s, t.typeArgument.withDeclaredNullability(t.nullability))
        // Rule 10.
        .orSubtypeCheckFor(
            s,
            new InterfaceType(types.hierarchy.coreTypes.futureClass,
                t.nullability, [t.typeArgument]),
            types);
  }

  @override
  IsSubtypeOf isFutureOrRelated(FutureOrType s, FutureOrType t, Types types) {
    // This follows from combining rules 7, 10, and 11.
    DartType sArgument = s.typeArgument;
    DartType tArgument = t.typeArgument;
    DartType sFutureOfArgument = new InterfaceType(
        types.hierarchy.coreTypes.futureClass,
        Nullability.nonNullable,
        [sArgument]);
    DartType tFutureOfArgument = new InterfaceType(
        types.hierarchy.coreTypes.futureClass,
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
    return types
        .performNullabilityAwareSubtypeCheck(sArgument, tArgument)
        .or(types
            .performNullabilityAwareSubtypeCheck(sArgument, tFutureOfArgument)
            .andSubtypeCheckFor(sFutureOfArgument, tArgument, types))
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isDynamicRelated(DynamicType s, FutureOrType t, Types types) {
    // Rule 11.
    return types.performNullabilityAwareSubtypeCheck(
        s, t.typeArgument.withDeclaredNullability(t.nullability));
  }

  @override
  IsSubtypeOf isVoidRelated(VoidType s, FutureOrType t, Types types) {
    // Rule 11.
    return types.performNullabilityAwareSubtypeCheck(
        s, t.typeArgument.withDeclaredNullability(t.nullability));
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, FutureOrType t, Types types) {
    // TODO(dmitryas): Revise the original optimization.
    return types
        // Rule 11.
        .performNullabilityAwareSubtypeCheck(
            s, t.typeArgument.withDeclaredNullability(t.nullability))
        // Rule 13.
        .orSubtypeCheckFor(
            s.parameter.bound.withDeclaredNullability(
                combineNullabilitiesForSubstitution(
                    s.parameter.bound.nullability, s.nullability)),
            t,
            types)
        // Rule 10.
        .orSubtypeCheckFor(
            s,
            new InterfaceType(types.hierarchy.coreTypes.futureClass,
                t.nullability, [t.typeArgument]),
            types);
  }

  @override
  IsSubtypeOf isFunctionRelated(FunctionType s, FutureOrType t, Types types) {
    // Rule 11.
    return types.performNullabilityAwareSubtypeCheck(
        s, t.typeArgument.withDeclaredNullability(t.nullability));
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      TypeParameterType intersection, FutureOrType t, Types types) {
    return isTypeParameterRelated(intersection, t, types) // Rule 8.
        .orSubtypeCheckFor(intersection.promotedBound, t, types); // Rule 12.
  }

  @override
  IsSubtypeOf isTypedefRelated(TypedefType s, FutureOrType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.unalias, t);
  }
}

class IsIntersectionSubtypeOf extends TypeRelation<TypeParameterType> {
  const IsIntersectionSubtypeOf();

  @override
  IsSubtypeOf isIntersectionRelated(TypeParameterType sIntersection,
      TypeParameterType tIntersection, Types types) {
    // Rule 9.
    return const IsTypeParameterSubtypeOf()
        .isIntersectionRelated(sIntersection, tIntersection, types)
        .andSubtypeCheckFor(sIntersection, tIntersection.promotedBound, types);
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, TypeParameterType intersection, Types types) {
    // Rule 9.
    return const IsTypeParameterSubtypeOf()
        .isTypeParameterRelated(s, intersection, types)
        .andSubtypeCheckFor(s, intersection.promotedBound, types);
  }

  @override
  IsSubtypeOf isInterfaceRelated(
      InterfaceType s, TypeParameterType intersection, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isDynamicRelated(
      DynamicType s, TypeParameterType intersection, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFunctionRelated(
      FunctionType s, TypeParameterType intersection, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFutureOrRelated(
      FutureOrType s, TypeParameterType intersection, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isTypedefRelated(
      TypedefType s, TypeParameterType intersection, Types types) {
    // Rule 5.
    return types.performNullabilityAwareSubtypeCheck(s.unalias, intersection);
  }

  @override
  IsSubtypeOf isVoidRelated(
      VoidType s, TypeParameterType intersection, Types types) {
    return const IsSubtypeOf.never();
  }
}

class IsNullTypeSubtypeOf implements TypeRelation<NullType> {
  const IsNullTypeSubtypeOf();

  IsSubtypeOf isDynamicRelated(DynamicType s, NullType t, Types types) {
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf isVoidRelated(VoidType s, NullType t, Types types) {
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf isInterfaceRelated(InterfaceType s, NullType t, Types types) {
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf isIntersectionRelated(
      TypeParameterType intersection, NullType t, Types types) {
    return types.performNullabilityAwareMutualSubtypesCheck(
        intersection.promotedBound, t);
  }

  IsSubtypeOf isFunctionRelated(FunctionType s, NullType t, Types types) {
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf isFutureOrRelated(FutureOrType s, NullType t, Types types) {
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, NullType t, Types types) {
    // We don't need to combine the check of the bound against [t] with the
    // check of the nullability of [s] against the nullability of [t] because
    // [t] is always nullable.
    return types.performNullabilityAwareSubtypeCheck(s.bound, t);
  }

  IsSubtypeOf isTypedefRelated(TypedefType s, NullType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.unalias, t);
  }
}

class IsNeverTypeSubtypeOf implements TypeRelation<NeverType> {
  const IsNeverTypeSubtypeOf();

  IsSubtypeOf isDynamicRelated(DynamicType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf isVoidRelated(VoidType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf isInterfaceRelated(InterfaceType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf isIntersectionRelated(
      TypeParameterType intersection, NeverType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(
        intersection.promotedBound, t);
  }

  IsSubtypeOf isFunctionRelated(FunctionType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf isFutureOrRelated(FutureOrType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, NeverType t, Types types) {
    return types
        .performNullabilityAwareSubtypeCheck(s.bound, t)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  IsSubtypeOf isTypedefRelated(TypedefType s, NeverType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.unalias, t);
  }
}
