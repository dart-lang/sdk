// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_library_builder;

import 'dart:convert' show jsonDecode;

import 'package:kernel/ast.dart';

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/dynamic_type_declaration_builder.dart';
import '../builder/extension_builder.dart';
import '../builder/modifier_builder.dart';
import '../builder/never_type_declaration_builder.dart';
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

import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/redirecting_factory_body.dart'
    show
        RedirectingFactoryBody,
        getRedirectingFactories,
        isRedirectingFactoryField;

import '../problems.dart' show internalProblem, unhandled, unimplemented;

import '../scope.dart';

import 'dill_class_builder.dart' show DillClassBuilder;

import 'dill_extension_builder.dart';

import 'dill_member_builder.dart';

import 'dill_loader.dart' show DillLoader;

import 'dill_type_alias_builder.dart' show DillTypeAliasBuilder;

class LazyLibraryScope extends LazyScope {
  DillLibraryBuilder? libraryBuilder;

  LazyLibraryScope.top({bool isModifiable: false})
      : super(<String, Builder>{}, <String, MemberBuilder>{}, null, "top",
            isModifiable: isModifiable);

  @override
  void ensureScope() {
    if (libraryBuilder == null) throw new StateError("No library builder.");
    libraryBuilder!.ensureLoaded();
  }
}

class DillLibraryBuilder extends LibraryBuilderImpl {
  @override
  final Library library;

  @override
  DillLoader loader;

  /// Exports that can't be serialized.
  ///
  /// The elements of this map are documented in
  /// [../kernel/kernel_library_builder.dart].
  Map<String, String>? unserializableExports;

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
    LazyLibraryScope lazyScope = scope as LazyLibraryScope;
    lazyScope.libraryBuilder = this;
    LazyLibraryScope lazyExportScope = exportScope as LazyLibraryScope;
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

    Map<String, Map<Name, Procedure>> tearOffs = {};
    List<Procedure> nonTearOffs = [];
    for (Procedure procedure in library.procedures) {
      List<Object>? names = extractTypedefNameFromTearOff(procedure.name);
      if (names != null) {
        Map<Name, Procedure> map = tearOffs[names[0] as String] ??= {};
        map[names[1] as Name] = procedure;
      } else {
        nonTearOffs.add(procedure);
      }
    }
    nonTearOffs.forEach(addMember);
    library.procedures.forEach(addMember);
    for (Typedef typedef in library.typedefs) {
      addTypedef(typedef, tearOffs[typedef.name]);
    }
    library.fields.forEach(addMember);

