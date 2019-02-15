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
        Scope,
        ScopeBuilder,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder;

import '../fasta_codes.dart'
    show LocatedMessage, Message, templateInternalProblemNotFoundIn;

abstract class ClassBuilder<T extends TypeBuilder, R>
    extends TypeDeclarationBuilder<T, R> {
  List<TypeVariableBuilder> typeVariables;

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

  /// Returns true if this class is the result of applying a mixin to its
  /// superclass.
  bool get isMixinApplication => mixedInType != null;

  @override
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

  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage> context}) {
    library.addProblem(message, charOffset, length, fileUri,
        wasHandled: wasHandled, context: context);
  }

  /// Find the first member of this class with [name]. This method isn't
  /// suitable for scope lookups as it will throw an error if the name isn't
  /// declared. The [scope] should be used for that. This method is used to
  /// find a member that is known to exist and it wil pick the first
  /// declaration if the name is ambiguous.
  ///
  /// For example, this method is convenient for use when building synthetic
  /// members, such as those of an enum.
  MemberBuilder firstMemberNamed(String name) {
    Declaration declaration = this[name];
    while (declaration.next != null) {
      declaration = declaration.next;
    }
    return declaration;
  }
}

class ConstructorRedirection {
  String target;
  bool cycleReported;

  ConstructorRedirection(this.target) : cycleReported = false;
}
