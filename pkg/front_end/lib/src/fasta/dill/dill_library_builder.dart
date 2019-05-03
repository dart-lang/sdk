// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_library_builder;

import 'dart:convert' show jsonDecode;

import 'package:kernel/ast.dart'
    show
        Class,
        DartType,
        DynamicType,
        Field,
        FunctionType,
        Library,
        ListLiteral,
        Member,
        Procedure,
        StaticGet,
        StringLiteral,
        Typedef;

import '../fasta_codes.dart'
    show
        Message,
        templateDuplicatedDeclaration,
        templateTypeNotFound,
        templateUnspecified;

import '../problems.dart' show internalProblem, unhandled, unimplemented;

import '../kernel/kernel_builder.dart'
    show
        Declaration,
        DynamicTypeBuilder,
        InvalidTypeBuilder,
        KernelInvalidTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        Scope;

import '../kernel/redirecting_factory_body.dart' show RedirectingFactoryBody;

import 'dill_class_builder.dart' show DillClassBuilder;

import 'dill_member_builder.dart' show DillMemberBuilder;

import 'dill_loader.dart' show DillLoader;

import 'dill_type_alias_builder.dart' show DillTypeAliasBuilder;

class DillLibraryBuilder extends LibraryBuilder<KernelTypeBuilder, Library> {
  final Library library;

  DillLoader loader;

  /// Exports that can't be serialized.
  ///
  /// The elements of this map are documented in
  /// [../kernel/kernel_library_builder.dart].
  Map<String, String> unserializableExports;

  DillLibraryBuilder(this.library, this.loader)
      : super(library.fileUri, new Scope.top(), new Scope.top());

  @override
  bool get isSynthetic => library.isSynthetic;

  Uri get uri => library.importUri;

  Uri get fileUri => library.fileUri;

  @override
  String get name => library.name;

  @override
  Library get target => library;

  void addSyntheticDeclarationOfDynamic() {
    addBuilder(
        "dynamic",
        new DynamicTypeBuilder<KernelTypeBuilder, DartType>(
            const DynamicType(), this, -1),
        -1);
  }

  void addClass(Class cls) {
    DillClassBuilder classBulder = new DillClassBuilder(cls, this);
    addBuilder(cls.name, classBulder, cls.fileOffset);
    cls.procedures.forEach(classBulder.addMember);
    cls.constructors.forEach(classBulder.addMember);
    for (Field field in cls.fields) {
      if (field.name.name == "_redirecting#") {
        ListLiteral initializer = field.initializer;
        for (StaticGet get in initializer.expressions) {
          RedirectingFactoryBody.restoreFromDill(get.target);
        }
      } else {
        classBulder.addMember(field);
      }
    }
  }

  void addMember(Member member) {
    String name = member.name.name;
    if (name == "_exports#") {
      Field field = member;
      StringLiteral string = field.initializer;
      var json = jsonDecode(string.value);
      unserializableExports =
          json != null ? new Map<String, String>.from(json) : null;
    } else {
      addBuilder(name, new DillMemberBuilder(member, this), member.fileOffset);
    }
  }

  @override
  Declaration addBuilder(String name, Declaration declaration, int charOffset) {
    if (name == null || name.isEmpty) return null;
    bool isSetter = declaration.isSetter;
    if (isSetter) {
      scopeBuilder.addSetter(name, declaration);
    } else {
      scopeBuilder.addMember(name, declaration);
    }
    if (!name.startsWith("_")) {
      if (isSetter) {
        exportScopeBuilder.addSetter(name, declaration);
      } else {
        exportScopeBuilder.addMember(name, declaration);
      }
    }
    return declaration;
  }

  void addTypedef(Typedef typedef) {
    DartType type = typedef.type;
    if (type is FunctionType && type.typedefType == null) {
      unhandled("null", "addTypedef", typedef.fileOffset, typedef.fileUri);
    }
    addBuilder(typedef.name, new DillTypeAliasBuilder(typedef, this),
        typedef.fileOffset);
  }

  @override
  void addToScope(
      String name, Declaration member, int charOffset, bool isImport) {
    unimplemented("addToScope", charOffset, fileUri);
  }

  @override
  Declaration computeAmbiguousDeclaration(
      String name, Declaration builder, Declaration other, int charOffset,
      {bool isExport: false, bool isImport: false}) {
    if (builder == other) return builder;
    if (builder is InvalidTypeBuilder) return builder;
    if (other is InvalidTypeBuilder) return other;
    // For each entry mapping key `k` to declaration `d` in `NS` an entry
    // mapping `k` to `d` is added to the exported namespace of `L` unless a
    // top-level declaration with the name `k` exists in `L`.
    if (builder.parent == this) return builder;
    return new KernelInvalidTypeBuilder(
        name,
        templateDuplicatedDeclaration
            .withArguments(name)
            .withLocation(fileUri, charOffset, name.length));
  }

  @override
  String get fullNameForErrors {
    return library.name ?? "<library '${library.fileUri}'>";
  }

  void finalizeExports() {
    unserializableExports?.forEach((String name, String messageText) {
      Declaration declaration;
      switch (name) {
        case "dynamic":
        case "void":
          // TODO(ahe): It's likely that we shouldn't be exporting these types
          // from dart:core, and this case can be removed.
          declaration = loader.coreLibrary.exportScopeBuilder[name];
          break;

        default:
          Message message = messageText == null
              ? templateTypeNotFound.withArguments(name)
              : templateUnspecified.withArguments(messageText);
          declaration =
              new KernelInvalidTypeBuilder(name, message.withoutLocation());
      }
      exportScopeBuilder.addMember(name, declaration);
    });

    for (var reference in library.additionalExports) {
      var node = reference.node;
      Uri libraryUri;
      String name;
      bool isSetter = false;
      if (node is Class) {
        libraryUri = node.enclosingLibrary.importUri;
        name = node.name;
      } else if (node is Procedure) {
        libraryUri = node.enclosingLibrary.importUri;
        name = node.name.name;
        isSetter = node.isSetter;
      } else if (node is Member) {
        libraryUri = node.enclosingLibrary.importUri;
        name = node.name.name;
      } else if (node is Typedef) {
        libraryUri = node.enclosingLibrary.importUri;
        name = node.name;
      } else {
        unhandled("${node.runtimeType}", "finalizeExports", -1, fileUri);
      }
      DillLibraryBuilder library = loader.builders[libraryUri];
      if (library == null) {
        internalProblem(
            templateUnspecified.withArguments("No builder for '$libraryUri'."),
            -1,
            fileUri);
      }
      Declaration declaration;
      if (isSetter) {
        declaration = library.exportScope.setters[name];
        exportScopeBuilder.addSetter(name, declaration);
      } else {
        declaration = library.exportScope.local[name];
        exportScopeBuilder.addMember(name, declaration);
      }
      if (declaration == null) {
        internalProblem(
            templateUnspecified.withArguments(
                "Exported element '$name' not found in '$libraryUri'."),
            -1,
            fileUri);
      }
      assert(node == declaration.target);
    }
  }
}
