// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_library_builder;

import 'dart:convert' show jsonEncode;

import 'package:kernel/ast.dart'
    show
        Arguments,
        Class,
        Constructor,
        ConstructorInvocation,
        DartType,
        DynamicType,
        Expression,
        Field,
        FunctionNode,
        FunctionType,
        InterfaceType,
        Library,
        LibraryDependency,
        LibraryPart,
        ListLiteral,
        MapLiteral,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        SetLiteral,
        StaticInvocation,
        StringLiteral,
        Supertype,
        Typedef,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration,
        VoidType;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/clone.dart' show CloneVisitor;

import 'package:kernel/src/bounds_checks.dart'
    show
        TypeArgumentIssue,
        findTypeArgumentIssues,
        findTypeArgumentIssuesForInvocation,
        getGenericTypeName;

import 'package:kernel/type_algebra.dart' show substitute;

import 'package:kernel/type_environment.dart' show TypeEnvironment;

import '../../scanner/token.dart' show Token;

import '../export.dart' show Export;

import '../fasta_codes.dart'
    show
        FormattedMessage,
        LocatedMessage,
        Message,
        messageConflictsWithTypeVariableCause,
        messageGenericFunctionTypeInBound,
        messageGenericFunctionTypeUsedAsActualTypeArgument,
        messageIncorrectTypeArgumentVariable,
        messageTypeVariableDuplicatedName,
        messageTypeVariableSameNameAsEnclosing,
        noLength,
        templateConflictsWithTypeVariable,
        templateDuplicatedExport,
        templateDuplicatedExportInType,
        templateDuplicatedImport,
        templateDuplicatedImportInType,
        templateExportHidesExport,
        templateGenericFunctionTypeInferredAsActualTypeArgument,
        templateImportHidesImport,
        templateIncorrectTypeArgument,
        templateIncorrectTypeArgumentInReturnType,
        templateIncorrectTypeArgumentInferred,
        templateIncorrectTypeArgumentQualified,
        templateIncorrectTypeArgumentQualifiedInferred,
        templateIntersectionTypeAsTypeArgument,
        templateLoadLibraryHidesMember,
        templateLocalDefinitionHidesExport,
        templateLocalDefinitionHidesImport,
        templatePatchInjectionFailed,
        templateTypeVariableDuplicatedNameCause;

import '../import.dart' show Import;

import '../loader.dart' show Loader;

import '../modifier.dart'
    show
        abstractMask,
        hasConstConstructorMask,
        hasInitializerMask,
        initializingFormalMask,
        mixinDeclarationMask,
        namedMixinApplicationMask,
        staticMask;

import '../problems.dart' show unexpected, unhandled;

import '../severity.dart' show Severity;

import '../source/source_class_builder.dart' show SourceClassBuilder;

import '../source/source_library_builder.dart'
    show DeclarationBuilder, SourceLibraryBuilder;

import '../type_inference/type_inferrer.dart' show TypeInferrerImpl;

import 'kernel_builder.dart'
    show
        AccessErrorBuilder,
        BuiltinTypeBuilder,
        ClassBuilder,
        ConstructorReferenceBuilder,
        Declaration,
        DynamicTypeBuilder,
        EnumConstantInfo,
        FormalParameterBuilder,
        ImplicitFieldType,
        InvalidTypeBuilder,
        KernelClassBuilder,
        KernelConstructorBuilder,
        KernelEnumBuilder,
        KernelFieldBuilder,
        KernelFormalParameterBuilder,
        KernelFunctionBuilder,
        KernelTypeAliasBuilder,
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
        NameIterator,
        PrefixBuilder,
        ProcedureBuilder,
        QualifiedName,
        Scope,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder,
        UnresolvedType,
        VoidTypeBuilder,
        compareProcedures,
        toKernelCombinators;

import 'metadata_collector.dart';

import 'type_algorithms.dart'
    show
        calculateBounds,
        findGenericFunctionTypes,
        getNonSimplicityIssuesForDeclaration,
        getNonSimplicityIssuesForTypeVariables;

