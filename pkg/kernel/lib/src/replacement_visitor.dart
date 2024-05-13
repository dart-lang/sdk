// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import '../type_algebra.dart';

/// Helper visitor that clones a type if a nested type is replaced, and
/// otherwise returns `null`.
class ReplacementVisitor implements DartTypeVisitor1<DartType?, Variance> {
  const ReplacementVisitor();

  Nullability? visitNullability(DartType node) => null;

  @override
  DartType? visitFunctionType(FunctionType node, Variance variance) {
    Nullability? newNullability = visitNullability(node);

    List<StructuralParameter>? newTypeParameters;
    for (int i = 0; i < node.typeParameters.length; i++) {
      StructuralParameter typeParameter = node.typeParameters[i];
      // TODO(johnniwinther): Bounds should not be null, even in case of
      // cyclic typedefs. Currently
      //   instantiate_to_bound/non_simple_class_parametrized_typedef_cycle
      // fails with this.
      DartType? newBound = typeParameter.bound
          .accept1(this, variance.combine(Variance.invariant));
      DartType? newDefaultType = typeParameter.defaultType
          .accept1(this, variance.combine(Variance.invariant));
      if (newBound != null || newDefaultType != null) {
        newTypeParameters ??= node.typeParameters.toList(growable: false);
        newTypeParameters[i] = new StructuralParameter(
            typeParameter.name,
            newBound ?? typeParameter.bound,
            newDefaultType ?? typeParameter.defaultType);
      }
    }

    FunctionTypeInstantiator? instantiator;
    if (newTypeParameters != null) {
      List<DartType> typeParameterTypes =
          new List<DartType>.generate(newTypeParameters.length, (int i) {
        // Note that we don't use [StructuralParameterType.forAlphaRenaming]
        // here. The bound of the new [StructuralParameter] may have changed,
        // which means that replacing old variables with the new ones is not
        // simply a matter of parameter identity, but has semantic meaning.
        return new StructuralParameterType(
            newTypeParameters![i],
            StructuralParameterType.computeNullabilityFromBound(
                newTypeParameters[i]));
      }, growable: false);
      instantiator =
          FunctionTypeInstantiator.fromInstantiation(node, typeParameterTypes);
      for (int i = 0; i < newTypeParameters.length; i++) {
        newTypeParameters[i].bound =
            instantiator.substitute(newTypeParameters[i].bound);
      }
    }

    DartType? visitType(DartType? type, Variance variance) {
      if (type == null) return null;
      DartType? result = type.accept1(this, variance);
      if (instantiator != null) {
        result = instantiator.substitute(result ?? type);
      }
      return result;
    }

    DartType? newReturnType = visitType(node.returnType, variance);
    List<DartType>? newPositionalParameters = null;
    for (int i = 0; i < node.positionalParameters.length; i++) {
      DartType? newType = visitType(node.positionalParameters[i],
          variance.combine(Variance.contravariant));
      if (newType != null) {
        newPositionalParameters ??=
            node.positionalParameters.toList(growable: false);
        newPositionalParameters[i] = newType;
      }
    }
    List<NamedType>? newNamedParameters = null;
    for (int i = 0; i < node.namedParameters.length; i++) {
      DartType? newType = visitType(node.namedParameters[i].type,
          variance.combine(Variance.contravariant));
      NamedType? newNamedType =
          createNamedType(node.namedParameters[i], newType);
      if (newNamedType != null) {
        newNamedParameters ??= node.namedParameters.toList(growable: false);
        newNamedParameters[i] = newNamedType;
      }
    }

    return createFunctionType(node, newNullability, newTypeParameters,
        newReturnType, newPositionalParameters, newNamedParameters);
  }

  @override
  DartType? visitRecordType(RecordType node, Variance variance) {
    Nullability? newNullability = visitNullability(node);

    DartType? visitType(DartType? type, Variance variance) {
      return type?.accept1(this, variance);
    }

    List<DartType>? newPositional = null;
    for (int i = 0; i < node.positional.length; i++) {
      DartType? newType = visitType(node.positional[i], variance);
      if (newType != null) {
        newPositional ??= node.positional.toList(growable: false);
        newPositional[i] = newType;
      }
    }
    List<NamedType>? newNamed = null;
    for (int i = 0; i < node.named.length; i++) {
      DartType? newType = visitType(node.named[i].type, variance);
      NamedType? newNamedType = createNamedType(node.named[i], newType);
      if (newNamedType != null) {
        newNamed ??= node.named.toList(growable: false);
        newNamed[i] = newNamedType;
      }
    }

    return createRecordType(node, newNullability, newPositional, newNamed);
  }

