// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import '../type_algebra.dart';

/// Helper visitor that clones a type if a nested type is replaced, and
/// otherwise returns `null`.
class ReplacementVisitor implements DartTypeVisitor1<DartType?, int> {
  const ReplacementVisitor();

  Nullability? visitNullability(DartType node) => null;

  @override
  DartType? visitFunctionType(FunctionType node, int variance) {
    Nullability? newNullability = visitNullability(node);

    List<TypeParameter>? newTypeParameters;
    for (int i = 0; i < node.typeParameters.length; i++) {
      TypeParameter typeParameter = node.typeParameters[i];
      // TODO(johnniwinther): Bounds should not be null, even in case of
      // cyclic typedefs. Currently
      //   instantiate_to_bound/non_simple_class_parametrized_typedef_cycle
      // fails with this.
      DartType? newBound = typeParameter.bound
          .accept1(this, Variance.combine(variance, Variance.invariant));
      DartType? newDefaultType = typeParameter.defaultType
          .accept1(this, Variance.combine(variance, Variance.invariant));
      if (newBound != null || newDefaultType != null) {
        newTypeParameters ??= node.typeParameters.toList(growable: false);
        newTypeParameters[i] = new TypeParameter(
            typeParameter.name,
            newBound ?? typeParameter.bound,
            newDefaultType ?? typeParameter.defaultType);
      }
    }

    Substitution? substitution;
    if (newTypeParameters != null) {
      List<TypeParameterType> typeParameterTypes =
          new List<TypeParameterType>.generate(newTypeParameters.length,
              (int i) {
        return new TypeParameterType.forAlphaRenaming(
            node.typeParameters[i], newTypeParameters![i]);
      }, growable: false);
      substitution =
          Substitution.fromPairs(node.typeParameters, typeParameterTypes);
      for (int i = 0; i < newTypeParameters.length; i++) {
        newTypeParameters[i].bound =
            substitution.substituteType(newTypeParameters[i].bound);
      }
    }

    DartType? visitType(DartType? type, int variance) {
      if (type == null) return null;
      DartType? result = type.accept1(this, variance);
      if (substitution != null) {
        result = substitution.substituteType(result ?? type);
      }
      return result;
    }

    DartType? newReturnType = visitType(node.returnType, variance);
    List<DartType>? newPositionalParameters = null;
    for (int i = 0; i < node.positionalParameters.length; i++) {
      DartType? newType = visitType(node.positionalParameters[i],
          Variance.combine(variance, Variance.contravariant));
      if (newType != null) {
        newPositionalParameters ??=
            node.positionalParameters.toList(growable: false);
        newPositionalParameters[i] = newType;
      }
    }
    List<NamedType>? newNamedParameters = null;
    for (int i = 0; i < node.namedParameters.length; i++) {
      DartType? newType = visitType(node.namedParameters[i].type,
          Variance.combine(variance, Variance.contravariant));
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
  DartType? visitRecordType(RecordType node, int variance) {
    Nullability? newNullability = visitNullability(node);

    DartType? visitType(DartType? type, int variance) {
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
      List<TypeParameter>? newTypeParameters,
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
  DartType? visitInterfaceType(InterfaceType node, int variance) {
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
  DartType? visitFutureOrType(FutureOrType node, int variance) {
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
  DartType? visitDynamicType(DynamicType node, int variance) => null;

  @override
  DartType? visitNeverType(NeverType node, int variance) {
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
  DartType? visitNullType(NullType node, int variance) => null;

  @override
  DartType? visitInvalidType(InvalidType node, int variance) => null;

  @override
  DartType? visitVoidType(VoidType node, int variance) => null;

  @override
  DartType? visitTypeParameterType(TypeParameterType node, int variance) {
    Nullability? newNullability = visitNullability(node);
    return createTypeParameterType(node, newNullability);
  }

  @override
  DartType? visitIntersectionType(IntersectionType node, int variance) {
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

  DartType? createIntersectionType(
      IntersectionType node, TypeParameterType? left, DartType? right) {
    if (left == null && right == null) {
      return null;
    } else {
      return new IntersectionType(left ?? node.left, right ?? node.right);
    }
  }

  @override
  DartType? visitTypedefType(TypedefType node, int variance) {
    Nullability? newNullability = visitNullability(node);
    List<DartType>? newTypeArguments = null;
    for (int i = 0; i < node.typeArguments.length; i++) {
      DartType? substitution = node.typeArguments[i].accept1(
          this,
          Variance.combine(
              variance, node.typedefNode.typeParameters[i].variance));
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
  DartType? visitExtensionType(ExtensionType node, int variance) {
    Nullability? newNullability = visitNullability(node);
    List<DartType>? newTypeArguments = null;
    for (int i = 0; i < node.typeArguments.length; i++) {
      DartType? substitution = node.typeArguments[i].accept1(
          this,
          Variance.combine(variance,
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
          newNullability ?? node.nullability,
          newTypeArguments ?? node.typeArguments);
    }
  }

  @override
  DartType? defaultDartType(DartType node, int variance) => null;
}
