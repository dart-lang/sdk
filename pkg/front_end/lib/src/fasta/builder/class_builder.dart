// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_builder;

import 'builder.dart' show
    Builder,
    ConstructorReferenceBuilder,
    LibraryBuilder,
    MetadataBuilder,
    TypeBuilder,
    TypeDeclarationBuilder,
    TypeVariableBuilder;

import 'scope.dart' show
    AmbiguousBuilder,
    Scope;

abstract class ClassBuilder<T extends TypeBuilder, R>
    extends TypeDeclarationBuilder<T, R> {
  final List<TypeVariableBuilder> typeVariables;

  T supertype;

  List<T> interfaces;

  final Map<String, Builder> members;

  ClassBuilder(
      List<MetadataBuilder> metadata, int modifiers,
      String name, this.typeVariables, this.supertype, this.interfaces,
      this.members, List<T> types, LibraryBuilder parent, int charOffset)
      : super(metadata, modifiers, name, types, parent, charOffset);

  List<ConstructorReferenceBuilder> get constructorReferences => null;

  Map<String, Builder> get constructors;

  Map<String, Builder> get membersInScope => members;

  int resolveTypes(LibraryBuilder library) {
    Scope scope;
    int count = 0;
    if (types != null) {
      scope = computeInstanceScope(library.scope);
      for (T t in types) {
        t.resolveIn(scope);
      }
      count += types.length;
    }
    return count;
  }

  int resolveConstructors(LibraryBuilder library) {
    if (constructorReferences == null) return 0;
    Scope scope = computeInstanceScope(library.scope);
    for (ConstructorReferenceBuilder ref in constructorReferences) {
      ref.resolveIn(scope);
    }
    return constructorReferences.length;
  }

  Scope computeInstanceScope(Scope parent) {
    if (typeVariables != null) {
      Map<String, Builder> local = <String, Builder>{};
      for (TypeVariableBuilder t in typeVariables) {
        local[t.name] = t;
      }
      parent = new Scope(local, parent, isModifiable: false);
    }
    return new Scope(membersInScope, parent, isModifiable: false);
  }

  /// Used to lookup a static member of this class.
  Builder findStaticBuilder(String name, int charOffset, Uri fileUri,
      {bool isSetter: false}) {
    Builder builder = members[name];
    if (builder?.next != null) {
      Builder getterBuilder;
      Builder setterBuilder;
      Builder current = builder;
      while (current != null) {
        if (current.isGetter && getterBuilder == null) {
          getterBuilder = current;
        } else if (current.isSetter && setterBuilder == null) {
          setterBuilder = current;
        } else {
          return new AmbiguousBuilder(builder, charOffset, fileUri);
        }
        current = current.next;
      }
      builder = isSetter ? setterBuilder : getterBuilder;
    }
    if (builder == null) {
      return null;
    } else if (isSetter && builder.isGetter) {
      return null;
    } else {
      return builder.isInstanceMember ? null : builder;
    }
  }

  Builder findConstructorOrFactory(String name);
}
