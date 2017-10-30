// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_target;

import 'dart:async' show Future;

import 'package:kernel/ast.dart'
    show
        Arguments,
        Block,
        CanonicalName,
        Class,
        Constructor,
        DartType,
        DynamicType,
        EmptyStatement,
        Expression,
        ExpressionStatement,
        Field,
        FieldInitializer,
        FunctionNode,
        Initializer,
        InvalidInitializer,
        Library,
        ListLiteral,
        Name,
        NamedExpression,
        NullLiteral,
        ProcedureKind,
        Program,
        Source,
        Statement,
        StringLiteral,
        SuperInitializer,
        Throw,
        TypeParameter,
        VariableDeclaration,
        VariableGet,
        VoidType;

import 'package:kernel/type_algebra.dart' show substitute;

import '../../../file_system.dart' show FileSystem;

import '../compiler_context.dart' show CompilerContext;

import '../deprecated_problems.dart'
    show deprecated_InputError, reportCrash, resetCrashReporting;

import '../dill/dill_target.dart' show DillTarget;

import '../messages.dart'
    show
        LocatedMessage,
        messageConstConstructorNonFinalField,
        messageConstConstructorNonFinalFieldCause,
        templateSuperclassHasNoDefaultConstructor;

import '../problems.dart' show unhandled;

import '../severity.dart' show Severity;

import '../source/source_class_builder.dart' show SourceClassBuilder;

import '../source/source_loader.dart' show SourceLoader;

import '../target_implementation.dart' show TargetImplementation;

import '../uri_translator.dart' show UriTranslator;

import '../util/relativize.dart' show relativizeUri;

import 'kernel_builder.dart'
    show
        Builder,
        ClassBuilder,
        InvalidTypeBuilder,
        KernelClassBuilder,
        KernelLibraryBuilder,
        KernelNamedTypeBuilder,
        KernelProcedureBuilder,
        LibraryBuilder,
        MemberBuilder,
        NamedTypeBuilder,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder;

import 'metadata_collector.dart' show MetadataCollector;

import 'verifier.dart' show verifyProgram;

class KernelTarget extends TargetImplementation {
  /// The [FileSystem] which should be used to access files.
  final FileSystem fileSystem;

  /// Whether comments should be scanned and parsed.
  final bool includeComments;

  final DillTarget dillTarget;

  /// Shared with [CompilerContext].
  final Map<String, Source> uriToSource;

  /// The [MetadataCollector] to write metadata to.
  final MetadataCollector metadataCollector;

  SourceLoader<Library> loader;

  Program program;

  final List<LocatedMessage> errors = <LocatedMessage>[];

  final TypeBuilder dynamicType = new KernelNamedTypeBuilder("dynamic", null);

  bool get strongMode => backendTarget.strongMode;

  bool get disableTypeInference => backendTarget.disableTypeInference;

  KernelTarget(this.fileSystem, this.includeComments, DillTarget dillTarget,
      UriTranslator uriTranslator,
      {Map<String, Source> uriToSource, MetadataCollector metadataCollector})
      : dillTarget = dillTarget,
        uriToSource = uriToSource ?? CompilerContext.current.uriToSource,
        metadataCollector = metadataCollector,
        super(dillTarget.ticker, uriTranslator, dillTarget.backendTarget) {
    resetCrashReporting();
    loader = createLoader();
  }

  SourceLoader<Library> createLoader() =>
      new SourceLoader<Library>(fileSystem, includeComments, this);

  void addSourceInformation(
      Uri uri, List<int> lineStarts, List<int> sourceCode) {
    String fileUri = relativizeUri(uri);
    uriToSource[fileUri] = new Source(lineStarts, sourceCode);
  }

  void read(Uri uri) {
    loader.read(uri, -1);
  }

  @override
  LibraryBuilder createLibraryBuilder(
      Uri uri, Uri fileUri, KernelLibraryBuilder origin) {
    if (dillTarget.isLoaded) {
      var builder = dillTarget.loader.builders[uri];
      if (builder != null) {
        return builder;
      }
    }
    return new KernelLibraryBuilder(uri, fileUri, loader, origin);
  }

