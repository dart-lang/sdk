// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock_compiler;

import "package:expect/expect.dart";
import 'dart:collection';
import 'dart:uri';

import '../../../sdk/lib/_internal/compiler/compiler.dart' as api;
import '../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart';
import '../../../sdk/lib/_internal/compiler/implementation/resolution/resolution.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file.dart';
import '../../../sdk/lib/_internal/compiler/implementation/tree/tree.dart';
import '../../../sdk/lib/_internal/compiler/implementation/util/util.dart';
import 'parser_helper.dart';

import '../../../sdk/lib/_internal/compiler/implementation/elements/modelx.dart'
    show ElementX,
         LibraryElementX,
         ErroneousElementX;

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
    hide TreeElementMapping;

import '../../../sdk/lib/_internal/compiler/implementation/dart_types.dart';

import '../../../sdk/lib/_internal/compiler/implementation/deferred_load.dart'
    show DeferredLoadTask;


class WarningMessage {
  Node node;
  Message message;
  WarningMessage(this.node, this.message);

  toString() => message.toString();
}

const String DEFAULT_HELPERLIB = r'''
  wrapException(x) { return x; }
  iae(x) { throw x; } ioore(x) { throw x; }
  guard$array(x) { return x; }
  guard$num(x) { return x; }
  guard$string(x) { return x; }
  guard$stringOrArray(x) { return x; }
  makeLiteralMap(List keyValuePairs) {}
  setRuntimeTypeInfo(a, b) {}
  getRuntimeTypeInfo(a) {}
  stringTypeCheck(x) {}
  boolConversionCheck(x) {}
  abstract class JavaScriptIndexingBehavior {}
  class JSInvocationMirror {}
  class Closure {}
  class Null {}
  class Dynamic_ {}
  class LinkedHashMap {}
  class ConstantMap {}
  class TypeImpl {}
  S() {}
  unwrapException(e) {}
  assertHelper(a){}
  createRuntimeType(a) {}
  throwNoSuchMethod(obj, name, arguments, expectedArgumentNames) {}
  throwAbstractClassInstantiationError(className) {}''';

const String FOREIGN_LIBRARY = r'''
  dynamic JS(String typeDescription, String codeTemplate,
    [var arg0, var arg1, var arg2, var arg3, var arg4, var arg5, var arg6,
     var arg7, var arg8, var arg9, var arg10, var arg11]) {}''';

const String DEFAULT_INTERCEPTORSLIB = r'''
  class Interceptor {
    toString() {}
    bool operator==(other) => identical(this, other);
  }
  class JSIndexable {}
  class JSArray extends Interceptor implements List, JSIndexable {
    var length;
    operator[](index) {}
    operator[]=(index, value) {}
    var add;
  }
  class JSMutableArray extends JSArray {}
  class JSFixedArray extends JSMutableArray {}
  class JSExtendableArray extends JSMutableArray {}
  class JSString extends Interceptor implements String, JSIndexable {
    var length;
    operator[](index) {}
    toString() {}
  }
  class JSNumber extends Interceptor implements num {
    // All these methods return a number to please type inferencing.
    operator-() => (this is JSInt) ? 42 : 42.0;
    operator +(other) => (this is JSInt) ? 42 : 42.0;
    operator -(other) => (this is JSInt) ? 42 : 42.0;
    operator ~/(other) => 42;
    operator /(other) => (this is JSInt) ? 42 : 42.0;
    operator *(other) => (this is JSInt) ? 42 : 42.0;
    operator %(other) => (this is JSInt) ? 42 : 42.0;
    operator <<(other) => 42;
    operator >>(other) => 42;
    operator |(other) => 42;
    operator &(other) => 42;
    operator ^(other) => 42;

    operator >(other) => true;
    operator >=(other) => true;
    operator <(other) => true;
    operator <=(other) => true;
    operator ==(other) => true;
  }
  class JSInt extends JSNumber implements int {
  }
  class JSDouble extends JSNumber implements double {
  }
  class JSNull extends Interceptor {
    bool operator==(other) => identical(null, other);
  }
  class JSBool extends Interceptor implements bool {
  }
  class JSFunction extends Interceptor implements Function {
  }
  class ObjectInterceptor {
  }
  getInterceptor(x) {}
  getNativeInterceptor(x) {}''';

