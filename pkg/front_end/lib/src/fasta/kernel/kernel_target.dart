// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_target;

import 'dart:async' show Future;

import 'dart:io' show File, IOSink;

import 'package:kernel/ast.dart'
    show
        Arguments,
        AsyncMarker,
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
        Name,
        NamedExpression,
        NullLiteral,
        ProcedureKind,
        Program,
        RedirectingInitializer,
        Source,
        StringLiteral,
        SuperInitializer,
        Throw,
        TypeParameter,
        VariableDeclaration,
        VariableGet,
        VoidType;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/text/ast_to_text.dart' show Printer;

import 'package:kernel/transformations/erasure.dart' show Erasure;

import 'package:kernel/transformations/continuation.dart' as transformAsync;

import 'package:kernel/transformations/mixin_full_resolution.dart'
    show MixinFullResolution;

import 'package:kernel/transformations/setup_builtin_library.dart'
    as setup_builtin_library;

import 'package:kernel/type_algebra.dart' show substitute;

import '../source/source_loader.dart' show SourceLoader;

import '../source/source_class_builder.dart' show SourceClassBuilder;

import '../target_implementation.dart' show TargetImplementation;

import '../translate_uri.dart' show TranslateUri;

import '../dill/dill_target.dart' show DillTarget;

import '../errors.dart'
    show InputError, internalError, reportCrash, resetCrashReporting;

import '../util/relativize.dart' show relativizeUri;

import '../compiler_context.dart' show CompilerContext;

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
        MixinApplicationBuilder,
        NamedMixinApplicationBuilder,
        NamedTypeBuilder,
        TypeBuilder,
        TypeVariableBuilder;

import 'verifier.dart' show verifyProgram;

class KernelTarget extends TargetImplementation {
  final DillTarget dillTarget;

  /// Shared with [CompilerContext].
  final Map<String, Source> uriToSource;

  SourceLoader<Library> loader;
  Program program;

  final List errors = [];

  final TypeBuilder dynamicType =
      new KernelNamedTypeBuilder("dynamic", null, -1, null);

  KernelTarget(DillTarget dillTarget, TranslateUri uriTranslator,
      [Map<String, Source> uriToSource])
      : dillTarget = dillTarget,
        uriToSource = uriToSource ?? CompilerContext.current.uriToSource,
        super(dillTarget.ticker, uriTranslator) {
    resetCrashReporting();
    loader = createLoader();
  }

  void addError(file, int charOffset, String message) {
    Uri uri = file is String ? Uri.parse(file) : file;
    InputError error = new InputError(uri, charOffset, message);
    print(error.format());
    errors.add(error);
  }

  SourceLoader<Library> createLoader() => new SourceLoader<Library>(this);

  void addSourceInformation(
      Uri uri, List<int> lineStarts, List<int> sourceCode) {
    String fileUri = relativizeUri(uri);
    uriToSource[fileUri] = new Source(lineStarts, sourceCode);
  }

  void read(Uri uri) {
    loader.read(uri);
  }

  LibraryBuilder createLibraryBuilder(Uri uri, Uri fileUri) {
    if (dillTarget.isLoaded) {
      var builder = dillTarget.loader.builders[uri];
      if (builder != null) {
        return builder;
      }
    }
    return new KernelLibraryBuilder(uri, fileUri, loader);
  }

  void addDirectSupertype(ClassBuilder cls, Set<ClassBuilder> set) {
    if (cls == null) return;
    TypeBuilder supertype = cls.supertype;
    add(NamedTypeBuilder type) {
      Builder builder = type.builder;
      if (builder is ClassBuilder) {
        set.add(builder);
      }
    }

    if (supertype == null) {
      // OK.
    } else if (supertype is MixinApplicationBuilder) {
      add(supertype.supertype);
      for (NamedTypeBuilder t in supertype.mixins) {
        add(t);
      }
    } else if (supertype is NamedTypeBuilder) {
      add(supertype);
    } else {
      internalError("Unhandled: ${supertype.runtimeType}");
    }
    if (cls.interfaces != null) {
      for (NamedTypeBuilder t in cls.interfaces) {
        add(t);
      }
    }
  }