  void forEachDirectSupertype(ClassBuilder cls, void f(NamedTypeBuilder type)) {
    TypeBuilder supertype = cls.supertype;
    if (supertype is NamedTypeBuilder) {
      f(supertype);
    } else if (supertype != null) {
      unhandled("${supertype.runtimeType}", "forEachDirectSupertype",
          cls.charOffset, cls.fileUri);
    }
    if (cls.interfaces != null) {
      for (NamedTypeBuilder t in cls.interfaces) {
        f(t);
      }
    }
    if (cls.library.loader == loader &&
        // TODO(ahe): Implement DillClassBuilder.mixedInType and remove the
        // above check.
        cls.mixedInType != null) {
      f(cls.mixedInType);
    }
  }

  void addDirectSupertype(ClassBuilder cls, Set<ClassBuilder> set) {
    if (cls == null) return;
    forEachDirectSupertype(cls, (NamedTypeBuilder type) {
      Builder builder = type.builder;
      if (builder is ClassBuilder) {
        set.add(builder);
      }
    });
  }

  List<ClassBuilder> collectAllClasses() {
    List<ClassBuilder> result = <ClassBuilder>[];
    loader.builders.forEach((Uri uri, LibraryBuilder library) {
      library.forEach((String name, Builder member) {
        if (member is KernelClassBuilder) {
          result.add(member);
        }
      });
      // TODO(ahe): Translate this if needed:
      // if (library is KernelLibraryBuilder) {
      //   result.addAll(library.mixinApplicationClasses);
      // }
    });
    return result;
  }

  List<SourceClassBuilder> collectAllSourceClasses() {
    List<SourceClassBuilder> result = <SourceClassBuilder>[];
    loader.builders.forEach((Uri uri, LibraryBuilder library) {
      library.forEach((String name, Builder member) {
        if (member is SourceClassBuilder) {
          result.add(member);
        }
      });
    });
    return result;
  }

  void breakCycle(ClassBuilder builder) {
    Class cls = builder.target;
    cls.implementedTypes.clear();
    cls.supertype = null;
    cls.mixedInType = null;
    builder.supertype = new KernelNamedTypeBuilder("Object", null)
      ..bind(objectClassBuilder);
    builder.interfaces = null;
    builder.mixedInType = null;
  }

  void handleInputError(deprecated_InputError error, {bool isFullProgram}) {
    if (error != null) {
      LocatedMessage message = deprecated_InputError.toMessage(error);
      context.report(message, Severity.error);
      errors.add(message);
    }
    program = erroneousProgram(isFullProgram);
  }

  @override
  Future<Program> buildOutlines({CanonicalName nameRoot}) async {
    if (loader.first == null) return null;
    try {
      loader.createTypeInferenceEngine();
      await loader.buildOutlines();
      loader.coreLibrary
          .becomeCoreLibrary(const DynamicType(), const VoidType());
      dynamicType.bind(loader.coreLibrary["dynamic"]);
      loader.resolveParts();
      loader.computeLibraryScopes();
      loader.resolveTypes();
      loader.checkSemantics();
      loader.buildProgram();
      List<SourceClassBuilder> sourceClasses = collectAllSourceClasses();
      installDefaultSupertypes();
      installDefaultConstructors(sourceClasses);
      loader.resolveConstructors();
      loader.finishTypeVariables(objectClassBuilder);
      program =
          link(new List<Library>.from(loader.libraries), nameRoot: nameRoot);
      if (metadataCollector != null) {
        program.addMetadataRepository(metadataCollector.repository);
      }
      loader.computeHierarchy(program);
      loader.checkOverrides(sourceClasses);
      if (!loader.target.disableTypeInference) {
        loader.prepareTopLevelInference(sourceClasses);
        loader.performTopLevelInference(sourceClasses);
      }
    } on deprecated_InputError catch (e) {
      handleInputError(e, isFullProgram: false);
    } catch (e, s) {
      return reportCrash(e, s, loader?.currentUriForCrashReporting);
    }
    return program;
  }

