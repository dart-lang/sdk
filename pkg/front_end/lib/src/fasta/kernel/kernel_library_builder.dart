// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_library_builder;

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
        templateLocalDefinitionHidesExport,
        templateLocalDefinitionHidesImport,
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
        KernelFunctionTypeAliasBuilder,
        KernelFunctionTypeBuilder,
        KernelInvalidTypeBuilder,
        KernelMixinApplicationBuilder,
        KernelNamedTypeBuilder,
        KernelProcedureBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        NamedTypeBuilder,
        PrefixBuilder,
        ProcedureBuilder,
        Scope,
        TypeBuilder,
        TypeVariableBuilder,
        compareProcedures;

class KernelLibraryBuilder
    extends SourceLibraryBuilder<KernelTypeBuilder, Library> {
  final Library library;

  final bool isPatch;

  final Map<String, SourceClassBuilder> mixinApplicationClasses =
      <String, SourceClassBuilder>{};

  final List<List> argumentsWithMissingDefaultValues = <List>[];

  final List<KernelProcedureBuilder> nativeMethods = <KernelProcedureBuilder>[];

  final List<KernelTypeVariableBuilder> boundlessTypeVariables =
      <KernelTypeVariableBuilder>[];

  KernelLibraryBuilder(Uri uri, Uri fileUri, Loader loader, this.isPatch)
      : library = new Library(uri, fileUri: relativizeUri(fileUri)),
        super(loader, fileUri);

  Library get target => library;

  Uri get uri => library.importUri;

  KernelTypeBuilder addNamedType(
      String name, List<KernelTypeBuilder> arguments, int charOffset) {
    return addType(
        new KernelNamedTypeBuilder(name, arguments, charOffset, fileUri));
  }

  KernelTypeBuilder addMixinApplication(KernelTypeBuilder supertype,
      List<KernelTypeBuilder> mixins, int charOffset) {
    KernelTypeBuilder type = new KernelMixinApplicationBuilder(
        supertype, mixins, this, charOffset, fileUri);
    return addType(type);
  }

  KernelTypeBuilder addVoidType(int charOffset) {
    return addNamedType("void", null, charOffset);
  }

  void addClass(
      List<MetadataBuilder> metadata,
      int modifiers,
      String className,
      List<TypeVariableBuilder> typeVariables,
      KernelTypeBuilder supertype,
      List<KernelTypeBuilder> interfaces,
      int charOffset) {
    // Nested declaration began in `OutlineBuilder.beginClassDeclaration`.
    var declaration = endNestedDeclaration(className)
      ..resolveTypes(typeVariables, this);
    assert(declaration.parent == libraryDeclaration);
    Map<String, MemberBuilder> members = declaration.members;
    Map<String, MemberBuilder> constructors = declaration.constructors;
    Map<String, MemberBuilder> setters = declaration.setters;

    Scope classScope = new Scope(
        members, setters, scope.withTypeVariables(typeVariables),
        isModifiable: false);

    // When looking up a constructor, we don't consider type variables or the
    // library scope.
    Scope constructorScope =
        new Scope(constructors, null, null, isModifiable: false);
    ClassBuilder cls = new SourceClassBuilder(
        metadata,
        modifiers,
        className,
        typeVariables,
        applyMixins(supertype,
            subclassName: className, typeVariables: typeVariables),
        interfaces,
        classScope,
        constructorScope,
        this,
        new List<ConstructorReferenceBuilder>.from(constructorReferences),
        charOffset);
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
      {List<MetadataBuilder> metadata,
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
      name = supertype.name;
      int index = name.indexOf("^");
      if (index != -1) {
        name = name.substring(0, index);
      }
      name = "$name&${mixin.name}$signature";
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
              isModifiable: false),
          new Scope(constructors, null, null, isModifiable: false),
          this,
          <ConstructorReferenceBuilder>[],
          charOffset,
          null,
          mixin);
      addBuilder(name, builder, charOffset);
      if (!isNamed) {
        mixinApplicationClasses[name] = builder;
      }
    }
    return addNamedType(name, <KernelTypeBuilder>[], charOffset)
      ..bind(isNamed ? builder : null);
  }

  KernelTypeBuilder applyMixins(KernelTypeBuilder type,
      {List<MetadataBuilder> metadata,
      String name,
      String subclassName,
      List<TypeVariableBuilder> typeVariables,
      int modifiers: abstractMask,
      List<KernelTypeBuilder> interfaces,
      int charOffset: -1}) {
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
              type.arguments[i] =
                  new KernelNamedTypeBuilder(name, null, -1, fileUri);
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
            typeVariables:
                new List<TypeVariableBuilder>.from(variables.values));
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
          metadata: metadata,
          name: name,
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
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      int modifiers,
      KernelTypeBuilder mixinApplication,
      List<KernelTypeBuilder> interfaces,
      int charOffset) {
    // Nested declaration began in `OutlineBuilder.beginNamedMixinApplication`.
    endNestedDeclaration(name).resolveTypes(typeVariables, this);
    KernelNamedTypeBuilder supertype = applyMixins(mixinApplication,
        metadata: metadata,
        name: name,
        typeVariables: typeVariables,
        modifiers: modifiers,
        interfaces: interfaces,
        charOffset: charOffset);
    checkTypeVariables(typeVariables, supertype.builder);
  }

  @override
  void addField(
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder type,
      String name,
      int charOffset,
      Token initializerTokenForInference,
      bool hasInitializer) {
    addBuilder(
        name,
        new KernelFieldBuilder(metadata, type, name, modifiers, this,
            charOffset, initializerTokenForInference, hasInitializer),
        charOffset);
  }

  String computeAndValidateConstructorName(String name, int charOffset) {
    String className = currentDeclaration.name;
    bool startsWithClassName = name.startsWith(className);
    if (startsWithClassName && name.length == className.length) {
      // Unnamed constructor or factory.
      return "";
    }
    int index = name.indexOf(".");
    if (startsWithClassName && index == className.length) {
      // Named constructor or factory.
      return name.substring(index + 1);
    }
    if (index == -1) {
      // A legal name for a regular method, but not for a constructor.
      return null;
    }
    String suffix = name.substring(index + 1);
    addCompileTimeError(
        templateIllegalMethodName.withArguments(name, "$className.$suffix"),
        charOffset,
        fileUri);
    return suffix;
  }

  void addProcedure(
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
    // Nested declaration began in `OutlineBuilder.beginMethod` or
    // `OutlineBuilder.beginTopLevelMethod`.
    endNestedDeclaration(name).resolveTypes(typeVariables, this);
    ProcedureBuilder procedure;
    String constructorName =
        isTopLevel ? null : computeAndValidateConstructorName(name, charOffset);
    if (constructorName != null) {
      name = constructorName;
      procedure = new KernelConstructorBuilder(
          metadata,
          modifiers & ~abstractMask,
          returnType,
          name,
          typeVariables,
          formals,
          this,
          charOffset,
          charOpenParenOffset,
          charEndOffset,
          nativeMethodName);
    } else {
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
    }
    checkTypeVariables(typeVariables, procedure);
    addBuilder(name, procedure, charOffset);
    if (nativeMethodName != null) {
      addNativeMethod(procedure);
    }
  }

  void addFactoryMethod(
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
    String name = constructorNameReference.name;
    String constructorName =
        computeAndValidateConstructorName(name, charOffset);
    if (constructorName != null) {
      name = constructorName;
    }
    assert(constructorNameReference.suffix == null);
    KernelProcedureBuilder procedure = new KernelProcedureBuilder(
        metadata,
        staticMask | modifiers,
        returnType,
        name,
        <TypeVariableBuilder>[],
        formals,
        ProcedureKind.Factory,
        this,
        charOffset,
        charOpenParenOffset,
        charEndOffset,
        nativeMethodName,
        redirectionTarget);
    currentDeclaration.addFactoryDeclaration(procedure, factoryDeclaration);
    addBuilder(name, procedure, charOffset);
    if (nativeMethodName != null) {
      addNativeMethod(procedure);
    }
  }

  void addEnum(List<MetadataBuilder> metadata, String name,
      List<Object> constantNamesAndOffsets, int charOffset, int charEndOffset) {
    addBuilder(
        name,
        new KernelEnumBuilder(metadata, name, constantNamesAndOffsets, this,
            charOffset, charEndOffset),
        charOffset);
  }

  void addFunctionTypeAlias(
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      covariant KernelFunctionTypeBuilder type,
      int charOffset) {
    KernelFunctionTypeAliasBuilder typedef = new KernelFunctionTypeAliasBuilder(
        metadata, name, typeVariables, type, this, charOffset);
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
    var builder = new KernelFunctionTypeBuilder(
        charOffset, fileUri, returnType, typeVariables, formals);
    checkTypeVariables(typeVariables, builder);
    // Nested declaration began in `OutlineBuilder.beginFunctionType` or
    // `OutlineBuilder.beginFunctionTypedFormalParameter`.
    endNestedDeclaration("#function_type").resolveTypes(typeVariables, this);
    return addType(builder);
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
    if (builder is SourceClassBuilder) {
      Class cls = builder.build(this, coreLibrary);
      library.addClass(cls);
    } else if (builder is KernelFieldBuilder) {
      library.addMember(builder.build(this)..isStatic = true);
    } else if (builder is KernelProcedureBuilder) {
      library.addMember(builder.build(this)..isStatic = true);
    } else if (builder is KernelFunctionTypeAliasBuilder) {
      library.addTypedef(builder.build(this));
    } else if (builder is KernelEnumBuilder) {
      library.addClass(builder.build(this, coreLibrary));
    } else if (builder is PrefixBuilder) {
      // Ignored. Kernel doesn't represent prefixes.
    } else if (builder is BuiltinTypeBuilder) {
      // Nothing needed.
    } else {
      unhandled("${builder.runtimeType}", "buildBuilder", builder.charOffset,
          builder.fileUri);
    }
  }

  @override
  Library build(LibraryBuilder coreLibrary) {
    super.build(coreLibrary);
    library.name = name;
    library.procedures.sort(compareProcedures);
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
      if (otherUri?.scheme == "dart" && uri?.scheme != "dart") {
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
          ..exports.merge(other.exports,
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

  void addNativeMethod(KernelProcedureBuilder method) {
    nativeMethods.add(method);
  }

  int finishNativeMethods() {
    for (KernelProcedureBuilder method in nativeMethods) {
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
}
