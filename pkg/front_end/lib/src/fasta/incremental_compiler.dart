// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.incremental_compiler;

import 'dart:async' show Future;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import '../api_prototype/file_system.dart' show FileSystemEntity;

import 'package:kernel/kernel.dart'
    show
        AsyncMarker,
        Component,
        DartType,
        DynamicType,
        InterfaceType,
        Library,
        LibraryPart,
        NamedNode,
        Procedure,
        ProcedureKind,
        Source,
        TypeParameter;

import '../api_prototype/incremental_kernel_generator.dart'
    show CompilationPosition, isLegalIdentifier, IncrementalKernelGenerator;

import 'builder/builder.dart' show LibraryBuilder;

import 'builder_graph.dart' show BuilderGraph;

import 'compiler_context.dart' show CompilerContext;

import 'dill/dill_library_builder.dart' show DillLibraryBuilder;

import 'dill/dill_target.dart' show DillTarget;

import 'kernel/kernel_incremental_target.dart'
    show KernelIncrementalTarget, KernelIncrementalTargetErroneousComponent;

import 'library_graph.dart' show LibraryGraph;

import 'kernel/kernel_library_builder.dart' show KernelLibraryBuilder;

import 'source/source_library_builder.dart' show SourceLibraryBuilder;

import 'ticker.dart' show Ticker;

import 'uri_translator.dart' show UriTranslator;

import 'modifier.dart' as Modifier;

import '../scanner/token.dart' show Token;

import 'scanner/error_token.dart' show ErrorToken;

import 'scanner/string_scanner.dart' show StringScanner;

import 'dill/built_type_builder.dart' show BuiltTypeBuilder;

import 'kernel/kernel_formal_parameter_builder.dart'
    show KernelFormalParameterBuilder;

import 'kernel/kernel_procedure_builder.dart' show KernelProcedureBuilder;

import 'builder/class_builder.dart' show ClassBuilder;

import 'kernel/kernel_shadow_ast.dart' show ShadowTypeInferenceEngine;

import 'kernel/body_builder.dart' show BodyBuilder;

import 'kernel/kernel_type_variable_builder.dart'
    show KernelTypeVariableBuilder;

import 'parser/parser.dart' show Parser;

import 'parser/member_kind.dart' show MemberKind;

import 'scope.dart' show Scope;

import 'type_inference/type_inferrer.dart' show TypeInferrer;

class IncrementalCompilationPosition implements CompilationPosition {
  final NamedNode kernelNode;
  final LibraryBuilder libraryBuilder; // will not be null
  final ClassBuilder classBuilder; // may be null if not inside a class

  IncrementalCompilationPosition(
      this.kernelNode, this.libraryBuilder, this.classBuilder);
}

class IncrementalCompiler implements IncrementalKernelGenerator {
  final CompilerContext context;

  final Ticker ticker;

  Set<Uri> invalidatedUris = new Set<Uri>();

  DillTarget dillLoadedData;
  Map<Uri, Source> dillLoadedDataUriToSource = <Uri, Source>{};
  Map<Uri, LibraryBuilder> platformBuilders;
  Map<Uri, LibraryBuilder> userBuilders;
  final Uri initializeFromDillUri;
  bool initializedFromDill = false;

  KernelIncrementalTarget userCode;

  IncrementalCompiler(this.context, [this.initializeFromDillUri])
      : ticker = context.options.ticker;

