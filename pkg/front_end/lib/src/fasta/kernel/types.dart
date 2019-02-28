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
        NamedType,
        TypeParameter,
        TypeParameterType,
        TypedefType,
        VoidType;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'kernel_builder.dart' show ClassHierarchyBuilder;

class Types {
  final ClassHierarchyBuilder hierarchy;

  Types(this.hierarchy);

  /// Returns true if [s] is a subtype of [t].
  bool isSubtypeOfKernel(DartType s, DartType t) {
    if (s is BottomType) {
      return true; // Rule 3.
    }
    if (s is InvalidType) {
      // InvalidType is also a bottom type.
      return true;
    }
    if (t is InvalidType) {
      return false;
    }
    if (t is DynamicType) {
      return true; // Rule 2.
    }
    if (t is VoidType) {
      return true; // Rule 2.
    }
    if (t is BottomType) {
      return false;
    }
    if (t is InterfaceType) {
      Class cls = t.classNode;
      if (cls == hierarchy.objectKernelClass) {
        return true; // Rule 2.
      }
      if (cls == hierarchy.futureOrKernelClass) {
        const IsFutureOrSubtypeOf relation = const IsFutureOrSubtypeOf();
        if (s is DynamicType) {
          return relation.isDynamicRelated(s, t, this);
        } else if (s is VoidType) {
          return relation.isVoidRelated(s, t, this);
        } else if (s is InterfaceType) {
          return s.classNode == hierarchy.futureOrKernelClass
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
          return s.classNode == hierarchy.futureOrKernelClass
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
        return s.classNode == hierarchy.futureOrKernelClass
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
          return s.classNode == hierarchy.futureOrKernelClass
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
          return s.classNode == hierarchy.futureOrKernelClass
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
        return s.classNode == hierarchy.futureOrKernelClass
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
      throw "Unhandled type: ${t.runtimeType}";
    }
    throw "Unhandled type combination: ${t.runtimeType} ${s.runtimeType}";
  }

  /// Returns true if all types in [s] and [t] pairwise are subtypes.
  bool areSubtypesOfKernel(List<DartType> s, List<DartType> t) {
    if (s.length != t.length) {
      throw "Numbers of type arguments don't match $s $t.";
    }
    for (int i = 0; i < s.length; i++) {
      if (!isSubtypeOfKernel(s[i], t[i])) return false;
    }
    return true;
  }

  bool isSameTypeKernel(DartType s, DartType t) {
    return isSubtypeOfKernel(s, t) && isSubtypeOfKernel(t, s);
  }
}

abstract class TypeRelation<T extends DartType> {
  const TypeRelation();

  bool isDynamicRelated(DynamicType s, T t, Types types);

  bool isVoidRelated(VoidType s, T t, Types types);

  bool isInterfaceRelated(InterfaceType s, T t, Types types);

  bool isIntersectionRelated(TypeParameterType intersection, T t, Types types);

  bool isFunctionRelated(FunctionType s, T t, Types types);

  bool isFutureOrRelated(InterfaceType futureOr, T t, Types types);

  bool isTypeParameterRelated(TypeParameterType s, T t, Types types);

  bool isTypedefRelated(TypedefType s, T t, Types types);
}

class IsInterfaceSubtypeOf extends TypeRelation<InterfaceType> {
  const IsInterfaceSubtypeOf();

  @override
  bool isInterfaceRelated(InterfaceType s, InterfaceType t, Types types) {
    if (s.classNode == types.hierarchy.nullKernelClass) {
      // This is an optimization, to avoid instantating unnecessary type
      // arguments in getKernelTypeAsInstanceOf.
      return true;
    }
    InterfaceType asSupertype =
        types.hierarchy.getKernelTypeAsInstanceOf(s, t.classNode);
    if (asSupertype == null) {
      return false;
    } else {
      return types.areSubtypesOfKernel(
          asSupertype.typeArguments, t.typeArguments);
    }
  }

  @override
  bool isTypeParameterRelated(
      TypeParameterType s, InterfaceType t, Types types) {
    return types.isSubtypeOfKernel(s.parameter.bound, t);
  }

  @override
  bool isFutureOrRelated(InterfaceType futureOr, InterfaceType t, Types types) {
    List<DartType> arguments = futureOr.typeArguments;
    if (!types.isSubtypeOfKernel(arguments.single, t)) {
      return false; // Rule 7.1
    }
    if (!types.isSubtypeOfKernel(
        new InterfaceType(types.hierarchy.futureKernelClass, arguments), t)) {
      return false; // Rule 7.2
    }
    return true;
  }

  @override
  bool isIntersectionRelated(
      TypeParameterType intersection, InterfaceType t, Types types) {
    return types.isSubtypeOfKernel(intersection.promotedBound, t); // Rule 12.
  }

  @override
  bool isDynamicRelated(DynamicType s, InterfaceType t, Types types) {
    return false;
  }

  @override
  bool isFunctionRelated(FunctionType s, InterfaceType t, Types types) {
    return t.classNode == types.hierarchy.functionKernelClass; // Rule 14.
  }

  @override
  bool isTypedefRelated(TypedefType s, InterfaceType t, Types types) {
    // Rule 5.
    return types.isSubtypeOfKernel(s.unalias, t);
  }

  @override
  bool isVoidRelated(VoidType s, InterfaceType t, Types types) {
    return false;
  }
}

class IsFunctionSubtypeOf extends TypeRelation<FunctionType> {
  const IsFunctionSubtypeOf();

  @override
  bool isFunctionRelated(FunctionType s, FunctionType t, Types types) {
    List<TypeParameter> sTypeVariables = s.typeParameters;
    List<TypeParameter> tTypeVariables = t.typeParameters;
    if (sTypeVariables.length != tTypeVariables.length) return false;
    if (sTypeVariables.isNotEmpty) {
      // If the function types have type variables, we alpha-rename the type
      // variables of [s] to use those of [t].
      List<DartType> typeVariableSubstitution = <DartType>[];
      bool secondBoundsCheckNeeded = false;
      for (int i = 0; i < sTypeVariables.length; i++) {
        TypeParameter sTypeVariable = sTypeVariables[i];
        TypeParameter tTypeVariable = tTypeVariables[i];
        if (!types.isSameTypeKernel(sTypeVariable.bound, tTypeVariable.bound)) {
          // If the bounds aren't the same, we need to try again after
          // computing the substitution of type variables.
          secondBoundsCheckNeeded = true;
        }
        typeVariableSubstitution.add(new TypeParameterType(tTypeVariable));
      }
      Substitution substitution =
          Substitution.fromPairs(sTypeVariables, typeVariableSubstitution);
      if (secondBoundsCheckNeeded) {
        for (int i = 0; i < sTypeVariables.length; i++) {
          TypeParameter sTypeVariable = sTypeVariables[i];
          TypeParameter tTypeVariable = tTypeVariables[i];
          if (!types.isSameTypeKernel(
              substitution.substituteType(sTypeVariable.bound),
              tTypeVariable.bound)) {
            return false;
          }
        }
      }
      s = substitution.substituteType(s.withoutTypeParameters);
    }
    if (!types.isSubtypeOfKernel(s.returnType, t.returnType)) return false;
    List<DartType> sPositional = s.positionalParameters;
    List<DartType> tPositional = t.positionalParameters;
    if (s.requiredParameterCount > t.requiredParameterCount) {
      // Rule 15, n1 <= n2.
      return false;
    }
    if (sPositional.length < tPositional.length) {
      // Rule 15, n1 + k1 >= n2 + k2.
      return false;
    }
    for (int i = 0; i < tPositional.length; i++) {
      if (!types.isSubtypeOfKernel(tPositional[i], sPositional[i])) {
        // Rule 15, Tj <: Sj.
        return false;
      }
    }
    List<NamedType> sNamed = s.namedParameters;
    List<NamedType> tNamed = t.namedParameters;
    if (sNamed.isNotEmpty || tNamed.isNotEmpty) {
      // Rule 16, the number of positional parameters must be the same.
      if (sPositional.length != tPositional.length) return false;
      if (s.requiredParameterCount != t.requiredParameterCount) return false;

      // Rule 16, the parameter names of [t] must be a subset of those of
      // [s]. Also, for the intersection, the type of the parameter of [t] must
      // be a subtype of the type of the parameter of [s].
      int sCount = 0;
      for (int tCount = 0; tCount < tNamed.length; tCount++) {
        String name = tNamed[tCount].name;
        for (; sCount < sNamed.length; sCount++) {
          if (sNamed[sCount].name == name) break;
        }
        if (sCount == sNamed.length) return false;
        if (!types.isSubtypeOfKernel(
            tNamed[tCount].type, sNamed[sCount].type)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  bool isInterfaceRelated(InterfaceType s, FunctionType t, Types types) {
    return s.classNode == types.hierarchy.nullKernelClass; // Rule 4.
  }

  @override
  bool isDynamicRelated(DynamicType s, FunctionType t, Types types) => false;

  @override
  bool isFutureOrRelated(InterfaceType futureOr, FunctionType t, Types types) {
    return false;
  }

  @override
  bool isIntersectionRelated(
      TypeParameterType intersection, FunctionType t, Types types) {
    // Rule 12.
    return types.isSubtypeOfKernel(intersection.promotedBound, t);
  }

  @override
  bool isTypeParameterRelated(
      TypeParameterType s, FunctionType t, Types types) {
    // Rule 13.
    return types.isSubtypeOfKernel(s.parameter.bound, t);
  }

  @override
  bool isTypedefRelated(TypedefType s, FunctionType t, Types types) {
    // Rule 5.
    return types.isSubtypeOfKernel(s.unalias, t);
  }

  @override
  bool isVoidRelated(VoidType s, FunctionType t, Types types) {
    return false;
  }
}

class IsTypeParameterSubtypeOf extends TypeRelation<TypeParameterType> {
  const IsTypeParameterSubtypeOf();

  @override
  bool isTypeParameterRelated(
      TypeParameterType s, TypeParameterType t, Types types) {
    return s.parameter == t.parameter ||
        // Rule 13.
        types.isSubtypeOfKernel(s.bound, t);
  }

  @override
  bool isIntersectionRelated(
      TypeParameterType intersection, TypeParameterType t, Types types) {
    return intersection.parameter == t.parameter; // Rule 8.
  }

  @override
  bool isInterfaceRelated(InterfaceType s, TypeParameterType t, Types types) {
    return s.classNode == types.hierarchy.nullKernelClass; // Rule 4.
  }

  @override
  bool isDynamicRelated(DynamicType s, TypeParameterType t, Types types) {
    return false;
  }

  @override
  bool isFunctionRelated(FunctionType s, TypeParameterType t, Types types) {
    return false;
  }

  @override
  bool isFutureOrRelated(
      InterfaceType futureOr, TypeParameterType t, Types types) {
    return false;
  }

  @override
  bool isTypedefRelated(TypedefType s, TypeParameterType t, Types types) {
    return types.isSubtypeOfKernel(s.unalias, t);
  }

  @override
  bool isVoidRelated(VoidType s, TypeParameterType t, Types types) {
    return false;
  }
}

class IsTypedefSubtypeOf extends TypeRelation<TypedefType> {
  const IsTypedefSubtypeOf();

  @override
  bool isInterfaceRelated(InterfaceType s, TypedefType t, Types types) {
    return types.isSubtypeOfKernel(s, t.unalias);
  }

  @override
  bool isDynamicRelated(DynamicType s, TypedefType t, Types types) {
    return types.isSubtypeOfKernel(s, t.unalias);
  }

  @override
  bool isFunctionRelated(FunctionType s, TypedefType t, Types types) {
    return types.isSubtypeOfKernel(s, t.unalias);
  }

  @override
  bool isFutureOrRelated(InterfaceType futureOr, TypedefType t, Types types) {
    return types.isSubtypeOfKernel(futureOr, t.unalias);
  }

  @override
  bool isIntersectionRelated(
      TypeParameterType intersection, TypedefType t, Types types) {
    return types.isSubtypeOfKernel(intersection, t.unalias);
  }

  @override
  bool isTypeParameterRelated(TypeParameterType s, TypedefType t, Types types) {
    return types.isSubtypeOfKernel(s, t.unalias);
  }

  @override
  bool isTypedefRelated(TypedefType s, TypedefType t, Types types) {
    return types.isSubtypeOfKernel(s.unalias, t.unalias);
  }

  @override
  bool isVoidRelated(VoidType s, TypedefType t, Types types) {
    return types.isSubtypeOfKernel(s, t.unalias);
  }
}

class IsFutureOrSubtypeOf extends TypeRelation<InterfaceType> {
  const IsFutureOrSubtypeOf();

  @override
  bool isInterfaceRelated(
      InterfaceType s, InterfaceType futureOr, Types types) {
    List<DartType> arguments = futureOr.typeArguments;
    if (types.isSubtypeOfKernel(s, arguments.single)) {
      return true; // Rule 11.
    }
    // Rule 10.
    return types.isSubtypeOfKernel(
        s, new InterfaceType(types.hierarchy.futureKernelClass, arguments));
  }

  @override
  bool isFutureOrRelated(
      InterfaceType sFutureOr, InterfaceType tFutureOr, Types types) {
    // This follows from combining rules 7, 10, and 11.
    return types.isSubtypeOfKernel(
        sFutureOr.typeArguments.single, tFutureOr.typeArguments.single);
  }

  @override
  bool isDynamicRelated(DynamicType s, InterfaceType futureOr, Types types) {
    // Rule 11.
    return types.isSubtypeOfKernel(s, futureOr.typeArguments.single);
  }

  @override
  bool isVoidRelated(VoidType s, InterfaceType futureOr, Types types) {
    // Rule 11.
    return types.isSubtypeOfKernel(s, futureOr.typeArguments.single);
  }

  @override
  bool isTypeParameterRelated(
      TypeParameterType s, InterfaceType futureOr, Types types) {
    List<DartType> arguments = futureOr.typeArguments;
    if (types.isSubtypeOfKernel(s, arguments.single)) {
      // Rule 11.
      return true;
    }

    if (types.isSubtypeOfKernel(s.parameter.bound, futureOr)) {
      // Rule 13.
      return true;
    }

    // Rule 10.
    return types.isSubtypeOfKernel(
        s, new InterfaceType(types.hierarchy.futureKernelClass, arguments));
  }

  @override
  bool isFunctionRelated(FunctionType s, InterfaceType futureOr, Types types) {
    // Rule 11.
    return types.isSubtypeOfKernel(s, futureOr.typeArguments.single);
  }

  @override
  bool isIntersectionRelated(
      TypeParameterType intersection, InterfaceType futureOr, Types types) {
    if (isTypeParameterRelated(intersection, futureOr, types)) {
      // Rule 8.
      return true;
    }
    // Rule 12.
    return types.isSubtypeOfKernel(intersection.promotedBound, futureOr);
  }

  @override
  bool isTypedefRelated(TypedefType s, InterfaceType futureOr, Types types) {
    return types.isSubtypeOfKernel(s.unalias, futureOr);
  }
}

class IsIntersectionSubtypeOf extends TypeRelation<TypeParameterType> {
  const IsIntersectionSubtypeOf();

  @override
  bool isIntersectionRelated(TypeParameterType sIntersection,
      TypeParameterType tIntersection, Types types) {
    // Rule 9.
    return const IsTypeParameterSubtypeOf()
            .isIntersectionRelated(sIntersection, tIntersection, types) &&
        types.isSubtypeOfKernel(sIntersection, tIntersection.promotedBound);
  }

  @override
  bool isTypeParameterRelated(
      TypeParameterType s, TypeParameterType intersection, Types types) {
    // Rule 9.
    return const IsTypeParameterSubtypeOf()
            .isTypeParameterRelated(s, intersection, types) &&
        types.isSubtypeOfKernel(s, intersection.promotedBound);
  }

  @override
  bool isInterfaceRelated(
      InterfaceType s, TypeParameterType intersection, Types types) {
    return s.classNode == types.hierarchy.nullKernelClass; // Rule 4.
  }

  bool isDynamicRelated(
      DynamicType s, TypeParameterType intersection, Types types) {
    return false;
  }

  bool isFunctionRelated(
      FunctionType s, TypeParameterType intersection, Types types) {
    return false;
  }

  bool isFutureOrRelated(
      InterfaceType futureOr, TypeParameterType intersection, Types types) {
    return false;
  }

  bool isTypedefRelated(
      TypedefType s, TypeParameterType intersection, Types types) {
    // Rule 5.
    return types.isSubtypeOfKernel(s.unalias, intersection);
  }

  bool isVoidRelated(VoidType s, TypeParameterType intersection, Types types) {
    return false;
  }
}