  /// Build the kernel representation of the program loaded by this target. The
  /// program will contain full bodies for the code loaded from sources, and
  /// only references to the code loaded by the [DillTarget], which may or may
  /// not include method bodies (depending on what was loaded into that target,
  /// an outline or a full kernel program).
  ///
  /// If [verify], run the default kernel verification on the resulting program.
  @override
  Future<Program> buildProgram({bool verify: false}) async {
    if (loader.first == null) return null;
    if (errors.isNotEmpty) {
      handleInputError(null, isFullProgram: true);
      return program;
    }

    try {
      await loader.buildBodies();
      loader.finishStaticInvocations();
      loader.finishDeferredLoadTearoffs();
      finishAllConstructors();
      loader.finishNativeMethods();
      runBuildTransformations();

      if (verify) this.verify();
      if (errors.isNotEmpty) {
        handleInputError(null, isFullProgram: true);
      }
      handleRecoverableErrors(loader.unhandledErrors);
    } on deprecated_InputError catch (e) {
      handleInputError(e, isFullProgram: true);
    } catch (e, s) {
      return reportCrash(e, s, loader?.currentUriForCrashReporting);
    }
    return program;
  }

  /// Adds a synthetic field named `#errors` to the main library that contains
  /// [recoverableErrors] formatted.
  ///
  /// If [recoverableErrors] is empty, this method does nothing.
  ///
  /// If there's no main library, this method uses [erroneousProgram] to
  /// replace [program].
  void handleRecoverableErrors(List<LocatedMessage> recoverableErrors) {
    if (recoverableErrors.isEmpty) return;
    KernelLibraryBuilder mainLibrary = loader.first;
    if (mainLibrary == null) {
      program = erroneousProgram(true);
      return;
    }
    List<Expression> expressions = <Expression>[];
    for (LocatedMessage error in recoverableErrors) {
      errors.add(error);
      expressions.add(new StringLiteral(context.format(error, Severity.error)));
    }
    mainLibrary.library.addMember(new Field(new Name("#errors"),
        initializer: new ListLiteral(expressions, isConst: true),
        isConst: true,
        isStatic: true));
  }

  Program erroneousProgram(bool isFullProgram) {
    Uri uri = loader.first?.uri ?? Uri.parse("error:error");
    Uri fileUri = loader.first?.fileUri ?? uri;
    KernelLibraryBuilder library =
        new KernelLibraryBuilder(uri, fileUri, loader, null);
    loader.first = library;
    if (isFullProgram) {
      // If this is an outline, we shouldn't add an executable main
      // method. Similarly considerations apply to separate compilation. It
      // could also make sense to add a way to mark .dill files as having
      // compile-time errors.
      KernelProcedureBuilder mainBuilder = new KernelProcedureBuilder(null, 0,
          null, "#main", null, null, ProcedureKind.Method, library, -1, -1, -1);
      library.addBuilder(mainBuilder.name, mainBuilder, -1);
      mainBuilder.body = new Block(new List<Statement>.from(errors.map(
          (LocatedMessage message) => new ExpressionStatement(new Throw(
              new StringLiteral(context.format(message, Severity.error)))))));
    }
    library.build(loader.coreLibrary);
    return link(<Library>[library.library]);
  }

  /// Creates a program by combining [libraries] with the libraries of
  /// `dillTarget.loader.program`.
  Program link(List<Library> libraries, {CanonicalName nameRoot}) {
    Map<String, Source> uriToSource =
        new Map<String, Source>.from(this.uriToSource);

    libraries.addAll(dillTarget.loader.libraries);
    uriToSource.addAll(dillTarget.loader.uriToSource);

    // TODO(ahe): Remove this line. Kernel seems to generate a default line map
    // that used when there's no fileUri on an element. Instead, ensure all
    // elements have a fileUri.
    uriToSource[""] = new Source(<int>[0], const <int>[]);
    Program program = new Program(
        nameRoot: nameRoot, libraries: libraries, uriToSource: uriToSource);
    if (loader.first != null) {
      // TODO(sigmund): do only for full program
      Builder builder = loader.first.exportScope.lookup("main", -1, null);
      if (builder is KernelProcedureBuilder) {
        program.mainMethod = builder.procedure;
      }
    }

    ticker.logMs("Linked program");
    return program;
  }