  @override
  Future<Component> computeDelta(
      {Uri entryPoint, bool fullComponent: false}) async {
    ticker.reset();
    entryPoint ??= context.options.inputs.single;
    return context.runInContext<Future<Component>>((CompilerContext c) async {
      IncrementalCompilerData data = new IncrementalCompilerData();

      bool bypassCache = false;
      if (this.invalidatedUris.contains(c.options.packagesUri)) {
        bypassCache = true;
      }
      UriTranslator uriTranslator =
          await c.options.getUriTranslator(bypassCache: bypassCache);
      ticker.logMs("Read packages file");

      if (dillLoadedData == null) {
        List<int> summaryBytes = await c.options.loadSdkSummaryBytes();
        int bytesLength = prepareSummary(summaryBytes, uriTranslator, c, data);
        if (initializeFromDillUri != null) {
          try {
            bytesLength +=
                await initializeFromDill(summaryBytes, uriTranslator, c, data);
          } catch (e) {
            // We might have loaded x out of y libraries into the component.
            // To avoid any unforeseen problems start over.
            bytesLength = prepareSummary(summaryBytes, uriTranslator, c, data);
          }
        }
        appendLibraries(data, bytesLength);

        try {
          await dillLoadedData.buildOutlines();
        } catch (e) {
          if (!initializedFromDill) rethrow;

          // Retry without initializing from dill.
          initializedFromDill = false;
          data.reset();
          bytesLength = prepareSummary(summaryBytes, uriTranslator, c, data);
          appendLibraries(data, bytesLength);
          await dillLoadedData.buildOutlines();
        }
        summaryBytes = null;
        userBuilders = <Uri, LibraryBuilder>{};
        platformBuilders = <Uri, LibraryBuilder>{};
        dillLoadedData.loader.builders.forEach((uri, builder) {
          if (builder.uri.scheme == "dart") {
            platformBuilders[uri] = builder;
          } else {
            userBuilders[uri] = builder;
          }
        });
        if (userBuilders.isEmpty) userBuilders = null;
      }

      Set<Uri> invalidatedUris = this.invalidatedUris.toSet();
      this.invalidatedUris.clear();
      if (fullComponent) {
        invalidatedUris.add(entryPoint);
      }

      List<LibraryBuilder> reusedLibraries =
          computeReusedLibraries(invalidatedUris, uriTranslator);
      Set<Uri> reusedLibraryUris =
          new Set<Uri>.from(reusedLibraries.map((b) => b.uri));
      for (Uri uri in new Set<Uri>.from(dillLoadedData.loader.builders.keys)
        ..removeAll(reusedLibraryUris)) {
        dillLoadedData.loader.builders.remove(uri);
        userBuilders?.remove(uri);
      }

      if (userCode != null) {
        ticker.logMs("Decided to reuse ${reusedLibraries.length}"
            " of ${userCode.loader.builders.length} libraries");
      }

      reusedLibraries.addAll(platformBuilders.values);

      KernelIncrementalTarget userCodeOld = userCode;
      userCode = new KernelIncrementalTarget(
          c.fileSystem, false, dillLoadedData, uriTranslator,
          uriToSource: c.uriToSource);

      for (LibraryBuilder library in reusedLibraries) {
        userCode.loader.builders[library.uri] = library;
        if (library.uri.scheme == "dart" && library.uri.path == "core") {
          userCode.loader.coreLibrary = library;
        }
      }

      Component componentWithDill;
      try {
        userCode.read(entryPoint);
        await userCode.buildOutlines();

        // This is not the full component. It is the component including all
        // libraries loaded from .dill files.
        componentWithDill =
            await userCode.buildComponent(verify: c.options.verify);
      } on KernelIncrementalTargetErroneousComponent {
        List<Library> librariesWithSdk = userCode.component.libraries;
        List<Library> compiledLibraries = <Library>[];
        for (Library lib in librariesWithSdk) {
          if (lib.importUri.scheme == "dart") continue;
          compiledLibraries.add(lib);
          break;
        }
        userCode.loader.builders.clear();
        userCode = userCodeOld;
        return new Component(
            libraries: compiledLibraries, uriToSource: <Uri, Source>{});
      }
      if (componentWithDill != null) {
        userCodeOld?.loader?.releaseAncillaryResources();
        userCodeOld?.loader?.builders?.clear();
        userCodeOld = null;
      }

      List<Library> compiledLibraries =
          new List<Library>.from(userCode.loader.libraries);
      Map<Uri, Source> uriToSource =
          new Map<Uri, Source>.from(dillLoadedDataUriToSource);
      uriToSource.addAll(userCode.uriToSource);
      Procedure mainMethod = componentWithDill == null
          ? data.userLoadedUriMain
          : componentWithDill.mainMethod;

      List<Library> outputLibraries;
      if (data.includeUserLoadedLibraries || fullComponent) {
        outputLibraries = computeTransitiveClosure(
            compiledLibraries, mainMethod, entryPoint, reusedLibraries, data);
      } else {
        outputLibraries = compiledLibraries;
      }

      if (componentWithDill == null) {
        userCode.loader.builders.clear();
        userCode = userCodeOld;
      }

      // This is the incremental component.
      return new Component(libraries: outputLibraries, uriToSource: uriToSource)
        ..mainMethod = mainMethod;
    });
  }

