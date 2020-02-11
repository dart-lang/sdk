// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.types;

import 'package:kernel/ast.dart'
    show
        BottomType,
        Class,
        DartType,
        DynamicType,
        FunctionType,
        InterfaceType,
        InvalidType,
        Library,
        NamedType,
        NeverType,
        Nullability,
        TypeParameter,
        TypeParameterType,
        TypedefType,
        Variance,
        VoidType;

import 'package:kernel/core_types.dart';

import 'package:kernel/type_algebra.dart'
    show Substitution, combineNullabilitiesForSubstitution;

import 'package:kernel/type_environment.dart';

import 'package:kernel/src/future_or.dart';

import 'kernel_builder.dart' show ClassHierarchyBuilder;

class Types implements SubtypeTester {
  final ClassHierarchyBuilder hierarchy;

  Types(this.hierarchy);

  /// Returns true if [s] is a subtype of [t].
  bool isSubtypeOfKernel(DartType s, DartType t, SubtypeCheckMode mode) {
    IsSubtypeOf result = performNullabilityAwareSubtypeCheck(s, t);
    switch (mode) {
      case SubtypeCheckMode.withNullabilities:
        return result.isSubtypeWhenUsingNullabilities();
      case SubtypeCheckMode.ignoringNullabilities:
        return result.isSubtypeWhenIgnoringNullabilities();
      default:
        throw new StateError("Unhandled subtype checking mode '$mode'");
    }
  }

