// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_library_builder;

import 'dart:convert' show JSON;

import 'package:kernel/ast.dart'
    show
        Class,
        Field,
        Library,
        ListLiteral,
        Member,
        Procedure,
        StaticGet,
        StringLiteral,
        Typedef;

import '../fasta_codes.dart' show templateUnspecified;

import '../problems.dart' show unhandled, unimplemented;

import '../kernel/kernel_builder.dart'
    show
        Builder,
        InvalidTypeBuilder,
        KernelInvalidTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        Scope;

import '../kernel/redirecting_factory_body.dart' show RedirectingFactoryBody;

import 'dill_class_builder.dart' show DillClassBuilder;

import 'dill_member_builder.dart' show DillMemberBuilder;

import 'dill_loader.dart' show DillLoader;

import 'dill_typedef_builder.dart' show DillFunctionTypeAliasBuilder;

class DillLibraryBuilder extends LibraryBuilder<KernelTypeBuilder, Library> {
  final Uri uri;

  final DillLoader loader;

  Library library;

  /// Exports that can't be serialized.
  ///
  /// The elements of this map are documented in
  /// [../kernel/kernel_library_builder.dart].
  Map<String, String> unserializableExports;

  DillLibraryBuilder(this.uri, this.loader)
      : super(uri, new Scope.top(), new Scope.top());

  Uri get fileUri => uri;

  @override
  Library get target => library;

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
      unserializableExports = JSON.decode(string.value);
    } else {
      addBuilder(name, new DillMemberBuilder(member, this), member.fileOffset);
    }
  }

  Builder addBuilder(String name, Builder builder, int charOffset) {
    if (name == null || name.isEmpty) return null;
    bool isSetter = builder.isSetter;
    if (isSetter) {
      scopeBuilder.addSetter(name, builder);
    } else {
      scopeBuilder.addMember(name, builder);
    }
    if (!name.startsWith("_")) {
      if (isSetter) {
        exportScopeBuilder.addSetter(name, builder);
      } else {
        exportScopeBuilder.addMember(name, builder);
      }
    }
    return builder;
  }

  void addTypedef(Typedef typedef) {
    var typedefBuilder = new DillFunctionTypeAliasBuilder(typedef, this);
    addBuilder(typedef.name, typedefBuilder, typedef.fileOffset);
  }

  @override
  void addToScope(String name, Builder member, int charOffset, bool isImport) {
    unimplemented("addToScope", charOffset, fileUri);
  }

  @override
  Builder buildAmbiguousBuilder(
      String name, Builder builder, Builder other, int charOffset,
      {bool isExport: false, bool isImport: false}) {
    if (builder == other) return builder;
    if (builder is InvalidTypeBuilder) return builder;
    if (other is InvalidTypeBuilder) return other;
    // For each entry mapping key `k` to declaration `d` in `NS` an entry
    // mapping `k` to `d` is added to the exported namespace of `L` unless a
    // top-level declaration with the name `k` exists in `L`.
    if (builder.parent == this) return builder;
    return new KernelInvalidTypeBuilder(name, charOffset, fileUri);
  }

  @override
  String get fullNameForErrors {
    return library.name ?? "<library '${library.fileUri}'>";
  }

  void finalizeExports() {
    unserializableExports?.forEach((String name, String message) {
      Builder builder;
      switch (name) {
        case "dynamic":
        case "void":
          // TODO(ahe): It's likely that we shouldn't be exporting these types
          // from dart:core, and this case can be removed.
          builder = loader.coreLibrary.exportScopeBuilder[name];
          break;

        default:
          builder = new KernelInvalidTypeBuilder(
              name,
              -1,
              null,
              message == null
                  ? null
                  : templateUnspecified.withArguments(message));
      }
      exportScopeBuilder.addMember(name, builder);
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
      var library = loader.read(libraryUri, -1);
      Builder builder;
      if (isSetter) {
        builder = library.exportScope.setters[name];
        exportScopeBuilder.addSetter(name, builder);
      } else {
        builder = library.exportScope.local[name];
        exportScopeBuilder.addMember(name, builder);
      }
      assert(node == builder.target);
    }
  }
}
