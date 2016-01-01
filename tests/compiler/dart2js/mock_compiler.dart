// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock_compiler;

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:collection';

import 'package:compiler/compiler.dart' as api;
import 'package:compiler/src/common/names.dart' show
    Uris;
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/diagnostics/diagnostic_listener.dart';
import 'package:compiler/src/diagnostics/source_span.dart';
import 'package:compiler/src/diagnostics/spannable.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/js_backend/backend_helpers.dart'
    show BackendHelpers;
import 'package:compiler/src/js_backend/lookup_map_analysis.dart'
    show LookupMapAnalysis;
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/resolution/members.dart';
import 'package:compiler/src/resolution/registry.dart';
import 'package:compiler/src/resolution/scope.dart';
import 'package:compiler/src/resolution/tree_elements.dart';
import 'package:compiler/src/script.dart';
import 'package:compiler/src/tree/tree.dart';
import 'package:compiler/src/old_to_new_api.dart';
import 'parser_helper.dart';

import 'package:compiler/src/elements/modelx.dart'
    show ElementX,
         LibraryElementX,
         ErroneousElementX,
         FunctionElementX;

import 'package:compiler/src/compiler.dart';

import 'package:compiler/src/deferred_load.dart'
    show DeferredLoadTask,
         OutputUnit;

import 'mock_libraries.dart';
import 'diagnostic_helper.dart';

export 'diagnostic_helper.dart';

final Uri PATCH_CORE = new Uri(scheme: 'patch', path: 'core');

typedef String LibrarySourceProvider(Uri uri);

class MockCompiler extends Compiler {
  api.DiagnosticHandler diagnosticHandler;
  /// Expected number of warnings. If `null`, the number of warnings is
  /// not checked.
  final int expectedWarnings;
  /// Expected number of errors. If `null`, the number of errors is not checked.
  final int expectedErrors;
  final Map<String, SourceFile> sourceFiles;
  Node parsedTree;
  final String testedPatchVersion;
  final LibrarySourceProvider librariesOverride;
  final DiagnosticCollector diagnosticCollector = new DiagnosticCollector();

  MockCompiler.internal(
      {Map<String, String> coreSource,
       bool enableTypeAssertions: false,
       bool enableUserAssertions: false,
       bool enableMinification: false,
       int maxConcreteTypeSize: 5,
       bool disableTypeInference: false,
       bool analyzeAll: false,
       bool analyzeOnly: false,
       bool emitJavaScript: true,
       bool preserveComments: false,
       // Our unit tests check code generation output that is
       // affected by inlining support.
       bool disableInlining: true,
       bool trustTypeAnnotations: false,
       bool trustJSInteropTypeAnnotations: false,
       bool enableAsyncAwait: false,
       int this.expectedWarnings,
       int this.expectedErrors,
       api.CompilerOutputProvider outputProvider,
       String patchVersion,
       LibrarySourceProvider this.librariesOverride})
      : sourceFiles = new Map<String, SourceFile>(),
        testedPatchVersion = patchVersion,
        super(enableTypeAssertions: enableTypeAssertions,
              enableUserAssertions: enableUserAssertions,
              enableAssertMessage: true,
              enableMinification: enableMinification,
              maxConcreteTypeSize: maxConcreteTypeSize,
              disableTypeInferenceFlag: disableTypeInference,
              analyzeAllFlag: analyzeAll,
              analyzeOnly: analyzeOnly,
              emitJavaScript: emitJavaScript,
              preserveComments: preserveComments,
              trustTypeAnnotations: trustTypeAnnotations,
              trustJSInteropTypeAnnotations: trustJSInteropTypeAnnotations,
              diagnosticOptions:
                  new DiagnosticOptions(shownPackageWarnings: const []),
              outputProvider: new LegacyCompilerOutput(outputProvider)) {
    this.disableInlining = disableInlining;

    deferredLoadTask = new MockDeferredLoadTask(this);

    registerSource(Uris.dart_core,
                   buildLibrarySource(DEFAULT_CORE_LIBRARY, coreSource));
    registerSource(PATCH_CORE, DEFAULT_PATCH_CORE_SOURCE);

    registerSource(BackendHelpers.DART_JS_HELPER,
                   buildLibrarySource(DEFAULT_JS_HELPER_LIBRARY));
    registerSource(BackendHelpers.DART_FOREIGN_HELPER,
                   buildLibrarySource(DEFAULT_FOREIGN_HELPER_LIBRARY));
    registerSource(BackendHelpers.DART_INTERCEPTORS,
                   buildLibrarySource(DEFAULT_INTERCEPTORS_LIBRARY));
    registerSource(BackendHelpers.DART_ISOLATE_HELPER,
                   buildLibrarySource(DEFAULT_ISOLATE_HELPER_LIBRARY));
    registerSource(Uris.dart_mirrors, DEFAULT_MIRRORS_SOURCE);
    registerSource(BackendHelpers.DART_JS_MIRRORS,
        DEFAULT_JS_MIRRORS_SOURCE);

    Map<String, String> asyncLibrarySource = <String, String>{};
    asyncLibrarySource.addAll(DEFAULT_ASYNC_LIBRARY);
    if (enableAsyncAwait) {
      asyncLibrarySource.addAll(ASYNC_AWAIT_LIBRARY);
    }
    registerSource(Uris.dart_async,
                   buildLibrarySource(asyncLibrarySource));
    registerSource(LookupMapAnalysis.PACKAGE_LOOKUP_MAP,
                   buildLibrarySource(DEFAULT_LOOKUP_MAP_LIBRARY));
  }

