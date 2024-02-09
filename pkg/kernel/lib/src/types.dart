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
    (typeChecksForTesting ??= <Object>[])
        .add([subtype, supertype, booleanResult]);
    return booleanResult;
  }

  IsSubtypeOf performNullabilityAwareSubtypeCheck(DartType s, DartType t) {
    // TODO(johnniwinther,cstefantsova): Ensure complete handling of
    // InvalidType in the subtype relation.
    if (s is InvalidType || t is InvalidType) {
      return const IsSubtypeOf.always();
    }

    if (t is DynamicType) {
      return const IsSubtypeOf.always(); // Rule 2.
    }
    if (t is VoidType) {
      return const IsSubtypeOf.always(); // Rule 2.
    }
    if (s is NeverType) {
      return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);
    }
    if (s is NullType) {
      // Rule 4.
      return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);
    }

    if (t is InterfaceType) {
      if (t.classReference == hierarchy.coreTypes.objectClass.reference) {
        if (s is ExtensionType) {
          if (s.extensionTypeErasure.isPotentiallyNullable &&
              !t.isPotentiallyNullable) {
            return new IsSubtypeOf.onlyIfIgnoringNullabilities(
                subtype: s, supertype: t);
          }
        }
        if (s is! FutureOrType) {
          return new IsSubtypeOf.basedSolelyOnNullabilities(s, t);
        }
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
        return relation.isTypeParameterRelated(s, t, this);
      } else if (s is StructuralParameterType) {
        return relation.isStructuralParameterRelated(s, t, this);
      } else if (s is IntersectionType) {
        return relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      } else if (s is RecordType) {
        return relation.isRecordRelated(s, t, this);
      } else if (s is ExtensionType) {
        return relation.isExtensionTypeRelated(s, t, this);
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
      } else if (s is StructuralParameterType) {
        return relation.isStructuralParameterRelated(s, t, this);
      } else if (s is IntersectionType) {
        return relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      } else if (s is RecordType) {
        return relation.isRecordRelated(s, t, this);
      } else if (s is ExtensionType) {
        return relation.isExtensionTypeRelated(s, t, this);
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
      } else if (s is StructuralParameterType) {
        return relation.isStructuralParameterRelated(s, t, this);
      } else if (s is IntersectionType) {
        return relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      } else if (s is RecordType) {
        return relation.isRecordRelated(s, t, this);
      } else if (s is ExtensionType) {
        return relation.isExtensionTypeRelated(s, t, this);
      }
    } else if (t is StructuralParameterType) {
      const IsStructuralParameterSubtypeOf relation =
          const IsStructuralParameterSubtypeOf();
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
      } else if (s is StructuralParameterType) {
        return relation.isStructuralParameterRelated(s, t, this);
      } else if (s is IntersectionType) {
        return relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      } else if (s is RecordType) {
        return relation.isRecordRelated(s, t, this);
      } else if (s is ExtensionType) {
        return relation.isExtensionTypeRelated(s, t, this);
      }
    } else if (t is IntersectionType) {
      const IsIntersectionSubtypeOf relation = const IsIntersectionSubtypeOf();
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
      } else if (s is StructuralParameterType) {
        return relation.isStructuralParameterRelated(s, t, this);
      } else if (s is IntersectionType) {
        return relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      } else if (s is RecordType) {
        return relation.isRecordRelated(s, t, this);
      } else if (s is ExtensionType) {
        return relation.isExtensionTypeRelated(s, t, this);
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
      } else if (s is StructuralParameterType) {
        return relation.isStructuralParameterRelated(s, t, this);
      } else if (s is IntersectionType) {
        return relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      } else if (s is RecordType) {
        return relation.isRecordRelated(s, t, this);
      } else if (s is ExtensionType) {
        return relation.isExtensionTypeRelated(s, t, this);
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
        return relation.isTypeParameterRelated(s, t, this);
      } else if (s is StructuralParameterType) {
        return relation.isStructuralParameterRelated(s, t, this);
      } else if (s is IntersectionType) {
        return relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      } else if (s is RecordType) {
        return relation.isRecordRelated(s, t, this);
      } else if (s is ExtensionType) {
        return relation.isExtensionTypeRelated(s, t, this);
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
        return relation.isTypeParameterRelated(s, t, this);
      } else if (s is StructuralParameterType) {
        return relation.isStructuralParameterRelated(s, t, this);
      } else if (s is IntersectionType) {
        return relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      } else if (s is RecordType) {
        return relation.isRecordRelated(s, t, this);
      } else if (s is ExtensionType) {
        return relation.isExtensionTypeRelated(s, t, this);
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
        return relation.isTypeParameterRelated(s, t, this);
      } else if (s is StructuralParameterType) {
        return relation.isStructuralParameterRelated(s, t, this);
      } else if (s is IntersectionType) {
        return relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      } else if (s is RecordType) {
        return relation.isRecordRelated(s, t, this);
      } else if (s is ExtensionType) {
        return relation.isExtensionTypeRelated(s, t, this);
      }
    } else if (t is RecordType) {
      const IsRecordSubtypeOf relation = const IsRecordSubtypeOf();
      if (s is DynamicType) {
        return relation.isDynamicRelated(s, t, this);
      } else if (s is VoidType) {
        return relation.isVoidRelated(s, t, this);
      } else if (s is InterfaceType) {
        return relation.isInterfaceRelated(s, t, this);
      } else if (s is FunctionType) {
        return relation.isFunctionRelated(s, t, this);
      } else if (s is StructuralParameterType) {
        return relation.isStructuralParameterRelated(s, t, this);
      } else if (s is IntersectionType) {
        return relation.isIntersectionRelated(s, t, this);
      } else if (s is TypeParameterType) {
        return relation.isTypeParameterRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      } else if (s is RecordType) {
        return relation.isRecordRelated(s, t, this);
      } else if (s is ExtensionType) {
        return relation.isExtensionTypeRelated(s, t, this);
      }
    } else if (t is ExtensionType) {
      const IsExtensionTypeSubtypeOf relation =
          const IsExtensionTypeSubtypeOf();
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
      } else if (s is StructuralParameterType) {
        return relation.isStructuralParameterRelated(s, t, this);
      } else if (s is IntersectionType) {
        return relation.isIntersectionRelated(s, t, this);
      } else if (s is TypedefType) {
        return relation.isTypedefRelated(s, t, this);
      } else if (s is FutureOrType) {
        return relation.isFutureOrRelated(s, t, this);
      } else if (s is RecordType) {
        return relation.isRecordRelated(s, t, this);
      } else if (s is ExtensionType) {
        return relation.isExtensionTypeRelated(s, t, this);
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

  static List<Object>? typeChecksForTesting;

  TypeDeclarationType? getTypeAsInstanceOf(TypeDeclarationType type,
      TypeDeclaration typeDeclaration, CoreTypes coreTypes,
      {required bool isNonNullableByDefault}) {
    return hierarchy.getTypeAsInstanceOf(type, typeDeclaration,
        isNonNullableByDefault: isNonNullableByDefault);
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

abstract class TypeRelation<T extends DartType> {
  const TypeRelation();

  IsSubtypeOf isDynamicRelated(DynamicType s, T t, Types types);

  IsSubtypeOf isVoidRelated(VoidType s, T t, Types types);

  IsSubtypeOf isInterfaceRelated(InterfaceType s, T t, Types types);

  IsSubtypeOf isIntersectionRelated(
      IntersectionType intersection, T t, Types types);

  IsSubtypeOf isFunctionRelated(FunctionType s, T t, Types types);

  IsSubtypeOf isFutureOrRelated(FutureOrType s, T t, Types types);

  IsSubtypeOf isTypeParameterRelated(TypeParameterType s, T t, Types types);

  IsSubtypeOf isStructuralParameterRelated(
      StructuralParameterType s, T t, Types types);

  IsSubtypeOf isTypedefRelated(TypedefType s, T t, Types types);

  IsSubtypeOf isRecordRelated(RecordType s, T t, Types types);

  IsSubtypeOf isExtensionTypeRelated(ExtensionType s, T t, Types types);
}

class IsInterfaceSubtypeOf extends TypeRelation<InterfaceType> {
  const IsInterfaceSubtypeOf();

  @override
  IsSubtypeOf isInterfaceRelated(
      InterfaceType s, InterfaceType t, Types types) {
    List<DartType>? asSupertypeArguments;
    if (s.classReference == t.classReference) {
      asSupertypeArguments = s.typeArguments;
    } else {
      asSupertypeArguments = types.hierarchy
          .getInterfaceTypeArgumentsAsInstanceOfClass(s, t.classNode);
    }
    if (asSupertypeArguments == null) {
      return const IsSubtypeOf.never();
    }
    if (asSupertypeArguments.isEmpty) {
      return const IsSubtypeOf.always()
          .and(new IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(s, t));
    }
    return types
        .areTypeArgumentsOfSubtypeKernel(
            asSupertypeArguments, t.typeArguments, t.classNode.typeParameters)
        .and(new IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(s, t));
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, InterfaceType t, Types types) {
    return types
        .performNullabilityAwareSubtypeCheck(s.parameter.bound, t)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isStructuralParameterRelated(
      StructuralParameterType s, InterfaceType t, Types types) {
    return types
        .performNullabilityAwareSubtypeCheck(s.parameter.bound, t)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isFutureOrRelated(FutureOrType s, InterfaceType t, Types types) {
    // Rules 7.1 and 7.2.
    return types
        .performNullabilityAwareSubtypeCheck(
            new InterfaceType(types.hierarchy.coreTypes.futureClass,
                Nullability.nonNullable, [s.typeArgument]),
            t)
        .andSubtypeCheckFor(s.typeArgument, t, types)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      IntersectionType intersection, InterfaceType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(
        intersection.right, t); // Rule 12.
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

  @override
  IsSubtypeOf isRecordRelated(RecordType s, InterfaceType t, Types types) {
    // 'Object' is handled separately.
    return t.classNode == types.hierarchy.coreTypes.recordClass
        ? new IsSubtypeOf.basedSolelyOnNullabilities(s, t)
        : const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isExtensionTypeRelated(
      ExtensionType s, InterfaceType t, Types types) {
    List<DartType>? asSupertypeArguments = types.hierarchy
        .getExtensionTypeArgumentsAsInstanceOfClass(s, t.classNode);
    if (asSupertypeArguments == null) {
      return const IsSubtypeOf.never();
    }
    if (asSupertypeArguments.isEmpty) {
      return const IsSubtypeOf.always()
          .and(new IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(s, t));
    }
    return types
        .areTypeArgumentsOfSubtypeKernel(
            asSupertypeArguments, t.typeArguments, t.classNode.typeParameters)
        .and(new IsSubtypeOf.basedSolelyOnNullabilitiesNotInvalidType(s, t));
  }
}

class IsFunctionSubtypeOf extends TypeRelation<FunctionType> {
  const IsFunctionSubtypeOf();

  @override
  IsSubtypeOf isFunctionRelated(FunctionType s, FunctionType t, Types types) {
    List<StructuralParameter> sTypeVariables = s.typeParameters;
    List<StructuralParameter> tTypeVariables = t.typeParameters;
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
        StructuralParameter sTypeVariable = sTypeVariables[i];
        StructuralParameter tTypeVariable = tTypeVariables[i];
        result = result.and(types.performNullabilityAwareMutualSubtypesCheck(
            sTypeVariable.bound, tTypeVariable.bound));
        typeVariableSubstitution.add(
            new StructuralParameterType.forAlphaRenaming(
                sTypeVariable, tTypeVariable));
      }
      FunctionTypeInstantiator instantiator =
          FunctionTypeInstantiator.fromIterables(
              sTypeVariables, typeVariableSubstitution);
      // If the bounds aren't the same, we need to try again after computing the
      // substitution of type variables.
      if (!result.isSubtypeWhenIgnoringNullabilities()) {
        result = const IsSubtypeOf.always();
        for (int i = 0; i < sTypeVariables.length; i++) {
          StructuralParameter sTypeVariable = sTypeVariables[i];
          StructuralParameter tTypeVariable = tTypeVariables[i];
          result = result.and(types.performNullabilityAwareMutualSubtypesCheck(
              instantiator.substitute(sTypeVariable.bound),
              tTypeVariable.bound));
          if (!result.isSubtypeWhenIgnoringNullabilities()) {
            return const IsSubtypeOf.never();
          }
        }
      }
      s = instantiator.substitute(s.withoutTypeParameters) as FunctionType;
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
        NamedType? sNamedParameter;
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
            tNamedParameter.type, sNamedParameter!.type));
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
      IntersectionType intersection, FunctionType t, Types types) {
    // Rule 12.
    return types.performNullabilityAwareSubtypeCheck(intersection.right, t);
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
  IsSubtypeOf isStructuralParameterRelated(
      StructuralParameterType s, FunctionType t, Types types) {
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

  @override
  IsSubtypeOf isRecordRelated(RecordType s, FunctionType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isExtensionTypeRelated(
      ExtensionType s, FunctionType t, Types types) {
    return const IsSubtypeOf.never();
  }
}

class IsRecordSubtypeOf extends TypeRelation<RecordType> {
  const IsRecordSubtypeOf();

  @override
  IsSubtypeOf isFunctionRelated(FunctionType s, RecordType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isInterfaceRelated(InterfaceType s, RecordType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isDynamicRelated(DynamicType s, RecordType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFutureOrRelated(FutureOrType s, RecordType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      IntersectionType intersection, RecordType t, Types types) {
    // Rule 12.
    return types.performNullabilityAwareSubtypeCheck(intersection.right, t);
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, RecordType t, Types types) {
    // Rule 13.
    return types
        .performNullabilityAwareSubtypeCheck(s.parameter.bound, t)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isStructuralParameterRelated(
      StructuralParameterType s, RecordType t, Types types) {
    // Rule 13.
    return types
        .performNullabilityAwareSubtypeCheck(s.parameter.bound, t)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isTypedefRelated(TypedefType s, RecordType t, Types types) {
    // Rule 5.
    return types.performNullabilityAwareSubtypeCheck(s.unalias, t);
  }

  @override
  IsSubtypeOf isVoidRelated(VoidType s, RecordType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isRecordRelated(RecordType s, RecordType t, Types types) {
    if (s.positional.length != t.positional.length ||
        s.named.length != t.named.length) {
      return const IsSubtypeOf.never();
    }
    for (int i = 0; i < s.named.length; i++) {
      if (s.named[i].name != t.named[i].name) {
        return const IsSubtypeOf.never();
      }
    }

    IsSubtypeOf result = IsSubtypeOf.always();
    for (int i = 0; i < s.positional.length; i++) {
      result = result.and(types.performNullabilityAwareSubtypeCheck(
          s.positional[i], t.positional[i]));
      if (!result.isSubtypeWhenIgnoringNullabilities()) {
        return const IsSubtypeOf.never();
      }
    }
    for (int i = 0; i < s.named.length; i++) {
      result = result.and(types.performNullabilityAwareSubtypeCheck(
          s.named[i].type, t.named[i].type));
      if (!result.isSubtypeWhenIgnoringNullabilities()) {
        return const IsSubtypeOf.never();
      }
    }
    return result.and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isExtensionTypeRelated(
      ExtensionType s, RecordType t, Types types) {
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
  IsSubtypeOf isStructuralParameterRelated(
      StructuralParameterType s, TypeParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      IntersectionType intersection, TypeParameterType t, Types types) {
    // Nullable types aren't promoted to intersection types.
    // TODO(cstefantsova): Uncomment the following when the inference is
    // updated.
    //assert(intersection.typeParameterTypeNullability != Nullability.nullable);

    // Rule 8.
    if (intersection.left.parameter == t.parameter) {
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
        intersection.right.withDeclaredNullability(intersection.nullability),
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

  @override
  IsSubtypeOf isRecordRelated(RecordType s, TypeParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isExtensionTypeRelated(
      ExtensionType s, TypeParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }
}

class IsStructuralParameterSubtypeOf
    extends TypeRelation<StructuralParameterType> {
  const IsStructuralParameterSubtypeOf();

  @override
  IsSubtypeOf isStructuralParameterRelated(
      StructuralParameterType s, StructuralParameterType t, Types types) {
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
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, StructuralParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      IntersectionType intersection, StructuralParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isInterfaceRelated(
      InterfaceType s, StructuralParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isDynamicRelated(
      DynamicType s, StructuralParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFunctionRelated(
      FunctionType s, StructuralParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFutureOrRelated(
      FutureOrType s, StructuralParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isTypedefRelated(
      TypedefType s, StructuralParameterType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.unalias, t);
  }

  @override
  IsSubtypeOf isVoidRelated(
      VoidType s, StructuralParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isRecordRelated(
      RecordType s, StructuralParameterType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isExtensionTypeRelated(
      ExtensionType s, StructuralParameterType t, Types types) {
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
      IntersectionType intersection, TypedefType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(intersection, t.unalias);
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, TypedefType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s, t.unalias);
  }

  @override
  IsSubtypeOf isStructuralParameterRelated(
      StructuralParameterType s, TypedefType t, Types types) {
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

  @override
  IsSubtypeOf isRecordRelated(RecordType s, TypedefType t, Types types) {
    return types.performNullabilityAwareMutualSubtypesCheck(s, t.unalias);
  }

  @override
  IsSubtypeOf isExtensionTypeRelated(
      ExtensionType s, TypedefType t, Types types) {
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
    // TODO(cstefantsova): Revise the original optimization.
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
  IsSubtypeOf isStructuralParameterRelated(
      StructuralParameterType s, FutureOrType t, Types types) {
    // TODO(cstefantsova): Revise the original optimization.
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
      IntersectionType intersection, FutureOrType t, Types types) {
    return isTypeParameterRelated(intersection.left, t, types) // Rule 8.
        .orSubtypeCheckFor(intersection.right, t, types); // Rule 12.
  }

  @override
  IsSubtypeOf isTypedefRelated(TypedefType s, FutureOrType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.unalias, t);
  }

  @override
  IsSubtypeOf isRecordRelated(RecordType s, FutureOrType t, Types types) {
    // Rule 11.
    return types.performNullabilityAwareSubtypeCheck(
        s, t.typeArgument.withDeclaredNullability(t.nullability));
  }

  @override
  IsSubtypeOf isExtensionTypeRelated(
      ExtensionType s, FutureOrType t, Types types) {
    // Rule 11.
    return types.performNullabilityAwareSubtypeCheck(
        s, t.typeArgument.withDeclaredNullability(t.nullability));
  }
}

class IsIntersectionSubtypeOf extends TypeRelation<IntersectionType> {
  const IsIntersectionSubtypeOf();

  @override
  IsSubtypeOf isIntersectionRelated(IntersectionType sIntersection,
      IntersectionType tIntersection, Types types) {
    // Rule 9.
    return const IsTypeParameterSubtypeOf()
        .isIntersectionRelated(sIntersection, tIntersection.left, types)
        .andSubtypeCheckFor(sIntersection, tIntersection.right, types);
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, IntersectionType intersection, Types types) {
    // Rule 9.
    return const IsTypeParameterSubtypeOf()
        .isTypeParameterRelated(s, intersection.left, types)
        .andSubtypeCheckFor(s, intersection.right, types);
  }

  @override
  IsSubtypeOf isStructuralParameterRelated(
      StructuralParameterType s, IntersectionType intersection, Types types) {
    // Rule 9.
    return const IsTypeParameterSubtypeOf()
        .isStructuralParameterRelated(s, intersection.left, types)
        .andSubtypeCheckFor(s, intersection.right, types);
  }

  @override
  IsSubtypeOf isInterfaceRelated(
      InterfaceType s, IntersectionType intersection, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isDynamicRelated(
      DynamicType s, IntersectionType intersection, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFunctionRelated(
      FunctionType s, IntersectionType intersection, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFutureOrRelated(
      FutureOrType s, IntersectionType intersection, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isTypedefRelated(
      TypedefType s, IntersectionType intersection, Types types) {
    // Rule 5.
    return types.performNullabilityAwareSubtypeCheck(s.unalias, intersection);
  }

  @override
  IsSubtypeOf isVoidRelated(
      VoidType s, IntersectionType intersection, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isRecordRelated(RecordType s, IntersectionType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isExtensionTypeRelated(
      ExtensionType s, IntersectionType t, Types types) {
    return const IsSubtypeOf.never();
  }
}

class IsNullTypeSubtypeOf implements TypeRelation<NullType> {
  const IsNullTypeSubtypeOf();

  @override
  IsSubtypeOf isDynamicRelated(DynamicType s, NullType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isVoidRelated(VoidType s, NullType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isInterfaceRelated(InterfaceType s, NullType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      IntersectionType intersection, NullType t, Types types) {
    return types.performNullabilityAwareMutualSubtypesCheck(
        intersection.right, t);
  }

  @override
  IsSubtypeOf isFunctionRelated(FunctionType s, NullType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFutureOrRelated(FutureOrType s, NullType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, NullType t, Types types) {
    // We don't need to combine the check of the bound against [t] with the
    // check of the nullability of [s] against the nullability of [t] because
    // [t] is always nullable.
    return types.performNullabilityAwareSubtypeCheck(s.bound, t);
  }

  @override
  IsSubtypeOf isStructuralParameterRelated(
      StructuralParameterType s, NullType t, Types types) {
    // We don't need to combine the check of the bound against [t] with the
    // check of the nullability of [s] against the nullability of [t] because
    // [t] is always nullable.
    return types.performNullabilityAwareSubtypeCheck(s.bound, t);
  }

  @override
  IsSubtypeOf isTypedefRelated(TypedefType s, NullType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.unalias, t);
  }

  @override
  IsSubtypeOf isRecordRelated(RecordType s, NullType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isExtensionTypeRelated(ExtensionType s, NullType t, Types types) {
    return const IsSubtypeOf.never();
  }
}

class IsNeverTypeSubtypeOf implements TypeRelation<NeverType> {
  const IsNeverTypeSubtypeOf();

  @override
  IsSubtypeOf isDynamicRelated(DynamicType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isVoidRelated(VoidType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isInterfaceRelated(InterfaceType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      IntersectionType intersection, NeverType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(intersection.right, t);
  }

  @override
  IsSubtypeOf isFunctionRelated(FunctionType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFutureOrRelated(FutureOrType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, NeverType t, Types types) {
    return types
        .performNullabilityAwareSubtypeCheck(s.bound, t)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isStructuralParameterRelated(
      StructuralParameterType s, NeverType t, Types types) {
    return types
        .performNullabilityAwareSubtypeCheck(s.bound, t)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }

  @override
  IsSubtypeOf isTypedefRelated(TypedefType s, NeverType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.unalias, t);
  }

  @override
  IsSubtypeOf isRecordRelated(RecordType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isExtensionTypeRelated(
      ExtensionType s, NeverType t, Types types) {
    return const IsSubtypeOf.never();
  }
}

class IsExtensionTypeSubtypeOf implements TypeRelation<ExtensionType> {
  const IsExtensionTypeSubtypeOf();

  @override
  IsSubtypeOf isDynamicRelated(DynamicType s, ExtensionType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isVoidRelated(VoidType s, ExtensionType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isInterfaceRelated(
      InterfaceType s, ExtensionType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isIntersectionRelated(
      IntersectionType intersection, ExtensionType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(intersection.right, t);
  }

  @override
  IsSubtypeOf isFunctionRelated(FunctionType s, ExtensionType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isFutureOrRelated(FutureOrType s, ExtensionType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isTypeParameterRelated(
      TypeParameterType s, ExtensionType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.bound, t);
  }

  @override
  IsSubtypeOf isStructuralParameterRelated(
      StructuralParameterType s, ExtensionType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.bound, t);
  }

  @override
  IsSubtypeOf isTypedefRelated(TypedefType s, ExtensionType t, Types types) {
    return types.performNullabilityAwareSubtypeCheck(s.unalias, t);
  }

  @override
  IsSubtypeOf isRecordRelated(RecordType s, ExtensionType t, Types types) {
    return const IsSubtypeOf.never();
  }

  @override
  IsSubtypeOf isExtensionTypeRelated(
      ExtensionType s, ExtensionType t, Types types) {
    List<DartType>? typeArguments = types.hierarchy
        .getExtensionTypeArgumentsAsInstanceOfExtensionTypeDeclaration(
            s, t.extensionTypeDeclaration);
    if (typeArguments == null) {
      return const IsSubtypeOf.never();
    }
    return types
        .areTypeArgumentsOfSubtypeKernel(typeArguments, t.typeArguments,
            t.extensionTypeDeclaration.typeParameters)
        .and(new IsSubtypeOf.basedSolelyOnNullabilities(s, t));
  }
}