  List<ClassBuilder> collectAllClasses() {
    List<ClassBuilder> result = <ClassBuilder>[];
    loader.builders.forEach((Uri uri, LibraryBuilder library) {
      library.members.forEach((String name, Builder member) {
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
      library.members.forEach((String name, Builder member) {
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
    builder.supertype = new KernelNamedTypeBuilder("Object", null,
        builder.charOffset, builder.fileUri ?? Uri.parse(cls.fileUri))
      ..builder = objectClassBuilder;
    builder.interfaces = null;
  }

  Future<Program> handleInputError(Uri uri, InputError error,
      {bool isFullProgram}) {
    if (error != null) {
      String message = error.format();
      print(message);
      errors.add(message);
    }
    program = erroneousProgram(isFullProgram);
    return uri == null
        ? new Future<Program>.value(program)
        : writeLinkedProgram(uri, program, isFullProgram: isFullProgram);
  }

  Future<Program> writeOutline(Uri uri) async {
    if (loader.first == null) return null;
    try {
      await loader.buildOutlines();
      loader.coreLibrary
          .becomeCoreLibrary(const DynamicType(), const VoidType());
      dynamicType.bind(loader.coreLibrary.members["dynamic"]);
      loader.resolveParts();
      loader.computeLibraryScopes();
      loader.resolveTypes();
      loader.buildProgram();
      loader.checkSemantics();
      List<SourceClassBuilder> sourceClasses = collectAllSourceClasses();
      installDefaultSupertypes();
      installDefaultConstructors(sourceClasses);
      loader.resolveConstructors();
      loader.finishTypeVariables(objectClassBuilder);
      program = link(new List<Library>.from(loader.libraries));
      loader.computeHierarchy(program);
      loader.checkOverrides(sourceClasses);
      if (uri == null) return program;
      return await writeLinkedProgram(uri, program, isFullProgram: false);
    } on InputError catch (e) {
      return handleInputError(uri, e, isFullProgram: false);
    } catch (e, s) {
      return reportCrash(e, s, loader?.currentUriForCrashReporting);
    }
  }

  Future<Program> writeProgram(Uri uri,
      {bool dumpIr: false, bool verify: false}) async {
    if (loader.first == null) return null;
    if (errors.isNotEmpty) {
      return handleInputError(uri, null, isFullProgram: true);
    }
    try {
      await loader.buildBodies();
      loader.finishStaticInvocations();
      finishAllConstructors();
      loader.finishNativeMethods();
      transformMixinApplications();
      // TODO(ahe): Don't call this from two different places.
      setup_builtin_library.transformProgram(program);
      otherTransformations();
      if (dumpIr) this.dumpIr();
      if (verify) this.verify();
      errors.addAll(loader.collectCompileTimeErrors().map((e) => e.format()));
      if (errors.isNotEmpty) {
        return handleInputError(uri, null, isFullProgram: true);
      }
      if (uri == null) return program;
      return await writeLinkedProgram(uri, program, isFullProgram: true);
    } on InputError catch (e) {
      return handleInputError(uri, e, isFullProgram: true);
    } catch (e, s) {
      return reportCrash(e, s, loader?.currentUriForCrashReporting);
    }
  }

  Future writeDepsFile(Uri output, Uri depsFile,
      {Iterable<Uri> extraDependencies}) async {
    String toRelativeFilePath(Uri uri) {
      return Uri.parse(relativizeUri(uri)).toFilePath();
    }

    if (loader.first == null) return null;
    StringBuffer sb = new StringBuffer();
    sb.write(toRelativeFilePath(output));
    sb.write(":");
    Set<String> allDependencies = new Set<String>();
    allDependencies.addAll(loader.getDependencies().map(toRelativeFilePath));
    if (extraDependencies != null) {
      allDependencies.addAll(extraDependencies.map(toRelativeFilePath));
    }
    for (String path in allDependencies) {
      sb.write(" ");
      sb.write(path);
    }
    sb.writeln();
    await new File.fromUri(depsFile).writeAsString("$sb");
    ticker.logMs("Wrote deps file");
  }

  Program erroneousProgram(bool isFullProgram) {
    Uri uri = loader.first?.uri ?? Uri.parse("error:error");
    Uri fileUri = loader.first?.fileUri ?? uri;
    KernelLibraryBuilder library =
        new KernelLibraryBuilder(uri, fileUri, loader);
    loader.first = library;
    if (isFullProgram) {
      // If this is an outline, we shouldn't add an executable main
      // method. Similarly considerations apply to separate compilation. It
      // could also make sense to add a way to mark .dill files as having
      // compile-time errors.
      KernelProcedureBuilder mainBuilder = new KernelProcedureBuilder(
          null,
          0,
          null,
          "main",
          null,
          null,
          AsyncMarker.Sync,
          ProcedureKind.Method,
          library,
          -1,
          -1,
          -1);
      library.addBuilder(mainBuilder.name, mainBuilder, -1);
      mainBuilder.body = new ExpressionStatement(
          new Throw(new StringLiteral("${errors.join('\n')}")));
    }
    library.build();
    return link(<Library>[library.library]);
  }

  /// Creates a program by combining [libraries] with the libraries of
  /// `dillTarget.loader.program`.
  Program link(List<Library> libraries) {
    Map<String, Source> uriToSource =
        new Map<String, Source>.from(this.uriToSource);

    final Program binary = dillTarget.loader.program;
    if (binary != null) {
      libraries.addAll(binary.libraries);
      uriToSource.addAll(binary.uriToSource);
    }

    // TODO(ahe): Remove this line. Kernel seems to generate a default line map
    // that used when there's no fileUri on an element. Instead, ensure all
    // elements have a fileUri.
    uriToSource[""] = new Source(<int>[0], const <int>[]);
    Program program = new Program(libraries, uriToSource);
    if (loader.first != null) {
      Builder builder = loader.first.members["main"];
      if (builder is KernelProcedureBuilder) {
        program.mainMethod = builder.procedure;
      }
    }
    if (errors.isEmpty || dillTarget.isLoaded) {
      setup_builtin_library.transformProgram(program);
    }
    ticker.logMs("Linked program");
    return program;
  }

  Future<Program> writeLinkedProgram(Uri uri, Program program,
      {bool isFullProgram}) async {
    File output = new File.fromUri(uri);
    IOSink sink = output.openWrite();
    try {
      new BinaryPrinter(sink).writeProgramFile(program);
      program.unbindCanonicalNames();
    } finally {
      await sink.close();
    }
    if (isFullProgram) {
      ticker.logMs("Wrote program to ${uri.toFilePath()}");
    } else {
      ticker.logMs("Wrote outline to ${uri.toFilePath()}");
    }
    return null;
  }

  void installDefaultSupertypes() {
    Class objectClass = this.objectClass;
    loader.builders.forEach((Uri uri, LibraryBuilder library) {
      library.members.forEach((String name, Builder builder) {
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

  KernelClassBuilder get objectClassBuilder {
    return loader.coreLibrary.exports["Object"];
  }

  Class get objectClass => objectClassBuilder.cls;

  /// If [builder] doesn't have a constructors, install the defaults.
  void installDefaultConstructor(SourceClassBuilder builder) {
    if (builder.cls.isMixinApplication) {
      // We have to test if builder.cls is a mixin application. [builder] may
      // think it's a mixin application, but if its mixed-in type couldn't be
      // resolved, the target class won't be a mixin application and we need
      // to add a default constructor to complete error recovery.
      return;
    }
    if (builder.constructors.isNotEmpty) return;

    /// Quotes below are from [Dart Programming Language Specification, 4th
    /// Edition](
    /// https://ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    if (builder is NamedMixinApplicationBuilder) {
      /// >A mixin application of the form S with M; defines a class C with
      /// >superclass S.
      /// >...

      /// >Let LM be the library in which M is declared. For each generative
      /// >constructor named qi(Ti1 ai1, . . . , Tiki aiki), i in 1..n of S
      /// >that is accessible to LM , C has an implicitly declared constructor
      /// >named q'i = [C/S]qi of the form q'i(ai1,...,aiki) :
      /// >super(ai1,...,aiki);.
      Builder supertype = builder;
      while (supertype is NamedMixinApplicationBuilder) {
        NamedMixinApplicationBuilder named = supertype;
        TypeBuilder type = named.mixinApplication;
        if (type is MixinApplicationBuilder) {
          MixinApplicationBuilder t = type;
          type = t.supertype;
        }
        if (type is NamedTypeBuilder) {
          supertype = type.builder;
        } else {
          internalError("Unhandled: ${type.runtimeType}");
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
        internalError("Unhandled: ${supertype.runtimeType}");
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
        name: new Name(""));
  }

  void finishAllConstructors() {
    Class objectClass = this.objectClass;
    for (SourceClassBuilder builder in collectAllSourceClasses()) {
      Class cls = builder.target;
      if (cls != objectClass) {
        finishConstructors(cls);
      }
    }
    ticker.logMs("Finished constructors");
  }

  /// Ensure constructors of [cls] have the correct initializers and other
  /// requirements.
  void finishConstructors(Class cls) {
    /// Quotes below are from [Dart Programming Language Specification, 4th
    /// Edition](http://www.ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf):
    Constructor superTarget;
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
    for (Constructor constructor in cls.constructors) {
      if (!isRedirectingGenerativeConstructor(constructor)) {
        /// >If no superinitializer is provided, an implicit superinitializer
        /// >of the form super() is added at the end of k’s initializer list,
        /// >unless the enclosing class is class Object.
        if (!constructor.initializers.any(isSuperinitializerOrInvalid)) {
          superTarget ??= defaultSuperConstructor(cls);
          Initializer initializer;
          if (superTarget == null) {
            addError(
                constructor.enclosingClass.fileUri,
                constructor.fileOffset,
                "${cls.superclass.name} has no constructor that takes no"
                " arguments.");
            initializer = new InvalidInitializer();
          } else {
            initializer =
                new SuperInitializer(superTarget, new Arguments.empty());
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
          addError(constructor.enclosingClass.fileUri, constructor.fileOffset,
              "Constructor is marked 'const' so all fields must be final.");
          for (Field field in nonFinalFields) {
            addError(constructor.enclosingClass.fileUri, field.fileOffset,
                "Field isn't final, but constructor is 'const'.");
          }
          nonFinalFields.clear();
        }
      }
    }
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
              new FieldInitializer(field, new NullLiteral());
          initializer.parent = constructor;
          constructor.initializers.insert(0, initializer);
        }
      }
    });
  }

  void transformMixinApplications() {
    new MixinFullResolution().transform(program);
    ticker.logMs("Transformed mixin applications");
  }

  void otherTransformations() {
    // TODO(ahe): Don't generate type variables in the first place.
    program.accept(new Erasure());
    ticker.logMs("Erased type variables in generic methods");
    // TODO(kmillikin): Make this run on a per-method basis.
    transformAsync.transformProgram(program);
    ticker.logMs("Transformed async methods");
  }

  void dumpIr() {
    StringBuffer sb = new StringBuffer();
    for (Library library in loader.libraries) {
      Printer printer = new Printer(sb);
      printer.writeLibraryFile(library);
    }
    print("$sb");
    ticker.logMs("Dumped IR");
  }

  void verify() {
    errors.addAll(verifyProgram(program));
    ticker.logMs("Verified program");
  }
}

bool isSuperinitializerOrInvalid(Initializer initializer) {
  return initializer is SuperInitializer || initializer is InvalidInitializer;
}

bool isRedirectingGenerativeConstructor(Constructor constructor) {
  List<Initializer> initializers = constructor.initializers;
  return initializers.length == 1 &&
      initializers.single is RedirectingInitializer;
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
