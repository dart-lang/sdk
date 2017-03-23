// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_builder;

import '../errors.dart' show internalError;

import 'builder.dart'
    show
        Builder,
        ConstructorReferenceBuilder,
        LibraryBuilder,
        MetadataBuilder,
        MixinApplicationBuilder,
        NamedTypeBuilder,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder;

import 'scope.dart' show AccessErrorBuilder, AmbiguousBuilder, Scope;

abstract class ClassBuilder<T extends TypeBuilder, R>
    extends TypeDeclarationBuilder<T, R> {
  final List<TypeVariableBuilder> typeVariables;

  T supertype;

  List<T> interfaces;

  final Map<String, Builder> members;

  ClassBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      this.typeVariables,
      this.supertype,
      this.interfaces,
      this.members,
      LibraryBuilder parent,
      int charOffset)
      : super(metadata, modifiers, name, parent, charOffset);

  /// Returns true if this class is the result of applying a mixin to its
  /// superclass.
  bool get isMixinApplication => mixedInType != null;

  T get mixedInType;

  List<ConstructorReferenceBuilder> get constructorReferences => null;

  Map<String, Builder> get constructors;

  Map<String, Builder> get membersInScope => members;

  LibraryBuilder get library {
    LibraryBuilder library = parent;
    return library.partOfLibrary ?? library;
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
          return new AmbiguousBuilder(name, builder, charOffset, fileUri);
        }
        current = current.next;
      }
      if (getterBuilder?.isInstanceMember ?? false) {
        getterBuilder = null;
      }
      if (setterBuilder?.isInstanceMember ?? false) {
        setterBuilder = null;
      }
      builder = isSetter ? setterBuilder : getterBuilder;
      if (builder == null) {
        if (isSetter && getterBuilder != null) {
          return new AccessErrorBuilder(
              name, getterBuilder, charOffset, fileUri);
        } else if (!isSetter && setterBuilder != null) {
          return new AccessErrorBuilder(
              name, setterBuilder, charOffset, fileUri);
        }
      }
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

  /// Returns a map which maps the type variables of [superclass] to their
  /// respective values as defined by the superclass clause of this class (and
  /// its superclasses).
  ///
  /// It's assumed that [superclass] is a superclass of this class.
  ///
  /// For example, given:
  ///
  ///     class Box<T> {}
  ///     class BeatBox extends Box<Beat> {}
  ///     class Beat {}
  ///
  /// We have:
  ///
  ///     [[BeatBox]].getSubstitutionMap([[Box]]) -> {[[Box::T]]: Beat]]}.
  ///
  /// This method returns null if the map is empty, and it's an error if
  /// [superclass] isn't a superclass.
  Map<TypeVariableBuilder, TypeBuilder> getSubstitutionMap(
      ClassBuilder superclass,
      Uri fileUri,
      int charOffset,
      TypeBuilder dynamicType) {
    TypeBuilder supertype = this.supertype;
    Map<TypeVariableBuilder, TypeBuilder> substitutionMap;
    List arguments;
    List variables;
    Builder builder;
    while (builder != superclass) {
      if (supertype is NamedTypeBuilder) {
        NamedTypeBuilder t = supertype;
        builder = t.builder;
        arguments = t.arguments;
        if (builder is ClassBuilder) {
          variables = builder.typeVariables;
          if (builder != superclass) {
            supertype = builder.supertype;
          }
        }
      } else if (supertype is MixinApplicationBuilder) {
        MixinApplicationBuilder t = supertype;
        supertype = t.supertype;
      } else {
        internalError("Superclass not found.", fileUri, charOffset);
      }
      if (variables != null) {
        Map<TypeVariableBuilder, TypeBuilder> directSubstitutionMap =
            <TypeVariableBuilder, TypeBuilder>{};
        arguments ??= const [];
        for (int i = 0; i < variables.length; i++) {
          TypeBuilder argument =
              arguments.length < i ? arguments[i] : dynamicType;
          if (substitutionMap != null) {
            argument = argument.subst(substitutionMap);
          }
          directSubstitutionMap[variables[i]] = argument;
        }
        substitutionMap = directSubstitutionMap;
      }
    }
    return substitutionMap;
  }

  void addCompileTimeError(int charOffset, String message) {
    library.addCompileTimeError(charOffset, message, fileUri: fileUri);
  }

  void addWarning(int charOffset, String message) {
    library.addWarning(charOffset, message, fileUri: fileUri);
  }

  void addNit(int charOffset, String message) {
    library.addNit(charOffset, message, fileUri: fileUri);
  }
}