  List<Library> computeTransitiveClosure(
      List<Library> inputLibraries,
      Procedure mainMethod,
      Uri entry,
      List<LibraryBuilder> reusedLibraries,
      IncrementalCompilerData data) {
    List<Library> result = new List<Library>.from(inputLibraries);
    Map<Uri, Library> libraryMap = <Uri, Library>{};
    for (Library library in inputLibraries) {
      libraryMap[library.importUri] = library;
    }
    List<Uri> worklist = new List<Uri>.from(libraryMap.keys);
    worklist.add(mainMethod?.enclosingLibrary?.importUri);
    if (entry != null) {
      worklist.add(entry);
    }

    Map<Uri, Library> potentiallyReferencedLibraries = <Uri, Library>{};
    for (LibraryBuilder library in reusedLibraries) {
      if (library.uri.scheme == "dart") continue;
      Library lib = library.target;
      potentiallyReferencedLibraries[library.uri] = lib;
      libraryMap[library.uri] = lib;
    }

    LibraryGraph graph = new LibraryGraph(libraryMap);
    while (worklist.isNotEmpty && potentiallyReferencedLibraries.isNotEmpty) {
      Uri uri = worklist.removeLast();
      if (libraryMap.containsKey(uri)) {
        for (Uri neighbor in graph.neighborsOf(uri)) {
          worklist.add(neighbor);
        }
        libraryMap.remove(uri);
        Library library = potentiallyReferencedLibraries.remove(uri);
        if (library != null) {
          result.add(library);
        }
      }
    }

    for (Uri uri in potentiallyReferencedLibraries.keys) {
      if (uri.scheme == "package") continue;
      userCode.loader.builders.remove(uri);
    }

    return result;
  }

  int prepareSummary(List<int> summaryBytes, UriTranslator uriTranslator,
      CompilerContext c, IncrementalCompilerData data) {
    dillLoadedData = new DillTarget(ticker, uriTranslator, c.options.target);
    int bytesLength = 0;

    if (summaryBytes != null) {
      ticker.logMs("Read ${c.options.sdkSummary}");
      data.component = new Component();
      new BinaryBuilder(summaryBytes, disableLazyReading: false)
          .readComponent(data.component);
      ticker.logMs("Deserialized ${c.options.sdkSummary}");
      bytesLength += summaryBytes.length;
    }

    return bytesLength;
  }

  // This procedure will try to load the dill file and will crash if it cannot.
  Future<int> initializeFromDill(
      List<int> summaryBytes,
      UriTranslator uriTranslator,
      CompilerContext c,
      IncrementalCompilerData data) async {
    int bytesLength = 0;
    FileSystemEntity entity =
        c.options.fileSystem.entityForUri(initializeFromDillUri);
    if (await entity.exists()) {
      List<int> initializationBytes = await entity.readAsBytes();
      if (initializationBytes != null) {
        ticker.logMs("Read $initializeFromDillUri");

        Set<Uri> sdkUris = data.component.uriToSource.keys.toSet();

        // We're going to output all we read here so lazy loading it
        // doesn't make sense.
        new BinaryBuilder(initializationBytes, disableLazyReading: true)
            .readComponent(data.component);

        // Check the any package-urls still point to the same file
        // (e.g. the package still exists and hasn't been updated).
        for (Library lib in data.component.libraries) {
          if (lib.importUri.scheme == "package" &&
              uriTranslator.translate(lib.importUri, false) != lib.fileUri) {
            // Package has been removed or updated.
            // This library should be thrown away.
            // Everything that depends on it should be thrown away.
            // TODO(jensj): Anything that doesn't depend on it can be kept.
            // For now just don't initialize from this dill.
            throw "Changed package";
          }
        }

        initializedFromDill = true;
        bytesLength += initializationBytes.length;
        data.userLoadedUriMain = data.component.mainMethod;
        data.includeUserLoadedLibraries = true;
        for (Uri uri in data.component.uriToSource.keys) {
          if (sdkUris.contains(uri)) continue;
          dillLoadedDataUriToSource[uri] = data.component.uriToSource[uri];
        }
      }
    }
    return bytesLength;
  }

