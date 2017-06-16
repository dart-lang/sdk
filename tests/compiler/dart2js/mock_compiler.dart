// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock_compiler;

import 'dart:async';
import 'dart:collection';

import 'package:compiler/compiler_new.dart' as api;
import 'package:compiler/src/common/names.dart' show Uris;
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/elements/resolution_types.dart'
    show ResolutionDartType;
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/diagnostics/source_span.dart';
import 'package:compiler/src/diagnostics/spannable.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/visitor.dart';
import 'package:compiler/src/library_loader.dart' show LoadedLibraries;
import 'package:compiler/src/js_backend/lookup_map_analysis.dart'
    show LookupMapResolutionAnalysis;
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/options.dart' show CompilerOptions;
import 'package:compiler/src/resolution/members.dart';
import 'package:compiler/src/resolution/registry.dart';
import 'package:compiler/src/resolution/scope.dart';
import 'package:compiler/src/resolution/tree_elements.dart';
import 'package:compiler/src/resolved_uri_translator.dart';
import 'package:compiler/src/script.dart';
import 'package:compiler/src/tree/tree.dart';
import 'package:compiler/src/old_to_new_api.dart';
import 'parser_helper.dart';

import 'package:compiler/src/elements/modelx.dart'
    show ErroneousElementX, FunctionElementX;

import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/common/tasks.dart' show Measurer;

import 'package:compiler/src/deferred_load.dart'
    show DeferredLoadTask, OutputUnit;

import 'mock_libraries.dart';
import 'diagnostic_helper.dart';

export 'diagnostic_helper.dart';

final Uri PATCH_CORE = new Uri(scheme: 'patch', path: 'core');

typedef String LibrarySourceProvider(Uri uri);

class MockCompiler extends Compiler {
  api.CompilerDiagnostics diagnosticHandler;

  /// Expected number of warnings. If `null`, the number of warnings is
  /// not checked.
  final int expectedWarnings;

  /// Expected number of errors. If `null`, the number of errors is not checked.
  final int expectedErrors;
  final Map<String, SourceFile> sourceFiles;
  Node parsedTree;
  final LibrarySourceProvider librariesOverride;
  final DiagnosticCollector diagnosticCollector = new DiagnosticCollector();
  final ResolvedUriTranslator resolvedUriTranslator =
      new MockResolvedUriTranslator();
  final Measurer measurer = new Measurer();

  MockCompiler.internal(
      {Map<String, String> coreSource,
      bool enableTypeAssertions: false,
      bool enableUserAssertions: false,
      bool enableMinification: false,
      bool disableTypeInference: false,
      bool analyzeAll: false,
      bool analyzeOnly: false,
      bool preserveComments: false,
      // Our unit tests check code generation output that is
      // affected by inlining support.
      bool disableInlining: true,
      bool trustTypeAnnotations: false,
      bool trustJSInteropTypeAnnotations: false,
      bool enableAsyncAwait: false,
      int this.expectedWarnings,
      int this.expectedErrors,
      api.CompilerOutput outputProvider,
      LibrarySourceProvider this.librariesOverride})
      : sourceFiles = new Map<String, SourceFile>(),
        super(
            options: new CompilerOptions(
                entryPoint: new Uri(scheme: 'mock'),
                libraryRoot: Uri.parse('placeholder_library_root_for_mock/'),
                enableTypeAssertions: enableTypeAssertions,
                enableUserAssertions: enableUserAssertions,
                disableInlining: disableInlining,
                enableAssertMessage: true,
                enableMinification: enableMinification,
                disableTypeInference: disableTypeInference,
                analyzeAll: analyzeAll,
                analyzeOnly: analyzeOnly,
                preserveComments: preserveComments,
                trustTypeAnnotations: trustTypeAnnotations,
                trustJSInteropTypeAnnotations: trustJSInteropTypeAnnotations,
                shownPackageWarnings: const []),
            outputProvider: outputProvider) {
    deferredLoadTask = new MockDeferredLoadTask(this);

    registerSource(
        Uris.dart_core, buildLibrarySource(DEFAULT_CORE_LIBRARY, coreSource));
    registerSource(PATCH_CORE, DEFAULT_PATCH_CORE_SOURCE);
    registerSource(
        Uris.dart__internal, buildLibrarySource(DEFAULT_INTERNAL_LIBRARY));

    registerSource(
        Uris.dart__js_helper, buildLibrarySource(DEFAULT_JS_HELPER_LIBRARY));
    registerSource(Uris.dart__foreign_helper,
        buildLibrarySource(DEFAULT_FOREIGN_HELPER_LIBRARY));
    registerSource(Uris.dart__interceptors,
        buildLibrarySource(DEFAULT_INTERCEPTORS_LIBRARY));
    registerSource(Uris.dart__isolate_helper,
        buildLibrarySource(DEFAULT_ISOLATE_HELPER_LIBRARY));
    registerSource(Uris.dart_mirrors, DEFAULT_MIRRORS_SOURCE);
    registerSource(Uris.dart__js_mirrors, DEFAULT_JS_MIRRORS_SOURCE);

    Map<String, String> asyncLibrarySource = <String, String>{};
    asyncLibrarySource.addAll(DEFAULT_ASYNC_LIBRARY);
    if (enableAsyncAwait) {
      asyncLibrarySource.addAll(ASYNC_AWAIT_LIBRARY);
    }
    registerSource(Uris.dart_async, buildLibrarySource(asyncLibrarySource));
    registerSource(LookupMapResolutionAnalysis.PACKAGE_LOOKUP_MAP,
        buildLibrarySource(DEFAULT_LOOKUP_MAP_LIBRARY));
  }

