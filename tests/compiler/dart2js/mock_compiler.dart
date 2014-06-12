// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock_compiler;

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:collection';

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
         ErroneousElementX,
         FunctionElementX;

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
    hide TreeElementMapping;

import '../../../sdk/lib/_internal/compiler/implementation/deferred_load.dart'
    show DeferredLoadTask,
         OutputUnit;

class WarningMessage {
  Spannable node;
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
  stringTypeCast(x) {}
  propertyTypeCast(x) {}
  boolConversionCheck(x) {}
  abstract class JavaScriptIndexingBehavior {}
  class JSInvocationMirror {}
  class BoundClosure extends Closure {
    var self;
    var target;
    var receiver;
  }
  class Closure implements Function {}
  class ConstantMap {}
  class ConstantStringMap {}
  class TypeImpl {}
  S() {}
  throwCyclicInit() {}
  throwExpression(e) {}
  unwrapException(e) {}
  assertHelper(a) {}
  isJsIndexable(a, b) {}
  createRuntimeType(a) {}
  createInvocationMirror(a0, a1, a2, a3, a4, a5) {}
  throwNoSuchMethod(obj, name, arguments, expectedArgumentNames) {}
  throwAbstractClassInstantiationError(className) {}
  boolTypeCheck(value) {}
  propertyTypeCheck(value, property) {}
  interceptedTypeCheck(value, property) {}
  functionSubtypeCast(Object object, String signatureName,
                      String contextName, var context) {}
  checkFunctionSubtype(var target, String signatureName,
                       String contextName, var context,
                       var typeArguments) {}
  computeSignature(var signature, var context, var contextName) {}
  getRuntimeTypeArguments(target, substitutionName) {}
  voidTypeCheck(value) {}''';

const String FOREIGN_LIBRARY = r'''
  dynamic JS(String typeDescription, String codeTemplate,
    [var arg0, var arg1, var arg2, var arg3, var arg4, var arg5, var arg6,
     var arg7, var arg8, var arg9, var arg10, var arg11]) {}''';

const String DEFAULT_INTERCEPTORSLIB = r'''
  class Interceptor {
    toString() {}
    bool operator==(other) => identical(this, other);
    get hashCode => throw "Interceptor.hashCode not implemented.";
    noSuchMethod(im) { throw im; }
  }
  abstract class JSIndexable {
    get length;
    operator[](index);
  }
  abstract class JSMutableIndexable extends JSIndexable {}
  class JSArray<E> extends Interceptor implements List<E>, JSIndexable {
    JSArray();
    factory JSArray.typed(a) => a;
    var length;
    operator[](index) => this[index];
    operator[]=(index, value) { this[index] = value; }
    add(value) { this[length + 1] = value; }
    insert(index, value) {}
    E get first => this[0];
    E get last => this[0];
    E get single => this[0];
    E removeLast() => this[0];
    E removeAt(index) => this[0];
    E elementAt(index) => this[0];
    E singleWhere(f) => this[0];
  }
  class JSMutableArray extends JSArray implements JSMutableIndexable {}
  class JSFixedArray extends JSMutableArray {}
  class JSExtendableArray extends JSMutableArray {}
  class JSString extends Interceptor implements String, JSIndexable {
    var length;
    operator[](index) {}
    toString() {}
    operator+(other) => this;
  }
  class JSPositiveInt extends JSInt {}
  class JSUInt32 extends JSPositiveInt {}
  class JSUInt31 extends JSUInt32 {}
  class JSNumber extends Interceptor implements num {
    // All these methods return a number to please type inferencing.
    operator-() => (this is JSInt) ? 42 : 42.2;
    operator +(other) => (this is JSInt) ? 42 : 42.2;
    operator -(other) => (this is JSInt) ? 42 : 42.2;
    operator ~/(other) => _tdivFast(other);
    operator /(other) => (this is JSInt) ? 42 : 42.2;
    operator *(other) => (this is JSInt) ? 42 : 42.2;
    operator %(other) => (this is JSInt) ? 42 : 42.2;
    operator <<(other) => _shlPositive(other);
    operator >>(other) {
      return _shrBothPositive(other) + _shrReceiverPositive(other) +
        _shrOtherPositive(other);
    }
    operator |(other) => 42;
    operator &(other) => 42;
    operator ^(other) => 42;

    operator >(other) => true;
    operator >=(other) => true;
    operator <(other) => true;
    operator <=(other) => true;
    operator ==(other) => true;
    get hashCode => throw "JSNumber.hashCode not implemented.";

    // We force side effects on _tdivFast to mimic the shortcomings of
    // the effect analysis: because the `_tdivFast` implementation of
    // the core library has calls that may not already be analyzed,
    // the analysis will conclude that `_tdivFast` may have side
    // effects.
    _tdivFast(other) => new List()..length = 42;
    _shlPositive(other) => 42;
    _shrBothPositive(other) => 42;
    _shrReceiverPositive(other) => 42;
    _shrOtherPositive(other) => 42;