const String DEFAULT_CORELIB = r'''
  print(var obj) {}
  abstract class num {}
  abstract class int extends num { }
  abstract class double extends num {
    static var NAN = 0;
    static parse(s) {}
  }
  class bool {}
  class String implements Pattern {}
  class Object {
    operator ==(other) {}
    String toString() { return null; }
  }
  class Type {}
  class Function {}
  class List<E> {}
  abstract class Map<K,V> {}
  class DateTime {
    DateTime(year);
    DateTime.utc(year);
  }
  abstract class Pattern {}
  bool identical(Object a, Object b) { return null; }''';

const String DEFAULT_ISOLATE_HELPERLIB = r'''
  class _WorkerBase {}''';

class MockCompiler extends Compiler {
  List<WarningMessage> warnings;
  List<WarningMessage> errors;
  final Map<String, SourceFile> sourceFiles;
  Node parsedTree;

  MockCompiler({String coreSource: DEFAULT_CORELIB,
                String helperSource: DEFAULT_HELPERLIB,
                String interceptorsSource: DEFAULT_INTERCEPTORSLIB,
                String isolateHelperSource: DEFAULT_ISOLATE_HELPERLIB,
                bool enableTypeAssertions: false,
                bool enableMinification: false,
                bool enableConcreteTypeInference: false,
                int maxConcreteTypeSize: 5,
                bool analyzeAll: false,
                bool analyzeOnly: false,
                bool preserveComments: false})
      : warnings = [], errors = [],
        sourceFiles = new Map<String, SourceFile>(),
        super(enableTypeAssertions: enableTypeAssertions,
              enableMinification: enableMinification,
              enableConcreteTypeInference: enableConcreteTypeInference,
              maxConcreteTypeSize: maxConcreteTypeSize,
              analyzeAll: analyzeAll,
              analyzeOnly: analyzeOnly,
              preserveComments: preserveComments) {
    coreLibrary = createLibrary("core", coreSource);
    // We need to set the assert method to avoid calls with a 'null'
    // target being interpreted as a call to assert.
    jsHelperLibrary = createLibrary("helper", helperSource);
    foreignLibrary = createLibrary("foreign", FOREIGN_LIBRARY);
    interceptorsLibrary = createLibrary("interceptors", interceptorsSource);
    isolateHelperLibrary = createLibrary("isolate_helper", isolateHelperSource);

    // Set up the library imports.
    importHelperLibrary(coreLibrary);
    libraryLoader.importLibrary(jsHelperLibrary, coreLibrary, null);
    libraryLoader.importLibrary(interceptorsLibrary, coreLibrary, null);
    libraryLoader.importLibrary(isolateHelperLibrary, coreLibrary, null);

    assertMethod = jsHelperLibrary.find(buildSourceString('assert'));

    mainApp = mockLibrary(this, "");
    initializeSpecialClasses();
    // We need to make sure the Object class is resolved. When registering a
    // dynamic invocation the ArgumentTypesRegistry eventually iterates over
    // the interfaces of the Object class which would be 'null' if the class
    // wasn't resolved.
    objectClass.ensureResolved(this);

    // Our unit tests check code generation output that is affected by
    // inlining support.
    disableInlining = true;

    deferredLoadTask = new MockDeferredLoadTask(this);
  }

  /**
   * Registers the [source] with [uri] making it possible load [source] as a
   * library.
   */
  void registerSource(Uri uri, String source) {
    sourceFiles[uri.toString()] = new MockFile(source);
  }

  /**
   * Used internally to create a library from a source text. The created library
   * is fixed to export its top-level declarations.
   */
  LibraryElement createLibrary(String name, String source) {
    Uri uri = new Uri.fromComponents(scheme: "dart", path: name);
    var script = new Script(uri, new MockFile(source));
    var library = new LibraryElementX(script);
    parseScript(source, library);
    library.setExports(library.localScope.values.toList());
    registerSource(uri, source);
    libraries.putIfAbsent(uri.toString(), () => library);
    return library;
  }

  void reportWarning(Node node, var message) {
    if (message is! Message) message = message.message;
    warnings.add(new WarningMessage(node, message));
  }

  void reportError(Node node, var message) {
    if (message is String && message.startsWith("no library name found in")) {
      // TODO(ahe): Fix the MockCompiler to not have this problem.
      return;
    }
    if (message is! Message) message = message.message;
    errors.add(new WarningMessage(node, message));
  }