  /// Initialize the mock compiler with an empty main library.
  Future<Uri> init([String mainSource = ""]) {
    Uri uri = new Uri(scheme: "mock");
    registerSource(uri, mainSource);
    return libraryLoader
        .loadLibrary(uri)
        .then((LoadedLibraries loadedLibraries) {
      processLoadedLibraries(loadedLibraries);
      mainApp = loadedLibraries.rootLibrary;
      startResolution();
      // We need to make sure the Object class is resolved. When registering a
      // dynamic invocation the ArgumentTypesRegistry eventually iterates over
      // the interfaces of the Object class which would be 'null' if the class
      // wasn't resolved.
      ClassElement objectClass = resolution.commonElements.objectClass;
      objectClass.ensureResolved(resolution);
    }).then((_) => uri);
  }

  Future run(Uri uri, [String mainSource = ""]) {
    return init(mainSource).then((Uri mainUri) {
      return super.run(uri == null ? mainUri : uri);
    }).then((result) {
      if (expectedErrors != null &&
          expectedErrors != diagnosticCollector.errors.length) {
        throw "unexpected error during compilation "
            "${diagnosticCollector.errors}";
      } else if (expectedWarnings != null &&
          expectedWarnings != diagnosticCollector.warnings.length) {
        throw "unexpected warnings during compilation "
            "${diagnosticCollector.warnings}";
      } else {
        return result;
      }
    });
  }

  /**
   * Registers the [source] with [uri] making it possible load [source] as a
   * library.  If an override has been provided in [librariesOverride], that
   * is used instead.
   */
  void registerSource(Uri uri, String source) {
    if (librariesOverride != null) {
      String override = librariesOverride(uri);
      if (override != null) {
        source = override;
      }
    }
    sourceFiles[uri.toString()] = new MockFile(source);
  }

  void reportDiagnostic(DiagnosticMessage message,
      List<DiagnosticMessage> infoMessages, api.Diagnostic kind) {
    void processMessage(DiagnosticMessage message, api.Diagnostic kind) {
      SourceSpan span = message.sourceSpan;
      Uri uri;
      int begin;
      int end;
      String text = '${message.message}';
      if (span != null) {
        uri = span.uri;
        begin = span.begin;
        end = span.end;
      }
      diagnosticCollector.report(message.message, uri, begin, end, text, kind);
      if (diagnosticHandler != null) {
        diagnosticHandler.report(message.message, uri, begin, end, text, kind);
      }
    }

    processMessage(message, kind);
    infoMessages.forEach((i) => processMessage(i, api.Diagnostic.INFO));
  }

  CollectingTreeElements resolveStatement(String text) {
    parsedTree = parseStatement(text);
    LibraryElement library = mainApp;
    return resolveNodeStatement(parsedTree, new MockElement(library));
  }

  TreeElementMapping resolveNodeStatement(
      Node tree, ExecutableElement element) {
    ResolverVisitor visitor = new ResolverVisitor(
        this.resolution,
        element,
        new ResolutionRegistry(
            this.backend.target, new CollectingTreeElements(element)),
        scope:
            new MockTypeVariablesScope(element.enclosingElement.buildScope()));
    if (visitor.scope is LibraryScope ||
        visitor.scope is MockTypeVariablesScope) {
      visitor.scope = new MethodScope(visitor.scope, element);
    }
    visitor.visit(tree);
    visitor.scope = new LibraryScope(element.library);
    return visitor.registry.mapping;
  }

  resolverVisitor() {
    LibraryElement library = mainApp;
    Element mockElement = new MockElement(library.entryCompilationUnit);
    ResolverVisitor visitor = new ResolverVisitor(
        this.resolution,
        mockElement,
        new ResolutionRegistry(
            this.backend.target, new CollectingTreeElements(mockElement)),
        scope: mockElement.enclosingElement.buildScope());
    visitor.scope = new MethodScope(visitor.scope, mockElement);
    return visitor;
  }

  parseScript(String text, [LibraryElement library]) {
    if (library == null) library = mainApp;
    parseUnit(text, this, library, registerSource);
  }

  Future scanBuiltinLibraries() {
    // Do nothing. The mock core library is already handled in the constructor.
    return new Future.value();
  }

