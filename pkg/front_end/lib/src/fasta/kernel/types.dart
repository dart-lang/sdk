// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.types;

import 'package:kernel/ast.dart'
    show
        BottomType,
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

import 'kernel_builder.dart' show ClassHierarchyBuilder, KernelNamedTypeBuilder;

class Types {
  final ClassHierarchyBuilder hierarchy;

  Types(this.hierarchy);

  /// Returns true if [s] is a subtype of [t].
  bool isSubtypeOfKernel(DartType s, DartType t) {
    if (s is BottomType) {
      return true;
    }
    if (s is InvalidType) {
      // InvalidType is also a bottom type.
      return true;
    }
    if (t is InvalidType) {
      return false;
    }
    if (t is DynamicType) {
      // A top type.
      return true;
    }
    if (t is VoidType) {
      // A top type.
      return true;
    }
    if (t is BottomType) {
      return false;
    }
    if (t is InterfaceType) {
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
        return relation.isTypeParameterRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
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
        return relation.isTypeParameterRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      }
    } else if (t is TypeParameterType) {
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
        return relation.isTypeParameterRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
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
        return relation.isTypeParameterRelated(s, t, this);
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
      throw "Numbers of type arguments don't match.";
    }
    for (int i = 0; i < s.length; i++) {
      if (!isSubtypeOfKernel(s[i], t[i])) return false;
    }
    return true;
  }

  bool areNamedSubtypesOfKernel(List<NamedType> s, List<NamedType> t) {
    if (s.length != t.length) {
      throw "Numbers of named arguments don't match.";
    }
    for (int i = 0; i < s.length; i++) {
      if (s[i].name != t[i].name) return false;
      if (!isSubtypeOfKernel(s[i].type, t[i].type)) return false;
    }
    return true;
  }
}

abstract class TypeRelation<T extends DartType> {
  const TypeRelation();

  bool isDynamicRelated(DynamicType s, T t, Types types);

  bool isVoidRelated(VoidType s, T t, Types types);

  bool isInterfaceRelated(InterfaceType s, T t, Types types);

  bool isFunctionRelated(FunctionType s, T t, Types types);

  bool isTypeParameterRelated(TypeParameterType s, T t, Types types);

  bool isTypedefRelated(TypedefType s, T t, Types types);
}

class IsInterfaceSubtypeOf extends TypeRelation<InterfaceType> {
  const IsInterfaceSubtypeOf();

  @override
  bool isInterfaceRelated(InterfaceType s, InterfaceType t, Types types) {
    if (s.classNode == t.classNode) {
      return types.areSubtypesOfKernel(s.typeArguments, t.typeArguments);
    }
    KernelNamedTypeBuilder supertype =
        types.hierarchy.asSupertypeOf(s.classNode, t.classNode);
    if (supertype == null) return false;
    if (supertype.arguments == null) return true;
    InterfaceType asSupertype =
        Substitution.fromInterfaceType(s).substituteType(supertype.build(null));
    return types.areSubtypesOfKernel(
        asSupertype.typeArguments, t.typeArguments);
  }

  @override
  bool isTypeParameterRelated(
      TypeParameterType s, InterfaceType t, Types types) {
    return types.isSubtypeOfKernel(s.parameter.bound, t);
  }

  // TODO(ahe): Remove this method.
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
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
        if (sTypeVariable.bound != tTypeVariable.bound) {
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
          if (substitution.substituteType(sTypeVariable.bound) !=
              tTypeVariable.bound) {
            return false;
          }
        }
      }
      s = substitution.substituteType(s.withoutTypeParameters);
    }
    if (!types.isSubtypeOfKernel(s.returnType, t.returnType)) {
      return false;
    } else if (!types.areSubtypesOfKernel(
        t.positionalParameters, s.positionalParameters)) {
      return false;
    } else if (!types.areNamedSubtypesOfKernel(
        t.namedParameters, s.namedParameters)) {
      return false;
    }
    return true;
  }

  // TODO(ahe): Remove this method.
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}

class IsTypeParameterSubtypeOf extends TypeRelation<TypeParameterType> {
  const IsTypeParameterSubtypeOf();

  @override
  bool isTypeParameterRelated(
      TypeParameterType s, TypeParameterType t, Types types) {
    return s.parameter == t.parameter;
  }

  // TODO(ahe): Remove this method.
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}

class IsTypedefSubtypeOf extends TypeRelation<TypedefType> {
  const IsTypedefSubtypeOf();

  // TODO(ahe): Remove this method.
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}
