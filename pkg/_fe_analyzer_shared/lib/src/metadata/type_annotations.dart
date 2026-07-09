// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'expressions.dart';
import 'formal_parameters.dart';
import 'proto.dart';
import 'references.dart';
import 'util.dart';

/// Supertype for all type annotations.
sealed class TypeAnnotation {
  /// Returns the [TypeAnnotation] corresponding to this [TypeAnnotation] in
  /// which all [UnresolvedIdentifier]s have been resolved within their scope.
  ///
  /// If this didn't create a new [TypeAnnotation], `null` is returned.
  ///
  /// [env] maps from the [FunctionTypeParameter]s of this [TypeAnnotation] to
  /// the [FunctionTypeParameter]s in the returned [TypeAnnotation]. This is
  /// needed because [FunctionTypeParameter] contains its bound, which itself
  /// might be resolved in the process.
  TypeAnnotation? resolve({
    Map<FunctionTypeParameter, FunctionTypeParameter> env = const {},
  });
}

class NamedTypeAnnotation extends TypeAnnotation {
  final Reference reference;
  final List<TypeAnnotation> typeArguments;

  NamedTypeAnnotation(this.reference, [this.typeArguments = const []]);

  @override
  String toString() => 'NamedTypeAnnotation($reference,$typeArguments)';

  @override
  TypeAnnotation? resolve({
    Map<FunctionTypeParameter, FunctionTypeParameter> env = const {},
  }) {
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (a) => a.resolve(env: env),
    );
    return newTypeArguments == null
        ? null
        : new NamedTypeAnnotation(reference, newTypeArguments);
  }
}

class NullableTypeAnnotation extends TypeAnnotation {
  final TypeAnnotation typeAnnotation;

  NullableTypeAnnotation(this.typeAnnotation);

  @override
  String toString() => 'NullableTypeAnnotation($typeAnnotation)';

  @override
  TypeAnnotation? resolve({
    Map<FunctionTypeParameter, FunctionTypeParameter> env = const {},
  }) {
    TypeAnnotation? newTypeAnnotation = typeAnnotation.resolve(env: env);
    return newTypeAnnotation == null
        ? null
        : new NullableTypeAnnotation(newTypeAnnotation);
  }
}

class VoidTypeAnnotation extends TypeAnnotation {
  final Reference reference;

  VoidTypeAnnotation(this.reference);

  @override
  String toString() => 'VoidTypeAnnotation()';

  @override
  TypeAnnotation? resolve({
    Map<FunctionTypeParameter, FunctionTypeParameter> env = const {},
  }) => null;
}

class DynamicTypeAnnotation extends TypeAnnotation {
  final Reference reference;

  DynamicTypeAnnotation(this.reference);

  @override
  String toString() => 'DynamicTypeAnnotation()';

  @override
  TypeAnnotation? resolve({
    Map<FunctionTypeParameter, FunctionTypeParameter> env = const {},
  }) => null;
}

class InvalidTypeAnnotation extends TypeAnnotation {
  InvalidTypeAnnotation();

  @override
  String toString() => 'InvalidTypeAnnotation()';

  @override
  TypeAnnotation? resolve({
    Map<FunctionTypeParameter, FunctionTypeParameter> env = const {},
  }) => null;
}

class UnresolvedTypeAnnotation extends TypeAnnotation {
  final Unresolved unresolved;

  UnresolvedTypeAnnotation(this.unresolved);

  @override
  String toString() => 'UnresolvedTypeAnnotation($unresolved)';

  @override
  TypeAnnotation? resolve({
    Map<FunctionTypeParameter, FunctionTypeParameter> env = const {},
  }) {
    return unresolved.resolveAsTypeAnnotation();
  }
}

class FunctionTypeAnnotation extends TypeAnnotation {
  final TypeAnnotation? returnType;
  final List<FunctionTypeParameter> typeParameters;
  final List<FormalParameter> formalParameters;

  FunctionTypeAnnotation(
    this.returnType,
    this.typeParameters,
    this.formalParameters,
  );

  @override
  String toString() =>
      'FunctionTypeAnnotation($returnType,$typeParameters,$formalParameters)';

