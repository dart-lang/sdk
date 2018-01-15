// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'kernel_builder.dart'
    show
        TypeVariableBuilder,
        KernelTypeBuilder,
        KernelNamedTypeBuilder,
        KernelTypeVariableBuilder,
        KernelClassBuilder,
        KernelFunctionTypeAliasBuilder,
        NamedTypeBuilder,
        TypeDeclarationBuilder;

KernelTypeBuilder substituteRec(
    KernelTypeBuilder type,
    Map<TypeVariableBuilder, KernelTypeBuilder> substitution,
    KernelTypeBuilder dynamicType,
    int depth) {
  if (type is KernelNamedTypeBuilder) {
    if (type.builder is KernelTypeVariableBuilder &&
        substitution.containsKey(type.builder)) {
      if (depth > 0) {
        return substituteRec(
            substitution[type.builder], substitution, dynamicType, depth - 1);
      }
      return dynamicType;
    } else if (type.builder is KernelClassBuilder ||
        type.builder is KernelFunctionTypeAliasBuilder) {
      if (type.arguments == null || type.arguments.length == 0) {
        return type;
      }
      List<KernelTypeBuilder> typeArguments =
          new List<KernelTypeBuilder>(type.arguments.length);
      for (int i = 0; i < typeArguments.length; i++) {
        typeArguments[i] =
            substituteRec(type.arguments[i], substitution, dynamicType, depth);
      }
      return new KernelNamedTypeBuilder(type.name, typeArguments)
        ..bind(type.builder);
    }
  }
  return type;
}

List<KernelTypeBuilder> calculateBounds(
    List<TypeVariableBuilder> typeParameters,
    KernelTypeBuilder dynamicType,
    KernelClassBuilder objectClass) {
  var refinedBounds = new List<KernelTypeBuilder>(typeParameters.length);
  var substitution = new Map<TypeVariableBuilder, KernelTypeBuilder>();

  for (int i = 0; i < typeParameters.length; i++) {
    KernelTypeBuilder type = typeParameters[i].bound;
    if (type == null ||
        type is KernelNamedTypeBuilder &&
            type.builder is KernelClassBuilder &&
            (type.builder as KernelClassBuilder).cls == objectClass?.cls) {
      type = dynamicType;
    }

    refinedBounds[i] = type;
    substitution[typeParameters[i]] = type;
  }

  // TODO(dmitryas): Replace the call to [substituteRec] with actual
  // instantiate-to-bounds algorithm.
  List<KernelTypeBuilder> result =
      new List<KernelTypeBuilder>(typeParameters.length);
  for (int i = 0; i < result.length; i++) {
    // The current bound `refinedBounds[i]` is used as a starting point for
    // [substituteRec], that is, the first substitution of a type parameter with
    // its bound is already performed, so the depth parameter is lessened by 1.
    result[i] = substituteRec(
        refinedBounds[i], substitution, dynamicType, typeParameters.length - 1);
  }
  return result;
}

List<KernelTypeBuilder> calculateBoundsForDeclaration(
    TypeDeclarationBuilder typeDeclarationBuilder,
    KernelTypeBuilder dynamicType,
    KernelClassBuilder objectClass) {
  List<TypeVariableBuilder> typeParameters;

  if (typeDeclarationBuilder is KernelClassBuilder) {
    typeParameters = typeDeclarationBuilder.typeVariables;
  } else if (typeDeclarationBuilder is KernelFunctionTypeAliasBuilder) {
    typeParameters = typeDeclarationBuilder.typeVariables;
  }

  if (typeParameters == null || typeParameters.length == 0) {
    return null;
  }

  return calculateBounds(typeParameters, dynamicType, objectClass);
}

int instantiateToBoundInPlace(NamedTypeBuilder typeBuilder,
    KernelTypeBuilder dynamicType, KernelClassBuilder objectClass) {
  int count = 0;

  if (typeBuilder.arguments == null) {
    typeBuilder.arguments = calculateBoundsForDeclaration(
        typeBuilder.builder, dynamicType, objectClass);
    count = typeBuilder.arguments?.length ?? 0;
  }

  return count;
}