  void appendLibraries(IncrementalCompilerData data, int bytesLength) {
    if (data.component != null) {
      dillLoadedData.loader
          .appendLibraries(data.component, byteCount: bytesLength);
    }
    ticker.logMs("Appended libraries");
  }

  IncrementalCompilationPosition resolveCompilationPosition(Uri libraryUri,
      [String className]) {
    if (userCode == null || dillLoadedData == null) return null;

    // Find library.
    LibraryBuilder enclosingLibrary = userCode.loader.builders[libraryUri];
    if (enclosingLibrary == null) return null;

    if (className == null) {
      return new IncrementalCompilationPosition(
          enclosingLibrary.target, enclosingLibrary, null);
    }

    ClassBuilder classBuilder = enclosingLibrary.scopeBuilder[className];
    if (classBuilder == null) return null;

    return new IncrementalCompilationPosition(
        classBuilder.target, enclosingLibrary, classBuilder);
  }

  @override
  Future<Procedure> compileExpression(
      String expression,
      Map<String, DartType> definitions,
      List<TypeParameter> typeDefinitions,
      covariant IncrementalCompilationPosition position,
      [bool isStatic = false]) async {
    assert(dillLoadedData != null && userCode != null);

    dillLoadedData.loader.seenMessages.clear();
    userCode.loader.seenMessages.clear();

    for (TypeParameter typeParam in typeDefinitions) {
      if (!isLegalIdentifier(typeParam.name)) return null;
    }
    for (String name in definitions.keys) {
      if (!isLegalIdentifier(name)) return null;
    }

    String expressionPrefix =
        '(${definitions.keys.map((name) => "dynamic $name").join(",")}) =>';

    return context.runInContext((CompilerContext c) async {
      // Find library builder or report error.
      bool inClass = position.classBuilder != null;
      LibraryBuilder enclosingLibraryBuilder = position.libraryBuilder;
      ClassBuilder classBuilder = position.classBuilder;
      Library enclosingLibrary = position.libraryBuilder.target;

      dillLoadedData.loader.coreTypes = userCode.loader.coreTypes;

      // Create a synthetic KernelLibraryBuilder to hold the compiled procedure.
      // This ensures that the uri and character offset positions inside the
      // expression refer to the the expression text, and not to random
      // positions in the enclosing library's source.
      Uri debugExprUri = new Uri(
          scheme: "org-dartlang-debug", path: "synthetic_debug_expression");
      KernelLibraryBuilder kernelLibraryBuilder = new KernelLibraryBuilder(
          debugExprUri,
          debugExprUri,
          userCode.loader,
          /*actualOrigin=*/ null,
          enclosingLibrary);

      // Parse the function prefix.
      StringScanner scanner = new StringScanner(expressionPrefix);
      Token startToken = scanner.tokenize();
      assert(startToken is! ErrorToken);
      assert(!scanner.hasErrors);

      // Parse the expression. By parsing the expression separately from the
      // function prefix, we ensure that the offsets for tokens coming from the
      // expression are correct.
      scanner = new StringScanner(expression);
      Token expressionStartToken = scanner.tokenize();
      while (expressionStartToken is ErrorToken) {
        ErrorToken token = expressionStartToken;
        // add compile time error
        kernelLibraryBuilder.addCompileTimeError(token.assertionMessage,
            token.charOffset, token.endOffset - token.charOffset, debugExprUri);
      }

      var functionLastToken = startToken;
      while (!functionLastToken.next.isEof) {
        functionLastToken.offset = -1;
        functionLastToken = functionLastToken.next;
      }
      functionLastToken.offset = -1;

      functionLastToken.next = expressionStartToken;
      expressionStartToken.previous = functionLastToken;

      // If we're in a library loaded from a dill file, we'll have to do some
      // extra work to get the scope setup.
      if (enclosingLibraryBuilder is DillLibraryBuilder) {
        dillLoadedData.loader.buildOutline(enclosingLibraryBuilder);
        Map<Uri, LibraryBuilder> libraries = <Uri, LibraryBuilder>{};
        if (userBuilders != null) libraries.addAll(userBuilders);
        libraries.addAll(platformBuilders);
        enclosingLibraryBuilder.addImportsToScope(libraries);
      }
      Scope scope =
          inClass ? classBuilder.scope : enclosingLibraryBuilder.scope;

      // Create a [ProcedureBuilder] and a [BodyBuilder] to parse the expression.
      dynamicType() => new BuiltTypeBuilder(new DynamicType());
      List<KernelFormalParameterBuilder> formalParameterBuilders =
          <KernelFormalParameterBuilder>[];
      definitions.forEach((name, type) {
        formalParameterBuilders.add(new KernelFormalParameterBuilder(
            null,
            Modifier.varMask,
            new BuiltTypeBuilder(type),
            name,
            false,
            kernelLibraryBuilder,
            -1));
      });
      List<KernelTypeVariableBuilder> typeVariableBuilders =
          <KernelTypeVariableBuilder>[];
      typeDefinitions.forEach((TypeParameter typeParam) {
        typeVariableBuilders.add(new KernelTypeVariableBuilder(
            typeParam.name,
            kernelLibraryBuilder,
            -1,
            new BuiltTypeBuilder(typeParam.bound),
            typeParam));
      });
      KernelProcedureBuilder procedureBuilder = new KernelProcedureBuilder(
          /*metadata=*/ null,
          isStatic ? Modifier.staticMask : Modifier.varMask,
          dynamicType(),
          "debugExpr",
          typeVariableBuilders,
          formalParameterBuilders,
          ProcedureKind.Method,
          kernelLibraryBuilder,
          /*charOffset=*/ -1,
          /*charOpenParenOffset=*/ -1,
          /*charEndOffset=*/ -1);
      Procedure procedure = procedureBuilder.build(kernelLibraryBuilder);
      procedure.parent =
          inClass ? classBuilder.target : kernelLibraryBuilder.target;
      scope = procedureBuilder.computeTypeParameterScope(scope);
      Scope formalParamScope =
          procedureBuilder.computeFormalParameterScope(scope);
      var typeInferenceEngine = new ShadowTypeInferenceEngine(
          null, /*strongMode=*/ context.options.strongMode);
      typeInferenceEngine.prepareTopLevel(
          userCode.loader.coreTypes, userCode.loader.hierarchy);
      InterfaceType thisType;
      if (inClass) {
        thisType = classBuilder.target.thisType;
      }
      TypeInferrer typeInferrer = typeInferenceEngine.createLocalTypeInferrer(
          debugExprUri, thisType, kernelLibraryBuilder);
      BodyBuilder bodyBuilder = new BodyBuilder(
          kernelLibraryBuilder,
          procedureBuilder,
          scope,
          formalParamScope,
          userCode.loader.hierarchy,
          userCode.loader.coreTypes,
          classBuilder,
          inClass && !isStatic,
          null /*uri*/,
          typeInferrer);
      bodyBuilder.scope = formalParamScope;

      // Parse the expression.
      MemberKind kind = inClass
          ? (isStatic ? MemberKind.StaticMethod : MemberKind.NonStaticMethod)
          : MemberKind.TopLevelMethod;
      Parser parser = new Parser(bodyBuilder);
      Token token = parser.syntheticPreviousToken(startToken);
      token = parser.parseFormalParametersOpt(token, kind);
      var formals = bodyBuilder.pop();
      bodyBuilder.checkEmpty(token.next.charOffset);
      parser.parseFunctionBody(
          token, /*isExpression=*/ true, /*allowAbstract=*/ false);
      var body = bodyBuilder.pop();
      bodyBuilder.checkEmpty(token.charOffset);
      bodyBuilder.finishFunction([], formals, AsyncMarker.Sync, body);

      return procedure;
    });
  }

