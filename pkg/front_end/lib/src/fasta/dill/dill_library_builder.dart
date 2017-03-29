// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_library_builder;

import 'package:kernel/ast.dart'
    show
        Class,
        ExpressionStatement,
        Field,
        FunctionNode,
        Let,
        Library,
        ListLiteral,
        Member,
        Procedure,
        StaticGet;

import '../errors.dart' show internalError;

import '../kernel/kernel_builder.dart'
    show Builder, KernelInvalidTypeBuilder, KernelTypeBuilder, LibraryBuilder;

import '../kernel/redirecting_factory_body.dart' show RedirectingFactoryBody;

import 'dill_class_builder.dart' show DillClassBuilder;

import 'dill_member_builder.dart' show DillMemberBuilder;

import 'dill_loader.dart' show DillLoader;

class DillLibraryBuilder extends LibraryBuilder<KernelTypeBuilder, Library> {
  final Uri uri;

  final Map<String, Builder> members = <String, Builder>{};

  // TODO(ahe): Some export information needs to be serialized.
  final Map<String, Builder> exports = <String, Builder>{};

  final DillLoader loader;

  Library library;

  DillLibraryBuilder(Uri uri, this.loader)
      : uri = uri,
        super(uri);

  get scope => internalError("Scope not supported");

  Uri get fileUri => uri;

  void addClass(Class cls) {
    DillClassBuilder classBulder = new DillClassBuilder(cls, this);
    addBuilder(cls.name, classBulder, cls.fileOffset);
    cls.procedures.forEach(classBulder.addMember);
    cls.constructors.forEach(classBulder.addMember);
    for (Field field in cls.fields) {
      if (field.name.name == "_redirecting#") {
        // This is a hack / work around for storing redirecting constructors in
        // dill files. See `buildFactoryConstructor` in
        // [package:kernel/analyzer/ast_from_analyzer.dart]
        // (../../../../kernel/lib/analyzer/ast_from_analyzer.dart).
        ListLiteral initializer = field.initializer;
        for (StaticGet get in initializer.expressions) {
          Procedure factory = get.target;
          FunctionNode function = factory.function;
          ExpressionStatement statement = function.body;
          Let let = statement.expression;
          StaticGet getTarget = let.variable.initializer;
          function.body = new RedirectingFactoryBody(getTarget.target)
            ..parent = function;
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
      // This is a hack / work around for storing exports in dill files. See
      // [compile_platform.dart](../compile_platform.dart).
    } else {
      addBuilder(name, new DillMemberBuilder(member, this), member.fileOffset);
    }
  }

  Builder addBuilder(String name, Builder builder, int charOffset) {
    if (name == null || name.isEmpty) return null;
    members[name] = builder;
    if (!name.startsWith("_")) {
      exports[name] = builder;
    }
    return builder;
  }

  bool addToExportScope(String name, Builder member) {
    return internalError("Not implemented yet.");
  }

  @override
  void addToScope(String name, Builder member, int charOffset, bool isImport) {
    internalError("Not implemented yet.");
  }

  @override
  Builder buildAmbiguousBuilder(
      String name, Builder builder, Builder other, int charOffset,
      {bool isExport: false, bool isImport: false}) {
    return new KernelInvalidTypeBuilder(name, charOffset, fileUri);
  }

  @override
  String get fullNameForErrors {
    return library.name ?? "<library '${library.fileUri}'>";
  }
}