  Future<LibraryElement> scanBuiltinLibrary(String name) {
    // Do nothing. The mock core library is already handled in the constructor.
    return new Future.value();
  }

  // The mock library doesn't need any patches.
  Uri resolvePatchUri(String dartLibraryName) {
    if (dartLibraryName == 'core') {
      return PATCH_CORE;
    }
    return null;
  }

  Future<Script> readScript(Uri uri, [Spannable spannable]) {
    SourceFile sourceFile = sourceFiles[uri.toString()];
    if (sourceFile == null) throw new ArgumentError(uri);
    return new Future.value(new Script(uri, uri, sourceFile));
  }

  Element lookupElementIn(ScopeContainerElement container, name) {
    Element element = container.localLookup(name);
    return element != null
        ? element
        : new ErroneousElementX(null, null, name, container);
  }

  /// Create a new [MockCompiler] and apply it asynchronously to [f].
  static Future create(f(MockCompiler compiler)) {
    MockCompiler compiler = new MockCompiler.internal();
    return compiler.init().then((_) => f(compiler));
  }
}

class MockResolvedUriTranslator implements ResolvedUriTranslator {
  static final _emptySet = new Set();

  Uri translate(LibraryElement importingLibrary, Uri resolvedUri,
          Spannable spannable) =>
      resolvedUri;
  Set<Uri> get disallowedLibraryUris => _emptySet;
  bool get mockableLibraryUsed => false;
  Map<String, Uri> get sdkLibraries => const <String, Uri>{};
}

class CollectingTreeElements extends TreeElementMapping {
  final Map<Node, Element> map = new LinkedHashMap<Node, Element>();

  CollectingTreeElements(Element currentElement) : super(currentElement);

  operator []=(Node node, Element element) {
    map[node] = element;
  }

  operator [](Node node) => map[node];

  void remove(Node node) {
    map.remove(node);
  }

  List<ConstantExpression> get constants {
    List<ConstantExpression> list = <ConstantExpression>[];
    forEachConstantNode((_, c) => list.add(c));
    return list;
  }
}

class MockTypeVariablesScope extends TypeVariablesScope {
  @override
  List<ResolutionDartType> get typeVariables => <ResolutionDartType>[];
  MockTypeVariablesScope(Scope parent) : super(parent);
  String toString() => 'MockTypeVariablesScope($parent)';
}

// The mock compiler does not split the program in output units.
class MockDeferredLoadTask extends DeferredLoadTask {
  MockDeferredLoadTask(Compiler compiler) : super(compiler);

  OutputUnit getElementOutputUnit(dynamic dependency) {
    return mainOutputUnit;
  }
}

api.CompilerDiagnostics createHandler(MockCompiler compiler, String text,
    {bool verbose: false}) {
  return new LegacyCompilerDiagnostics(
      (uri, int begin, int end, String message, kind) {
    if (kind == api.Diagnostic.VERBOSE_INFO && !verbose) return;
    SourceFile sourceFile;
    if (uri == null) {
      sourceFile = new StringSourceFile.fromName('analysis', text);
    } else {
      sourceFile = compiler.sourceFiles[uri.toString()];
    }
    if (sourceFile != null && begin != null && end != null) {
      print('${kind}: ${sourceFile.getLocationMessage(message, begin, end)}');
    } else {
      print('${kind}: $message');
    }
  });
}

class MockElement extends FunctionElementX {
  MockElement(Element enclosingElement)
      : super('', ElementKind.FUNCTION, Modifiers.EMPTY, enclosingElement);

  get node => null;

  parseNode(_) => null;

  bool get hasNode => false;

  accept(ElementVisitor visitor, arg) {
    return visitor.visitMethodElement(this, arg);
  }
}

// TODO(herhut): Disallow warnings and errors during compilation by default.
MockCompiler compilerFor(String code, Uri uri,
    {bool analyzeAll: false,
    bool analyzeOnly: false,
    Map<String, String> coreSource,
    bool disableInlining: true,
    bool minify: false,
    bool trustTypeAnnotations: false,
    bool enableTypeAssertions: false,
    bool enableUserAssertions: false,
    int expectedErrors,
    int expectedWarnings,
    api.CompilerOutput outputProvider}) {
  MockCompiler compiler = new MockCompiler.internal(
      analyzeAll: analyzeAll,
      analyzeOnly: analyzeOnly,
      coreSource: coreSource,
      disableInlining: disableInlining,
      enableMinification: minify,
      trustTypeAnnotations: trustTypeAnnotations,
      enableTypeAssertions: enableTypeAssertions,
      enableUserAssertions: enableUserAssertions,
      expectedErrors: expectedErrors,
      expectedWarnings: expectedWarnings,
      outputProvider: outputProvider);
  compiler.registerSource(uri, code);
  compiler.diagnosticHandler = createHandler(compiler, code);
  return compiler;
}
