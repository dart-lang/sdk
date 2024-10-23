// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'proto.dart';
import 'references.dart';
import 'type_annotations.dart';

/// Scope used to lookup named entities.
abstract class Scope {
  /// Returns the [Proto] corresponding to [name] in this scope.
  ///
  /// This might be an [UnresolvedIdentifier] if [name] was not found in this
  /// scope.
  Proto lookup(String name);
}

/// Scope of a type declaration used to lookup static members.
abstract class TypeDeclarationScope {
  /// Returns the [Proto] corresponding to accessing [name] on the type
  /// declaration.
  ///
  /// If the access is preceded by [typeArguments], these must be passed and
  /// included in the returned [Proto].
  Proto lookup(String name, [List<TypeAnnotation>? typeArguments]);
}

/// Base implementation for creating a [TypeDeclarationScope] for a class.
abstract base class BaseClassScope implements TypeDeclarationScope {
  ClassReference get classReference;

  Proto createConstructorProto(List<TypeAnnotation>? typeArguments,
      ConstructorReference constructorReference) {
    return new ConstructorProto(
        classReference, typeArguments ?? const [], constructorReference);
  }

  Proto createMemberProto<T>(List<TypeAnnotation>? typeArguments, String name,
      T? member, Proto Function(T, String) memberToProto) {
    if (member == null) {
      if (typeArguments != null) {
        return new UnresolvedAccess(
            new GenericClassProto(classReference, this, typeArguments), name);
      } else {
        return new UnresolvedAccess(new ClassProto(classReference, this), name);
      }
    } else {
      if (typeArguments != null) {
        return new InvalidAccessProto(
            new GenericClassProto(classReference, this, typeArguments), name);
      } else {
        return memberToProto(member, name);
      }
    }
  }
}

/// Base implementation for creating a [TypeDeclarationScope] for an extension.
abstract base class BaseExtensionScope implements TypeDeclarationScope {
  ExtensionReference get extensionReference;

  Proto createMemberProto<T>(List<TypeAnnotation>? typeArguments, String name,
      T? member, Proto Function(T, String) memberToProto) {
    if (typeArguments != null) {
      return new UnresolvedAccess(
          new InvalidInstantiationProto(
              new ExtensionProto(extensionReference, this), typeArguments),
          name);
    } else if (member == null) {
      return new UnresolvedAccess(
          new ExtensionProto(extensionReference, this), name);
    } else {
      return memberToProto(member, name);
    }
  }
}

/// Base implementation for creating a [TypeDeclarationScope] for a typedef.
abstract base class BaseTypedefScope implements TypeDeclarationScope {
  TypedefReference get typedefReference;

  Proto createConstructorProto(List<TypeAnnotation>? typeArguments,
      ConstructorReference constructorReference) {
    return new ConstructorProto(
        typedefReference, typeArguments ?? const [], constructorReference);
  }

  Proto createMemberProto(List<TypeAnnotation>? typeArguments, String name) {
    if (typeArguments != null) {
      return new UnresolvedAccess(
          new GenericTypedefProto(typedefReference, this, typeArguments), name);
    } else {
      return new UnresolvedAccess(
          new TypedefProto(typedefReference, this), name);
    }
  }
}
