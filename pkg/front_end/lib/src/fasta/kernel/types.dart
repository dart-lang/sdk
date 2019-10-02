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
        Nullability,
        TypeParameter,
        TypeParameterType,
        TypedefType,
        VoidType;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'package:kernel/type_environment.dart';

import 'kernel_builder.dart' show ClassHierarchyBuilder;

class Types {
  final ClassHierarchyBuilder hierarchy;

  Types(this.hierarchy);

  /// Returns true if [s] is a subtype of [t].
  bool isSubtypeOfKernel(DartType s, DartType t, SubtypeCheckMode mode) {
    if (s is InvalidType) {
      // InvalidType is a bottom type.
      return true;
    }
    if (t is InvalidType) {
      return false;
    }
    return isSubtypeOfKernelNullability(s, s.nullability, t, t.nullability);
  }

  bool isSubtypeOfKernelNullability(
      DartType s, Nullability sNullability, DartType t, tNullability) {
    if (s is BottomType) {
      return true; // Rule 3.
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
      if (cls == hierarchy.objectClass) {
        return true; // Rule 2.
      }
      if (cls == hierarchy.futureOrClass) {
        const IsFutureOrSubtypeOf relation = const IsFutureOrSubtypeOf();
        if (s is DynamicType) {
          return relation.isDynamicRelated(
              s, sNullability, t, tNullability, this);
        } else if (s is VoidType) {
          return relation.isVoidRelated(s, sNullability, t, tNullability, this);
        } else if (s is InterfaceType) {
          return s.classNode == hierarchy.futureOrClass
              ? relation.isFutureOrRelated(
                  s, sNullability, t, tNullability, this)
              : relation.isInterfaceRelated(
                  s, sNullability, t, tNullability, this);
        } else if (s is FunctionType) {
          return relation.isFunctionRelated(
              s, sNullability, t, tNullability, this);
        } else if (s is TypeParameterType) {
          return s.promotedBound == null
              ? relation.isTypeParameterRelated(
                  s, sNullability, t, tNullability, this)
              : relation.isIntersectionRelated(
                  s, sNullability, t, tNullability, this);
        } else if (s is TypedefType) {
          return relation.isTypedefRelated(
              s, sNullability, t, tNullability, this);
        }
      } else {
        const IsInterfaceSubtypeOf relation = const IsInterfaceSubtypeOf();
        if (s is DynamicType) {
          return relation.isDynamicRelated(
              s, sNullability, t, tNullability, this);
        } else if (s is VoidType) {
          return relation.isVoidRelated(s, sNullability, t, tNullability, this);
        } else if (s is InterfaceType) {
          return s.classNode == hierarchy.futureOrClass
              ? relation.isFutureOrRelated(
                  s, sNullability, t, tNullability, this)
              : relation.isInterfaceRelated(
                  s, sNullability, t, tNullability, this);
        } else if (s is FunctionType) {
          return relation.isFunctionRelated(
              s, sNullability, t, tNullability, this);
        } else if (s is TypeParameterType) {
          return s.promotedBound == null
              ? relation.isTypeParameterRelated(
                  s, sNullability, t, tNullability, this)
              : relation.isIntersectionRelated(
                  s, sNullability, t, tNullability, this);
        } else if (s is TypedefType) {
          return relation.isTypedefRelated(
              s, sNullability, t, tNullability, this);
        }
      }
    } else if (t is FunctionType) {
      const IsFunctionSubtypeOf relation = const IsFunctionSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(
            s, sNullability, t, tNullability, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, sNullability, t, tNullability, this);
      } else if (s is InterfaceType) {
        return s.classNode == hierarchy.futureOrClass
            ? relation.isFutureOrRelated(s, sNullability, t, tNullability, this)
            : relation.isInterfaceRelated(
                s, sNullability, t, tNullability, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(
            s, sNullability, t, tNullability, this);
      } else if (s is TypeParameterType) {
        return s.promotedBound == null
            ? relation.isTypeParameterRelated(
                s, sNullability, t, tNullability, this)
            : relation.isIntersectionRelated(
                s, sNullability, t, tNullability, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(
            s, sNullability, t, tNullability, this);
      }
    } else if (t is TypeParameterType) {
      if (t.promotedBound == null) {
        const IsTypeParameterSubtypeOf relation =
            const IsTypeParameterSubtypeOf();
        if (s is DynamicType) {
          return relation.isDynamicRelated(
              s, sNullability, t, tNullability, this);
        } else if (s is VoidType) {
          return relation.isVoidRelated(s, sNullability, t, tNullability, this);
        } else if (s is InterfaceType) {
          return s.classNode == hierarchy.futureOrClass
              ? relation.isFutureOrRelated(
                  s, sNullability, t, tNullability, this)
              : relation.isInterfaceRelated(
                  s, sNullability, t, tNullability, this);
        } else if (s is FunctionType) {
          return relation.isFunctionRelated(
              s, sNullability, t, tNullability, this);
        } else if (s is TypeParameterType) {
          return s.promotedBound == null
              ? relation.isTypeParameterRelated(
                  s, sNullability, t, tNullability, this)
              : relation.isIntersectionRelated(
                  s, sNullability, t, tNullability, this);
        } else if (s is TypedefType) {
          return relation.isTypedefRelated(
              s, sNullability, t, tNullability, this);
        }
      } else {
        const IsIntersectionSubtypeOf relation =
            const IsIntersectionSubtypeOf();
        if (s is DynamicType) {
          return relation.isDynamicRelated(
              s, sNullability, t, tNullability, this);
        } else if (s is VoidType) {
          return relation.isVoidRelated(s, sNullability, t, tNullability, this);
        } else if (s is InterfaceType) {
          return s.classNode == hierarchy.futureOrClass
              ? relation.isFutureOrRelated(
                  s, sNullability, t, tNullability, this)
              : relation.isInterfaceRelated(
                  s, sNullability, t, tNullability, this);
        } else if (s is FunctionType) {
          return relation.isFunctionRelated(
              s, sNullability, t, tNullability, this);
        } else if (s is TypeParameterType) {
          return s.promotedBound == null
              ? relation.isTypeParameterRelated(
                  s, sNullability, t, tNullability, this)
              : relation.isIntersectionRelated(
                  s, sNullability, t, tNullability, this);
        } else if (s is TypedefType) {
          return relation.isTypedefRelated(
              s, sNullability, t, tNullability, this);
        }
      }
    } else if (t is TypedefType) {
      const IsTypedefSubtypeOf relation = const IsTypedefSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(
            s, sNullability, t, tNullability, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, sNullability, t, tNullability, this);
      } else if (s is InterfaceType) {
        return s.classNode == hierarchy.futureOrClass
            ? relation.isFutureOrRelated(s, sNullability, t, tNullability, this)
            : relation.isInterfaceRelated(
                s, sNullability, t, tNullability, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(
            s, sNullability, t, tNullability, this);
      } else if (s is TypeParameterType) {
        return s.promotedBound == null
            ? relation.isTypeParameterRelated(
                s, sNullability, t, tNullability, this)
            : relation.isIntersectionRelated(
                s, sNullability, t, tNullability, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(
            s, sNullability, t, tNullability, this);
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
      if (!isSubtypeOfKernel(
          s[i], t[i], SubtypeCheckMode.ignoringNullabilities)) return false;
    }
    return true;
  }

  bool isSameTypeKernel(DartType s, DartType t) {
    return isSubtypeOfKernel(s, t, SubtypeCheckMode.ignoringNullabilities) &&
        isSubtypeOfKernel(t, s, SubtypeCheckMode.ignoringNullabilities);
  }
}

abstract class TypeRelation<T extends DartType> {
  const TypeRelation();

  bool isDynamicRelated(DynamicType s, Nullability sNullability, T t,
      Nullability tNullability, Types types);

  bool isVoidRelated(VoidType s, Nullability sNullability, T t,
      Nullability tNullability, Types types);

  bool isInterfaceRelated(InterfaceType s, Nullability sNullability, T t,
      Nullability tNullability, Types types);

  bool isIntersectionRelated(
      TypeParameterType intersection,
      Nullability intersectionNullability,
      T t,
      Nullability tNullability,
      Types types);

  bool isFunctionRelated(FunctionType s, Nullability sNullability, T t,
      Nullability tNullability, Types types);

  bool isFutureOrRelated(
      InterfaceType futureOr,
      Nullability futureOrNullability,
      T t,
      Nullability tNullability,
      Types types);

  bool isTypeParameterRelated(TypeParameterType s, Nullability sNullability,
      T t, Nullability tNullability, Types types);

  bool isTypedefRelated(TypedefType s, Nullability sNullability, T t,
      Nullability tNullability, Types types);
}

class IsInterfaceSubtypeOf extends TypeRelation<InterfaceType> {
  const IsInterfaceSubtypeOf();

  @override
  bool isInterfaceRelated(InterfaceType s, Nullability sNullability,
      InterfaceType t, Nullability tNullability, Types types) {
    if (s.classNode == types.hierarchy.nullClass) {
      // This is an optimization, to avoid instantiating unnecessary type
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
  bool isTypeParameterRelated(TypeParameterType s, Nullability sNullability,
      InterfaceType t, Nullability tNullability, Types types) {
    return types.isSubtypeOfKernel(
        s.parameter.bound, t, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isFutureOrRelated(
      InterfaceType futureOr,
      Nullability futureOrNullability,
      InterfaceType t,
      Nullability tNullability,
      Types types) {
    List<DartType> arguments = futureOr.typeArguments;
    if (!types.isSubtypeOfKernel(
        arguments.single, t, SubtypeCheckMode.ignoringNullabilities)) {
      return false; // Rule 7.1
    }
    if (!types.isSubtypeOfKernel(
        new InterfaceType(types.hierarchy.futureClass, arguments),
        t,
        SubtypeCheckMode.ignoringNullabilities)) {
      return false; // Rule 7.2
    }
    return true;
  }

  @override
  bool isIntersectionRelated(
      TypeParameterType intersection,
      Nullability intersectionNullability,
      InterfaceType t,
      Nullability tNullability,
      Types types) {
    return types.isSubtypeOfKernel(intersection.promotedBound, t,
        SubtypeCheckMode.ignoringNullabilities); // Rule 12.
  }

  @override
  bool isDynamicRelated(DynamicType s, Nullability sNullability,
      InterfaceType t, Nullability tNullability, Types types) {
    return false;
  }

  @override
  bool isFunctionRelated(FunctionType s, Nullability sNullability,
      InterfaceType t, Nullability tNullability, Types types) {
    return t.classNode == types.hierarchy.functionClass; // Rule 14.
  }

  @override
  bool isTypedefRelated(TypedefType s, Nullability sNullability,
      InterfaceType t, Nullability tNullability, Types types) {
    // Rule 5.
    return types.isSubtypeOfKernel(
        s.unalias, t, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isVoidRelated(VoidType s, Nullability sNullability, InterfaceType t,
      Nullability tNullability, Types types) {
    return false;
  }
}

class IsFunctionSubtypeOf extends TypeRelation<FunctionType> {
  const IsFunctionSubtypeOf();

  @override
  bool isFunctionRelated(FunctionType s, Nullability sNullability,
      FunctionType t, Nullability tNullability, Types types) {
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
    if (!types.isSubtypeOfKernel(
        s.returnType, t.returnType, SubtypeCheckMode.ignoringNullabilities)) {
      return false;
    }
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
      if (!types.isSubtypeOfKernel(tPositional[i], sPositional[i],
          SubtypeCheckMode.ignoringNullabilities)) {
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
        if (!types.isSubtypeOfKernel(tNamed[tCount].type, sNamed[sCount].type,
            SubtypeCheckMode.ignoringNullabilities)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  bool isInterfaceRelated(InterfaceType s, Nullability sNullability,
      FunctionType t, Nullability tNullability, Types types) {
    return s.classNode == types.hierarchy.nullClass; // Rule 4.
  }

  @override
  bool isDynamicRelated(DynamicType s, Nullability sNullability, FunctionType t,
      Nullability tNullability, Types types) {
    return false;
  }

  @override
  bool isFutureOrRelated(
      InterfaceType futureOr,
      Nullability futureOrNullability,
      FunctionType t,
      Nullability tNullability,
      Types types) {
    return false;
  }

  @override
  bool isIntersectionRelated(
      TypeParameterType intersection,
      Nullability intersectionNullability,
      FunctionType t,
      Nullability tNullability,
      Types types) {
    // Rule 12.
    return types.isSubtypeOfKernel(
        intersection.promotedBound, t, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isTypeParameterRelated(TypeParameterType s, Nullability sNullability,
      FunctionType t, Nullability tNullability, Types types) {
    // Rule 13.
    return types.isSubtypeOfKernel(
        s.parameter.bound, t, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isTypedefRelated(TypedefType s, Nullability sNullability, FunctionType t,
      Nullability tNullability, Types types) {
    // Rule 5.
    return types.isSubtypeOfKernel(
        s.unalias, t, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isVoidRelated(VoidType s, Nullability sNullability, FunctionType t,
      Nullability tNullability, Types types) {
    return false;
  }
}

class IsTypeParameterSubtypeOf extends TypeRelation<TypeParameterType> {
  const IsTypeParameterSubtypeOf();

  @override
  bool isTypeParameterRelated(TypeParameterType s, Nullability sNullability,
      TypeParameterType t, Nullability tNullability, Types types) {
    return s.parameter == t.parameter ||
        // Rule 13.
        types.isSubtypeOfKernel(
            s.bound, t, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isIntersectionRelated(
      TypeParameterType intersection,
      Nullability intersectionNullability,
      TypeParameterType t,
      Nullability tNullability,
      Types types) {
    return intersection.parameter == t.parameter; // Rule 8.
  }

  @override
  bool isInterfaceRelated(InterfaceType s, Nullability sNullability,
      TypeParameterType t, Nullability tNullability, Types types) {
    return s.classNode == types.hierarchy.nullClass; // Rule 4.
  }

  @override
  bool isDynamicRelated(DynamicType s, Nullability sNullability,
      TypeParameterType t, Nullability tNullability, Types types) {
    return false;
  }

  @override
  bool isFunctionRelated(FunctionType s, Nullability sNullability,
      TypeParameterType t, Nullability tNullability, Types types) {
    return false;
  }

  @override
  bool isFutureOrRelated(
      InterfaceType futureOr,
      Nullability futureOrNullability,
      TypeParameterType t,
      Nullability tNullability,
      Types types) {
    return false;
  }

  @override
  bool isTypedefRelated(TypedefType s, Nullability sNullability,
      TypeParameterType t, Nullability tNullability, Types types) {
    return types.isSubtypeOfKernel(
        s.unalias, t, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isVoidRelated(VoidType s, Nullability sNullability, TypeParameterType t,
      Nullability tNullability, Types types) {
    return false;
  }
}

class IsTypedefSubtypeOf extends TypeRelation<TypedefType> {
  const IsTypedefSubtypeOf();

  @override
  bool isInterfaceRelated(InterfaceType s, Nullability sNullability,
      TypedefType t, Nullability tNullability, Types types) {
    return types.isSubtypeOfKernel(
        s, t.unalias, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isDynamicRelated(DynamicType s, Nullability sNullability, TypedefType t,
      Nullability tNullability, Types types) {
    return types.isSubtypeOfKernel(
        s, t.unalias, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isFunctionRelated(FunctionType s, Nullability sNullability,
      TypedefType t, Nullability tNullability, Types types) {
    return types.isSubtypeOfKernel(
        s, t.unalias, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isFutureOrRelated(
      InterfaceType futureOr,
      Nullability futureOrNullability,
      TypedefType t,
      Nullability tNullability,
      Types types) {
    return types.isSubtypeOfKernel(
        futureOr, t.unalias, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isIntersectionRelated(
      TypeParameterType intersection,
      Nullability intersectionNullability,
      TypedefType t,
      Nullability tNullability,
      Types types) {
    return types.isSubtypeOfKernel(
        intersection, t.unalias, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isTypeParameterRelated(TypeParameterType s, Nullability sNullability,
      TypedefType t, Nullability tNullability, Types types) {
    return types.isSubtypeOfKernel(
        s, t.unalias, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isTypedefRelated(TypedefType s, Nullability sNullability, TypedefType t,
      Nullability tNullability, Types types) {
    return types.isSubtypeOfKernel(
        s.unalias, t.unalias, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isVoidRelated(VoidType s, Nullability sNullability, TypedefType t,
      Nullability tNullability, Types types) {
    return types.isSubtypeOfKernel(
        s, t.unalias, SubtypeCheckMode.ignoringNullabilities);
  }
}

class IsFutureOrSubtypeOf extends TypeRelation<InterfaceType> {
  const IsFutureOrSubtypeOf();

  @override
  bool isInterfaceRelated(InterfaceType s, Nullability sNullability,
      InterfaceType futureOr, Nullability futureOrNullability, Types types) {
    List<DartType> arguments = futureOr.typeArguments;
    if (types.isSubtypeOfKernel(
        s, arguments.single, SubtypeCheckMode.ignoringNullabilities)) {
      return true; // Rule 11.
    }
    // Rule 10.
    return types.isSubtypeOfKernel(
        s,
        new InterfaceType(types.hierarchy.futureClass, arguments),
        SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isFutureOrRelated(
      InterfaceType sFutureOr,
      Nullability sFutureOrNullability,
      InterfaceType tFutureOr,
      Nullability tFutureOrNullability,
      Types types) {
    // This follows from combining rules 7, 10, and 11.
    return types.isSubtypeOfKernel(sFutureOr.typeArguments.single,
        tFutureOr.typeArguments.single, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isDynamicRelated(DynamicType s, Nullability sNullability,
      InterfaceType futureOr, Nullability futureOrNullability, Types types) {
    // Rule 11.
    return types.isSubtypeOfKernel(s, futureOr.typeArguments.single,
        SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isVoidRelated(VoidType s, Nullability sNullability,
      InterfaceType futureOr, Nullability futureOrNullability, Types types) {
    // Rule 11.
    return types.isSubtypeOfKernel(s, futureOr.typeArguments.single,
        SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isTypeParameterRelated(TypeParameterType s, Nullability sNullability,
      InterfaceType futureOr, Nullability futureOrNullability, Types types) {
    List<DartType> arguments = futureOr.typeArguments;
    if (types.isSubtypeOfKernel(
        s, arguments.single, SubtypeCheckMode.ignoringNullabilities)) {
      // Rule 11.
      return true;
    }

    if (types.isSubtypeOfKernel(
        s.parameter.bound, futureOr, SubtypeCheckMode.ignoringNullabilities)) {
      // Rule 13.
      return true;
    }

    // Rule 10.
    return types.isSubtypeOfKernel(
        s,
        new InterfaceType(types.hierarchy.futureClass, arguments),
        SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isFunctionRelated(FunctionType s, Nullability sNullability,
      InterfaceType futureOr, Nullability futureOrNullability, Types types) {
    // Rule 11.
    return types.isSubtypeOfKernel(s, futureOr.typeArguments.single,
        SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isIntersectionRelated(
      TypeParameterType intersection,
      Nullability intersectionNullability,
      InterfaceType futureOr,
      Nullability futureOrNullability,
      Types types) {
    if (isTypeParameterRelated(intersection, intersectionNullability, futureOr,
        futureOrNullability, types)) {
      // Rule 8.
      return true;
    }
    // Rule 12.
    return types.isSubtypeOfKernel(intersection.promotedBound, futureOr,
        SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isTypedefRelated(TypedefType s, Nullability sNullability,
      InterfaceType futureOr, Nullability futureOrNullability, Types types) {
    return types.isSubtypeOfKernel(
        s.unalias, futureOr, SubtypeCheckMode.ignoringNullabilities);
  }
}

class IsIntersectionSubtypeOf extends TypeRelation<TypeParameterType> {
  const IsIntersectionSubtypeOf();

  @override
  bool isIntersectionRelated(
      TypeParameterType sIntersection,
      Nullability sIntersectionNullability,
      TypeParameterType tIntersection,
      Nullability tIntersectionNullability,
      Types types) {
    // Rule 9.
    return const IsTypeParameterSubtypeOf().isIntersectionRelated(
            sIntersection,
            sIntersectionNullability,
            tIntersection,
            tIntersectionNullability,
            types) &&
        types.isSubtypeOfKernel(sIntersection, tIntersection.promotedBound,
            SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isTypeParameterRelated(
      TypeParameterType s,
      Nullability sNullability,
      TypeParameterType intersection,
      Nullability intersectionNullability,
      Types types) {
    // Rule 9.
    return const IsTypeParameterSubtypeOf().isTypeParameterRelated(
            s, sNullability, intersection, intersectionNullability, types) &&
        types.isSubtypeOfKernel(s, intersection.promotedBound,
            SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isInterfaceRelated(
      InterfaceType s,
      Nullability sNullability,
      TypeParameterType intersection,
      Nullability intersectionNullability,
      Types types) {
    return s.classNode == types.hierarchy.nullClass; // Rule 4.
  }

  @override
  bool isDynamicRelated(
      DynamicType s,
      Nullability sNullability,
      TypeParameterType intersection,
      Nullability intersectionNullability,
      Types types) {
    return false;
  }

  @override
  bool isFunctionRelated(
      FunctionType s,
      Nullability sNullability,
      TypeParameterType intersection,
      Nullability intersectionNullability,
      Types types) {
    return false;
  }

  @override
  bool isFutureOrRelated(
      InterfaceType futureOr,
      Nullability futureOrNullability,
      TypeParameterType intersection,
      Nullability intersectionNullability,
      Types types) {
    return false;
  }

  @override
  bool isTypedefRelated(
      TypedefType s,
      Nullability sNullability,
      TypeParameterType intersection,
      Nullability intersectionNullability,
      Types types) {
    // Rule 5.
    return types.isSubtypeOfKernel(
        s.unalias, intersection, SubtypeCheckMode.ignoringNullabilities);
  }

  @override
  bool isVoidRelated(
      VoidType s,
      Nullability sNullability,
      TypeParameterType intersection,
      Nullability intersectionNullability,
      Types types) {
    return false;
  }
}