  @override
  TypeAnnotation? resolve({
    Map<FunctionTypeParameter, FunctionTypeParameter> env = const {},
  }) {
    bool needsNewTypeParameters = false;
    for (FunctionTypeParameter typeParameter in typeParameters) {
      if (typeParameter.bound?.resolve(env: env) != null) {
        needsNewTypeParameters = true;
        break;
      }
      if (typeParameter.metadata?.resolve((e) => e.resolve()) != null) {
        needsNewTypeParameters = true;
        break;
      }
    }
    List<FunctionTypeParameter>? resolvedTypeParameters;
    if (needsNewTypeParameters) {
      resolvedTypeParameters = [];
      env = {...env};
      for (FunctionTypeParameter typeParameter in typeParameters) {
        FunctionTypeParameter resolvedTypeParameter = new FunctionTypeParameter(
          typeParameter.name,
        );
        env[typeParameter] = resolvedTypeParameter;
        resolvedTypeParameters.add(resolvedTypeParameter);
      }
      for (int i = 0; i < typeParameters.length; i++) {
        FunctionTypeParameter typeParameter = typeParameters[i];
        FunctionTypeParameter resolvedTypeParameter = resolvedTypeParameters[i];
        resolvedTypeParameter.bound =
            typeParameter.bound?.resolve(env: env) ?? typeParameter.bound;
        resolvedTypeParameter.metadata =
            typeParameter.metadata?.resolve((e) => e.resolve()) ??
            typeParameter.metadata;
      }
    }
    TypeAnnotation? resolvedReturnType = returnType?.resolve();
    List<FormalParameter>? resolvedFormalParameters = formalParameters.resolve(
      (a) => a.resolve(),
    );
    return resolvedReturnType == null &&
            resolvedFormalParameters == null &&
            resolvedTypeParameters == null
        ? null
        : new FunctionTypeAnnotation(
            resolvedReturnType ?? returnType,
            resolvedTypeParameters ?? typeParameters,
            resolvedFormalParameters ?? formalParameters,
          );
  }
}

class FunctionTypeParameter {
  final String name;
  TypeAnnotation? bound;
  List<Expression>? metadata;

  FunctionTypeParameter(this.name);

  @override
  String toString() => 'FunctionTypeParameter($metadata,$name,$bound)';
}

class FunctionTypeParameterType extends TypeAnnotation {
  final FunctionTypeParameter functionTypeParameter;

  FunctionTypeParameterType(this.functionTypeParameter);

  @override
  String toString() => 'FunctionTypeParameterType($functionTypeParameter)';

  @override
  TypeAnnotation? resolve({
    Map<FunctionTypeParameter, FunctionTypeParameter> env = const {},
  }) {
    FunctionTypeParameter? resolvedFunctionTypeParameter =
        env[functionTypeParameter];
    return resolvedFunctionTypeParameter == null
        ? null
        : new FunctionTypeParameterType(resolvedFunctionTypeParameter);
  }
}

class RecordTypeAnnotation extends TypeAnnotation {
  final List<RecordTypeEntry> positional;
  final List<RecordTypeEntry> named;

  RecordTypeAnnotation(this.positional, this.named);

  @override
  String toString() => 'FunctionTypeParameterType($positional,$named)';

  @override
  TypeAnnotation? resolve({
    Map<FunctionTypeParameter, FunctionTypeParameter> env = const {},
  }) {
    List<RecordTypeEntry>? resolvedPositional = positional.resolve(
      (e) => e.resolve(env: env),
    );
    List<RecordTypeEntry>? resolvedNamed = named.resolve(
      (e) => e.resolve(env: env),
    );
    return resolvedPositional == null && resolvedNamed == null
        ? null
        : new RecordTypeAnnotation(
            resolvedPositional ?? positional,
            resolvedNamed ?? named,
          );
  }
}

class RecordTypeEntry {
  final List<Expression> metadata;
  final TypeAnnotation typeAnnotation;
  final String? name;

  RecordTypeEntry(this.metadata, this.typeAnnotation, this.name);

  RecordTypeEntry? resolve({
    Map<FunctionTypeParameter, FunctionTypeParameter> env = const {},
  }) {
    List<Expression>? resolvedMetadata = metadata.resolve((e) => e.resolve());
    TypeAnnotation? resolvedTypeAnnotation = typeAnnotation.resolve(env: env);
    return resolvedMetadata == null && resolvedTypeAnnotation == null
        ? null
        : new RecordTypeEntry(
            resolvedMetadata ?? metadata,
            resolvedTypeAnnotation ?? typeAnnotation,
            name,
          );
  }

  @override
  String toString() => 'RecordTypeEntry($metadata,$typeAnnotation,$name)';
}