    abs() => (this is JSInt) ? 42 : 42.2;
    remainder(other) => (this is JSInt) ? 42 : 42.2;
    truncate() => 42;
  }
  class JSInt extends JSNumber implements int {
  }
  class JSDouble extends JSNumber implements double {
  }
  class JSNull extends Interceptor {
    bool operator==(other) => identical(null, other);
    get hashCode => throw "JSNull.hashCode not implemented.";
    String toString() => 'Null';
    Type get runtimeType => null;
    noSuchMethod(x) => super.noSuchMethod(x);
  }
  class JSBool extends Interceptor implements bool {
  }
  class JSFunction extends Interceptor implements Function {
  }
  class ObjectInterceptor {
  }
  getInterceptor(x) {}
  getNativeInterceptor(x) {}
  var dispatchPropertyName;
  var mapTypeToInterceptor;
  getDispatchProperty(o) {}
  initializeDispatchProperty(f,p,i) {}
  initializeDispatchPropertyCSP(f,p,i) {}
''';

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
    const Object();
    operator ==(other) { return true; }
    get hashCode => throw "Object.hashCode not implemented.";
    String toString() { return null; }
    noSuchMethod(im) { throw im; }
  }
  class Null {}
  abstract class StackTrace {}
  class Type {}
  class Function {}
  class List<E> {
    var length;
    List([length]);
    List.filled(length, element);
    E get first => null;
    E get last => null;
    E get single => null;
    E removeLast() => null;
    E removeAt(i) => null;
    E elementAt(i) => null;
    E singleWhere(f) => null;
  }
  abstract class Map<K,V> {}
  class LinkedHashMap {
    factory LinkedHashMap._empty() => null;
    factory LinkedHashMap._literal(elements) => null;
  }
  class DateTime {
    DateTime(year);
    DateTime.utc(year);
  }
  abstract class Pattern {}
  bool identical(Object a, Object b) { return true; }
  const proxy = 0;''';

final Uri PATCH_CORE = new Uri(scheme: 'patch', path: 'core');

const String PATCH_CORE_SOURCE = r'''
import 'dart:_js_helper';
import 'dart:_interceptors';
import 'dart:_isolate_helper';
''';

const String DEFAULT_ISOLATE_HELPERLIB = r'''
  var startRootIsolate;
  var _currentIsolate;
  var _callInIsolate;
  class _WorkerBase {}''';

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
      {String coreSource: DEFAULT_CORELIB,
       String interceptorsSource: DEFAULT_INTERCEPTORSLIB,
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
              showPackageWarnings: true) {
    this.disableInlining = disableInlining;

    deferredLoadTask = new MockDeferredLoadTask(this);

    clearMessages();

    registerSource(Compiler.DART_CORE, coreSource);
    registerSource(PATCH_CORE, PATCH_CORE_SOURCE);

    registerSource(Compiler.DART_JS_HELPER, DEFAULT_HELPERLIB);
    registerSource(Compiler.DART_FOREIGN_HELPER, FOREIGN_LIBRARY);
    registerSource(Compiler.DART_INTERCEPTORS, interceptorsSource);
    registerSource(Compiler.DART_ISOLATE_HELPER, DEFAULT_ISOLATE_HELPERLIB);
  }

  /// Initialize the mock compiler with an empty main library.
  Future init([String mainSource = ""]) {
    Uri uri = new Uri(scheme: "mock");
    registerSource(uri, mainSource);
    return libraryLoader.loadLibrary(uri, null, uri)
        .then((LibraryElement library) {
      coreLibrary = libraries['${Compiler.DART_CORE}'];
      jsHelperLibrary = libraries['${Compiler.DART_JS_HELPER}'];
      foreignLibrary = libraries['${Compiler.DART_FOREIGN_HELPER}'];
      interceptorsLibrary = libraries['${Compiler.DART_INTERCEPTORS}'];
      isolateHelperLibrary = libraries['${Compiler.DART_ISOLATE_HELPER}'];

      assertMethod = jsHelperLibrary.find('assertHelper');
      identicalFunction = coreLibrary.find('identical');

      mainApp = library;
      initializeSpecialClasses();
      // We need to make sure the Object class is resolved. When registering a
      // dynamic invocation the ArgumentTypesRegistry eventually iterates over
      // the interfaces of the Object class which would be 'null' if the class
      // wasn't resolved.
      objectClass.ensureResolved(this);
    });
  }

  Future runCompiler(Uri uri) {
    return init().then((_) {
      return super.runCompiler(uri);
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
    return resolveNodeStatement(parsedTree, mainApp);
  }

  TreeElementMapping resolveNodeStatement(Node tree, Element element) {
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
  static Future create(f(MockCompiler compiler)) {
    MockCompiler compiler = new MockCompiler.internal();
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

api.DiagnosticHandler createHandler(MockCompiler compiler, String text) {
  return (uri, int begin, int end, String message, kind) {
    SourceFile sourceFile;
    if (uri == null) {
      sourceFile = new StringSourceFile('analysis', text);
    } else {
      sourceFile = compiler.sourceFiles[uri.toString()];
    }
    if (sourceFile != null && begin != null && end != null) {
      print(sourceFile.getLocationMessage(message, begin, end, true, (x) => x));
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
}