  void reportMessage(SourceSpan span, var message, api.Diagnostic kind) {
    var diagnostic = new WarningMessage(null, message.message);
    if (kind == api.Diagnostic.ERROR) {
      errors.add(diagnostic);
    } else {
      warnings.add(diagnostic);
    }
  }

  void reportDiagnostic(SourceSpan span, String message, var kind) {
    print(message);
  }

  bool get compilationFailed => !errors.isEmpty;

  void clearWarnings() {
    warnings = [];
  }

  void clearErrors() {
    errors = [];
  }

  TreeElementMapping resolveStatement(String text) {
    parsedTree = parseStatement(text);
    return resolveNodeStatement(parsedTree, mainApp);
  }

  TreeElementMapping resolveNodeStatement(Node tree, Element element) {
    ResolverVisitor visitor =
        new ResolverVisitor(this, element, new CollectingTreeElements(element));
    if (visitor.scope is LibraryScope) {
      visitor.scope = new MethodScope(visitor.scope, element);
    }
    visitor.visit(tree);
    visitor.scope = new LibraryScope(element.getLibrary());
    return visitor.mapping;
  }

  resolverVisitor() {
    Element mockElement =
        new ElementX(buildSourceString(''), ElementKind.FUNCTION, mainApp);
    ResolverVisitor visitor =
        new ResolverVisitor(this, mockElement,
                            new CollectingTreeElements(mockElement));
    visitor.scope = new MethodScope(visitor.scope, mockElement);
    return visitor;
  }

  parseScript(String text, [LibraryElement library]) {
    if (library == null) library = mainApp;
    parseUnit(text, this, library);
  }

  void scanBuiltinLibraries() {
    // Do nothing. The mock core library is already handled in the constructor.
  }

  LibraryElement scanBuiltinLibrary(String name) {
    // Do nothing. The mock core library is already handled in the constructor.
  }

  void importCoreLibrary(LibraryElement library) {
    scanner.importLibrary(library, coreLibrary, null);
  }

  Uri translateResolvedUri(LibraryElement importingLibrary,
                           Uri resolvedUri, Node node) => resolvedUri;

  // The mock library doesn't need any patches.
  Uri resolvePatchUri(String dartLibraryName) => null;

  Script readScript(Uri uri, [Node node]) {
    SourceFile sourceFile = sourceFiles[uri.toString()];
    if (sourceFile == null) throw new ArgumentError(uri);
    return new Script(uri, sourceFile);
  }

  Element lookupElementIn(ScopeContainerElement container, name) {
    Element element = container.localLookup(name);
    return element != null
        ? element
        : new ErroneousElementX(null, null, name, container);
  }
}

void compareWarningKinds(String text, expectedWarnings, foundWarnings) {
  var fail = (message) => Expect.fail('$text: $message');
  HasNextIterator<MessageKind> expected =
      new HasNextIterator(expectedWarnings.iterator);
  HasNextIterator<WarningMessage> found =
      new HasNextIterator(foundWarnings.iterator);
  while (expected.hasNext && found.hasNext) {
    Expect.equals(expected.next(), found.next().message.kind);
  }
  if (expected.hasNext) {
    do {
      print('Expected warning "${expected.next()}" did not occur');
    } while (expected.hasNext);
    fail('Too few warnings');
  }
  if (found.hasNext) {
    do {
      print('Additional warning "${found.next()}"');
    } while (found.hasNext);
    fail('Too many warnings');
  }
}

void importLibrary(LibraryElement target, LibraryElement imported,
                   Compiler compiler) {
  for (var element in imported.localMembers) {
    compiler.withCurrentElement(element, () {
      target.addToScope(element, compiler);
    });
  }
}

LibraryElement mockLibrary(Compiler compiler, String source) {
  Uri uri = new Uri.fromComponents(scheme: "source");
  var library = new LibraryElementX(new Script(uri, new MockFile(source)));
  importLibrary(library, compiler.coreLibrary, compiler);
  return library;
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

class MockDeferredLoadTask extends DeferredLoadTask {
  MockDeferredLoadTask(Compiler compiler) : super(compiler);

  void registerMainApp(LibraryElement mainApp) {
    // Do nothing.
  }
}