  @override
  IsSubtypeOf performNullabilityAwareSubtypeCheck(DartType s, DartType t) {
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

    // TODO(dmitryas): Remove InvalidType from subtype relation.
    if (s is InvalidType) {
      // InvalidType is a bottom type.
      return const IsSubtypeOf.always();
    }
    if (t is InvalidType) {
      return const IsSubtypeOf.never();
    }

    if (t is InterfaceType) {
      Class cls = t.classNode;
      if (cls == hierarchy.objectClass &&
          !(s is InterfaceType && s.classNode == hierarchy.futureOrClass)) {
        return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);
      }
      if (cls == hierarchy.futureOrClass) {
        const IsFutureOrSubtypeOf relation = const IsFutureOrSubtypeOf();
        if (s is DynamicType) {
          return relation.isDynamicRelated(s, t, this);
        } else if (s is VoidType) {
          return relation.isVoidRelated(s, t, this);
        } else if (s is InterfaceType) {
          return s.classNode == hierarchy.futureOrClass
              ? relation.isFutureOrRelated(s, t, this)
              : relation.isInterfaceRelated(s, t, this);
        } else if (s is FunctionType) {
          return relation.isFunctionRelated(s, t, this);
        } else if (s is TypeParameterType) {
          return s.promotedBound == null
              ? relation.isTypeParameterRelated(s, t, this)
              : relation.isIntersectionRelated(s, t, this);
        } else if (s is TypedefType) {
          return relation.isTypedefRelated(s, t, this);
        }
      } else {
        const IsInterfaceSubtypeOf relation = const IsInterfaceSubtypeOf();
        if (s is DynamicType) {
          return relation.isDynamicRelated(s, t, this);
        } else if (s is VoidType) {
          return relation.isVoidRelated(s, t, this);
        } else if (s is InterfaceType) {
          return s.classNode == hierarchy.futureOrClass
              ? relation.isFutureOrRelated(s, t, this)
              : relation.isInterfaceRelated(s, t, this);
        } else if (s is FunctionType) {
          return relation.isFunctionRelated(s, t, this);
        } else if (s is TypeParameterType) {
          return s.promotedBound == null
              ? relation.isTypeParameterRelated(s, t, this)
              : relation.isIntersectionRelated(s, t, this);
        } else if (s is TypedefType) {
          return relation.isTypedefRelated(s, t, this);
        }
      }
    } else if (t is FunctionType) {
      const IsFunctionSubtypeOf relation = const IsFunctionSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return s.classNode == hierarchy.futureOrClass
            ? relation.isFutureOrRelated(s, t, this)
            : relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return s.promotedBound == null
            ? relation.isTypeParameterRelated(s, t, this)
            : relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
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
          return s.classNode == hierarchy.futureOrClass
              ? relation.isFutureOrRelated(s, t, this)
              : relation.isInterfaceRelated(s, t, this);
        } else if (s is FunctionType) {
          return relation.isFunctionRelated(s, t, this);
        } else if (s is TypeParameterType) {
          return s.promotedBound == null
              ? relation.isTypeParameterRelated(s, t, this)
              : relation.isIntersectionRelated(s, t, this);
        } else if (s is TypedefType) {
          return relation.isTypedefRelated(s, t, this);
        }
      } else {
        const IsIntersectionSubtypeOf relation =
            const IsIntersectionSubtypeOf();
        if (s is DynamicType) {
          return relation.isDynamicRelated(s, t, this);
        } else if (s is VoidType) {
          return relation.isVoidRelated(s, t, this);
        } else if (s is InterfaceType) {
          return s.classNode == hierarchy.futureOrClass
              ? relation.isFutureOrRelated(s, t, this)
              : relation.isInterfaceRelated(s, t, this);
        } else if (s is FunctionType) {
          return relation.isFunctionRelated(s, t, this);
        } else if (s is TypeParameterType) {
          return s.promotedBound == null
              ? relation.isTypeParameterRelated(s, t, this)
              : relation.isIntersectionRelated(s, t, this);
        } else if (s is TypedefType) {
          return relation.isTypedefRelated(s, t, this);
        }
      }
    } else if (t is TypedefType) {
      const IsTypedefSubtypeOf relation = const IsTypedefSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return s.classNode == hierarchy.futureOrClass
            ? relation.isFutureOrRelated(s, t, this)
            : relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return s.promotedBound == null
            ? relation.isTypeParameterRelated(s, t, this)
            : relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
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
        result = result.and(isSameTypeKernel(s[i], t[i]));
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

  IsSubtypeOf isSameTypeKernel(DartType s, DartType t) {
    return performNullabilityAwareSubtypeCheck(s, t)
        .andSubtypeCheckFor(t, s, this);
  }

  @override
  bool isSubtypeOf(
      DartType subtype, DartType supertype, SubtypeCheckMode mode) {
    return isSubtypeOfKernel(subtype, supertype, mode);
  }

  @override
  Class get futureOrClass => hierarchy.coreTypes.futureOrClass;

  @override
  Class get functionClass => hierarchy.coreTypes.functionClass;

  @override
  InterfaceType get functionLegacyRawType =>
      hierarchy.coreTypes.functionLegacyRawType;

  @override
  InterfaceType futureType(DartType type, Nullability nullability) {
    return new InterfaceType(
        hierarchy.coreTypes.futureClass, nullability, <DartType>[type]);
  }

  @override
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass,
      Library clientLibrary, CoreTypes coreTypes) {
    return hierarchy.getKernelTypeAsInstanceOf(type, superclass, clientLibrary);
  }

  @override
  List<DartType> getTypeArgumentsAsInstanceOf(
      InterfaceType type, Class superclass) {
    return hierarchy.getKernelTypeArgumentsAsInstanceOf(type, superclass);
  }

  @override
  bool isTop(DartType type) {
    return type is DynamicType ||
        type is VoidType ||
        type == objectLegacyRawType ||
        type == objectNullableRawType;
  }

  @override
  InterfaceType get nullType => hierarchy.coreTypes.nullType;

  @override
  Class get objectClass => hierarchy.coreTypes.objectClass;

  @override
  InterfaceType get objectLegacyRawType {
    return hierarchy.coreTypes.objectLegacyRawType;
  }

  @override
  InterfaceType get objectNullableRawType {
    return hierarchy.coreTypes.objectNullableRawType;
  }

  @override
  IsSubtypeOf performNullabilityAwareMutualSubtypesCheck(
      DartType type1, DartType type2) {
    return isSameTypeKernel(type1, type2);
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

  IsSubtypeOf isFutureOrRelated(InterfaceType futureOr, T t, Types types);

  IsSubtypeOf isTypeParameterRelated(TypeParameterType s, T t, Types types);

  IsSubtypeOf isTypedefRelated(TypedefType s, T t, Types types);
}