class KernelLibraryBuilder
    extends SourceLibraryBuilder<KernelTypeBuilder, Library> {
  final Library library;

  final KernelLibraryBuilder actualOrigin;

  final List<KernelFunctionBuilder> nativeMethods = <KernelFunctionBuilder>[];

  final List<KernelTypeVariableBuilder> boundlessTypeVariables =
      <KernelTypeVariableBuilder>[];

  // A list of alternating forwarders and the procedures they were generated
  // for.  Note that it may not include a forwarder-origin pair in cases when
  // the former does not need to be updated after the body of the latter was
  // built.
  final List<Procedure> forwardersOrigins = <Procedure>[];

  // List of types inferred in the outline.  Errors in these should be reported
  // differently than for specified types.
  // TODO(dmitryas):  Find a way to mark inferred types.
  final Set<DartType> inferredTypes = new Set<DartType>.identity();

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

  List<KernelFormalParameterBuilder> untypedInitializingFormals;

  KernelLibraryBuilder(Uri uri, Uri fileUri, Loader loader, this.actualOrigin,
      [Scope scope, Library target])
      : library = target ??
            (actualOrigin?.library ?? new Library(uri, fileUri: fileUri)),
        super(loader, fileUri, scope);

  @override
  KernelLibraryBuilder get origin => actualOrigin ?? this;

  @override
  Library get target => library;

  Uri get uri => library.importUri;

  void addSyntheticDeclarationOfDynamic() {
    addBuilder(
        "dynamic",
        new DynamicTypeBuilder<KernelTypeBuilder, DartType>(
            const DynamicType(), this, -1),
        -1);
  }

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
      ..bind(new VoidTypeBuilder<KernelTypeBuilder, VoidType>(
          const VoidType(), this, charOffset));
  }

  @override
  FormattedMessage addProblem(
      Message message, int charOffset, int length, Uri fileUri,
      {bool wasHandled: false,
      List<LocatedMessage> context,
      Severity severity,
      bool problemOnLibrary: false}) {
    FormattedMessage formattedMessage = super.addProblem(
        message, charOffset, length, fileUri,
        wasHandled: wasHandled,
        context: context,
        severity: severity,
        problemOnLibrary: true);
    if (formattedMessage != null) {
      target.problemsAsJson ??= <String>[];
      target.problemsAsJson.add(formattedMessage.toJsonString());
    }
    return formattedMessage;
  }

  void addClass(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      String className,
      List<TypeVariableBuilder> typeVariables,
      KernelTypeBuilder supertype,
      List<KernelTypeBuilder> interfaces,
      int startCharOffset,
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
    Scope constructorScope =
        new Scope(constructors, null, null, className, isModifiable: false);
    bool isMixinDeclaration = false;
    if (modifiers & mixinDeclarationMask != 0) {
      isMixinDeclaration = true;
      modifiers = (modifiers & ~mixinDeclarationMask) | abstractMask;
    }
    if (declaration.hasConstConstructor) {
      modifiers |= hasConstConstructorMask;
    }
    ClassBuilder cls = new SourceClassBuilder(
        metadata,
        modifiers,
        className,
        typeVariables,
        applyMixins(supertype, startCharOffset, charOffset, charEndOffset,
            className, isMixinDeclaration,
            typeVariables: typeVariables),
        interfaces,
        classScope,
        constructorScope,
        this,
        new List<ConstructorReferenceBuilder>.from(constructorReferences),
        startCharOffset,
        charOffset,
        charEndOffset,
        isMixinDeclaration: isMixinDeclaration);
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
          cls.addProblem(templateConflictsWithTypeVariable.withArguments(name),
              member.charOffset, name.length,
              context: [
                messageConflictsWithTypeVariableCause.withLocation(
                    tv.fileUri, tv.charOffset, name.length)
              ]);
        }
      }
      setParent(name, member);
    }

    members.forEach(setParentAndCheckConflicts);
    constructors.forEach(setParentAndCheckConflicts);
    setters.forEach(setParentAndCheckConflicts);
    addBuilder(className, cls, charOffset);
  }

  Map<String, TypeVariableBuilder> checkTypeVariables(
      List<TypeVariableBuilder> typeVariables, Declaration owner) {
    if (typeVariables?.isEmpty ?? true) return null;
    Map<String, TypeVariableBuilder> typeVariablesByName =
        <String, TypeVariableBuilder>{};
    for (TypeVariableBuilder tv in typeVariables) {
      TypeVariableBuilder existing = typeVariablesByName[tv.name];
      if (existing != null) {
        addProblem(messageTypeVariableDuplicatedName, tv.charOffset,
            tv.name.length, fileUri,
            context: [
              templateTypeVariableDuplicatedNameCause
                  .withArguments(tv.name)
                  .withLocation(
                      fileUri, existing.charOffset, existing.name.length)
            ]);
      } else {
        typeVariablesByName[tv.name] = tv;
        if (owner is ClassBuilder) {
          // Only classes and type variables can't have the same name. See
          // [#29555](https://github.com/dart-lang/sdk/issues/29555).
          if (tv.name == owner.name) {
            addProblem(messageTypeVariableSameNameAsEnclosing, tv.charOffset,
                tv.name.length, fileUri);
          }
        }
      }
    }
    return typeVariablesByName;
  }

  KernelTypeBuilder applyMixins(
      KernelTypeBuilder type,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      String subclassName,
      bool isMixinDeclaration,
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
      KernelTypeBuilder supertype = type.supertype ?? loader.target.objectType;

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

      /// Helper function that returns `true` if a type variable with a name
      /// from [typeVariableNames] is referenced in [type].
      bool usesTypeVariables(KernelTypeBuilder type) {
        if (type is KernelNamedTypeBuilder) {
          if (type.declaration is KernelTypeVariableBuilder) {
            return typeVariableNames.contains(type.declaration.name);
          }

          List<KernelTypeBuilder> typeArguments = type.arguments;
          if (typeArguments != null && typeVariables != null) {
            for (KernelTypeBuilder argument in typeArguments) {
              if (usesTypeVariables(argument)) {
                return true;
              }
            }
          }
        } else if (type is KernelFunctionTypeBuilder) {
          if (type.formals != null) {
            for (FormalParameterBuilder formal in type.formals) {
              if (usesTypeVariables(formal.type)) {
                return true;
              }
            }
          }
          return usesTypeVariables(type.returnType);
        }
        return false;
      }

      /// Iterate over the mixins from left to right. At the end of each
      /// iteration, a new [supertype] is computed that is the mixin
      /// application of [supertype] with the current mixin.
      for (int i = 0; i < type.mixins.length; i++) {
        KernelTypeBuilder mixin = type.mixins[i];
        isNamedMixinApplication = name != null && mixin == type.mixins.last;
        bool isGeneric = false;
        if (!isNamedMixinApplication) {
          if (supertype is KernelNamedTypeBuilder) {
            isGeneric = isGeneric || usesTypeVariables(supertype);
          }
          if (mixin is KernelNamedTypeBuilder) {
            runningName += "&${extractName(mixin.name)}";
            isGeneric = isGeneric || usesTypeVariables(mixin);
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
          if (isGeneric) {
            this.beginNestedDeclaration("mixin application");

            applicationTypeVariables =
                copyTypeVariables(typeVariables, currentDeclaration);

            List<TypeBuilder> newTypes = <TypeBuilder>[];
            if (supertype is KernelNamedTypeBuilder &&
                supertype.arguments != null) {
              for (int i = 0; i < supertype.arguments.length; ++i) {
                supertype.arguments[i] = supertype.arguments[i].clone(newTypes);
              }
            }
            if (mixin is KernelNamedTypeBuilder && mixin.arguments != null) {
              for (int i = 0; i < mixin.arguments.length; ++i) {
                mixin.arguments[i] = mixin.arguments[i].clone(newTypes);
              }
            }
            for (TypeBuilder newType in newTypes) {
              currentDeclaration.addType(
                  new UnresolvedType<KernelTypeBuilder>(newType, -1, null));
            }

            DeclarationBuilder mixinDeclaration =
                this.endNestedDeclaration("mixin application");
            mixinDeclaration.resolveTypes(applicationTypeVariables, this);

            applicationTypeArguments = <KernelTypeBuilder>[];
            for (TypeVariableBuilder typeVariable in typeVariables) {
              applicationTypeArguments
                  .add(addNamedType(typeVariable.name, null, charOffset)..bind(
                      // The type variable types passed as arguments to the
                      // generic class representing the anonymous mixin
                      // application should refer back to the type variables of
                      // the class that extend the anonymous mixin application.
                      typeVariable));
            }
          }
        }
        final int computedStartCharOffset =
            (isNamedMixinApplication ? metadata : null) == null
                ? startCharOffset
                : metadata.first.charOffset;
        SourceClassBuilder application = new SourceClassBuilder(
            isNamedMixinApplication ? metadata : null,
            isNamedMixinApplication
                ? modifiers | namedMixinApplicationMask
                : abstractMask,
            fullname,
            applicationTypeVariables,
            isMixinDeclaration ? null : supertype,
            isNamedMixinApplication
                ? interfaces
                : isMixinDeclaration ? [supertype, mixin] : null,
            new Scope(<String, MemberBuilder>{}, <String, MemberBuilder>{},
                scope.withTypeVariables(typeVariables),
                "mixin $fullname ", isModifiable: false),
            new Scope(<String, MemberBuilder>{}, null, null, fullname,
                isModifiable: false),
            this,
            <ConstructorReferenceBuilder>[],
            computedStartCharOffset,
            charOffset,
            charEndOffset,
            mixedInType: isMixinDeclaration ? null : mixin);
        if (isNamedMixinApplication) {
          loader.target.metadataCollector?.setDocumentationComment(
              application.target, documentationComment);
        }
        // TODO(ahe, kmillikin): Should always be true?
        // pkg/analyzer/test/src/summary/resynthesize_kernel_test.dart can't
        // handle that :(
        application.cls.isAnonymousMixin = !isNamedMixinApplication;
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
      int startCharOffset,
      int charOffset,
      int charEndOffset) {
    // Nested declaration began in `OutlineBuilder.beginNamedMixinApplication`.
    endNestedDeclaration(name).resolveTypes(typeVariables, this);
    KernelNamedTypeBuilder supertype = applyMixins(mixinApplication,
        startCharOffset, charOffset, charEndOffset, name, false,
        documentationComment: documentationComment,
        metadata: metadata,
        name: name,
        typeVariables: typeVariables,
        modifiers: modifiers,
        interfaces: interfaces);
    checkTypeVariables(typeVariables, supertype.declaration);
  }

  @override
  void addField(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder type,
      String name,
      int charOffset,
      int charEndOffset,
      Token initializerTokenForInference,
      bool hasInitializer) {
    if (hasInitializer) {
      modifiers |= hasInitializerMask;
    }
    KernelFieldBuilder field = new KernelFieldBuilder(
        metadata, type, name, modifiers, this, charOffset, charEndOffset);
    addBuilder(name, field, charOffset);
    if (initializerTokenForInference != null) {
      assert(type == null);
      field.target.type =
          new ImplicitFieldType(field, initializerTokenForInference);
    }
    loader.target.metadataCollector
        ?.setDocumentationComment(field.target, documentationComment);
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
      int startCharOffset,
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
        startCharOffset,
        charOffset,
        charOpenParenOffset,
        charEndOffset,
        nativeMethodName);
    if (formals != null) {
      for (int i = 0; i < formals.length; i++) {
        formals[i].parent = procedure;
      }
    }
    metadataCollector?.setDocumentationComment(
        procedure.target, documentationComment);
    metadataCollector?.setConstructorNameOffset(procedure.target, name);
    checkTypeVariables(typeVariables, procedure);
    addBuilder(constructorName, procedure, charOffset);
    if (nativeMethodName != null) {
      addNativeMethod(procedure);
    }
    if (procedure.isConst) currentDeclaration?.hasConstConstructor = true;
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
      int startCharOffset,
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
        startCharOffset,
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
      Object name,
      List<FormalParameterBuilder> formals,
      ConstructorReferenceBuilder redirectionTarget,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName) {
    KernelTypeBuilder returnType = addNamedType(
        currentDeclaration.parent.name, <KernelTypeBuilder>[], charOffset);
    // Nested declaration began in `OutlineBuilder.beginFactoryMethod`.
    DeclarationBuilder<KernelTypeBuilder> factoryDeclaration =
        endNestedDeclaration("#factory_method");

    // Prepare the simple procedure name.
    String procedureName;
    String constructorName =
        computeAndValidateConstructorName(name, charOffset, isFactory: true);
    if (constructorName != null) {
      procedureName = constructorName;
    } else {
      procedureName = name;
    }

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
          startCharOffset,
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
          startCharOffset,
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

  @override
  void addEnum(
      String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<EnumConstantInfo> enumConstantInfos,
      int startCharOffset,
      int charOffset,
      int charEndOffset) {
    MetadataCollector metadataCollector = loader.target.metadataCollector;
    KernelEnumBuilder builder = new KernelEnumBuilder(
        metadataCollector,
        metadata,
        name,
        enumConstantInfos,
        this,
        startCharOffset,
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
    KernelTypeAliasBuilder typedef = new KernelTypeAliasBuilder(
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
    if (hasThis) {
      modifiers |= initializingFormalMask;
    }
    KernelFormalParameterBuilder formal = new KernelFormalParameterBuilder(
        metadata, modifiers, type, name, this, charOffset);
    if (legacyMode && hasThis && type == null) {
      (untypedInitializingFormals ??= <KernelFormalParameterBuilder>[])
          .add(formal);
    }
    return formal;
  }

  KernelTypeVariableBuilder addTypeVariable(
      String name, KernelTypeBuilder bound, int charOffset) {
    var builder = new KernelTypeVariableBuilder(name, this, charOffset, bound);
    boundlessTypeVariables.add(builder);
    return builder;
  }

  @override
  void buildBuilder(Declaration declaration, LibraryBuilder coreLibrary) {
    Class cls;
    Member member;
    Typedef typedef;
    if (declaration is SourceClassBuilder) {
      cls = declaration.build(this, coreLibrary);
    } else if (declaration is KernelFieldBuilder) {
      member = declaration.build(this)..isStatic = true;
    } else if (declaration is KernelProcedureBuilder) {
      member = declaration.build(this)..isStatic = true;
    } else if (declaration is KernelTypeAliasBuilder) {
      typedef = declaration.build(this);
    } else if (declaration is KernelEnumBuilder) {
      cls = declaration.build(this, coreLibrary);
    } else if (declaration is PrefixBuilder) {
      // Ignored. Kernel doesn't represent prefixes.
      return;
    } else if (declaration is BuiltinTypeBuilder) {
      // Nothing needed.
      return;
    } else {
      unhandled("${declaration.runtimeType}", "buildBuilder",
          declaration.charOffset, declaration.fileUri);
      return;
    }
    if (declaration.isPatch) {
      // The kernel node of a patch is shared with the origin declaration. We
      // have two builders: the origin, and the patch, but only one kernel node
      // (which corresponds to the final output). Consequently, the node
      // shouldn't be added to its apparent kernel parent as this would create
      // a duplicate entry in the parent's list of children/members.
      return;
    }
    if (cls != null) {
      if (declaration.next != null) {
        int count = 0;
        Declaration current = declaration.next;
        while (current != null) {
          count++;
          current = current.next;
        }
        cls.name += "#$count";
      }
      library.addClass(cls);
    } else if (member != null) {
      if (declaration.next == null) {
        library.addMember(member);
      }
    } else if (typedef != null) {
      if (declaration.next == null) {
        library.addTypedef(typedef);
      }
    }
  }

  void addNativeDependency(String nativeImportPath) {
    Declaration constructor = loader.getNativeAnnotation();
    Arguments arguments =
        new Arguments(<Expression>[new StringLiteral(nativeImportPath)]);
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
        if (import.nativeImportPath != null) {
          addNativeDependency(import.nativeImportPath);
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
      part.addDependencies(library, seen);
    }
  }

  @override
  void addPart(List<MetadataBuilder> metadata, String uri, int charOffset) {
    super.addPart(metadata, uri, charOffset);
    // TODO(ahe): [metadata] should be stored, evaluated, and added to [part].
    LibraryPart part = new LibraryPart(<Expression>[], uri)
      ..fileOffset = charOffset;
    library.addPart(part);
  }

  @override
  Library build(LibraryBuilder coreLibrary, {bool modifyTarget}) {
    super.build(coreLibrary);

    if (modifyTarget == false) return library;

    library.isSynthetic = isSynthetic;
    addDependencies(library, new Set<KernelLibraryBuilder>());

    loader.target.metadataCollector
        ?.setDocumentationComment(library, documentationComment);

    library.name = name;
    library.procedures.sort(compareProcedures);

    if (unserializableExports != null) {
      library.addMember(new Field(new Name("_exports#", library),
          initializer: new StringLiteral(jsonEncode(unserializableExports)),
          isStatic: true,
          isConst: true));
    }

    return library;
  }

  @override
  Declaration computeAmbiguousDeclaration(
      String name, Declaration declaration, Declaration other, int charOffset,
      {bool isExport: false, bool isImport: false}) {
    // TODO(ahe): Can I move this to Scope or Prefix?
    if (declaration == other) return declaration;
    if (declaration is InvalidTypeBuilder) return declaration;
    if (other is InvalidTypeBuilder) return other;
    if (declaration is AccessErrorBuilder) {
      AccessErrorBuilder error = declaration;
      declaration = error.builder;
    }
    if (other is AccessErrorBuilder) {
      AccessErrorBuilder error = other;
      other = error.builder;
    }
    bool isLocal = false;
    bool isLoadLibrary = false;
    Declaration preferred;
    Uri uri;
    Uri otherUri;
    Uri preferredUri;
    Uri hiddenUri;
    if (scope.local[name] == declaration) {
      isLocal = true;
      preferred = declaration;
      hiddenUri = computeLibraryUri(other);
    } else {
      uri = computeLibraryUri(declaration);
      otherUri = computeLibraryUri(other);
      if (declaration is LoadLibraryBuilder) {
        isLoadLibrary = true;
        preferred = declaration;
        preferredUri = otherUri;
      } else if (other is LoadLibraryBuilder) {
        isLoadLibrary = true;
        preferred = other;
        preferredUri = uri;
      } else if (otherUri?.scheme == "dart" && uri?.scheme != "dart") {
        preferred = declaration;
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
    if (declaration.next == null && other.next == null) {
      if (isImport && declaration is PrefixBuilder && other is PrefixBuilder) {
        // Handles the case where the same prefix is used for different
        // imports.
        return declaration
          ..exportScope.merge(other.exportScope,
              (String name, Declaration existing, Declaration member) {
            return computeAmbiguousDeclaration(
                name, existing, member, charOffset,
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
    return new KernelInvalidTypeBuilder(
        name,
        builderTemplate
            .withArguments(
                name,
                // TODO(ahe): We should probably use a context object here
                // instead of including URIs in this message.
                uri,
                otherUri)
            .withLocation(fileUri, charOffset, name.length));
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

  int finishForwarders() {
    int count = 0;
    CloneVisitor cloner = new CloneVisitor();
    for (int i = 0; i < forwardersOrigins.length; i += 2) {
      Procedure forwarder = forwardersOrigins[i];
      Procedure origin = forwardersOrigins[i + 1];

      int positionalCount = origin.function.positionalParameters.length;
      if (forwarder.function.positionalParameters.length != positionalCount) {
        return unexpected(
            "$positionalCount",
            "${forwarder.function.positionalParameters.length}",
            origin.fileOffset,
            origin.fileUri);
      }
      for (int j = 0; j < positionalCount; ++j) {
        VariableDeclaration forwarderParameter =
            forwarder.function.positionalParameters[j];
        VariableDeclaration originParameter =
            origin.function.positionalParameters[j];
        if (originParameter.initializer != null) {
          forwarderParameter.initializer =
              cloner.clone(originParameter.initializer);
          forwarderParameter.initializer.parent = forwarderParameter;
        }
      }

      Map<String, VariableDeclaration> originNamedMap =
          <String, VariableDeclaration>{};
      for (VariableDeclaration originNamed in origin.function.namedParameters) {
        originNamedMap[originNamed.name] = originNamed;
      }
      for (VariableDeclaration forwarderNamed
          in forwarder.function.namedParameters) {
        VariableDeclaration originNamed = originNamedMap[forwarderNamed.name];
        if (originNamed == null) {
          return unhandled(
              "null", forwarder.name.name, origin.fileOffset, origin.fileUri);
        }
        if (originNamed.initializer == null) continue;
        forwarderNamed.initializer = cloner.clone(originNamed.initializer);
        forwarderNamed.initializer.parent = forwarderNamed;
      }

      ++count;
    }
    forwardersOrigins.clear();
    return count;
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
      declaration
          .addType(new UnresolvedType<KernelTypeBuilder>(newType, -1, null));
    }
    return copy;
  }

  int finishTypeVariables(ClassBuilder object, TypeBuilder dynamicType) {
    int count = boundlessTypeVariables.length;
    for (KernelTypeVariableBuilder builder in boundlessTypeVariables) {
      builder.finish(this, object, dynamicType);
    }
    boundlessTypeVariables.clear();
    return count;
  }

  int computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder bottomType,
      ClassBuilder objectClass) {
    int count = 0;

    int computeDefaultTypesForVariables(
        List<TypeVariableBuilder<TypeBuilder, Object>> variables,
        bool legacyMode) {
      if (variables == null) return 0;

      bool haveErroneousBounds = false;
      if (!legacyMode) {
        for (int i = 0; i < variables.length; ++i) {
          TypeVariableBuilder<TypeBuilder, Object> variable = variables[i];
          List<TypeBuilder> genericFunctionTypes = <TypeBuilder>[];
          findGenericFunctionTypes(variable.bound,
              result: genericFunctionTypes);
          if (genericFunctionTypes.length > 0) {
            haveErroneousBounds = true;
            addProblem(messageGenericFunctionTypeInBound, variable.charOffset,
                variable.name.length, variable.fileUri);
          }
        }

        if (!haveErroneousBounds) {
          List<KernelTypeBuilder> calculatedBounds =
              calculateBounds(variables, dynamicType, bottomType, objectClass);
          for (int i = 0; i < variables.length; ++i) {
            variables[i].defaultType = calculatedBounds[i];
          }
        }
      }

      if (legacyMode || haveErroneousBounds) {
        // In Dart 1, put `dynamic` everywhere.
        for (int i = 0; i < variables.length; ++i) {
          variables[i].defaultType = dynamicType;
        }
      }

      return variables.length;
    }

    void reportIssues(List<Object> issues) {
      for (int i = 0; i < issues.length; i += 3) {
        TypeDeclarationBuilder<TypeBuilder, Object> declaration = issues[i];
        Message message = issues[i + 1];
        List<LocatedMessage> context = issues[i + 2];

        addProblem(message, declaration.charOffset, declaration.name.length,
            declaration.fileUri,
            context: context);
      }
    }

    bool legacyMode = loader.target.legacyMode;
    for (var declaration in libraryDeclaration.members.values) {
      if (declaration is KernelClassBuilder) {
        {
          List<Object> issues = legacyMode
              ? const <Object>[]
              : getNonSimplicityIssuesForDeclaration(declaration,
                  performErrorRecovery: true);
          reportIssues(issues);
          // In case of issues, use legacy mode for error recovery.
          count += computeDefaultTypesForVariables(
              declaration.typeVariables, legacyMode || issues.isNotEmpty);
        }
        declaration.forEach((String name, Declaration member) {
          if (member is KernelProcedureBuilder) {
            List<Object> issues = legacyMode
                ? const <Object>[]
                : getNonSimplicityIssuesForTypeVariables(member.typeVariables);
            reportIssues(issues);
            // In case of issues, use legacy mode for error recovery.
            count += computeDefaultTypesForVariables(
                member.typeVariables, legacyMode || issues.isNotEmpty);
          }
        });
      } else if (declaration is KernelTypeAliasBuilder) {
        List<Object> issues = legacyMode
            ? const <Object>[]
            : getNonSimplicityIssuesForDeclaration(declaration,
                performErrorRecovery: true);
        reportIssues(issues);
        // In case of issues, use legacy mode for error recovery.
        count += computeDefaultTypesForVariables(
            declaration.typeVariables, legacyMode || issues.isNotEmpty);
      } else if (declaration is KernelFunctionBuilder) {
        List<Object> issues = legacyMode
            ? const <Object>[]
            : getNonSimplicityIssuesForTypeVariables(declaration.typeVariables);
        reportIssues(issues);
        // In case of issues, use legacy mode for error recovery.
        count += computeDefaultTypesForVariables(
            declaration.typeVariables, legacyMode || issues.isNotEmpty);
      }
    }

    return count;
  }

  @override
  void includePart(
      covariant KernelLibraryBuilder part, Set<Uri> usedParts, int partOffset) {
    super.includePart(part, usedParts, partOffset);
    nativeMethods.addAll(part.nativeMethods);
    boundlessTypeVariables.addAll(part.boundlessTypeVariables);
    // Check that the targets are different. This is not normally a problem
    // but is for patch files.
    if (target != part.target && part.target.problemsAsJson != null) {
      target.problemsAsJson ??= <String>[];
      target.problemsAsJson.addAll(part.target.problemsAsJson);
    }
  }

  @override
  void addImportsToScope() {
    super.addImportsToScope();
    exportScope.forEach((String name, Declaration member) {
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
              // Eventually (in #buildBuilder) members aren't added to the
              // library if the have 'next' pointers, so don't add them as
              // additionalExports either. Add the last one only (the one that
              // will eventually be added to the library).
              Declaration memberLast = member;
              while (memberLast.next != null) memberLast = memberLast.next;
              library.additionalExports.add(memberLast.target.reference);
            }
        }
      }
    });
  }

  @override
  void applyPatches() {
    if (!isPatch) return;
    NameIterator originDeclarations = origin.nameIterator;
    while (originDeclarations.moveNext()) {
      String name = originDeclarations.name;
      Declaration member = originDeclarations.current;
      bool isSetter = member.isSetter;
      Declaration patch = isSetter ? scope.setters[name] : scope.local[name];
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
    }
    NameIterator patchDeclarations = nameIterator;
    while (patchDeclarations.moveNext()) {
      String name = patchDeclarations.name;
      Declaration member = patchDeclarations.current;
      // We need to inject all non-patch members into the origin library. This
      // should only apply to private members.
      if (member.isPatch) {
        // Ignore patches.
      } else if (name.startsWith("_")) {
        origin.injectMemberFromPatch(name, member);
      } else {
        origin.exportMemberFromPatch(name, member);
      }
    }
  }

  int finishPatchMethods() {
    if (!isPatch) return 0;
    int count = 0;
    Iterator<Declaration> iterator = this.iterator;
    while (iterator.moveNext()) {
      count += iterator.current.finishPatch();
    }
    return count;
  }

  void injectMemberFromPatch(String name, Declaration member) {
    if (member.isSetter) {
      assert(scope.setters[name] == null);
      scopeBuilder.addSetter(name, member);
    } else {
      assert(scope.local[name] == null);
      scopeBuilder.addMember(name, member);
    }
  }

  void exportMemberFromPatch(String name, Declaration member) {
    if (uri.scheme != "dart" || !uri.path.startsWith("_")) {
      addProblem(templatePatchInjectionFailed.withArguments(name, uri),
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

  void reportTypeArgumentIssues(List<TypeArgumentIssue> issues, int offset,
      {bool inferred, DartType targetReceiver, String targetName}) {
    for (TypeArgumentIssue issue in issues) {
      DartType argument = issue.argument;
      TypeParameter typeParameter = issue.typeParameter;

      Message message;
      bool issueInferred = inferred ?? inferredTypes.contains(argument);
      if (argument is FunctionType && argument.typeParameters.length > 0) {
        if (issueInferred) {
          message = templateGenericFunctionTypeInferredAsActualTypeArgument
              .withArguments(argument);
        } else {
          message = messageGenericFunctionTypeUsedAsActualTypeArgument;
        }
        typeParameter = null;
      } else if (argument is TypeParameterType &&
          argument.promotedBound != null) {
        addProblem(
            templateIntersectionTypeAsTypeArgument.withArguments(
                typeParameter.name, argument, argument.promotedBound),
            offset,
            noLength,
            fileUri);
        continue;
      } else {
        if (issue.enclosingType == null && targetReceiver != null) {
          if (issueInferred) {
            message =
                templateIncorrectTypeArgumentQualifiedInferred.withArguments(
                    argument,
                    typeParameter.bound,
                    typeParameter.name,
                    targetReceiver,
                    targetName);
          } else {
            message = templateIncorrectTypeArgumentQualified.withArguments(
                argument,
                typeParameter.bound,
                typeParameter.name,
                targetReceiver,
                targetName);
          }
        } else {
          String enclosingName = issue.enclosingType == null
              ? targetName
              : getGenericTypeName(issue.enclosingType);
          assert(enclosingName != null);
          if (issueInferred) {
            message = templateIncorrectTypeArgumentInferred.withArguments(
                argument,
                typeParameter.bound,
                typeParameter.name,
                enclosingName);
          } else {
            message = templateIncorrectTypeArgument.withArguments(argument,
                typeParameter.bound, typeParameter.name, enclosingName);
          }
        }
      }

      reportTypeArgumentIssue(message, offset, typeParameter);
    }
  }

  void reportTypeArgumentIssue(
      Message message, int fileOffset, TypeParameter typeParameter) {
    List<LocatedMessage> context;
    if (typeParameter != null && typeParameter.fileOffset != -1) {
      // It looks like when parameters come from patch files, they don't
      // have a reportable location.
      context = <LocatedMessage>[
        messageIncorrectTypeArgumentVariable.withLocation(
            typeParameter.location.file, typeParameter.fileOffset, noLength)
      ];
    }
    addProblem(message, fileOffset, noLength, fileUri, context: context);
  }

  void checkBoundsInField(Field field, TypeEnvironment typeEnvironment) {
    if (loader.target.legacyMode) return;
    checkBoundsInType(field.type, typeEnvironment, field.fileOffset,
        allowSuperBounded: true);
  }

  void checkBoundsInFunctionNodeParts(
      TypeEnvironment typeEnvironment, int fileOffset,
      {List<TypeParameter> typeParameters,
      List<VariableDeclaration> positionalParameters,
      List<VariableDeclaration> namedParameters,
      DartType returnType}) {
    if (loader.target.legacyMode) return;
    if (typeParameters != null) {
      for (TypeParameter parameter in typeParameters) {
        checkBoundsInType(
            parameter.bound, typeEnvironment, parameter.fileOffset,
            allowSuperBounded: false);
      }
    }
    if (positionalParameters != null) {
      for (VariableDeclaration formal in positionalParameters) {
        checkBoundsInType(formal.type, typeEnvironment, formal.fileOffset,
            allowSuperBounded: true);
      }
    }
    if (namedParameters != null) {
      for (VariableDeclaration named in namedParameters) {
        checkBoundsInType(named.type, typeEnvironment, named.fileOffset,
            allowSuperBounded: true);
      }
    }
    if (returnType != null) {
      List<TypeArgumentIssue> issues = findTypeArgumentIssues(
          returnType, typeEnvironment,
          allowSuperBounded: true);
      if (issues != null) {
        int offset = fileOffset;
        for (TypeArgumentIssue issue in issues) {
          DartType argument = issue.argument;
          TypeParameter typeParameter = issue.typeParameter;

          // We don't need to check if [argument] was inferred or specified
          // here, because inference in return types boils down to instantiate-
          // -to-bound, and it can't provide a type that violates the bound.
          Message message;
          if (argument is FunctionType && argument.typeParameters.length > 0) {
            message = messageGenericFunctionTypeUsedAsActualTypeArgument;
            typeParameter = null;
          } else {
            message = templateIncorrectTypeArgumentInReturnType.withArguments(
                argument,
                typeParameter.bound,
                typeParameter.name,
                getGenericTypeName(issue.enclosingType));
          }

          reportTypeArgumentIssue(message, offset, typeParameter);
        }
      }
    }
  }

  void checkBoundsInFunctionNode(
      FunctionNode function, TypeEnvironment typeEnvironment) {
    if (loader.target.legacyMode) return;
    checkBoundsInFunctionNodeParts(typeEnvironment, function.fileOffset,
        typeParameters: function.typeParameters,
        positionalParameters: function.positionalParameters,
        namedParameters: function.namedParameters,
        returnType: function.returnType);
  }

  void checkBoundsInListLiteral(
      ListLiteral node, TypeEnvironment typeEnvironment,
      {bool inferred = false}) {
    if (loader.target.legacyMode) return;
    checkBoundsInType(node.typeArgument, typeEnvironment, node.fileOffset,
        inferred: inferred, allowSuperBounded: true);
  }

  void checkBoundsInSetLiteral(SetLiteral node, TypeEnvironment typeEnvironment,
      {bool inferred = false}) {
    if (loader.target.legacyMode) return;
    checkBoundsInType(node.typeArgument, typeEnvironment, node.fileOffset,
        inferred: inferred, allowSuperBounded: true);
  }

  void checkBoundsInMapLiteral(MapLiteral node, TypeEnvironment typeEnvironment,
      {bool inferred = false}) {
    if (loader.target.legacyMode) return;
    checkBoundsInType(node.keyType, typeEnvironment, node.fileOffset,
        inferred: inferred, allowSuperBounded: true);
    checkBoundsInType(node.valueType, typeEnvironment, node.fileOffset,
        inferred: inferred, allowSuperBounded: true);
  }

  void checkBoundsInType(
      DartType type, TypeEnvironment typeEnvironment, int offset,
      {bool inferred, bool allowSuperBounded = true}) {
    if (loader.target.legacyMode) return;
    List<TypeArgumentIssue> issues = findTypeArgumentIssues(
        type, typeEnvironment,
        allowSuperBounded: allowSuperBounded);
    if (issues != null) {
      reportTypeArgumentIssues(issues, offset, inferred: inferred);
    }
  }

  void checkBoundsInVariableDeclaration(
      VariableDeclaration node, TypeEnvironment typeEnvironment,
      {bool inferred = false}) {
    if (loader.target.legacyMode) return;
    if (node.type == null) return;
    checkBoundsInType(node.type, typeEnvironment, node.fileOffset,
        inferred: inferred, allowSuperBounded: true);
  }

  void checkBoundsInConstructorInvocation(
      ConstructorInvocation node, TypeEnvironment typeEnvironment,
      {bool inferred = false}) {
    if (loader.target.legacyMode) return;
    if (node.arguments.types.isEmpty) return;
    Constructor constructor = node.target;
    Class klass = constructor.enclosingClass;
    DartType constructedType = new InterfaceType(klass, node.arguments.types);
    checkBoundsInType(constructedType, typeEnvironment, node.fileOffset,
        inferred: inferred, allowSuperBounded: false);
  }

  void checkBoundsInFactoryInvocation(
      StaticInvocation node, TypeEnvironment typeEnvironment,
      {bool inferred = false}) {
    if (loader.target.legacyMode) return;
    if (node.arguments.types.isEmpty) return;
    Procedure factory = node.target;
    assert(factory.isFactory);
    Class klass = factory.enclosingClass;
    DartType constructedType = new InterfaceType(klass, node.arguments.types);
    checkBoundsInType(constructedType, typeEnvironment, node.fileOffset,
        inferred: inferred, allowSuperBounded: false);
  }

  void checkBoundsInStaticInvocation(
      StaticInvocation node, TypeEnvironment typeEnvironment,
      {bool inferred = false}) {
    if (loader.target.legacyMode) return;
    if (node.arguments.types.isEmpty) return;
    Class klass = node.target.enclosingClass;
    List<TypeParameter> parameters = node.target.function.typeParameters;
    List<DartType> arguments = node.arguments.types;
    // The following error is to be reported elsewhere.
    if (parameters.length != arguments.length) return;
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        parameters, arguments, typeEnvironment);
    if (issues != null) {
      DartType targetReceiver;
      if (klass != null) {
        targetReceiver = new InterfaceType(klass);
      }
      String targetName = node.target.name.name;
      reportTypeArgumentIssues(issues, node.fileOffset,
          inferred: inferred,
          targetReceiver: targetReceiver,
          targetName: targetName);
    }
  }

  void checkBoundsInMethodInvocation(
      DartType receiverType,
      TypeEnvironment typeEnvironment,
      ClassHierarchy hierarchy,
      TypeInferrerImpl typeInferrer,
      Name name,
      Member interfaceTarget,
      Arguments arguments,
      int offset,
      {bool inferred = false}) {
    if (loader.target.legacyMode) return;
    if (arguments.types.isEmpty) return;
    Class klass;
    List<DartType> receiverTypeArguments;
    if (receiverType is InterfaceType) {
      klass = receiverType.classNode;
      receiverTypeArguments = receiverType.typeArguments;
    } else {
      return;
    }
    // TODO(dmitryas): Find a better way than relying on [interfaceTarget].
    Member method = hierarchy.getDispatchTarget(klass, name) ?? interfaceTarget;
    if (method == null || method is! Procedure) {
      return;
    }
    if (klass != method.enclosingClass) {
      Supertype parent =
          hierarchy.getClassAsInstanceOf(klass, method.enclosingClass);
      klass = method.enclosingClass;
      receiverTypeArguments = parent.typeArguments;
    }
    Map<TypeParameter, DartType> substitutionMap = <TypeParameter, DartType>{};
    for (int i = 0; i < receiverTypeArguments.length; ++i) {
      substitutionMap[klass.typeParameters[i]] = receiverTypeArguments[i];
    }
    List<TypeParameter> methodParameters = method.function.typeParameters;
    // The error is to be reported elsewhere.
    if (methodParameters.length != arguments.types.length) return;
    List<TypeParameter> instantiatedMethodParameters =
        new List<TypeParameter>.filled(methodParameters.length, null);
    for (int i = 0; i < instantiatedMethodParameters.length; ++i) {
      instantiatedMethodParameters[i] =
          new TypeParameter(methodParameters[i].name);
      substitutionMap[methodParameters[i]] =
          new TypeParameterType(instantiatedMethodParameters[i]);
    }
    for (int i = 0; i < instantiatedMethodParameters.length; ++i) {
      instantiatedMethodParameters[i].bound =
          substitute(methodParameters[i].bound, substitutionMap);
    }
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
        instantiatedMethodParameters, arguments.types, typeEnvironment);
    if (issues != null) {
      reportTypeArgumentIssues(issues, offset,
          inferred: inferred,
          targetReceiver: receiverType,
          targetName: name.name);
    }
  }

  void checkBoundsInOutline(TypeEnvironment typeEnvironment) {
    if (loader.target.legacyMode) return;
    Iterator<Declaration> iterator = this.iterator;
    while (iterator.moveNext()) {
      Declaration declaration = iterator.current;
      if (declaration is KernelFieldBuilder) {
        checkBoundsInField(declaration.target, typeEnvironment);
      } else if (declaration is KernelProcedureBuilder) {
        checkBoundsInFunctionNode(declaration.target.function, typeEnvironment);
      } else if (declaration is KernelClassBuilder) {
        declaration.checkBoundsInOutline(typeEnvironment);
      }
    }
    inferredTypes.clear();
  }

  @override
  int finalizeInitializingFormals() {
    if (!legacyMode || untypedInitializingFormals == null) return 0;
    for (int i = 0; i < untypedInitializingFormals.length; i++) {
      untypedInitializingFormals[i].finalizeInitializingFormal();
    }
    int count = untypedInitializingFormals.length;
    untypedInitializingFormals = null;
    return count;
  }
}

Uri computeLibraryUri(Declaration declaration) {
  Declaration current = declaration;
  do {
    if (current is LibraryBuilder) return current.uri;
    current = current.parent;
  } while (current != null);
  return unhandled("no library parent", "${declaration.runtimeType}",
      declaration.charOffset, declaration.fileUri);
}

String extractName(name) => name is QualifiedName ? name.name : name;
