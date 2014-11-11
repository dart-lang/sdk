// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock_compiler;

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:collection';

import 'package:compiler/compiler.dart' as api;
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/js_backend/js_backend.dart'
    show JavaScriptBackend;
import 'package:compiler/src/resolution/resolution.dart';
import 'package:compiler/src/source_file.dart';
import 'package:compiler/src/tree/tree.dart';
import 'package:compiler/src/util/util.dart';
import 'parser_helper.dart';

import 'package:compiler/src/elements/modelx.dart'
    show ElementX,
         LibraryElementX,
         ErroneousElementX,
         FunctionElementX;

import 'package:compiler/src/dart2jslib.dart'
    hide TreeElementMapping;

import 'package:compiler/src/deferred_load.dart'
    show DeferredLoadTask,
         OutputUnit;

import 'mock_libraries.dart';

class WarningMessage {
  Spannable node;
  Message message;
  WarningMessage(this.node, this.message);

  toString() => message.toString();
}

final Uri PATCH_CORE = new Uri(scheme: 'patch', path: 'core');

class MockCompiler extends Compiler {
  api.DiagnosticHandler diagnosticHandler;
  List<WarningMessage> warnings;
  List<WarningMessage> errors;
  List<WarningMessage> hints;
  List<WarningMessage> infos;
  List<WarningMessage> crashes;
  /// Expected number of warnings. If `null`, the number of warnings is
  /// not checked.
  final int expectedWarnings;
  /// Expected number of errors. If `null`, the number of errors is not checked.
  final int expectedErrors;
  final Map<String, SourceFile> sourceFiles;
  Node parsedTree;

