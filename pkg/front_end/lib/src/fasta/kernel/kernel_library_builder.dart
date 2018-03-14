// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_library_builder;

import 'dart:convert' show JSON;

import 'package:kernel/ast.dart';

import '../../scanner/token.dart' show Token;

import '../export.dart' show Export;

import '../fasta_codes.dart'
    show
        Message,
        messageConflictsWithTypeVariableCause,
        messageTypeVariableDuplicatedName,
        messageTypeVariableSameNameAsEnclosing,
        noLength,
        templateConflictsWithTypeVariable,
        templateDuplicatedExport,
        templateDuplicatedExportInType,
        templateDuplicatedImport,
        templateDuplicatedImportInType,
        templateExportHidesExport,
        templateImportHidesImport,
        templateLoadLibraryHidesMember,
        templateLocalDefinitionHidesExport,
        templateLocalDefinitionHidesImport,
        templatePatchInjectionFailed,
        templateTypeVariableDuplicatedNameCause;

import '../import.dart' show Import;

import '../loader.dart' show Loader;

import '../modifier.dart'
    show abstractMask, namedMixinApplicationMask, staticMask;

import '../problems.dart' show unhandled;

import '../source/source_class_builder.dart' show SourceClassBuilder;

import '../source/source_library_builder.dart'
    show DeclarationBuilder, SourceLibraryBuilder;

import 'kernel_builder.dart'
    show
        AccessErrorBuilder,
        Builder,
        BuiltinTypeBuilder,
        ClassBuilder,
        ConstructorReferenceBuilder,
        FormalParameterBuilder,
        InvalidTypeBuilder,
        KernelClassBuilder,
        KernelConstructorBuilder,
        KernelEnumBuilder,
        KernelFieldBuilder,
        KernelFormalParameterBuilder,
        KernelFunctionBuilder,
        KernelFunctionTypeAliasBuilder,
        KernelFunctionTypeBuilder,
        KernelInvalidTypeBuilder,
        KernelMixinApplicationBuilder,
        KernelNamedTypeBuilder,
        KernelProcedureBuilder,
        KernelRedirectingFactoryBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        LoadLibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        PrefixBuilder,
        ProcedureBuilder,
        QualifiedName,
        Scope,
        TypeBuilder,
        TypeVariableBuilder,
        UnresolvedType,
        VoidTypeBuilder,
        compareProcedures,
        toKernelCombinators;

import 'metadata_collector.dart';

import 'type_algorithms.dart' show calculateBounds;