  NamedType? createNamedType(NamedType node, DartType? newType) {
    if (newType == null) {
      return null;
    } else {
      return new NamedType(node.name, newType, isRequired: node.isRequired);
    }
  }

  DartType? createFunctionType(
      FunctionType node,
      Nullability? newNullability,
      List<StructuralParameter>? newTypeParameters,
      DartType? newReturnType,
      List<DartType>? newPositionalParameters,
      List<NamedType>? newNamedParameters) {
    if (newNullability == null &&
        newReturnType == null &&
        newPositionalParameters == null &&
        newNamedParameters == null) {
      // No nullability or types had to be substituted.
      return null;
    } else {
      return new FunctionType(
          newPositionalParameters ?? node.positionalParameters,
          newReturnType ?? node.returnType,
          newNullability ?? node.nullability,
          namedParameters: newNamedParameters ?? node.namedParameters,
          typeParameters: newTypeParameters ?? node.typeParameters,
          requiredParameterCount: node.requiredParameterCount);
    }
  }

  DartType? createRecordType(RecordType node, Nullability? newNullability,
      List<DartType>? newPositional, List<NamedType>? newNamed) {
    if (newNullability == null && newPositional == null && newNamed == null) {
      // No nullability or types had to be substituted.
      return null;
    } else {
      return new RecordType(newPositional ?? node.positional,
          newNamed ?? node.named, newNullability ?? node.nullability);
    }
  }

  @override
  DartType? visitInterfaceType(InterfaceType node, Variance variance) {
    Nullability? newNullability = visitNullability(node);
    List<DartType>? newTypeArguments = null;
    for (int i = 0; i < node.typeArguments.length; i++) {
      DartType? substitution = node.typeArguments[i].accept1(this, variance);
      if (substitution != null) {
        newTypeArguments ??= node.typeArguments.toList(growable: false);
        newTypeArguments[i] = substitution;
      }
    }
    return createInterfaceType(node, newNullability, newTypeArguments);
  }

  DartType? createInterfaceType(InterfaceType node, Nullability? newNullability,
      List<DartType>? newTypeArguments) {
    if (newNullability == null && newTypeArguments == null) {
      // No nullability or type arguments needed to be substituted.
      return null;
    } else {
      return new InterfaceType.byReference(
          node.classReference,
          newNullability ?? node.nullability,
          newTypeArguments ?? node.typeArguments);
    }
  }

  @override
  DartType? visitFutureOrType(FutureOrType node, Variance variance) {
    Nullability? newNullability = visitNullability(node);
    DartType? newTypeArgument = node.typeArgument.accept1(this, variance);
    return createFutureOrType(node, newNullability, newTypeArgument);
  }

  DartType? createFutureOrType(FutureOrType node, Nullability? newNullability,
      DartType? newTypeArgument) {
    if (newNullability == null && newTypeArgument == null) {
      // No nullability or type arguments needed to be substituted.
      return null;
    } else {
      newTypeArgument ??= node.typeArgument;
      newNullability ??= node.declaredNullability;

      // The top-level nullability of a FutureOr should remain the same, with
      // the exception of the case of [Nullability.undetermined].  In that case
      // it remains undetermined if the nullability of [typeArgument] is
      // undetermined, and otherwise it should become
      // [Nullability.nonNullable].
      Nullability adjustedNullability;
      if (newNullability == Nullability.undetermined) {
        if (newTypeArgument.nullability == Nullability.undetermined) {
          adjustedNullability = Nullability.undetermined;
        } else {
          adjustedNullability = Nullability.nonNullable;
        }
      } else {
        adjustedNullability = newNullability;
      }

      return new FutureOrType(newTypeArgument, adjustedNullability);
    }
  }

  @override
  DartType? visitDynamicType(DynamicType node, Variance variance) => null;

  @override
  DartType? visitNeverType(NeverType node, Variance variance) {
    Nullability? newNullability = visitNullability(node);
    return createNeverType(node, newNullability);
  }