  MockCompiler.internal(
      {Map<String, String> coreSource,
       bool enableTypeAssertions: false,
       bool enableMinification: false,
       bool enableConcreteTypeInference: false,
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
       bool enableEnums: false,
       int this.expectedWarnings,
       int this.expectedErrors})
      : sourceFiles = new Map<String, SourceFile>(),
        super(enableTypeAssertions: enableTypeAssertions,
              enableMinification: enableMinification,
              enableConcreteTypeInference: enableConcreteTypeInference,
              maxConcreteTypeSize: maxConcreteTypeSize,
              disableTypeInferenceFlag: disableTypeInference,
              analyzeAllFlag: analyzeAll,
              analyzeOnly: analyzeOnly,
              emitJavaScript: emitJavaScript,
              preserveComments: preserveComments,
              trustTypeAnnotations: trustTypeAnnotations,
              showPackageWarnings: true,
              enableEnums: enableEnums) {
    this.disableInlining = disableInlining;

    deferredLoadTask = new MockDeferredLoadTask(this);

    clearMessages();

    registerSource(Compiler.DART_CORE,
                   buildLibrarySource(DEFAULT_CORE_LIBRARY, coreSource));
    registerSource(PATCH_CORE, DEFAULT_PATCH_CORE_SOURCE);

    registerSource(JavaScriptBackend.DART_JS_HELPER,
                   buildLibrarySource(DEFAULT_JS_HELPER_LIBRARY));
    registerSource(JavaScriptBackend.DART_FOREIGN_HELPER,
                   buildLibrarySource(DEFAULT_FOREIGN_HELPER_LIBRARY));
    registerSource(JavaScriptBackend.DART_INTERCEPTORS,
                   buildLibrarySource(DEFAULT_INTERCEPTORS_LIBRARY));
    registerSource(JavaScriptBackend.DART_ISOLATE_HELPER,
                   buildLibrarySource(DEFAULT_ISOLATE_HELPER_LIBRARY));
    registerSource(Compiler.DART_MIRRORS,
                   buildLibrarySource(DEFAULT_MIRRORS_LIBRARY));
    registerSource(Compiler.DART_ASYNC,
                   buildLibrarySource(DEFAULT_ASYNC_LIBRARY));
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
      objectClass.ensureResolved(this);
    }).then((_) => uri);
  }

  Future runCompiler(Uri uri, [String mainSource = ""]) {
    return init(mainSource).then((Uri mainUri) {
      return super.runCompiler(uri == null ? mainUri : uri);
    }).then((result) {
      if (expectedErrors != null &&
          expectedErrors != errors.length) {
        throw "unexpected error during compilation ${errors}";
      } else if (expectedWarnings != null &&
                 expectedWarnings != warnings.length) {
        throw "unexpected warnings during compilation ${warnings}";
      } else {
        return result;
      }
    });
  }

  /**
   * Registers the [source] with [uri] making it possible load [source] as a
   * library.
   */
  void registerSource(Uri uri, String source) {
    sourceFiles[uri.toString()] = new MockFile(source);
  }

  // TODO(johnniwinther): Remove this when we don't filter certain type checker
  // warnings.
  void reportWarning(Spannable node, MessageKind messageKind,
                     [Map arguments = const {}]) {
    reportDiagnostic(node,
                     messageKind.message(arguments, terseDiagnostics),
                     api.Diagnostic.WARNING);
  }

  void reportFatalError(Spannable node,
                        MessageKind messageKind,
                        [Map arguments = const {}]) {
    reportError(node, messageKind, arguments);
  }

  void reportDiagnostic(Spannable node,
                        Message message,
                        api.Diagnostic kind) {
    var diagnostic = new WarningMessage(node, message);
    if (kind == api.Diagnostic.CRASH) {
      crashes.add(diagnostic);
    } else if (kind == api.Diagnostic.ERROR) {
      errors.add(diagnostic);
    } else if (kind == api.Diagnostic.WARNING) {
      warnings.add(diagnostic);
    } else if (kind == api.Diagnostic.INFO) {
      infos.add(diagnostic);
    } else if (kind == api.Diagnostic.HINT) {
      hints.add(diagnostic);
    }
    if (diagnosticHandler != null) {
      SourceSpan span = spanFromSpannable(node);
      if (span != null) {
        diagnosticHandler(span.uri, span.begin, span.end, '$message', kind);
      } else {
        diagnosticHandler(null, null, null, '$message', kind);
      }
    }
  }

  bool get compilationFailed => !crashes.isEmpty || !errors.isEmpty;

  void clearMessages() {
    warnings = [];
    errors = [];
    hints = [];
    infos = [];
    crashes = [];
  }

  CollectingTreeElements resolveStatement(String text) {
    parsedTree = parseStatement(text);
    return resolveNodeStatement(parsedTree, new MockElement(mainApp));
  }

  TreeElementMapping resolveNodeStatement(Node tree,
                                          ExecutableElement element) {
    ResolverVisitor visitor =
        new ResolverVisitor(this, element,
            new ResolutionRegistry.internal(this,
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
          new ResolutionRegistry.internal(this,
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
                           Uri resolvedUri, Node node) => resolvedUri;

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
  static Future create(f(MockCompiler compiler),
                       {bool enableEnums: false}) {
    MockCompiler compiler = new MockCompiler.internal(
        enableEnums: enableEnums);
    return compiler.init().then((_) => f(compiler));
  }
}

/// A function the checks [message]. If the check fails or if [message] is
/// `null`, an error string is returned. Otherwise `null` is returned.
typedef String CheckMessage(Message message);

CheckMessage checkMessage(MessageKind kind, Map arguments) {
  return (Message message) {
    if (message == null) return '$kind';
    if (message.kind != kind) return 'Expected message $kind, found $message.';
    for (var key in arguments.keys) {
      if (!message.arguments.containsKey(key)) {
        return 'Expected argument $key not found in $message.kind.';
      }
      String expectedValue = '${arguments[key]}';
      String foundValue = '${message.arguments[key]}';
      if (expectedValue != foundValue) {
        return 'Expected argument $key with value $expectedValue, '
               'found $foundValue.';
      }
    }
    return null;
  };
}

void compareWarningKinds(String text,
                         List expectedWarnings,
                         List<WarningMessage> foundWarnings) {
  compareMessageKinds(text, expectedWarnings, foundWarnings, 'warning');
}

/// [expectedMessages] must be a list of either [MessageKind] or [CheckMessage].
void compareMessageKinds(String text,
                         List expectedMessages,
                         List<WarningMessage> foundMessages,
                         String kind) {
  var fail = (message) => Expect.fail('$text: $message');
  HasNextIterator expectedIterator =
      new HasNextIterator(expectedMessages.iterator);
  HasNextIterator<WarningMessage> foundIterator =
      new HasNextIterator(foundMessages.iterator);
  while (expectedIterator.hasNext && foundIterator.hasNext) {
    var expected = expectedIterator.next();
    var found = foundIterator.next();
    if (expected is MessageKind) {
      Expect.equals(expected, found.message.kind);
    } else if (expected is CheckMessage) {
      String error = expected(found.message);
      Expect.isNull(error, error);
    } else {
      Expect.fail("Unexpected $kind value: $expected.");
    }
  }
  if (expectedIterator.hasNext) {
    do {
      var expected = expectedIterator.next();
      if (expected is CheckMessage) expected = expected(null);
      print('Expected $kind "${expected}" did not occur');
    } while (expectedIterator.hasNext);
    fail('Too few ${kind}s');
  }
  if (foundIterator.hasNext) {
    do {
      print('Additional $kind "${foundIterator.next()}"');
    } while (foundIterator.hasNext);
    fail('Too many ${kind}s');
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
      sourceFile = new StringSourceFile('analysis', text);
    } else {
      sourceFile = compiler.sourceFiles[uri.toString()];
    }
    if (sourceFile != null && begin != null && end != null) {
      print(sourceFile.getLocationMessage(message, begin, end));
    } else {
      print(message);
    }
  };
}

class MockElement extends FunctionElementX {
  MockElement(Element enclosingElement)
      : super('', ElementKind.FUNCTION, Modifiers.EMPTY,
              enclosingElement, false);

  get node => null;

  parseNode(_) => null;

  bool get hasNode => false;
}