class KernelLibraryBuilder
    extends SourceLibraryBuilder<KernelTypeBuilder, Library> {
  final Library library;

  final KernelLibraryBuilder actualOrigin;

  final List<KernelFunctionBuilder> nativeMethods = <KernelFunctionBuilder>[];

  final List<KernelTypeVariableBuilder> boundlessTypeVariables =
      <KernelTypeVariableBuilder>[];

  /// Exports that can't be serialized.
  ///
  /// The key is the name of the exported member.
  ///
  /// If the name is `dynamic` or `void`, this library reexports the
  /// corresponding type from `dart:core`, and the value is null.
  ///
  /// Otherwise, this represents an error (an ambiguous export). In this case,
  /// the error message is the corresponding value in the map.
  Map<String, String> unserializableExports;

  KernelLibraryBuilder(Uri uri, Uri fileUri, Loader loader, this.actualOrigin)
      : library = actualOrigin?.library ?? new Library(uri, fileUri: fileUri),
        super(loader, fileUri);

  @override
  KernelLibraryBuilder get origin => actualOrigin ?? this;

  @override
  Library get target => library;

  Uri get uri => library.importUri;

  KernelTypeBuilder addNamedType(
      Object name, List<KernelTypeBuilder> arguments, int charOffset) {
    return addType(new KernelNamedTypeBuilder(name, arguments), charOffset);
  }

  KernelTypeBuilder addMixinApplication(KernelTypeBuilder supertype,
      List<KernelTypeBuilder> mixins, int charOffset) {
    return addType(
        new KernelMixinApplicationBuilder(supertype, mixins), charOffset);
  }

  KernelTypeBuilder addVoidType(int charOffset) {
    return addNamedType("void", null, charOffset)
      ..bind(new VoidTypeBuilder(const VoidType(), this, charOffset));
  }

  void addClass(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      String className,
      List<TypeVariableBuilder> typeVariables,
      KernelTypeBuilder supertype,
      List<KernelTypeBuilder> interfaces,
      int charOffset,
      int charEndOffset,
      int supertypeOffset) {
    // Nested declaration began in `OutlineBuilder.beginClassDeclaration`.
    var declaration = endNestedDeclaration(className)
      ..resolveTypes(typeVariables, this);
    assert(declaration.parent == libraryDeclaration);
    Map<String, MemberBuilder> members = declaration.members;
    Map<String, MemberBuilder> constructors = declaration.constructors;
    Map<String, MemberBuilder> setters = declaration.setters;

    Scope classScope = new Scope(members, setters,
        scope.withTypeVariables(typeVariables), "class $className",
        isModifiable: false);

    // When looking up a constructor, we don't consider type variables or the
    // library scope.
    Scope constructorScope = new Scope(constructors, null, null, "constructors",
        isModifiable: false);
    ClassBuilder cls = new SourceClassBuilder(
        metadata,
        modifiers,
        className,
        typeVariables,
        applyMixins(supertype, supertypeOffset, className,
            typeVariables: typeVariables),
        interfaces,
        classScope,
        constructorScope,
        this,
        new List<ConstructorReferenceBuilder>.from(constructorReferences),
        charOffset,
        charEndOffset);
    loader.target.metadataCollector
        ?.setDocumentationComment(cls.target, documentationComment);

    constructorReferences.clear();
    Map<String, TypeVariableBuilder> typeVariablesByName =
        checkTypeVariables(typeVariables, cls);
    void setParent(String name, MemberBuilder member) {
      while (member != null) {
        member.parent = cls;
        member = member.next;
      }
    }

    void setParentAndCheckConflicts(String name, MemberBuilder member) {
      if (typeVariablesByName != null) {
        TypeVariableBuilder tv = typeVariablesByName[name];
        if (tv != null) {
          cls.addCompileTimeError(
              templateConflictsWithTypeVariable.withArguments(name),
              member.charOffset,
              name.length,
              context: messageConflictsWithTypeVariableCause.withLocation(
                  tv.fileUri, tv.charOffset, name.length));
        }
      }
      setParent(name, member);
    }

    members.forEach(setParentAndCheckConflicts);
    constructors.forEach(setParentAndCheckConflicts);
    // Formally, a setter has the name `id=`, so it can never conflict with a
    // type variable.
    setters.forEach(setParent);
    addBuilder(className, cls, charOffset);
  }

  Map<String, TypeVariableBuilder> checkTypeVariables(
      List<TypeVariableBuilder> typeVariables, Builder owner) {
    if (typeVariables?.isEmpty ?? true) return null;
    Map<String, TypeVariableBuilder> typeVariablesByName =
        <String, TypeVariableBuilder>{};
    for (TypeVariableBuilder tv in typeVariables) {
      TypeVariableBuilder existing = typeVariablesByName[tv.name];
      if (existing != null) {
        addCompileTimeError(messageTypeVariableDuplicatedName, tv.charOffset,
            tv.name.length, fileUri,
            context: templateTypeVariableDuplicatedNameCause
                .withArguments(tv.name)
                .withLocation(
                    fileUri, existing.charOffset, existing.name.length));
      } else {
        typeVariablesByName[tv.name] = tv;
        if (owner is ClassBuilder) {
          // Only classes and type variables can't have the same name. See
          // [#29555](https://github.com/dart-lang/sdk/issues/29555).
          if (tv.name == owner.name) {
            addCompileTimeError(messageTypeVariableSameNameAsEnclosing,
                tv.charOffset, tv.name.length, fileUri);
          }
        }
      }
    }
    return typeVariablesByName;
  }

  KernelTypeBuilder applyMixins(
      KernelTypeBuilder type, int charOffset, String subclassName,
      {String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      int modifiers,
      List<KernelTypeBuilder> interfaces}) {
    if (name == null) {
      // The following parameters should only be used when building a named
      // mixin application.
      if (documentationComment != null) {
        unhandled("documentationComment", "unnamed mixin application",
            charOffset, fileUri);
      } else if (metadata != null) {
        unhandled("metadata", "unnamed mixin application", charOffset, fileUri);
      } else if (interfaces != null) {
        unhandled(
            "interfaces", "unnamed mixin application", charOffset, fileUri);
      }
    }
    if (type is KernelMixinApplicationBuilder) {
      String extractName(name) {
        if (name is QualifiedName) {
          return name.suffix;
        } else {
          return name;
        }
      }

      // Documentation below assumes the given mixin application is in one of
      // these forms:
      //
      //     class C extends S with M1, M2, M3;
      //     class Named = S with M1, M2, M3;
      //
      // When we refer to the subclass, we mean `C` or `Named`.

      /// The current supertype.
      ///
      /// Starts out having the value `S` and on each iteration of the loop
      /// below, it will take on the value corresponding to:
      ///
      /// 1. `S with M1`.
      /// 2. `(S with M1) with M2`.
      /// 3. `((S with M1) with M2) with M3`.
      KernelTypeBuilder supertype = type.supertype;

      /// The variable part of the mixin application's synthetic name. It
      /// starts out as the name of the superclass, but is only used after it
      /// has been combined with the name of the current mixin. In the examples
      /// from above, it will take these values:
      ///
      /// 1. `S&M1`
      /// 2. `S&M1&M2`
      /// 3. `S&M1&M2&M3`.
      ///
      /// The full name of the mixin application is obtained by prepending the
      /// name of the subclass (`C` or `Named` in the above examples) to the
      /// running name. For the example `C`, that leads to these full names:
      ///
      /// 1. `_C&S&M1`
      /// 2. `_C&S&M1&M2`
      /// 3. `_C&S&M1&M2&M3`.
      ///
      /// For a named mixin application, the last name has been given by the
      /// programmer, so for the example `Named` we see these full names:
      ///
      /// 1. `_Named&S&M1`
      /// 2. `_Named&S&M1&M2`
      /// 3. `Named`.
      String runningName = extractName(supertype.name);

      /// True when we're building a named mixin application. Notice that for
      /// the `Named` example above, this is only true on the last
      /// iteration because only the full mixin application is named.
      bool isNamedMixinApplication;

      /// The names of the type variables of the subclass.
      Set<String> typeVariableNames;
      if (typeVariables != null) {
        typeVariableNames = new Set<String>();
        for (TypeVariableBuilder typeVariable in typeVariables) {
          typeVariableNames.add(typeVariable.name);
        }
      }

      /// The type variables used in [supertype] and the current mixin.
      Map<String, TypeVariableBuilder> usedTypeVariables;

      /// Helper function that updates [usedTypeVariables]. It needs to be
      /// called twice per iteration: once on supertype and once on the current
      /// mixin.
      void computeUsedTypeVariables(KernelNamedTypeBuilder type) {
        List<KernelTypeBuilder> typeArguments = type.arguments;
        if (typeArguments != null && typeVariables != null) {
          for (KernelTypeBuilder argument in typeArguments) {
            if (typeVariableNames.contains(argument.name)) {
              usedTypeVariables ??= <String, TypeVariableBuilder>{};
              KernelTypeVariableBuilder freshTypeVariable =
                  (usedTypeVariables[argument.name] ??=
                      addTypeVariable(argument.name, null, charOffset));
              // Notice that [argument] may have been created below as part of
              // [applicationTypeArguments] and have to be rebound now
              // (otherwise it would refer to a type variable in the subclass).
              argument.bind(freshTypeVariable);
            } else {
              if (argument is KernelNamedTypeBuilder) {
                computeUsedTypeVariables(argument);
              }
            }
          }
        }
      }

      /// Iterate over the mixins from left to right. At the end of each
      /// iteration, a new [supertype] is computed that is the mixin
      /// application of [supertype] with the current mixin.
      for (int i = 0; i < type.mixins.length; i++) {
        KernelTypeBuilder mixin = type.mixins[i];
        isNamedMixinApplication = name != null && mixin == type.mixins.last;
        usedTypeVariables = null;
        if (!isNamedMixinApplication) {
          if (supertype is KernelNamedTypeBuilder) {
            computeUsedTypeVariables(supertype);
          }
          if (mixin is KernelNamedTypeBuilder) {
            runningName += "&${extractName(mixin.name)}";
            computeUsedTypeVariables(mixin);
          }
        }
        String fullname =
            isNamedMixinApplication ? name : "_$subclassName&$runningName";
        List<TypeVariableBuilder> applicationTypeVariables;
        List<KernelTypeBuilder> applicationTypeArguments;
        if (isNamedMixinApplication) {
          // If this is a named mixin application, it must be given all the
          // declarated type variables.
          applicationTypeVariables = typeVariables;
        } else {
          // Otherwise, we pass the fresh type variables to the mixin
          // application in the same order as they're declared on the subclass.
          if (usedTypeVariables != null) {
            applicationTypeVariables = <TypeVariableBuilder>[];
            applicationTypeArguments = <KernelTypeBuilder>[];
            for (TypeVariableBuilder typeVariable in typeVariables) {
              TypeVariableBuilder freshTypeVariable =
                  usedTypeVariables[typeVariable.name];
              if (freshTypeVariable != null) {
                applicationTypeVariables.add(freshTypeVariable);
                applicationTypeArguments.add(
                    addNamedType(typeVariable.name, null, charOffset)..bind(
                        // This may be rebound in the next iteration when
                        // calling [computeUsedTypeVariables].
                        typeVariable));
              }
            }
          }
        }
        SourceClassBuilder application = new SourceClassBuilder(
            isNamedMixinApplication ? metadata : null,
            isNamedMixinApplication
                ? modifiers | namedMixinApplicationMask
                : abstractMask,
            fullname,
            applicationTypeVariables,
            supertype,
            isNamedMixinApplication ? interfaces : null,
            new Scope(<String, MemberBuilder>{}, <String, MemberBuilder>{},
                scope.withTypeVariables(typeVariables),
                "mixin $fullname ", isModifiable: false),
            new Scope(<String, MemberBuilder>{}, null, null, "constructors",
                isModifiable: false),
            this,
            <ConstructorReferenceBuilder>[],
            charOffset,
            TreeNode.noOffset,
            null,
            mixin);
        if (isNamedMixinApplication) {
          loader.target.metadataCollector?.setDocumentationComment(
              application.target, documentationComment);
        }
        // TODO(ahe, kmillikin): Should always be true?
        // pkg/analyzer/test/src/summary/resynthesize_kernel_test.dart can't
        // handle that :(
        application.cls.isSyntheticMixinImplementation =
            !isNamedMixinApplication;
        addBuilder(fullname, application, charOffset);
        supertype =
            addNamedType(fullname, applicationTypeArguments, charOffset);
      }
      return supertype;
    } else {
      return type;
    }
  }

  void addNamedMixinApplication(
      String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      int modifiers,
      KernelTypeBuilder mixinApplication,
      List<KernelTypeBuilder> interfaces,
      int charOffset) {
    // Nested declaration began in `OutlineBuilder.beginNamedMixinApplication`.
    endNestedDeclaration(name).resolveTypes(typeVariables, this);
    KernelNamedTypeBuilder supertype = applyMixins(
        mixinApplication, charOffset, name,
        documentationComment: documentationComment,
        metadata: metadata,
        name: name,
        typeVariables: typeVariables,
        modifiers: modifiers,
        interfaces: interfaces);
    checkTypeVariables(typeVariables, supertype.builder);
  }

  @override
  void addField(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder type,
      String name,
      int charOffset,
      Token initializerTokenForInference,
      bool hasInitializer) {
    var builder = new KernelFieldBuilder(metadata, type, name, modifiers, this,
        charOffset, initializerTokenForInference, hasInitializer);
    addBuilder(name, builder, charOffset);
    loader.target.metadataCollector
        ?.setDocumentationComment(builder.target, documentationComment);
  }

  void addConstructor(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder returnType,
      final Object name,
      String constructorName,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName) {
    MetadataCollector metadataCollector = loader.target.metadataCollector;
    ProcedureBuilder procedure = new KernelConstructorBuilder(
        metadata,
        modifiers & ~abstractMask,
        returnType,
        constructorName,
        typeVariables,
        formals,
        this,
        charOffset,
        charOpenParenOffset,
        charEndOffset,
        nativeMethodName);
    metadataCollector?.setDocumentationComment(
        procedure.target, documentationComment);
    metadataCollector?.setConstructorNameOffset(procedure.target, name);
    checkTypeVariables(typeVariables, procedure);
    addBuilder(constructorName, procedure, charOffset);
    if (nativeMethodName != null) {
      addNativeMethod(procedure);
    }
  }

  void addProcedure(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      ProcedureKind kind,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName,
      {bool isTopLevel}) {
    MetadataCollector metadataCollector = loader.target.metadataCollector;
    ProcedureBuilder procedure = new KernelProcedureBuilder(
        metadata,
        modifiers,
        returnType,
        name,
        typeVariables,
        formals,
        kind,
        this,
        charOffset,
        charOpenParenOffset,
        charEndOffset,
        nativeMethodName);
    metadataCollector?.setDocumentationComment(
        procedure.target, documentationComment);
    checkTypeVariables(typeVariables, procedure);
    addBuilder(name, procedure, charOffset);
    if (nativeMethodName != null) {
      addNativeMethod(procedure);
    }
  }

  void addFactoryMethod(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      ConstructorReferenceBuilder constructorNameReference,
      List<FormalParameterBuilder> formals,
      ConstructorReferenceBuilder redirectionTarget,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName) {
    KernelTypeBuilder returnType = addNamedType(
        currentDeclaration.parent.name, <KernelTypeBuilder>[], charOffset);
    // Nested declaration began in `OutlineBuilder.beginFactoryMethod`.
    DeclarationBuilder<KernelTypeBuilder> factoryDeclaration =
        endNestedDeclaration("#factory_method");
    Object name = constructorNameReference.name;

    // Prepare the simple procedure name.
    String procedureName;
    String constructorName =
        computeAndValidateConstructorName(name, charOffset);
    if (constructorName != null) {
      procedureName = constructorName;
    } else {
      procedureName = name;
    }

    assert(constructorNameReference.suffix == null);
    KernelProcedureBuilder procedure;
    if (redirectionTarget != null) {
      procedure = new KernelRedirectingFactoryBuilder(
          metadata,
          staticMask | modifiers,
          returnType,
          procedureName,
          copyTypeVariables(
              currentDeclaration.typeVariables ?? <TypeVariableBuilder>[],
              factoryDeclaration),
          formals,
          this,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          nativeMethodName,
          redirectionTarget);
    } else {
      procedure = new KernelProcedureBuilder(
          metadata,
          staticMask | modifiers,
          returnType,
          procedureName,
          copyTypeVariables(
              currentDeclaration.typeVariables ?? <TypeVariableBuilder>[],
              factoryDeclaration),
          formals,
          ProcedureKind.Factory,
          this,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          nativeMethodName);
    }

    var metadataCollector = loader.target.metadataCollector;
    metadataCollector?.setDocumentationComment(
        procedure.target, documentationComment);
    metadataCollector?.setConstructorNameOffset(procedure.target, name);

    DeclarationBuilder<TypeBuilder> savedDeclaration = currentDeclaration;
    currentDeclaration = factoryDeclaration;
    for (TypeVariableBuilder tv in procedure.typeVariables) {
      KernelNamedTypeBuilder t = procedure.returnType;
      t.arguments.add(addNamedType(tv.name, null, procedure.charOffset));
    }
    currentDeclaration = savedDeclaration;

    factoryDeclaration.resolveTypes(procedure.typeVariables, this);
    addBuilder(procedureName, procedure, charOffset);
    if (nativeMethodName != null) {
      addNativeMethod(procedure);
    }
  }

  void addEnum(
      String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<Object> constantNamesAndOffsets,
      int charOffset,
      int charEndOffset) {
    MetadataCollector metadataCollector = loader.target.metadataCollector;
    KernelEnumBuilder builder = new KernelEnumBuilder(
        metadataCollector,
        metadata,
        name,
        constantNamesAndOffsets,
        this,
        charOffset,
        charEndOffset);
    addBuilder(name, builder, charOffset);
    metadataCollector?.setDocumentationComment(
        builder.target, documentationComment);
  }

  void addFunctionTypeAlias(
      String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      covariant KernelFunctionTypeBuilder type,
      int charOffset) {
    KernelFunctionTypeAliasBuilder typedef = new KernelFunctionTypeAliasBuilder(
        metadata, name, typeVariables, type, this, charOffset);
    loader.target.metadataCollector
        ?.setDocumentationComment(typedef.target, documentationComment);
    checkTypeVariables(typeVariables, typedef);
    // Nested declaration began in `OutlineBuilder.beginFunctionTypeAlias`.
    endNestedDeclaration("#typedef").resolveTypes(typeVariables, this);
    addBuilder(name, typedef, charOffset);
  }

  KernelFunctionTypeBuilder addFunctionType(
      KernelTypeBuilder returnType,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      int charOffset) {
    var builder =
        new KernelFunctionTypeBuilder(returnType, typeVariables, formals);
    checkTypeVariables(typeVariables, null);
    // Nested declaration began in `OutlineBuilder.beginFunctionType` or
    // `OutlineBuilder.beginFunctionTypedFormalParameter`.
    endNestedDeclaration("#function_type").resolveTypes(typeVariables, this);
    return addType(builder, charOffset);
  }

  KernelFormalParameterBuilder addFormalParameter(
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder type,
      String name,
      bool hasThis,
      int charOffset) {
    return new KernelFormalParameterBuilder(
        metadata, modifiers, type, name, hasThis, this, charOffset);
  }

  KernelTypeVariableBuilder addTypeVariable(
      String name, KernelTypeBuilder bound, int charOffset) {
    var builder = new KernelTypeVariableBuilder(name, this, charOffset, bound);
    boundlessTypeVariables.add(builder);
    return builder;
  }

  @override
  void buildBuilder(Builder builder, LibraryBuilder coreLibrary) {
    Class cls;
    Member member;
    Typedef typedef;
    if (builder is SourceClassBuilder) {
      cls = builder.build(this, coreLibrary);
    } else if (builder is KernelFieldBuilder) {
      member = builder.build(this)..isStatic = true;
    } else if (builder is KernelProcedureBuilder) {
      member = builder.build(this)..isStatic = true;
    } else if (builder is KernelFunctionTypeAliasBuilder) {
      typedef = builder.build(this);
    } else if (builder is KernelEnumBuilder) {
      cls = builder.build(this, coreLibrary);
    } else if (builder is PrefixBuilder) {
      // Ignored. Kernel doesn't represent prefixes.
      return;
    } else if (builder is BuiltinTypeBuilder) {
      // Nothing needed.
      return;
    } else {
      unhandled("${builder.runtimeType}", "buildBuilder", builder.charOffset,
          builder.fileUri);
      return;
    }
    if (builder.isPatch) {
      // The kernel node of a patch is shared with the origin builder. We have
      // two builders: the origin, and the patch, but only one kernel node
      // (which corresponds to the final output). Consequently, the node
      // shouldn't be added to its apparent kernel parent as this would create
      // a duplicate entry in the parent's list of children/members.
      return;
    }
    if (cls != null) {
      library.addClass(cls);
    } else if (member != null) {
      library.addMember(member);
    } else if (typedef != null) {
      library.addTypedef(typedef);
    }
  }

  void addNativeDependency(Uri nativeImportUri) {
    Builder constructor = loader.getNativeAnnotation();
    Arguments arguments =
        new Arguments(<Expression>[new StringLiteral("$nativeImportUri")]);
    Expression annotation;
    if (constructor.isConstructor) {
      annotation = new ConstructorInvocation(constructor.target, arguments)
        ..isConst = true;
    } else {
      annotation = new StaticInvocation(constructor.target, arguments)
        ..isConst = true;
    }
    library.addAnnotation(annotation);
  }

  void addDependencies(Library library, Set<KernelLibraryBuilder> seen) {
    if (!seen.add(this)) {
      return;
    }

    // Merge import and export lists to have the dependencies in source order.
    // This is required for the DietListener to correctly match up metadata.
    int importIndex = 0;
    int exportIndex = 0;
    while (importIndex < imports.length || exportIndex < exports.length) {
      if (exportIndex >= exports.length ||
          (importIndex < imports.length &&
              imports[importIndex].charOffset <
                  exports[exportIndex].charOffset)) {
        // Add import
        Import import = imports[importIndex++];

        // Rather than add a LibraryDependency, we attach an annotation.
        if (import.nativeImportUri != null) {
          addNativeDependency(import.nativeImportUri);
          continue;
        }

        if (import.deferred && import.prefixBuilder?.dependency != null) {
          library.addDependency(import.prefixBuilder.dependency);
        } else {
          library.addDependency(new LibraryDependency.import(
              import.imported.target,
              name: import.prefix,
              combinators: toKernelCombinators(import.combinators))
            ..fileOffset = import.charOffset);
        }
      } else {
        // Add export
        Export export = exports[exportIndex++];
        library.addDependency(new LibraryDependency.export(
            export.exported.target,
            combinators: toKernelCombinators(export.combinators))
          ..fileOffset = export.charOffset);
      }
    }

    for (KernelLibraryBuilder part in parts) {
      library.addPart(new LibraryPart(<Expression>[], part.fileUri));
      part.addDependencies(library, seen);
    }
  }

  @override
  Library build(LibraryBuilder coreLibrary) {
    super.build(coreLibrary);

    addDependencies(library, new Set<KernelLibraryBuilder>());

    loader.target.metadataCollector
        ?.setDocumentationComment(library, documentationComment);
    library.name = name;
    library.procedures.sort(compareProcedures);

    if (unserializableExports != null) {
      library.addMember(new Field(new Name("_exports#", library),
          initializer: new StringLiteral(JSON.encode(unserializableExports)),
          isStatic: true,
          isConst: true));
    }

    return library;
  }

  @override
  Builder buildAmbiguousBuilder(
      String name, Builder builder, Builder other, int charOffset,
      {bool isExport: false, bool isImport: false}) {
    // TODO(ahe): Can I move this to Scope or Prefix?
    if (builder == other) return builder;
    if (builder is InvalidTypeBuilder) return builder;
    if (other is InvalidTypeBuilder) return other;
    if (builder is AccessErrorBuilder) {
      AccessErrorBuilder error = builder;
      builder = error.builder;
    }
    if (other is AccessErrorBuilder) {
      AccessErrorBuilder error = other;
      other = error.builder;
    }
    bool isLocal = false;
    bool isLoadLibrary = false;
    Builder preferred;
    Uri uri;
    Uri otherUri;
    Uri preferredUri;
    Uri hiddenUri;
    if (scope.local[name] == builder) {
      isLocal = true;
      preferred = builder;
      hiddenUri = other.computeLibraryUri();
    } else {
      uri = builder.computeLibraryUri();
      otherUri = other.computeLibraryUri();
      if (builder is LoadLibraryBuilder) {
        isLoadLibrary = true;
        preferred = builder;
        preferredUri = otherUri;
      } else if (other is LoadLibraryBuilder) {
        isLoadLibrary = true;
        preferred = other;
        preferredUri = uri;
      } else if (otherUri?.scheme == "dart" && uri?.scheme != "dart") {
        preferred = builder;
        preferredUri = uri;
        hiddenUri = otherUri;
      } else if (uri?.scheme == "dart" && otherUri?.scheme != "dart") {
        preferred = other;
        preferredUri = otherUri;
        hiddenUri = uri;
      }
    }
    if (preferred != null) {
      if (isLocal) {
        var template = isExport
            ? templateLocalDefinitionHidesExport
            : templateLocalDefinitionHidesImport;
        addProblem(template.withArguments(name, hiddenUri), charOffset,
            noLength, fileUri);
      } else if (isLoadLibrary) {
        addProblem(templateLoadLibraryHidesMember.withArguments(preferredUri),
            charOffset, noLength, fileUri);
      } else {
        var template =
            isExport ? templateExportHidesExport : templateImportHidesImport;
        addProblem(template.withArguments(name, preferredUri, hiddenUri),
            charOffset, noLength, fileUri);
      }
      return preferred;
    }
    if (builder.next == null && other.next == null) {
      if (isImport && builder is PrefixBuilder && other is PrefixBuilder) {
        // Handles the case where the same prefix is used for different
        // imports.
        return builder
          ..exportScope.merge(other.exportScope,
              (String name, Builder existing, Builder member) {
            return buildAmbiguousBuilder(name, existing, member, charOffset,
                isExport: isExport, isImport: isImport);
          });
      }
    }
    var template =
        isExport ? templateDuplicatedExport : templateDuplicatedImport;
    Message message = template.withArguments(name, uri, otherUri);
    addProblem(message, charOffset, noLength, fileUri);
    var builderTemplate = isExport
        ? templateDuplicatedExportInType
        : templateDuplicatedImportInType;
    return new KernelInvalidTypeBuilder(name, charOffset, fileUri,
        builderTemplate.withArguments(name, uri, otherUri));
  }

  int finishDeferredLoadTearoffs() {
    int total = 0;
    for (var import in imports) {
      if (import.deferred) {
        Procedure tearoff = import.prefixBuilder.loadLibraryBuilder.tearoff;
        if (tearoff != null) library.addMember(tearoff);
        total++;
      }
    }
    return total;
  }

  void addNativeMethod(KernelFunctionBuilder method) {
    nativeMethods.add(method);
  }

  int finishNativeMethods() {
    for (KernelFunctionBuilder method in nativeMethods) {
      method.becomeNative(loader);
    }
    return nativeMethods.length;
  }

  List<TypeVariableBuilder> copyTypeVariables(
      List<TypeVariableBuilder> original, DeclarationBuilder declaration) {
    List<TypeBuilder> newTypes = <TypeBuilder>[];
    List<TypeVariableBuilder> copy = <TypeVariableBuilder>[];
    for (KernelTypeVariableBuilder variable in original) {
      var newVariable = new KernelTypeVariableBuilder(variable.name, this,
          variable.charOffset, variable.bound?.clone(newTypes));
      copy.add(newVariable);
      boundlessTypeVariables.add(newVariable);
    }
    for (TypeBuilder newType in newTypes) {
      declaration.addType(new UnresolvedType(newType, -1, null));
    }
    return copy;
  }

  int finishTypeVariables(ClassBuilder object) {
    int count = boundlessTypeVariables.length;
    for (KernelTypeVariableBuilder builder in boundlessTypeVariables) {
      builder.finish(this, object);
    }
    boundlessTypeVariables.clear();
    return count;
  }

  int instantiateToBound(TypeBuilder dynamicType, TypeBuilder bottomType,
      ClassBuilder objectClass) {
    int count = 0;

    for (var declarationBuilder in libraryDeclaration.members.values) {
      if (declarationBuilder is KernelClassBuilder) {
        if (declarationBuilder.typeVariables != null) {
          declarationBuilder.calculatedBounds = calculateBounds(
              declarationBuilder.typeVariables,
              dynamicType,
              bottomType,
              objectClass);
          count += declarationBuilder.calculatedBounds.length;
        }
      } else if (declarationBuilder is KernelFunctionTypeAliasBuilder) {
        if (declarationBuilder.typeVariables != null) {
          declarationBuilder.calculatedBounds = calculateBounds(
              declarationBuilder.typeVariables,
              dynamicType,
              bottomType,
              objectClass);
          count += declarationBuilder.calculatedBounds.length;
        }
      }
    }

    return count;
  }

  @override
  void includePart(covariant KernelLibraryBuilder part) {
    super.includePart(part);
    nativeMethods.addAll(part.nativeMethods);
    boundlessTypeVariables.addAll(part.boundlessTypeVariables);
  }

  @override
  void addImportsToScope() {
    super.addImportsToScope();
    exportScope.forEach((String name, Builder member) {
      if (member.parent != this) {
        switch (name) {
          case "dynamic":
          case "void":
            unserializableExports ??= <String, String>{};
            unserializableExports[name] = null;
            break;

          default:
            if (member is InvalidTypeBuilder) {
              unserializableExports ??= <String, String>{};
              unserializableExports[name] = member.message.message;
            } else {
              library.additionalExports.add(member.target.reference);
            }
        }
      }
    });
  }

  @override
  void applyPatches() {
    if (!isPatch) return;
    origin.forEach((String name, Builder member) {
      bool isSetter = member.isSetter;
      Builder patch = isSetter ? scope.setters[name] : scope.local[name];
      if (patch != null) {
        // [patch] has the same name as a [member] in [origin] library, so it
        // must be a patch to [member].
        member.applyPatch(patch);
        // TODO(ahe): Verify that patch has the @patch annotation.
      } else {
        // No member with [name] exists in this library already. So we need to
        // import it into the patch library. This ensures that the origin
        // library is in scope of the patch library.
        if (isSetter) {
          scopeBuilder.addSetter(name, member);
        } else {
          scopeBuilder.addMember(name, member);
        }
      }
    });
    forEach((String name, Builder member) {
      // We need to inject all non-patch members into the origin library. This
      // should only apply to private members.
      if (member.isPatch) {
        // Ignore patches.
      } else if (name.startsWith("_")) {
        origin.injectMemberFromPatch(name, member);
      } else {
        origin.exportMemberFromPatch(name, member);
      }
    });
  }

  int finishPatchMethods() {
    if (!isPatch) return 0;
    int count = 0;
    forEach((String name, Builder member) {
      count += member.finishPatch();
    });
    return count;
  }

  void injectMemberFromPatch(String name, Builder member) {
    if (member.isSetter) {
      assert(scope.setters[name] == null);
      scopeBuilder.addSetter(name, member);
    } else {
      assert(scope.local[name] == null);
      scopeBuilder.addMember(name, member);
    }
  }

  void exportMemberFromPatch(String name, Builder member) {
    if (uri.scheme != "dart" || !uri.path.startsWith("_")) {
      addCompileTimeError(templatePatchInjectionFailed.withArguments(name, uri),
          member.charOffset, noLength, member.fileUri);
    }
    // Platform-private libraries, such as "dart:_internal" have special
    // semantics: public members are injected into the origin library.
    // TODO(ahe): See if we can remove this special case.

    // If this member already exist in the origin library scope, it should
    // have been marked as patch.
    assert((member.isSetter && scope.setters[name] == null) ||
        (!member.isSetter && scope.local[name] == null));
    addToExportScope(name, member);
  }
}