  DartType? createNeverType(NeverType node, Nullability? newNullability) {
    if (newNullability == null) {
      // No nullability needed to be substituted.
      return null;
    } else {
      return NeverType.fromNullability(newNullability);
    }
  }

  @override
  DartType? visitNullType(NullType node, Variance variance) => null;

  @override
  DartType? visitInvalidType(InvalidType node, Variance variance) => null;

  @override
  DartType? visitVoidType(VoidType node, Variance variance) => null;

  @override
  DartType? visitTypeParameterType(TypeParameterType node, Variance variance) {
    Nullability? newNullability = visitNullability(node);
    return createTypeParameterType(node, newNullability);
  }

  @override
  DartType? visitStructuralParameterType(
      StructuralParameterType node, Variance variance) {
    Nullability? newNullability = visitNullability(node);
    return createStructuralParameterType(node, newNullability);
  }

  @override
  DartType? visitIntersectionType(IntersectionType node, Variance variance) {
    DartType? newLeft = node.left.accept1(this, variance);
    DartType? newRight = node.right.accept1(this, variance);
    return createIntersectionType(
        node, newLeft as TypeParameterType?, newRight);
  }

  DartType? createTypeParameterType(
      TypeParameterType node, Nullability? newNullability) {
    if (newNullability == null) {
      // No nullability needed to be substituted.
      return null;
    } else {
      return new TypeParameterType(node.parameter, newNullability);
    }
  }

  DartType? createStructuralParameterType(
      StructuralParameterType node, Nullability? newNullability) {
    if (newNullability == null) {
      // No nullability needed to be substituted.
      return null;
    } else {
      return new StructuralParameterType(node.parameter, newNullability);
    }
  }

  DartType? createIntersectionType(
      IntersectionType node, TypeParameterType? left, DartType? right) {
    if (left == null && right == null) {
      return null;
    } else {
      return new IntersectionType(left ?? node.left, right ?? node.right);
    }
  }

  @override
  DartType? visitTypedefType(TypedefType node, Variance variance) {
    Nullability? newNullability = visitNullability(node);
    List<DartType>? newTypeArguments = null;
    for (int i = 0; i < node.typeArguments.length; i++) {
      DartType? substitution = node.typeArguments[i].accept1(
          this, variance.combine(node.typedefNode.typeParameters[i].variance));
      if (substitution != null) {
        newTypeArguments ??= node.typeArguments.toList(growable: false);
        newTypeArguments[i] = substitution;
      }
    }
    return createTypedef(node, newNullability, newTypeArguments);
  }

  DartType? createTypedef(TypedefType node, Nullability? newNullability,
      List<DartType>? newTypeArguments) {
    if (newNullability == null && newTypeArguments == null) {
      // No nullability or type arguments needed to be substituted.
      return null;
    } else {
      return new TypedefType(
          node.typedefNode,
          newNullability ?? node.nullability,
          newTypeArguments ?? node.typeArguments);
    }
  }

  @override
  DartType? visitExtensionType(ExtensionType node, Variance variance) {
    Nullability? newNullability = visitNullability(node);
    List<DartType>? newTypeArguments = null;
    for (int i = 0; i < node.typeArguments.length; i++) {
      DartType? substitution = node.typeArguments[i].accept1(
          this,
          variance.combine(
              node.extensionTypeDeclaration.typeParameters[i].variance));
      if (substitution != null) {
        newTypeArguments ??= node.typeArguments.toList(growable: false);
        newTypeArguments[i] = substitution;
      }
    }
    return createExtensionType(node, newNullability, newTypeArguments);
  }

  DartType? createExtensionType(ExtensionType node, Nullability? newNullability,
      List<DartType>? newTypeArguments) {
    if (newNullability == null && newTypeArguments == null) {
      // No nullability or type arguments needed to be substituted.
      return null;
    } else {
      return new ExtensionType(
          node.extensionTypeDeclaration,
          newNullability ?? node.declaredNullability,
          newTypeArguments ?? node.typeArguments);
    }
  }

  @override
  DartType? visitAuxiliaryType(AuxiliaryType node, Variance variance) {
    // TODO(johnniwinther): Use [DartTypeVisitor1AuxiliaryFunction] to handle
    // [AuxiliaryType]s.
    return null;
  }
}
