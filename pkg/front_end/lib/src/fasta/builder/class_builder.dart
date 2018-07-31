// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_builder;

import '../problems.dart' show internalProblem;

import 'builder.dart'
    show
        ConstructorReferenceBuilder,
        Declaration,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        MixinApplicationBuilder,
        NamedTypeBuilder,
        Scope,
        ScopeBuilder,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        templateInternalProblemNotFoundIn,
        templateInternalProblemSuperclassNotFound;

abstract class ClassBuilder<T extends TypeBuilder, R>
    extends TypeDeclarationBuilder<T, R> {
  final List<TypeVariableBuilder> typeVariables;

  T supertype;

  List<T> interfaces;

  final Scope scope;

  final Scope constructors;

  final ScopeBuilder scopeBuilder;

  final ScopeBuilder constructorScopeBuilder;

  Map<String, ConstructorRedirection> redirectingConstructors;

  ClassBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      this.typeVariables,
      this.supertype,
      this.interfaces,
      this.scope,
      this.constructors,
      LibraryBuilder parent,
      int charOffset)
      : scopeBuilder = new ScopeBuilder(scope),
        constructorScopeBuilder = new ScopeBuilder(constructors),
        super(metadata, modifiers, name, parent, charOffset);

  String get debugName => "ClassBuilder";

  @override
  bool get buildsArguments => true;

  /// Returns true if this class is the result of applying a mixin to its
  /// superclass.
  bool get isMixinApplication => mixedInType != null;

  bool get isNamedMixinApplication {
    return isMixinApplication && super.isNamedMixinApplication;
  }

  T get mixedInType;

  void set mixedInType(T mixin);

  List<ConstructorReferenceBuilder> get constructorReferences => null;

  LibraryBuilder get library {
    LibraryBuilder library = parent;
    return library.partOfLibrary ?? library;
  }

  /// Registers a constructor redirection for this class and returns true if
  /// this redirection gives rise to a cycle that has not been reported before.
  bool checkConstructorCyclic(String source, String target) {
    ConstructorRedirection redirect = new ConstructorRedirection(target);
    redirectingConstructors ??= <String, ConstructorRedirection>{};
    redirectingConstructors[source] = redirect;
    while (redirect != null) {
      if (redirect.cycleReported) return false;
      if (redirect.target == source) {
        redirect.cycleReported = true;
        return true;
      }
      redirect = redirectingConstructors[redirect.target];
    }
    return false;
  }

  @override
  int resolveConstructors(LibraryBuilder library) {
    if (constructorReferences == null) return 0;
    for (ConstructorReferenceBuilder ref in constructorReferences) {
      ref.resolveIn(scope, library);
    }
    return constructorReferences.length;
  }

  /// Used to lookup a static member of this class.
  Declaration findStaticBuilder(
      String name, int charOffset, Uri fileUri, LibraryBuilder accessingLibrary,
      {bool isSetter: false}) {
    if (accessingLibrary.origin != library.origin && name.startsWith("_")) {
      return null;
    }
    Declaration declaration = isSetter
        ? scope.lookupSetter(name, charOffset, fileUri, isInstanceScope: false)
        : scope.lookup(name, charOffset, fileUri, isInstanceScope: false);
    return declaration;
  }

  Declaration findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary) {
    if (accessingLibrary.origin != library.origin && name.startsWith("_")) {
      return null;
    }
    return constructors.lookup(name, charOffset, uri);
  }

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
    Declaration declaration;

    /// If [application] is mixing in [superclass] directly or via other named
    /// mixin applications, return it.
    NamedTypeBuilder findSuperclass(MixinApplicationBuilder application) {
      for (TypeBuilder t in application.mixins) {
        if (t is NamedTypeBuilder) {
          if (t.declaration == superclass) return t;
        } else if (t is MixinApplicationBuilder) {
          NamedTypeBuilder s = findSuperclass(t);
          if (s != null) return s;
        }
      }
      return null;
    }

    void handleNamedTypeBuilder(NamedTypeBuilder t) {
      declaration = t.declaration;
      arguments = t.arguments ?? const [];
      if (declaration is ClassBuilder) {
        ClassBuilder cls = declaration;
        variables = cls.typeVariables;
        supertype = cls.supertype;
      }
    }

    while (declaration != superclass) {
      variables = null;
      if (supertype is NamedTypeBuilder) {
        handleNamedTypeBuilder(supertype);
      } else if (supertype is MixinApplicationBuilder) {
        MixinApplicationBuilder t = supertype;
        NamedTypeBuilder s = findSuperclass(t);
        if (s != null) {
          handleNamedTypeBuilder(s);
        }
        supertype = t.supertype;
      } else {
        internalProblem(
            templateInternalProblemSuperclassNotFound
                .withArguments(superclass.fullNameForErrors),
            charOffset,
            fileUri);
      }
      if (variables != null) {
        Map<TypeVariableBuilder, TypeBuilder> directSubstitutionMap =
            <TypeVariableBuilder, TypeBuilder>{};
        for (int i = 0; i < variables.length; i++) {
          TypeBuilder argument =
              i < arguments.length ? arguments[i] : dynamicType;
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

  void forEach(void f(String name, MemberBuilder builder)) {
    scope.forEach(f);
  }

  /// Don't use for scope lookup. Only use when an element is known to exist
  /// (and isn't a setter).
  MemberBuilder operator [](String name) {
    // TODO(ahe): Rename this to getLocalMember.
    return scope.local[name] ??
        internalProblem(
            templateInternalProblemNotFoundIn.withArguments(
                name, fullNameForErrors),
            -1,
            null);
  }

  void addCompileTimeError(Message message, int charOffset, int length,
      {List<LocatedMessage> context}) {
    library.addCompileTimeError(message, charOffset, length, fileUri,
        context: context);
  }

  void addProblem(Message message, int charOffset, int length,
      {List<LocatedMessage> context}) {
    library.addProblem(message, charOffset, length, fileUri, context: context);
  }

  void prepareTopLevelInference() {}
}

class ConstructorRedirection {
  String target;
  bool cycleReported;

  ConstructorRedirection(this.target) : cycleReported = false;
}
