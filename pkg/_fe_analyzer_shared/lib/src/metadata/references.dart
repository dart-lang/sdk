// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A resolved reference to an entity.
// TODO(johnniwinther): Do we need to split these into subtypes?
sealed class Reference {
  const Reference();
}

abstract class FieldReference extends Reference {
  String get name;

  @override
  String toString() => 'FieldReference(${name})';
}

abstract class FunctionReference extends Reference {
  String get name;

  @override
  String toString() => 'FunctionReference(${name})';
}

abstract class ConstructorReference extends Reference {
  String get name;

  @override
  String toString() => 'ConstructorReference(${name})';
}

abstract class TypeReference extends Reference {
  const TypeReference();

  String get name;

  @override
  String toString() => 'TypeReference(${name})';
}

abstract class ClassReference extends Reference {
  String get name;

  @override
  String toString() => 'ClassReference(${name})';
}

abstract class TypedefReference extends Reference {
  String get name;

  @override
  String toString() => 'TypedefReference(${name})';
}

abstract class ExtensionReference extends Reference {
  String get name;

  @override
  String toString() => 'ExtensionReference(${name})';
}

abstract class ExtensionTypeReference extends Reference {
  String get name;

  @override
  String toString() => 'ExtensionTypeReference(${name})';
}

abstract class EnumReference extends Reference {
  String get name;

  @override
  String toString() => 'EnumReference(${name})';
}

abstract class MixinReference extends Reference {
  String get name;

  @override
  String toString() => 'MixinReference(${name})';
}

abstract class FunctionTypeParameterReference extends Reference {
  String get name;

  @override
  String toString() => 'FunctionTypeParameterReference(${name})';
}

/// Symbolic references needed during parsing.
abstract class References {
  /// The [TypeReference] used for parsing `void`.
  TypeReference get voidReference;

  /// The [TypeReference] used for parsing `void`.
  TypeReference get dynamicReference;
}
