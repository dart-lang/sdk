// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_library_builder;

import 'dart:convert' show jsonDecode;

import 'package:kernel/ast.dart'
    show
        Class,
        ConstantExpression,
        DartType,
        DynamicType,
        Extension,
        Field,
        FunctionType,
        Library,
        ListLiteral,
        Member,
        NamedNode,
        NeverType,
        Nullability,
        Procedure,
        Reference,
        StaticGet,
        StringConstant,
        StringLiteral,
        Typedef,
        Version;

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/dynamic_type_builder.dart';
import '../builder/extension_builder.dart';
import '../builder/modifier_builder.dart';
import '../builder/never_type_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/type_alias_builder.dart';

import '../fasta_codes.dart'
    show
        Message,
        noLength,
        templateDuplicatedDeclaration,
        templateTypeNotFound,
        templateUnspecified;

import '../kernel/redirecting_factory_body.dart'
    show RedirectingFactoryBody, isRedirectingFactoryField;

import '../problems.dart' show internalProblem, unhandled, unimplemented;

import '../scope.dart';

import 'dill_class_builder.dart' show DillClassBuilder;

import 'dill_extension_builder.dart';

import 'dill_member_builder.dart' show DillMemberBuilder;

import 'dill_loader.dart' show DillLoader;

import 'dill_type_alias_builder.dart' show DillTypeAliasBuilder;

class LazyLibraryScope extends LazyScope {
  DillLibraryBuilder libraryBuilder;

  LazyLibraryScope.top({bool isModifiable: false})
      : super(<String, Builder>{}, <String, MemberBuilder>{}, null, "top",
            isModifiable: isModifiable);

  @override
  void ensureScope() {
    if (libraryBuilder == null) throw new StateError("No library builder.");
    libraryBuilder.ensureLoaded();
  }
}

class DillLibraryBuilder extends LibraryBuilderImpl {
  @override
  final Library library;

  DillLoader loader;

  /// Exports that can't be serialized.
  ///
  /// The elements of this map are documented in
  /// [../kernel/kernel_library_builder.dart].
  Map<String, String> unserializableExports;

  // TODO(jensj): These 5 booleans could potentially be merged into a single
  // state field.
  bool isReadyToBuild = false;
  bool isReadyToFinalizeExports = false;
  bool suppressFinalizationErrors = false;
  bool isBuilt = false;
  bool isBuiltAndMarked = false;

  DillLibraryBuilder(this.library, this.loader)
      : super(library.fileUri, new LazyLibraryScope.top(),
            new LazyLibraryScope.top()) {
    LazyLibraryScope lazyScope = scope;
    lazyScope.libraryBuilder = this;
    LazyLibraryScope lazyExportScope = exportScope;
    lazyExportScope.libraryBuilder = this;
  }

  void ensureLoaded() {
    if (!isReadyToBuild) throw new StateError("Not ready to build.");
    if (isBuilt && !isBuiltAndMarked) {
      isBuiltAndMarked = true;
      finalizeExports();
      return;
    }
    isBuiltAndMarked = true;
    if (isBuilt) return;
    isBuilt = true;
    library.classes.forEach(addClass);
    library.extensions.forEach(addExtension);
    library.procedures.forEach(addMember);
    library.typedefs.forEach(addTypedef);
    library.fields.forEach(addMember);

    if (isReadyToFinalizeExports) {
      finalizeExports();
    } else {
      throw new StateError("Not ready to finalize exports.");
    }
  }

  @override
  bool get isSynthetic => library.isSynthetic;

  @override
  bool get isNonNullableByDefault => library.isNonNullableByDefault;

  @override
  void setLanguageVersion(Version version,
      {int offset: 0, int length, bool explicit}) {}

  @override
  Uri get importUri => library.importUri;

  @override
  Uri get fileUri => library.fileUri;

  @override
  String get name => library.name;

  void addSyntheticDeclarationOfDynamic() {
    addBuilder(
        "dynamic", new DynamicTypeBuilder(const DynamicType(), this, -1), -1);
  }

  void addSyntheticDeclarationOfNever() {
    addBuilder(
        "Never",
        new NeverTypeBuilder(
            const NeverType(Nullability.nonNullable), this, -1),
        -1);
  }

  void addClass(Class cls) {
    DillClassBuilder classBulder = new DillClassBuilder(cls, this);
    addBuilder(cls.name, classBulder, cls.fileOffset);
    cls.procedures.forEach(classBulder.addMember);
    cls.constructors.forEach(classBulder.addMember);
    for (Field field in cls.fields) {
      if (isRedirectingFactoryField(field)) {
        ListLiteral initializer = field.initializer;
        for (StaticGet get in initializer.expressions) {
          RedirectingFactoryBody.restoreFromDill(get.target);
        }
      } else {
        classBulder.addMember(field);
      }
    }
  }

  void addExtension(Extension extension) {
    DillExtensionBuilder extensionBuilder =
        new DillExtensionBuilder(extension, this);
    addBuilder(extension.name, extensionBuilder, extension.fileOffset);
  }