  String get patchVersion {
    return testedPatchVersion != null ? testedPatchVersion : super.patchVersion;
  }

  /// Initialize the mock compiler with an empty main library.
  Future<Uri> init([String mainSource = ""]) {
    Uri uri = new Uri(scheme: "mock");
    registerSource(uri, mainSource);
    return libraryLoader.loadLibrary(uri)
        .then((LibraryElement library) {
      mainApp = library;
      // We need to make sure the Object class is resolved. When registering a
      // dynamic invocation the ArgumentTypesRegistry eventually iterates over
      // the interfaces of the Object class which would be 'null' if the class
      // wasn't resolved.
      coreClasses.objectClass.ensureResolved(resolution);
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
                        List<DiagnosticMessage> infoMessages,
                        api.Diagnostic kind) {

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
        diagnosticHandler(uri, begin, end, text, kind);
      }
    }

    processMessage(message, kind);
    infoMessages.forEach((i) => processMessage(i, api.Diagnostic.INFO));
  }

  CollectingTreeElements resolveStatement(String text) {
    parsedTree = parseStatement(text);
    return resolveNodeStatement(parsedTree, new MockElement(mainApp));
  }

  TreeElementMapping resolveNodeStatement(Node tree,
                                          ExecutableElement element) {
    ResolverVisitor visitor =
        new ResolverVisitor(this, element,
            new ResolutionRegistry(this,
                new CollectingTreeElements(element)));
    if (visitor.scope is LibraryScope) {
      visitor.scope = new MethodScope(visitor.scope, element);
    }
    visitor.visit(tree);
    visitor.scope = new LibraryScope(element.library);
    return visitor.registry.mapping;
  }

  resolverVisitor() {
    Element mockElement = new MockElement(mainApp.entryCompilationUnit);
    ResolverVisitor visitor =
        new ResolverVisitor(this, mockElement,
          new ResolutionRegistry(this,
              new CollectingTreeElements(mockElement)));
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

  Uri translateResolvedUri(LibraryElement importingLibrary,
                           Uri resolvedUri, Spannable spannable) => resolvedUri;

  // The mock library doesn't need any patches.
  Uri resolvePatchUri(String dartLibraryName) {
    if (dartLibraryName == 'core') {
      return PATCH_CORE;
    }
    return null;
  }

  Future<Script> readScript(Spannable node, Uri uri) {
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

// The mock compiler does not split the program in output units.
class MockDeferredLoadTask extends DeferredLoadTask {
  MockDeferredLoadTask(Compiler compiler) : super(compiler);

  OutputUnit getElementOutputUnit(dynamic dependency) {
    return mainOutputUnit;
  }
}

api.DiagnosticHandler createHandler(MockCompiler compiler, String text,
                                    {bool verbose: false}) {
  return (uri, int begin, int end, String message, kind) {
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
  };
}

class MockElement extends FunctionElementX {
  MockElement(Element enclosingElement)
      : super('', ElementKind.FUNCTION, Modifiers.EMPTY,
              enclosingElement);

  get node => null;

  parseNode(_) => null;

  bool get hasNode => false;
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
                          api.CompilerOutputProvider outputProvider}) {
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