  void installDefaultSupertypes() {
    Class objectClass = this.objectClass;
    loader.builders.forEach((Uri uri, LibraryBuilder library) {
      library.forEach((String name, Builder builder) {
        if (builder is SourceClassBuilder) {
          Class cls = builder.target;
          if (cls != objectClass) {
            cls.supertype ??= objectClass.asRawSupertype;
          }
          if (builder.isMixinApplication) {
            cls.mixedInType = builder.mixedInType.buildSupertype(library);
          }
        }
      });
    });
    ticker.logMs("Installed Object as implicit superclass");
  }

  void installDefaultConstructors(List<SourceClassBuilder> builders) {
    Class objectClass = this.objectClass;
    for (SourceClassBuilder builder in builders) {
      if (builder.target != objectClass) {
        installDefaultConstructor(builder);
      }
    }
    ticker.logMs("Installed default constructors");
  }

  KernelClassBuilder get objectClassBuilder => loader.coreLibrary["Object"];

  Class get objectClass => objectClassBuilder.cls;

  /// If [builder] doesn't have a constructors, install the defaults.
  void installDefaultConstructor(SourceClassBuilder builder) {
    if (builder.isMixinApplication && !builder.isNamedMixinApplication) return;
    if (builder.constructors.local.isNotEmpty) return;

    /// Quotes below are from [Dart Programming Language Specification, 4th
    /// Edition](
    /// https://ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    if (builder.isNamedMixinApplication) {
      /// >A mixin application of the form S with M; defines a class C with
      /// >superclass S.
      /// >...

      /// >Let LM be the library in which M is declared. For each generative
      /// >constructor named qi(Ti1 ai1, . . . , Tiki aiki), i in 1..n of S
      /// >that is accessible to LM , C has an implicitly declared constructor
      /// >named q'i = [C/S]qi of the form q'i(ai1,...,aiki) :
      /// >super(ai1,...,aiki);.
      TypeDeclarationBuilder supertype = builder;
      while (supertype.isMixinApplication) {
        SourceClassBuilder named = supertype;
        TypeBuilder type = named.supertype;
        if (type is NamedTypeBuilder) {
          supertype = type.builder;
        } else {
          unhandled("${type.runtimeType}", "installDefaultConstructor",
              builder.charOffset, builder.fileUri);
        }
      }
      if (supertype is KernelClassBuilder) {
        Map<TypeParameter, DartType> substitutionMap =
            computeKernelSubstitutionMap(
                builder.getSubstitutionMap(supertype, builder.fileUri,
                    builder.charOffset, dynamicType),
                builder.parent);
        if (supertype.cls.constructors.isEmpty) {
          builder.addSyntheticConstructor(makeDefaultConstructor());
        } else {
          for (Constructor constructor in supertype.cls.constructors) {
            builder.addSyntheticConstructor(makeMixinApplicationConstructor(
                builder.cls.mixin, constructor, substitutionMap));
          }
        }
      } else if (supertype is InvalidTypeBuilder) {
        builder.addSyntheticConstructor(makeDefaultConstructor());
      } else {
        unhandled("${supertype.runtimeType}", "installDefaultConstructor",
            builder.charOffset, builder.fileUri);
      }
    } else {
      /// >Iff no constructor is specified for a class C, it implicitly has a
      /// >default constructor C() : super() {}, unless C is class Object.
      // The superinitializer is installed below in [finishConstructors].
      builder.addSyntheticConstructor(makeDefaultConstructor());
    }
  }

  Map<TypeParameter, DartType> computeKernelSubstitutionMap(
      Map<TypeVariableBuilder, TypeBuilder> substitutionMap,
      LibraryBuilder library) {
    if (substitutionMap == null) return const <TypeParameter, DartType>{};
    Map<TypeParameter, DartType> result = <TypeParameter, DartType>{};
    substitutionMap
        .forEach((TypeVariableBuilder variable, TypeBuilder argument) {
      result[variable.target] = argument.build(library);
    });
    return result;
  }

  Constructor makeMixinApplicationConstructor(Class mixin,
      Constructor constructor, Map<TypeParameter, DartType> substitutionMap) {
    VariableDeclaration copyFormal(VariableDeclaration formal) {
      // TODO(ahe): Handle initializers.
      return new VariableDeclaration(formal.name,
          type: substitute(formal.type, substitutionMap),
          isFinal: formal.isFinal,
          isConst: formal.isConst);
    }

    List<VariableDeclaration> positionalParameters = <VariableDeclaration>[];
    List<VariableDeclaration> namedParameters = <VariableDeclaration>[];
    List<Expression> positional = <Expression>[];
    List<NamedExpression> named = <NamedExpression>[];
    for (VariableDeclaration formal
        in constructor.function.positionalParameters) {
      positionalParameters.add(copyFormal(formal));
      positional.add(new VariableGet(positionalParameters.last));
    }
    for (VariableDeclaration formal in constructor.function.namedParameters) {
      namedParameters.add(copyFormal(formal));
      named.add(new NamedExpression(
          formal.name, new VariableGet(namedParameters.last)));
    }
    FunctionNode function = new FunctionNode(new EmptyStatement(),
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: constructor.function.requiredParameterCount,
        returnType: const VoidType());
    SuperInitializer initializer = new SuperInitializer(
        constructor, new Arguments(positional, named: named));
    return new Constructor(function,
        name: constructor.name, initializers: <Initializer>[initializer]);
  }

  Constructor makeDefaultConstructor() {
    return new Constructor(
        new FunctionNode(new EmptyStatement(), returnType: const VoidType()),
        name: new Name(""),
        isSyntheticDefault: true);
  }

  void finishAllConstructors() {
    Class objectClass = this.objectClass;
    for (SourceClassBuilder builder in collectAllSourceClasses()) {
      Class cls = builder.target;
      if (cls != objectClass) {
        finishConstructors(builder);
      }
    }
    ticker.logMs("Finished constructors");
  }

  /// Ensure constructors of [cls] have the correct initializers and other
  /// requirements.
  void finishConstructors(SourceClassBuilder builder) {
    Class cls = builder.target;

    /// Quotes below are from [Dart Programming Language Specification, 4th
    /// Edition](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    List<Field> uninitializedFields = <Field>[];
    List<Field> nonFinalFields = <Field>[];
    for (Field field in cls.fields) {
      if (field.isInstanceMember && !field.isFinal) {
        nonFinalFields.add(field);
      }
      if (field.initializer == null) {
        uninitializedFields.add(field);
      }
    }
    Map<Constructor, List<FieldInitializer>> fieldInitializers =
        <Constructor, List<FieldInitializer>>{};
    Constructor superTarget;
    builder.constructors.forEach((String name, Builder member) {
      if (member.isFactory) return;
      MemberBuilder constructorBuilder = member;
      Constructor constructor = constructorBuilder.target;
      if (!constructorBuilder.isRedirectingGenerativeConstructor) {
        /// >If no superinitializer is provided, an implicit superinitializer
        /// >of the form super() is added at the end of k’s initializer list,
        /// >unless the enclosing class is class Object.
        if (constructor.initializers.isEmpty) {
          superTarget ??= defaultSuperConstructor(cls);
          Initializer initializer;
          if (superTarget == null) {
            builder.addCompileTimeError(
                templateSuperclassHasNoDefaultConstructor
                    .withArguments(cls.superclass.name),
                constructor.fileOffset);
            initializer = new InvalidInitializer();
          } else {
            initializer =
                new SuperInitializer(superTarget, new Arguments.empty())
                  ..isSynthetic = true;
          }
          constructor.initializers.add(initializer);
          initializer.parent = constructor;
        }
        if (constructor.function.body == null) {
          /// >If a generative constructor c is not a redirecting constructor
          /// >and no body is provided, then c implicitly has an empty body {}.
          /// We use an empty statement instead.
          constructor.function.body = new EmptyStatement();
          constructor.function.body.parent = constructor.function;
        }
        List<FieldInitializer> myFieldInitializers = <FieldInitializer>[];
        for (Initializer initializer in constructor.initializers) {
          if (initializer is FieldInitializer) {
            myFieldInitializers.add(initializer);
          }
        }
        fieldInitializers[constructor] = myFieldInitializers;
        if (constructor.isConst && nonFinalFields.isNotEmpty) {
          builder.addCompileTimeError(
              messageConstConstructorNonFinalField, constructor.fileOffset);
          for (Field field in nonFinalFields) {
            builder.addCompileTimeError(
                messageConstConstructorNonFinalFieldCause, field.fileOffset);
          }
          nonFinalFields.clear();
        }
      }
    });
    Set<Field> initializedFields;
    fieldInitializers.forEach(
        (Constructor constructor, List<FieldInitializer> initializers) {
      Iterable<Field> fields = initializers.map((i) => i.field);
      if (initializedFields == null) {
        initializedFields = new Set<Field>.from(fields);
      } else {
        initializedFields.addAll(fields);
      }
    });
    // Run through all fields that aren't initialized by any constructor, and
    // set their initializer to `null`.
    for (Field field in uninitializedFields) {
      if (initializedFields == null || !initializedFields.contains(field)) {
        field.initializer = new NullLiteral()..parent = field;
      }
    }
    // Run through all fields that are initialized by some constructor, and
    // make sure that all other constructors also initialize them.
    fieldInitializers.forEach(
        (Constructor constructor, List<FieldInitializer> initializers) {
      Iterable<Field> fields = initializers.map((i) => i.field);
      for (Field field in initializedFields.difference(fields.toSet())) {
        if (field.initializer == null) {
          FieldInitializer initializer =
              new FieldInitializer(field, new NullLiteral())
                ..isSynthetic = true;
          initializer.parent = constructor;
          constructor.initializers.insert(0, initializer);
        }
      }
    });
  }

  /// Run all transformations that are needed when building a program for the
  /// first time.
  void runBuildTransformations() {
    backendTarget.performModularTransformationsOnLibraries(
        loader.coreTypes, loader.hierarchy, loader.libraries,
        logger: (String msg) => ticker.logMs(msg));
    backendTarget.performGlobalTransformations(loader.coreTypes, program,
        logger: (String msg) => ticker.logMs(msg));
  }

  void verify() {
    errors.addAll(verifyProgram(program));
    ticker.logMs("Verified program");
  }

  /// Return `true` if the given [library] was built by this [KernelTarget]
  /// from sources, and not loaded from a [DillTarget].
  bool isSourceLibrary(Library library) {
    return loader.libraries.contains(library);
  }

  @override
  void readPatchFiles(KernelLibraryBuilder library) {
    assert(library.uri.scheme == "dart");
    List<Uri> patches = uriTranslator.getDartPatches(library.uri.path);
    if (patches != null) {
      KernelLibraryBuilder first;
      for (Uri patch in patches) {
        if (first == null) {
          first =
              library.loader.read(patch, -1, fileUri: patch, origin: library);
        } else {
          // If there's more than one patch file, it's interpreted as a part of
          // the patch library.
          KernelLibraryBuilder part =
              library.loader.read(patch, -1, fileUri: patch);
          first.parts.add(part);
          part.addPartOf(null, null, "${first.uri}");
        }
      }
    }
  }
}

/// Looks for a constructor call that matches `super()` from a constructor in
/// [cls]. Such a constructor may have optional arguments, but no required
/// arguments.
Constructor defaultSuperConstructor(Class cls) {
  Class superclass = cls.superclass;
  while (superclass != null && superclass.isMixinApplication) {
    superclass = superclass.superclass;
  }
  for (Constructor constructor in superclass.constructors) {
    if (constructor.name.name.isEmpty) {
      return constructor.function.requiredParameterCount == 0
          ? constructor
          : null;
    }
  }
  return null;
}
