// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_library_builder;

import 'dart:convert' show JSON;

import 'package:front_end/src/fasta/export.dart';
import 'package:front_end/src/fasta/import.dart';
import 'package:kernel/ast.dart';

import 'package:kernel/clone.dart' show CloneVisitor;

import '../../scanner/token.dart' show Token;

import '../fasta_codes.dart'
    show
        Message,
        messageConflictsWithTypeVariableCause,
        messageTypeVariableDuplicatedName,
        messageTypeVariableSameNameAsEnclosing,
        templateConflictsWithTypeVariable,
        templateDuplicatedExport,
        templateDuplicatedImport,
        templateExportHidesExport,
        templateIllegalMethodName,
        templateImportHidesImport,
        templateLoadLibraryHidesMember,
        templateLocalDefinitionHidesExport,
        templateLocalDefinitionHidesImport,
        templatePatchInjectionFailed,
        templateTypeVariableDuplicatedNameCause;

import '../loader.dart' show Loader;

import '../modifier.dart'
    show abstractMask, namedMixinApplicationMask, staticMask;

import '../problems.dart' show unhandled;

import '../source/source_class_builder.dart' show SourceClassBuilder;

import '../source/source_library_builder.dart'
    show DeclarationBuilder, SourceLibraryBuilder;

import '../util/relativize.dart' show relativizeUri;

import 'kernel_builder.dart'
    show
        AccessErrorBuilder,
        Builder,
        BuiltinTypeBuilder,
        ClassBuilder,
        ConstructorReferenceBuilder,
        FormalParameterBuilder,
        InvalidTypeBuilder,
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
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        LoadLibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        NamedTypeBuilder,
        PrefixBuilder,
        ProcedureBuilder,
        QualifiedName,
        Scope,
        TypeBuilder,
        TypeVariableBuilder,
        compareProcedures,
        toKernelCombinators;

import 'metadata_collector.dart';

