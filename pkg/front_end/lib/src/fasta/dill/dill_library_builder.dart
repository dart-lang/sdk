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
        StaticGet,
        StringLiteral,
        Typedef;

import '../fasta_codes.dart' show templateUnspecified;

import '../problems.dart' show unimplemented;

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

  /// Exports in addition to the members declared in this library.
  ///
  /// Each entry in the list is either two or three elements long.
  ///
  /// The first element is the library URI, if it is null, this is an ambiguous
  /// export and the list has three elements. Otherwise the list has two
  /// elements.
  ///
  /// The second element is the name of the exported element.
  ///
  /// The third element (if present) is an error message.
  List<List<String>> additionalExports;

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
        initializer.expressions.clear();
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
      additionalExports = JSON.decode(string.value);
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
    if (additionalExports != null) {
      for (List<String> additionalExport in additionalExports) {
        Uri originUri = Uri.parse(additionalExport[0]);
        String name = additionalExport[1];
        Builder builder;
        if (originUri == null) {
          builder = new KernelInvalidTypeBuilder(name, -1, null,
              templateUnspecified.withArguments(additionalExport[2]));
        } else {
          DillLibraryBuilder library = loader.read(originUri, -1);
          builder = library.exportScopeBuilder[name];
          if (library != null) {
            builder = library.exportScopeBuilder[name];
          }
          if (builder == null) {
            builder = new KernelInvalidTypeBuilder(name, -1, null);
          }
        }
        exportScopeBuilder.addMember(name, builder);
      }
    }
  }
}