  void addMember(Member member) {
    String name = member.name.name;
    if (name == "_exports#") {
      Field field = member;
      String stringValue;
      if (field.initializer is ConstantExpression) {
        ConstantExpression constantExpression = field.initializer;
        StringConstant string = constantExpression.constant;
        stringValue = string.value;
      } else {
        StringLiteral string = field.initializer;
        stringValue = string.value;
      }
      Map<dynamic, dynamic> json = jsonDecode(stringValue);
      unserializableExports =
          json != null ? new Map<String, String>.from(json) : null;
    } else {
      addBuilder(name, new DillMemberBuilder(member, this), member.fileOffset);
    }
  }

  @override
  Builder addBuilder(String name, Builder declaration, int charOffset) {
    if (name == null || name.isEmpty) return null;
    bool isSetter = declaration.isSetter;
    if (isSetter) {
      scopeBuilder.addSetter(name, declaration);
    } else {
      scopeBuilder.addMember(name, declaration);
    }
    if (declaration.isExtension) {
      scopeBuilder.addExtension(declaration);
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
  void addToScope(String name, Builder member, int charOffset, bool isImport) {
    unimplemented("addToScope", charOffset, fileUri);
  }

  @override
  Builder computeAmbiguousDeclaration(
      String name, Builder builder, Builder other, int charOffset,
      {bool isExport: false, bool isImport: false}) {
    if (builder == other) return builder;
    if (builder is InvalidTypeDeclarationBuilder) return builder;
    if (other is InvalidTypeDeclarationBuilder) return other;
    // For each entry mapping key `k` to declaration `d` in `NS` an entry
    // mapping `k` to `d` is added to the exported namespace of `L` unless a
    // top-level declaration with the name `k` exists in `L`.
    if (builder.parent == this) return builder;
    Message message = templateDuplicatedDeclaration.withArguments(name);
    addProblem(message, charOffset, name.length, fileUri);
    return new InvalidTypeDeclarationBuilder(
        name, message.withLocation(fileUri, charOffset, name.length));
  }

  @override
  String get fullNameForErrors {
    return library.name ?? "<library '${library.fileUri}'>";
  }

  void markAsReadyToBuild() {
    isReadyToBuild = true;
  }

  void markAsReadyToFinalizeExports({bool suppressFinalizationErrors: false}) {
    isReadyToFinalizeExports = true;
    this.suppressFinalizationErrors = suppressFinalizationErrors;
  }

  void finalizeExports() {
    unserializableExports?.forEach((String name, String messageText) {
      Builder declaration;
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
          if (!suppressFinalizationErrors) {
            addProblem(message, -1, noLength, null);
          }
          declaration = new InvalidTypeDeclarationBuilder(
              name, message.withoutLocation());
      }
      exportScopeBuilder.addMember(name, declaration);
    });

    Map<Reference, Builder> sourceBuildersMap =
        loader.currentSourceLoader?.buildersCreatedWithReferences;
    for (Reference reference in library.additionalExports) {
      NamedNode node = reference.node;
      Builder declaration;
      String name;
      if (sourceBuildersMap?.containsKey(reference) == true) {
        declaration = sourceBuildersMap[reference];
        assert(declaration != null);
        if (declaration is ModifierBuilder) {
          name = declaration.name;
        } else {
          throw new StateError(
              "Unexpected: $declaration (${declaration.runtimeType}");
        }

        if (declaration.isSetter) {
          exportScopeBuilder.addSetter(name, declaration);
        } else {
          exportScopeBuilder.addMember(name, declaration);
        }
      } else {
        Uri libraryUri;
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
        } else if (node is Extension) {
          libraryUri = node.enclosingLibrary.importUri;
          name = node.name;
        } else {
          unhandled("${node.runtimeType}", "finalizeExports", -1, fileUri);
        }
        LibraryBuilder library = loader.builders[libraryUri];
        if (library == null) {
          internalProblem(
              templateUnspecified
                  .withArguments("No builder for '$libraryUri'."),
              -1,
              fileUri);
        }
        if (isSetter) {
          declaration =
              library.exportScope.lookupLocalMember(name, setter: true);
          exportScopeBuilder.addSetter(name, declaration);
        } else {
          declaration =
              library.exportScope.lookupLocalMember(name, setter: false);
          exportScopeBuilder.addMember(name, declaration);
        }
        if (declaration == null) {
          internalProblem(
              templateUnspecified.withArguments(
                  "Exported element '$name' not found in '$libraryUri'."),
              -1,
              fileUri);
        }
      }

      assert(
          (declaration is ClassBuilder && node == declaration.cls) ||
              (declaration is TypeAliasBuilder &&
                  node == declaration.typedef) ||
              (declaration is MemberBuilder && node == declaration.member) ||
              (declaration is ExtensionBuilder &&
                  node == declaration.extension),
          "Unexpected declaration ${declaration} (${declaration.runtimeType}) "
          "for node ${node} (${node.runtimeType}).");
    }
  }
}