class IsInterfaceSubtypeOf extends TypeRelation<InterfaceType> {
  const IsInterfaceSubtypeOf();

  @override
  IsSubtypeOf isInterfaceRelated(
      InterfaceType s, InterfaceType t, Types types) {
    if (s.classNode == types.hierarchy.nullClass) {
      // This is an optimization, to avoid instantiating unnecessary type
      // arguments in getKernelTypeAsInstanceOf.
      return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);
    }
    List<DartType> asSupertypeArguments =
        types.hierarchy.getKernelTypeArgumentsAsInstanceOf(s, t.classNode);
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
  IsSubtypeOf isFutureOrRelated(
      InterfaceType futureOr, InterfaceType t, Types types) {
    List<DartType> arguments = futureOr.typeArguments;
    // Rules 7.1 and 7.2.
    return types
        .performNullabilityAwareSubtypeCheck(arguments.single, t)
        .andSubtypeCheckFor(
            new InterfaceType(types.hierarchy.futureClass,
                Nullability.nonNullable, arguments),
            t,
            types)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(futureOr, t));
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
    return t.classNode == types.hierarchy.functionClass
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
        result = result.and(
            types.isSameTypeKernel(sTypeVariable.bound, tTypeVariable.bound));
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
          result = result.and(types.isSameTypeKernel(
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
    List<NamedType> sNamed = s.namedParameters;
    List<NamedType> tNamed = t.namedParameters;
    if (sNamed.isNotEmpty || tNamed.isNotEmpty) {
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
      for (int tCount = 0; tCount < tNamed.length; tCount++) {
        String name = tNamed[tCount].name;
        for (; sCount < sNamed.length; sCount++) {
          if (sNamed[sCount].name == name) break;
        }
        if (sCount == sNamed.length) return const IsSubtypeOf.never();
        result = result.and(types.performNullabilityAwareSubtypeCheck(
            tNamed[tCount].type, sNamed[sCount].type));
        if (!result.isSubtypeWhenIgnoringNullabilities()) {
          return const IsSubtypeOf.never();
        }
      }
    }
    return result.and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isInterfaceRelated(InterfaceType s, FunctionType t, Types types) {
    if (s.classNode == types.hierarchy.nullClass) {
      // Rule 4.
      return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);
    }
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isDynamicRelated(DynamicType s, FunctionType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFutureOrRelated(
      InterfaceType futureOr, FunctionType t, Types types) {
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
        intersection.promotedBound.withNullability(intersection.nullability),
        t);
  }

  @override
  IsSubtypeOf isInterfaceRelated(
      InterfaceType s, TypeParameterType t, Types types) {
    if (s.classNode == types.hierarchy.nullClass) {
      // Rule 4.
      return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);
    }
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
      InterfaceType futureOr, TypeParameterType t, Types types) {
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
  IsSubtypeOf isFutureOrRelated(
      InterfaceType futureOr, TypedefType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(futureOr, t.unalias);
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

class IsFutureOrSubtypeOf extends TypeRelation<InterfaceType> {
  const IsFutureOrSubtypeOf();

  @override
  IsSubtypeOf isInterfaceRelated(
      InterfaceType s, InterfaceType futureOr, Types types) {
    List<DartType> arguments = futureOr.typeArguments;

    Nullability unitedNullability =
        computeNullabilityOfFutureOr(futureOr, types.hierarchy.futureOrClass);

    return types
        // Rule 11.
        .performNullabilityAwareSubtypeCheck(
            s, arguments.single.withNullability(unitedNullability))
        // Rule 10.
        .orSubtypeCheckFor(
            s,
            new InterfaceType(
                types.hierarchy.futureClass, unitedNullability, arguments),
            types);
  }

  @override
  IsSubtypeOf isFutureOrRelated(
      InterfaceType sFutureOr, InterfaceType tFutureOr, Types types) {
    // This follows from combining rules 7, 10, and 11.
    DartType sArgument = sFutureOr.typeArguments.single;
    DartType tArgument = tFutureOr.typeArguments.single;
    return types.performNullabilityAwareSubtypeCheck(sArgument, tArgument);
  }

  @override
  IsSubtypeOf isDynamicRelated(
      DynamicType s, InterfaceType futureOr, Types types) {
    // Rule 11.
    DartType argument = futureOr.typeArguments.single;
    return types.performNullabilityAwareSubtypeCheck(
        s,
        argument.withNullability(computeNullabilityOfFutureOr(
            futureOr, types.hierarchy.futureOrClass)));
  }

  @override
  IsSubtypeOf isVoidRelated(VoidType s, InterfaceType futureOr, Types types) {
    // Rule 11.
    DartType argument = futureOr.typeArguments.single;
    return types.performNullabilityAwareSubtypeCheck(
        s,
        argument.withNullability(computeNullabilityOfFutureOr(
            futureOr, types.hierarchy.futureOrClass)));
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, InterfaceType futureOr, Types types) {
    List<DartType> arguments = futureOr.typeArguments;
    Nullability unitedNullability =
        computeNullabilityOfFutureOr(futureOr, types.hierarchy.futureOrClass);
    // TODO(dmitryas): Revise the original optimization.
    return types
        // Rule 11.
        .performNullabilityAwareSubtypeCheck(
            s, arguments.single.withNullability(unitedNullability))
        // Rule 13.
        .orSubtypeCheckFor(
            s.parameter.bound.withNullability(
                combineNullabilitiesForSubstitution(
                    s.parameter.bound.nullability, s.nullability)),
            futureOr,
            types)
        // Rule 10.
        .orSubtypeCheckFor(
            s,
            new InterfaceType(
                types.hierarchy.futureClass, unitedNullability, arguments),
            types);
  }

  @override
  IsSubtypeOf isFunctionRelated(
      FunctionType s, InterfaceType futureOr, Types types) {
    // Rule 11.
    DartType argument = futureOr.typeArguments.single;
    return types.performNullabilityAwareSubtypeCheck(
        s,
        argument.withNullability(computeNullabilityOfFutureOr(
            futureOr, types.hierarchy.futureOrClass)));
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      TypeParameterType intersection, InterfaceType futureOr, Types types) {
    return isTypeParameterRelated(intersection, futureOr, types) // Rule 8.
        .orSubtypeCheckFor(
            intersection.promotedBound, futureOr, types); // Rule 12.
  }

  @override
  IsSubtypeOf isTypedefRelated(
      TypedefType s, InterfaceType futureOr, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.unalias, futureOr);
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
    if (s.classNode == types.hierarchy.nullClass) {
      // Rule 4.
      return new IsSubtypeOf.basedSolelyOnNullabilities(s, intersection);
    }
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
      InterfaceType futureOr, TypeParameterType intersection, Types types) {
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

class IsNeverTypeSubtypeOf implements TypeRelation<NeverType> {
  const IsNeverTypeSubtypeOf();

  IsSubtypeOf isDynamicRelated(DynamicType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf isVoidRelated(VoidType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  IsSubtypeOf isInterfaceRelated(InterfaceType s, NeverType t, Types types) {
    if (s.classNode == types.hierarchy.nullClass) {
      if (t.nullability == Nullability.nullable ||
          t.nullability == Nullability.legacy) {
        return const IsSubtypeOf.always();
      }
      if (t.nullability == Nullability.nonNullable) {
        return const IsSubtypeOf.never();
      }
      throw new StateError(
          "Unexpected nullability '$t.nullability' of type Never");
    }
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

  IsSubtypeOf isFutureOrRelated(
      InterfaceType futureOr, NeverType t, Types types) {
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