    if (isReadyToFinalizeExports) {
      finalizeExports();
    } else {
      throw new StateError("Not ready to finalize exports.");
    }
  }

  @override
  bool get isUnsupported => library.isUnsupported;

  @override
  bool get isSynthetic => library.isSynthetic;

  @override
  bool get isNonNullableByDefault => library.isNonNullableByDefault;

  @override
  Uri get importUri => library.importUri;

  @override
  Uri get fileUri => library.fileUri;

  @override
  String? get name => library.name;

  @override
  LibraryBuilder get nameOriginBuilder => this;

  @override
  void addSyntheticDeclarationOfDynamic() {
    addBuilder("dynamic",
        new DynamicTypeDeclarationBuilder(const DynamicType(), this, -1), -1);
  }

  @override
  void addSyntheticDeclarationOfNever() {
    addBuilder(
        "Never",
        new NeverTypeDeclarationBuilder(
            const NeverType.nonNullable(), this, -1),
        -1);
  }

  @override
  void addSyntheticDeclarationOfNull() {
    // The name "Null" is declared by the class Null.
  }

  void addClass(Class cls) {
    DillClassBuilder classBuilder = new DillClassBuilder(cls, this);
    addBuilder(cls.name, classBuilder, cls.fileOffset);
    Map<String, Procedure> tearOffs = {};
    List<Procedure> nonTearOffs = [];
    for (Procedure procedure in cls.procedures) {
      String? name = extractConstructorNameFromTearOff(procedure.name);
      if (name != null) {
        tearOffs[name] = procedure;
      } else {
        nonTearOffs.add(procedure);
      }
    }
    for (Procedure procedure in nonTearOffs) {
      if (procedure.kind == ProcedureKind.Factory) {
        classBuilder.addFactory(procedure, tearOffs[procedure.name.text]);
      } else {
        classBuilder.addProcedure(procedure);
      }
    }
    for (Constructor constructor in cls.constructors) {
      classBuilder.addConstructor(constructor, tearOffs[constructor.name.text]);
    }
    for (Field field in cls.fields) {
      if (isRedirectingFactoryField(field)) {
        for (Procedure target in getRedirectingFactories(field)) {
          RedirectingFactoryBody.restoreFromDill(target);
        }
      } else {
        classBuilder.addField(field);
      }
    }
  }

  void addExtension(Extension extension) {
    DillExtensionBuilder extensionBuilder =
        new DillExtensionBuilder(extension, this);
    addBuilder(extension.name, extensionBuilder, extension.fileOffset);
  }

  void addMember(Member member) {
    if (member.isExtensionMember) {
      return null;
    }
    String name = member.name.text;
    if (name == "_exports#") {
      Field field = member as Field;
      String stringValue;
      if (field.initializer is ConstantExpression) {
        ConstantExpression constantExpression =
            field.initializer as ConstantExpression;
        StringConstant string = constantExpression.constant as StringConstant;
        stringValue = string.value;
      } else {
        StringLiteral string = field.initializer as StringLiteral;
        stringValue = string.value;
      }
      Map<dynamic, dynamic>? json = jsonDecode(stringValue);
      unserializableExports =
          json != null ? new Map<String, String>.from(json) : null;
    } else {
      if (member is Field) {
        addBuilder(name, new DillFieldBuilder(member, this), member.fileOffset);
      } else if (member is Procedure) {
        switch (member.kind) {
          case ProcedureKind.Setter:
            addBuilder(
                name, new DillSetterBuilder(member, this), member.fileOffset);
            break;
          case ProcedureKind.Getter:
            addBuilder(
                name, new DillGetterBuilder(member, this), member.fileOffset);
            break;
          case ProcedureKind.Operator:
            addBuilder(
                name, new DillOperatorBuilder(member, this), member.fileOffset);
            break;
          case ProcedureKind.Method:
            addBuilder(
                name, new DillMethodBuilder(member, this), member.fileOffset);
            break;
          case ProcedureKind.Factory:
            throw new UnsupportedError(
                "Unexpected library procedure ${member.kind} for ${member}");
        }
      } else {
        throw new UnsupportedError(
            "Unexpected library member ${member} (${member.runtimeType})");
      }
    }
  }

  @override
  Builder? addBuilder(String? name, Builder declaration, int charOffset) {
    if (name == null || name.isEmpty) return null;

    bool isSetter = declaration.isSetter;
    if (isSetter) {
      scopeBuilder.addSetter(name, declaration as MemberBuilder);
    } else {
      scopeBuilder.addMember(name, declaration);
    }
    if (declaration.isExtension) {
      scopeBuilder.addExtension(declaration as ExtensionBuilder);
    }
    if (!name.startsWith("_") && !name.contains('#')) {
      if (isSetter) {
        exportScopeBuilder.addSetter(name, declaration as MemberBuilder);
      } else {
        exportScopeBuilder.addMember(name, declaration);
      }
    }
    return declaration;
  }

  void addTypedef(Typedef typedef, Map<Name, Procedure>? tearOffs) {
    DartType? type = typedef.type;
    if (type is FunctionType && type.typedefType == null) {
      unhandled("null", "addTypedef", typedef.fileOffset, typedef.fileUri);
    }
    addBuilder(typedef.name, new DillTypeAliasBuilder(typedef, tearOffs, this),
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
          declaration = loader.coreLibrary.exportScopeBuilder[name]!;
          break;

        default:
          // ignore: unnecessary_null_comparison
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

    Map<Reference, Builder>? sourceBuildersMap =
        loader.currentSourceLoader?.buildersCreatedWithReferences;
    for (Reference reference in library.additionalExports) {
      NamedNode node = reference.node as NamedNode;
      Builder declaration;
      String name;
      if (sourceBuildersMap?.containsKey(reference) == true) {
        declaration = sourceBuildersMap![reference]!;
        // ignore: unnecessary_null_comparison
        assert(declaration != null);
        if (declaration is ModifierBuilder) {
          name = declaration.name!;
        } else {
          throw new StateError(
              "Unexpected: $declaration (${declaration.runtimeType}");
        }

        if (declaration.isSetter) {
          exportScopeBuilder.addSetter(name, declaration as MemberBuilder);
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
          name = node.name.text;
          isSetter = node.isSetter;
        } else if (node is Member) {
          libraryUri = node.enclosingLibrary.importUri;
          name = node.name.text;
        } else if (node is Typedef) {
          libraryUri = node.enclosingLibrary.importUri;
          name = node.name;
        } else if (node is Extension) {
          libraryUri = node.enclosingLibrary.importUri;
          name = node.name;
        } else {
          unhandled("${node.runtimeType}", "finalizeExports", -1, fileUri);
        }
        LibraryBuilder? library = loader.lookupLibraryBuilder(libraryUri);
        if (library == null) {
          internalProblem(
              templateUnspecified
                  .withArguments("No builder for '$libraryUri'."),
              -1,
              fileUri);
        }
        if (isSetter) {
          declaration =
              library.exportScope.lookupLocalMember(name, setter: true)!;
          exportScopeBuilder.addSetter(name, declaration as MemberBuilder);
        } else {
          declaration =
              library.exportScope.lookupLocalMember(name, setter: false)!;
          exportScopeBuilder.addMember(name, declaration);
        }
        // ignore: unnecessary_null_comparison
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