class KernelLibraryBuilder
    extends SourceLibraryBuilder<KernelTypeBuilder, Library> {
  final Library library;

  final KernelLibraryBuilder actualOrigin;

  final Map<String, SourceClassBuilder> mixinApplicationClasses =
      <String, SourceClassBuilder>{};

  final List<List> argumentsWithMissingDefaultValues = <List>[];

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
      : library = actualOrigin?.library ??
            new Library(uri, fileUri: relativizeUri(fileUri)),
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
    return addNamedType("void", null, charOffset);
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
        applyMixins(supertype, supertypeOffset,
            isSyntheticMixinImplementation: true,
            subclassName: className,
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
              member.charOffset);
          cls.addCompileTimeError(
              messageConflictsWithTypeVariableCause, tv.charOffset);
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
        addCompileTimeError(
            messageTypeVariableDuplicatedName, tv.charOffset, fileUri);
        addCompileTimeError(
            templateTypeVariableDuplicatedNameCause.withArguments(tv.name),
            existing.charOffset,
            fileUri);
      } else {
        typeVariablesByName[tv.name] = tv;
        if (owner is ClassBuilder) {
          // Only classes and type variables can't have the same name. See
          // [#29555](https://github.com/dart-lang/sdk/issues/29555).
          if (tv.name == owner.name) {
            addCompileTimeError(
                messageTypeVariableSameNameAsEnclosing, tv.charOffset, fileUri);
          }
        }
      }
    }
    return typeVariablesByName;
  }

  KernelTypeBuilder applyMixin(
      KernelTypeBuilder supertype, KernelTypeBuilder mixin, String signature,
      {String documentationComment,
      List<MetadataBuilder> metadata,
      bool isSyntheticMixinImplementation: false,
      String name,
      List<TypeVariableBuilder> typeVariables,
      int modifiers: abstractMask,
      List<KernelTypeBuilder> interfaces,
      int charOffset: -1}) {
    var constructors = <String, MemberBuilder>{};
    bool isNamed = name != null;
    SourceClassBuilder builder;
    if (isNamed) {
      modifiers |= namedMixinApplicationMask;
    } else {
      name = "${supertype.name}";
      int index = name.indexOf("^");
      if (index != -1) {
        name = name.substring(0, index);
      }
      name = "_$name&${mixin.name}$signature";
      builder = mixinApplicationClasses[name];
    }
    if (builder == null) {
      builder = new SourceClassBuilder(
          metadata,
          modifiers,
          name,
          typeVariables,
          supertype,
          interfaces,
          new Scope(<String, MemberBuilder>{}, <String, MemberBuilder>{},
              scope.withTypeVariables(typeVariables),
              "mixin $name", isModifiable: false),
          new Scope(constructors, null, null, "constructors",
              isModifiable: false),
          this,
          <ConstructorReferenceBuilder>[],
          charOffset,
          TreeNode.noOffset,
          null,
          mixin);
      loader.target.metadataCollector
          ?.setDocumentationComment(builder.target, documentationComment);
      builder.cls.isSyntheticMixinImplementation =
          isSyntheticMixinImplementation;
      addBuilder(name, builder, charOffset);
      if (!isNamed) {
        mixinApplicationClasses[name] = builder;
      }
    }
    return addNamedType(name, <KernelTypeBuilder>[], charOffset)
      ..bind(isNamed ? builder : null);
  }

  KernelTypeBuilder applyMixins(KernelTypeBuilder type, int charOffset,
      {String documentationComment,
      List<MetadataBuilder> metadata,
      bool isSyntheticMixinImplementation: false,
      String name,
      String subclassName,
      List<TypeVariableBuilder> typeVariables,
      int modifiers: abstractMask,
      List<KernelTypeBuilder> interfaces}) {
    if (type is KernelMixinApplicationBuilder) {
      subclassName ??= name;
      List<List<String>> signatureParts = <List<String>>[];
      Map<String, String> unresolved = <String, String>{};
      Map<String, String> unresolvedReversed = <String, String>{};
      int unresolvedCount = 0;
      Map<String, TypeBuilder> freeTypes = <String, TypeBuilder>{};

      if (name == null || type.mixins.length != 1) {
        TypeBuilder last = type.mixins.last;

        /// Compute a signature of the type arguments used by the supertype and
        /// mixins. These types are free variables. At this point we can't
        /// trust that the number of type arguments match the type parameters,
        /// so we also need to be able to detect missing type arguments.  To do
        /// so, we separate each list of type arguments by `^` and type
        /// arguments by `&`. For example, the mixin `C<S> with M<T, U>` would
        /// look like this:
        ///
        ///     ^#U0^#U1&#U2
        ///
        /// Where `#U0`, `#U1`, and `#U2` are the free variables arising from
        /// `S`, `T`, and `U` respectively.
        ///
        /// As we can resolve any type parameters used at this point, those are
        /// named `#T0` and so forth. This reduces the number of free variables
        /// which is crucial for memory usage and the Dart VM's bootstrap
        /// sequence.
        ///
        /// For example, consider this use of mixin applications:
        ///
        ///     class _InternalLinkedHashMap<K, V> extends _HashVMBase
        ///         with
        ///             MapMixin<K, V>,
        ///             _LinkedHashMapMixin<K, V>,
        ///             _HashBase,
        ///             _OperatorEqualsAndHashCode {}
        ///
        /// In this case, only two variables are free, and we produce this
        /// signature: `^^#T0&#T1^#T0&#T1^^`. Assume another class uses the
        /// sames mixins but with missing type arguments for `MapMixin`, its
        /// signature would be: `^^^#T0&#T1^^`.
        ///
        /// Note that we do not need to compute a signature for a named mixin
        /// application with only one mixin as we don't have to invent a name
        /// for any classes in this situation.
        void analyzeArguments(TypeBuilder type) {
          if (name != null && type == last) {
            // The last mixin of a named mixin application doesn't contribute
            // to free variables.
            return;
          }
          if (type is NamedTypeBuilder) {
            List<String> part = <String>[];
            for (int i = 0; i < (type.arguments?.length ?? 0); i++) {
              var argument = type.arguments[i];
              String name;
              if (argument is NamedTypeBuilder) {
                if (argument.builder != null) {
                  int index = typeVariables?.indexOf(argument.builder) ?? -1;
                  if (index != -1) {
                    name = "#T${index}";
                  }
                } else if (argument.arguments == null) {
                  name = unresolved[argument.name] ??= "#U${unresolvedCount++}";
                }
              }
              name ??= "#U${unresolvedCount++}";
              unresolvedReversed[name] = argument.name;
              freeTypes[name] = argument;
              part.add(name);
              type.arguments[i] = new KernelNamedTypeBuilder(name, null);
            }
            signatureParts.add(part);
          }
        }

        analyzeArguments(type.supertype);
        type.mixins.forEach(analyzeArguments);
      }
      KernelTypeBuilder supertype = type.supertype;
      List<List<String>> currentSignatureParts = <List<String>>[];
      int currentSignatureCount = 0;
      String computeSignature() {
        if (freeTypes.isEmpty) return "";
        currentSignatureParts.add(signatureParts[currentSignatureCount++]);
        if (currentSignatureParts.any((l) => l.isNotEmpty)) {
          return "^${currentSignatureParts.map((l) => l.join('&')).join('^')}";
        } else {
          return "";
        }
      }

      Map<String, TypeVariableBuilder> computeTypeVariables() {
        Map<String, TypeVariableBuilder> variables =
            <String, TypeVariableBuilder>{};
        for (List<String> strings in currentSignatureParts) {
          for (String name in strings) {
            variables[name] ??= addTypeVariable(name, null, -1);
          }
        }
        return variables;
      }

      checkArguments(t) {
        for (var argument in t.arguments ?? const []) {
          if (argument.builder == null && argument.name.startsWith("#")) {
            throw "No builder on ${argument.name}";
          }
        }
      }

      computeSignature(); // This combines the supertype with the first mixin.
      for (int i = 0; i < type.mixins.length - 1; i++) {
        Set<String> supertypeArguments = new Set<String>();
        for (var part in currentSignatureParts) {
          supertypeArguments.addAll(part);
        }
        String signature = computeSignature();
        var variables = computeTypeVariables();
        if (supertypeArguments.isNotEmpty) {
          supertype = addNamedType(
              supertype.name,
              supertypeArguments
                  .map((n) => addNamedType(n, null, -1)..bind(variables[n]))
                  .toList(),
              -1);
        }
        KernelNamedTypeBuilder mixin = type.mixins[i];
        for (var type in mixin.arguments ?? const []) {
          type.bind(variables[type.name]);
        }
        checkArguments(supertype);
        checkArguments(mixin);
        supertype = applyMixin(supertype, mixin, signature,
            isSyntheticMixinImplementation: true,
            typeVariables: new List<TypeVariableBuilder>.from(variables.values),
            // TODO(ahe): Eventually, the charOffset should be -1 as these
            // classes are canonicalized and synthetic. For now, for the
            // benefit of dart2js, we add offsets to help the compiler during
            // the migration process. We add i because dart2js uses these
            // numbers to sort the classes by. Adding i isn't precisely what
            // dart2js does, but it should be good enough.
            charOffset: charOffset + i);
      }
      KernelNamedTypeBuilder mixin = type.mixins.last;

      Set<String> supertypeArguments = new Set<String>();
      for (var part in currentSignatureParts) {
        supertypeArguments.addAll(part);
      }
      String signature = name == null ? computeSignature() : "";
      var variables;
      if (name == null) {
        variables = computeTypeVariables();
        typeVariables = new List<TypeVariableBuilder>.from(variables.values);
        if (supertypeArguments.isNotEmpty) {
          supertype = addNamedType(
              supertype.name,
              supertypeArguments
                  .map((n) => addNamedType(n, null, -1)..bind(variables[n]))
                  .toList(),
              -1);
        }
      } else {
        if (supertypeArguments.isNotEmpty) {
          supertype = addNamedType(supertype.name,
              supertypeArguments.map((n) => freeTypes[n]).toList(), -1);
        }
      }

      if (name == null) {
        for (var type in mixin.arguments ?? const []) {
          type.bind(variables[type.name]);
        }
      }
      checkArguments(supertype);
      checkArguments(mixin);

      KernelNamedTypeBuilder t = applyMixin(supertype, mixin, signature,
          documentationComment: documentationComment,
          metadata: metadata,
          name: name,
          isSyntheticMixinImplementation: isSyntheticMixinImplementation,
          typeVariables: typeVariables,
          modifiers: modifiers,
          interfaces: interfaces,
          charOffset: charOffset);
      if (name == null) {
        var builder = t.builder;
        t = addNamedType(
            t.name, freeTypes.keys.map((k) => freeTypes[k]).toList(), -1);
        if (builder != null) {
          t.bind(builder);
        }
      }
      return t;
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
    KernelNamedTypeBuilder supertype = applyMixins(mixinApplication, charOffset,
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

  String computeAndValidateConstructorName(Object name, int charOffset) {
    String className = currentDeclaration.name;
    String prefix;
    String suffix;
    if (name is QualifiedName) {
      prefix = name.prefix;
      suffix = name.suffix;
    } else {
      prefix = name;
      suffix = null;
    }
    if (prefix == className) {
      return suffix ?? "";
    }
    if (suffix == null) {
      // A legal name for a regular method, but not for a constructor.
      return null;
    }
    addCompileTimeError(
        templateIllegalMethodName.withArguments("$name", "$className.$suffix"),
        charOffset,
        fileUri);
    return suffix;
  }

  void addProcedure(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder returnType,
      final Object name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      ProcedureKind kind,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName,
      {bool isTopLevel}) {
    // Nested declaration began in `OutlineBuilder.beginMethod` or
    // `OutlineBuilder.beginTopLevelMethod`.
    endNestedDeclaration("#method").resolveTypes(typeVariables, this);
    String procedureName;
    ProcedureBuilder procedure;
    String constructorName =
        isTopLevel ? null : computeAndValidateConstructorName(name, charOffset);
    MetadataCollector metadataCollector = loader.target.metadataCollector;
    if (constructorName != null) {
      procedureName = constructorName;
      procedure = new KernelConstructorBuilder(
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
    } else {
      assert(name is String);
      procedureName = name;
      procedure = new KernelProcedureBuilder(
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
    }
    checkTypeVariables(typeVariables, procedure);
    addBuilder(procedureName, procedure, charOffset);
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
    KernelProcedureBuilder procedure = new KernelProcedureBuilder(
        metadata,
        staticMask | modifiers,
        returnType,
        procedureName,
        <TypeVariableBuilder>[],
        formals,
        ProcedureKind.Factory,
        this,
        charOffset,
        charOpenParenOffset,
        charEndOffset,
        nativeMethodName,
        redirectionTarget);

    var metadataCollector = loader.target.metadataCollector;
    metadataCollector?.setDocumentationComment(
        procedure.target, documentationComment);
    metadataCollector?.setConstructorNameOffset(procedure.target, name);

    currentDeclaration.addFactoryDeclaration(procedure, factoryDeclaration);
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
      library.addPart(new LibraryPart(<Expression>[], part.relativeFileUri));
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
        addNit(template.withArguments(name, hiddenUri), charOffset, fileUri);
      } else if (isLoadLibrary) {
        addNit(templateLoadLibraryHidesMember.withArguments(preferredUri),
            charOffset, fileUri);
      } else {
        var template =
            isExport ? templateExportHidesExport : templateImportHidesImport;
        addNit(template.withArguments(name, preferredUri, hiddenUri),
            charOffset, fileUri);
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
    addNit(message, charOffset, fileUri);
    return new KernelInvalidTypeBuilder(name, charOffset, fileUri, message);
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

  int finishStaticInvocations() {
    CloneVisitor cloner;
    for (var list in argumentsWithMissingDefaultValues) {
      final Arguments arguments = list[0];
      final FunctionNode function = list[1];

      Expression defaultArgumentFrom(Expression expression) {
        if (expression == null) {
          return new NullLiteral();
        }
        cloner ??= new CloneVisitor();
        return cloner.clone(expression);
      }

      for (int i = function.requiredParameterCount;
          i < function.positionalParameters.length;
          i++) {
        arguments.positional[i] ??=
            defaultArgumentFrom(function.positionalParameters[i].initializer)
              ..parent = arguments;
      }
      Map<String, VariableDeclaration> names;
      for (NamedExpression expression in arguments.named) {
        if (expression.value == null) {
          if (names == null) {
            names = <String, VariableDeclaration>{};
            for (VariableDeclaration parameter in function.namedParameters) {
              names[parameter.name] = parameter;
            }
          }
          expression.value =
              defaultArgumentFrom(names[expression.name].initializer)
                ..parent = expression;
        }
      }
    }
    return argumentsWithMissingDefaultValues.length;
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
      List<TypeVariableBuilder> original) {
    List<TypeVariableBuilder> copy = <TypeVariableBuilder>[];
    for (KernelTypeVariableBuilder variable in original) {
      var newVariable = new KernelTypeVariableBuilder(
          variable.name, this, variable.charOffset);
      copy.add(newVariable);
      boundlessTypeVariables.add(newVariable);
    }
    Map<TypeVariableBuilder, TypeBuilder> substitution =
        <TypeVariableBuilder, TypeBuilder>{};
    int i = 0;
    for (KernelTypeVariableBuilder variable in original) {
      substitution[variable] = copy[i++].asTypeBuilder();
    }
    i = 0;
    for (KernelTypeVariableBuilder variable in original) {
      copy[i++].bound = variable.bound?.subst(substitution);
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

  @override
  void includePart(covariant KernelLibraryBuilder part) {
    part.mixinApplicationClasses
        .forEach((String name, SourceClassBuilder builder) {
      SourceClassBuilder existing =
          mixinApplicationClasses.putIfAbsent(name, () => builder);
      if (existing != builder) {
        part.scope.local.remove(name);
      }
    });
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
          member.charOffset, member.fileUri);
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