  List<LibraryBuilder> computeReusedLibraries(
      Set<Uri> invalidatedUris, UriTranslator uriTranslator) {
    if (userCode == null && userBuilders == null) {
      return <LibraryBuilder>[];
    }

    // Maps all non-platform LibraryBuilders from their import URI.
    Map<Uri, LibraryBuilder> builders = <Uri, LibraryBuilder>{};

    // Invalidated URIs translated back to their import URI (package:, dart:,
    // etc.).
    List<Uri> invalidatedImportUris = <Uri>[];

    bool isInvalidated(Uri importUri, Uri fileUri) {
      if (invalidatedUris.contains(importUri) ||
          (importUri != fileUri && invalidatedUris.contains(fileUri))) {
        return true;
      }
      if (importUri.scheme == "package" &&
          uriTranslator.translate(importUri, false) != fileUri) {
        return true;
      }
      return false;
    }

    addBuilderAndInvalidateUris(Uri uri, LibraryBuilder library) {
      builders[uri] = library;
      if (isInvalidated(uri, library.target.fileUri)) {
        invalidatedImportUris.add(uri);
      }
      if (library is SourceLibraryBuilder) {
        for (LibraryBuilder part in library.parts) {
          if (isInvalidated(part.uri, part.fileUri)) {
            invalidatedImportUris.add(part.uri);
            builders[part.uri] = part;
          }
        }
      } else if (library is DillLibraryBuilder) {
        for (LibraryPart part in library.target.parts) {
          Uri partUri = library.uri.resolve(part.partUri);
          Uri fileUri = library.library.fileUri.resolve(part.partUri);
          if (isInvalidated(partUri, fileUri)) {
            invalidatedImportUris.add(partUri);
            builders[partUri] = library;
          }
        }
      }
    }

    userBuilders?.forEach(addBuilderAndInvalidateUris);
    if (userCode != null) {
      userCode.loader.builders.forEach(addBuilderAndInvalidateUris);
    }

    recordInvalidatedImportUrisForTesting(invalidatedImportUris);

    BuilderGraph graph = new BuilderGraph(builders);

    // Compute direct dependencies for each import URI (the reverse of the
    // edges returned by `graph.neighborsOf`).
    Map<Uri, Set<Uri>> directDependencies = <Uri, Set<Uri>>{};
    for (Uri vertex in graph.vertices) {
      for (Uri neighbor in graph.neighborsOf(vertex)) {
        (directDependencies[neighbor] ??= new Set<Uri>()).add(vertex);
      }
    }

    // Remove all dependencies of [invalidatedImportUris] from builders.
    List<Uri> workList = invalidatedImportUris;
    while (workList.isNotEmpty) {
      Uri removed = workList.removeLast();
      LibraryBuilder current = builders.remove(removed);
      // [current] is null if the corresponding key (URI) has already been
      // removed.
      if (current != null) {
        Set<Uri> s = directDependencies[current.uri];
        if (current.uri != removed) {
          if (s == null) {
            s = directDependencies[removed];
          } else {
            s.addAll(directDependencies[removed]);
          }
        }
        if (s != null) {
          // [s] is null for leaves.
          for (Uri dependency in s) {
            workList.add(dependency);
          }
        }
      }
    }

    // Builders contain mappings from part uri to builder, meaning the same
    // builder can exist multiple times in the values list.
    Set<Uri> seenUris = new Set<Uri>();
    List<LibraryBuilder> result = <LibraryBuilder>[];
    for (LibraryBuilder builder in builders.values) {
      if (builder.isPart) continue;
      // TODO(jensj/ahe): This line can probably go away once
      // https://dart-review.googlesource.com/47442 lands.
      if (builder.isPatch) continue;
      if (!seenUris.add(builder.uri)) continue;
      result.add(builder);
    }
    return result;
  }

  @override
  void invalidate(Uri uri) {
    invalidatedUris.add(uri);
  }

  void recordInvalidatedImportUrisForTesting(List<Uri> uris) {}
}

class IncrementalCompilerData {
  bool includeUserLoadedLibraries;
  Procedure userLoadedUriMain;
  Component component;

  IncrementalCompilerData() {
    reset();
  }

  reset() {
    includeUserLoadedLibraries = false;
    userLoadedUriMain = null;
    component = null;
  }
}
