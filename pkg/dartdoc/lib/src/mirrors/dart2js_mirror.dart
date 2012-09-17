// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('mirrors.dart2js');

#import('dart:io');
#import('dart:uri');

#import('../../../../../lib/compiler/compiler.dart', prefix: 'diagnostics');
#import('../../../../../lib/compiler/implementation/elements/elements.dart');
#import('../../../../../lib/compiler/implementation/apiimpl.dart', prefix: 'api');
#import('../../../../../lib/compiler/implementation/scanner/scannerlib.dart');
#import('../../../../../lib/compiler/implementation/leg.dart');
#import('../../../../../lib/compiler/implementation/filenames.dart');
#import('../../../../../lib/compiler/implementation/source_file.dart');
#import('../../../../../lib/compiler/implementation/tree/tree.dart');
#import('../../../../../lib/compiler/implementation/util/util.dart');
#import('../../../../../lib/compiler/implementation/util/uri_extras.dart');
#import('../../../../../lib/compiler/implementation/dart2js.dart');

// TODO(rnystrom): Use "package:" URL (#4968).
#import('../../mirrors.dart');
#import('util.dart');

//------------------------------------------------------------------------------
// Utility types and functions for the dart2js mirror system
//------------------------------------------------------------------------------

bool _isPrivate(String name) {
  return name.startsWith('_');
}

List<ParameterMirror> _parametersFromFunctionSignature(
    Dart2JsMirrorSystem system,
    Dart2JsMethodMirror method,
    FunctionSignature signature) {
  var parameters = <ParameterMirror>[];
  Link<Element> link = signature.requiredParameters;
  while (!link.isEmpty()) {
    parameters.add(new Dart2JsParameterMirror(
        system, method, link.head, false));
    link = link.tail;
  }
  link = signature.optionalParameters;
  while (!link.isEmpty()) {
    parameters.add(new Dart2JsParameterMirror(
        system, method, link.head, true));
    link = link.tail;
  }
  return parameters;
}

Dart2JsTypeMirror _convertTypeToTypeMirror(
    Dart2JsMirrorSystem system,
    DartType type,
    InterfaceType defaultType,
    [FunctionSignature functionSignature]) {
  if (type === null) {
    return new Dart2JsInterfaceTypeMirror(system, defaultType);
  } else if (type is InterfaceType) {
    return new Dart2JsInterfaceTypeMirror(system, type);
  } else if (type is TypeVariableType) {
    return new Dart2JsTypeVariableMirror(system, type);
  } else if (type is FunctionType) {
    return new Dart2JsFunctionTypeMirror(system, type, functionSignature);
  } else if (type is VoidType) {
    return new Dart2JsVoidMirror(system, type);
  } else if (type is TypedefType) {
    return new Dart2JsTypedefMirror(system, type);
  }
  throw new IllegalArgumentException("Unexpected interface type $type");
}

Collection<Dart2JsMemberMirror> _convertElementMemberToMemberMirrors(
    Dart2JsObjectMirror library, Element element) {
  if (element is SynthesizedConstructorElement) {
    return const <Dart2JsMemberMirror>[];
  } else if (element is VariableElement) {
    return <Dart2JsMemberMirror>[new Dart2JsFieldMirror(library, element)];
  } else if (element is FunctionElement) {
    return <Dart2JsMemberMirror>[new Dart2JsMethodMirror(library, element)];
  } else if (element is AbstractFieldElement) {
    var members = <Dart2JsMemberMirror>[];
    if (element.getter !== null) {
      members.add(new Dart2JsMethodMirror(library, element.getter));
    }
    if (element.setter !== null) {
      members.add(new Dart2JsMethodMirror(library, element.setter));
    }
    return members;
  }
  throw new IllegalArgumentException(
      "Unexpected member type $element ${element.kind}");
}

MethodMirror _convertElementMethodToMethodMirror(Dart2JsObjectMirror library,
                                                 Element element) {
  if (element is FunctionElement) {
    return new Dart2JsMethodMirror(library, element);
  } else {
    return null;
  }
}

class Dart2JsMethodKind {
  static const Dart2JsMethodKind NORMAL = const Dart2JsMethodKind("normal");
  static const Dart2JsMethodKind CONSTRUCTOR
      = const Dart2JsMethodKind("constructor");
  static const Dart2JsMethodKind CONST = const Dart2JsMethodKind("const");
  static const Dart2JsMethodKind FACTORY = const Dart2JsMethodKind("factory");
  static const Dart2JsMethodKind GETTER = const Dart2JsMethodKind("getter");
  static const Dart2JsMethodKind SETTER = const Dart2JsMethodKind("setter");
  static const Dart2JsMethodKind OPERATOR = const Dart2JsMethodKind("operator");

  final String text;

  const Dart2JsMethodKind(this.text);

  String toString() => text;
}


String _getOperatorFromOperatorName(String name) {
  Map<String, String> mapping = const {
    'eq': '==',
    'not': '~',
    'index': '[]',
    'indexSet': '[]=',
    'mul': '*',
    'div': '/',
    'mod': '%',
    'tdiv': '~/',
    'add': '+',
    'sub': '-',
    'shl': '<<',
    'shr': '>>',
    'ge': '>=',
    'gt': '>',
    'le': '<=',
    'lt': '<',
    'and': '&',
    'xor': '^',
    'or': '|',
  };
  String newName = mapping[name];
  if (newName === null) {
    throw new Exception('Unhandled operator name: $name');
  }
  return newName;
}

DiagnosticListener get _diagnosticListener {
  return const Dart2JsDiagnosticListener();
}

class Dart2JsDiagnosticListener implements DiagnosticListener {
  const Dart2JsDiagnosticListener();

  void cancel([String reason, node, token, instruction, element]) {
    print(reason);
  }

  void log(message) {
    print(message);
  }

  void internalError(String message,
                     [Node node, Token token, HInstruction instruction,
                      Element element]) {
    cancel('Internal error: $message', node, token, instruction, element);
  }

  void internalErrorOnElement(Element element, String message) {
    internalError(message, element: element);
  }
}

//------------------------------------------------------------------------------
// Compiler extension for apidoc.
//------------------------------------------------------------------------------

/**
 * Extension of the compiler that enables the analysis of several libraries with
 * no particular entry point.
 */
class LibraryCompiler extends api.Compiler {
  LibraryCompiler(diagnostics.ReadStringFromUri provider,
                  diagnostics.DiagnosticHandler handler,
                  Uri libraryRoot, Uri packageRoot,
                  List<String> options)
      : super(provider, handler, libraryRoot, packageRoot, options) {
    checker = new LibraryTypeCheckerTask(this);
    resolver = new LibraryResolverTask(this);
  }

  // TODO(johnniwinther): The following methods are added to enable the analysis
  // of a collection of libraries to be used for apidoc. Most of the methods
  // are based on copies of existing methods and could probably be implemented
  // such that the duplicate code is avoided. Not to affect the correctness and
  // speed of dart2js as is, the redundancy is accepted temporarily.

  /**
   * Run the compiler on a list of libraries. No entry point is used.
   */
  bool runList(List<Uri> uriList) {
    bool success = _runList(uriList);
    for (final task in tasks) {
      log('${task.name} took ${task.timing}msec');
    }
    return success;
  }

  bool _runList(List<Uri> uriList) {
    try {
      runCompilerList(uriList);
    } on CompilerCancelledException catch (exception) {
      log(exception.toString());
      log('compilation failed');
      return false;
    }
    tracer.close();
    log('compilation succeeded');
    return true;
  }

  void runCompilerList(List<Uri> uriList) {
    scanBuiltinLibraries();
    var elementList = <LibraryElement>[];
    for (var uri in uriList) {
      elementList.add(scanner.loadLibrary(uri, null, uri));
    }
    libraries.forEach((_, library) {
      maybeEnableJSHelper(library);
    });

    world.populate();

    log('Resolving...');
    phase = Compiler.PHASE_RESOLVING;
    backend.enqueueHelpers(enqueuer.resolution);
    processQueueList(enqueuer.resolution, elementList);
    log('Resolved ${enqueuer.resolution.resolvedElements.length} elements.');
  }

  void processQueueList(Enqueuer world, List<LibraryElement> elements) {
    backend.processNativeClasses(world, libraries.getValues());
    for (var library in elements) {
      library.localMembers.forEach((element) {
        world.addToWorkList(element);
      });
    }
    progress.reset();
    world.forEach((WorkItem work) {
      withCurrentElement(work.element, () => work.run(this, world));
    });
  }

  String codegen(WorkItem work, Enqueuer world) {
    return null;
  }
}

// TODO(johnniwinther): The source for the apidoc includes calls to methods on
// for instance [MathPrimitives] which are not resolved by dart2js. Since we
// do not need to analyse the body of functions to produce the documenation
// we use a specialized resolver which bypasses method bodies.
class LibraryResolverTask extends ResolverTask {
  LibraryResolverTask(api.Compiler compiler) : super(compiler);

  void visitBody(ResolverVisitor visitor, Statement body) {}
}

// TODO(johnniwinther): As a side-effect of bypassing method bodies in
// [LibraryResolveTask] we can not perform the typecheck.
class LibraryTypeCheckerTask extends TypeCheckerTask {
  LibraryTypeCheckerTask(api.Compiler compiler) : super(compiler);

  void check(Node tree, TreeElements elements) {}
}

//------------------------------------------------------------------------------
// Compilation implementation
//------------------------------------------------------------------------------

class Dart2JsCompilation implements Compilation {
  bool isWindows = (Platform.operatingSystem == 'windows');
  api.Compiler _compiler;
  Uri cwd;
  bool isAborting = false;
  Map<String, SourceFile> sourceFiles;

  Future<String> provider(Uri uri) {
    if (uri.scheme != 'file') {
      throw new IllegalArgumentException(uri);
    }
    String source;
    try {
      source = readAll(uriPathToNative(uri.path));
    } on FileIOException catch (ex) {
      throw 'Error: Cannot read "${relativize(cwd, uri, isWindows)}" '
            '(${ex.osError}).';
    }
    sourceFiles[uri.toString()] =
      new SourceFile(relativize(cwd, uri, isWindows), source);
    return new Future.immediate(source);
  }

  void handler(Uri uri, int begin, int end,
               String message, diagnostics.Diagnostic kind) {
    if (isAborting) return;
    bool fatal =
        kind === diagnostics.Diagnostic.CRASH ||
        kind === diagnostics.Diagnostic.ERROR;
    if (uri === null) {
      if (!fatal) {
        return;
      }
      print(message);
      throw message;
    } else if (fatal) {
      SourceFile file = sourceFiles[uri.toString()];
      print(file.getLocationMessage(message, begin, end, true, (s) => s));
      throw message;
    }
  }

  Dart2JsCompilation(Path script, Path libraryRoot,
                     [Path packageRoot, List<String> opts = const <String>[]])
      : cwd = getCurrentDirectory(), sourceFiles = <String, SourceFile>{} {
    var libraryUri = cwd.resolve(libraryRoot.toString());
    var packageUri;
    if (packageRoot !== null) {
      packageUri = cwd.resolve(packageRoot.toString());
    } else {
      packageUri = libraryUri;
    }
    _compiler = new api.Compiler(provider, handler,
        libraryUri, packageUri, <String>[]);
    var scriptUri = cwd.resolve(script.toString());
    // TODO(johnniwinther): Detect file not found
    _compiler.run(scriptUri);
  }

  Dart2JsCompilation.library(List<Path> libraries, Path libraryRoot,
                     [Path packageRoot, List<String> opts = const <String>[]])
      : cwd = getCurrentDirectory(), sourceFiles = <String, SourceFile>{} {
    var libraryUri = cwd.resolve(libraryRoot.toString());
    var packageUri;
    if (packageRoot !== null) {
      packageUri = cwd.resolve(packageRoot.toString());
    } else {
      packageUri = libraryUri;
    }
    _compiler = new LibraryCompiler(provider, handler,
        libraryUri, packageUri, <String>[]);
    var librariesUri = <Uri>[];
    for (Path library in libraries) {
      librariesUri.add(cwd.resolve(library.toString()));
      // TODO(johnniwinther): Detect file not found
    }
    _compiler.runList(librariesUri);
  }

  void addLibrary(String path) {
    var uri = cwd.resolve(nativeToUriPath(path));
    _compiler.scanner.loadLibrary(uri, null);
  }

  MirrorSystem get mirrors => new Dart2JsMirrorSystem(_compiler);

  Future<String> compileToJavaScript() =>
      new Future<String>.immediate(_compiler.assembledCode);
}


//------------------------------------------------------------------------------
// Dart2Js specific extensions of mirror interfaces
//------------------------------------------------------------------------------

abstract class Dart2JsMirror implements Mirror {
  /**
   * A unique name used as the key in maps.
   */
  String get canonicalName;
  Dart2JsMirrorSystem get system;
}

abstract class Dart2JsMemberMirror implements Dart2JsMirror, MemberMirror {

}

abstract class Dart2JsTypeMirror implements Dart2JsMirror, TypeMirror {

}

abstract class Dart2JsElementMirror implements Dart2JsMirror {
  final Dart2JsMirrorSystem system;
  final Element _element;

  Dart2JsElementMirror(this.system, this._element) {
    assert (system !== null);
    assert (_element !== null);
  }

  String get simpleName => _element.name.slowToString();

  Location get location => new Dart2JsLocation(
      _element.getCompilationUnit().script,
      system.compiler.spanFromElement(_element));

  String toString() => _element.toString();

  int hashCode() => qualifiedName.hashCode();
}

abstract class Dart2JsProxyMirror implements Dart2JsMirror {
  final Dart2JsMirrorSystem system;

  Dart2JsProxyMirror(this.system);

  int hashCode() => qualifiedName.hashCode();
}

//------------------------------------------------------------------------------
// Mirror system implementation.
//------------------------------------------------------------------------------

class Dart2JsMirrorSystem implements MirrorSystem, Dart2JsMirror {
  final api.Compiler compiler;
  Map<String, Dart2JsLibraryMirror> _libraries;
  Map<LibraryElement, Dart2JsLibraryMirror> _libraryMap;

  Dart2JsMirrorSystem(this.compiler)
    : _libraryMap = new Map<LibraryElement, Dart2JsLibraryMirror>();

  void _ensureLibraries() {
    if (_libraries == null) {
      _libraries = <String, Dart2JsLibraryMirror>{};
      compiler.libraries.forEach((_, LibraryElement v) {
        var mirror = new Dart2JsLibraryMirror(system, v);
        _libraries[mirror.canonicalName] = mirror;
        _libraryMap[v] = mirror;
      });
    }
  }

  Map<Object, LibraryMirror> get libraries {
    _ensureLibraries();
    return new ImmutableMapWrapper<Object, LibraryMirror>(_libraries);
  }

  Dart2JsLibraryMirror getLibrary(LibraryElement element) {
    return _libraryMap[element];
  }

  Dart2JsMirrorSystem get system => this;

  String get simpleName => "mirror";
  String get qualifiedName => simpleName;

  String get canonicalName => simpleName;

  // TODO(johnniwinther): Hack! Dart2JsMirrorSystem need not be a Mirror.
  int hashCode() => qualifiedName.hashCode();
}

abstract class Dart2JsObjectMirror extends Dart2JsElementMirror
    implements ObjectMirror {
  Dart2JsObjectMirror(Dart2JsMirrorSystem system, Element element)
      : super(system, element);
}

class Dart2JsLibraryMirror extends Dart2JsObjectMirror
    implements LibraryMirror {
  Map<String, InterfaceMirror> _types;
  Map<String, MemberMirror> _members;

  Dart2JsLibraryMirror(Dart2JsMirrorSystem system, LibraryElement library)
      : super(system, library);

  LibraryElement get _library => _element;

  LibraryMirror library() => this;

  String get canonicalName => simpleName;

  /**
   * Returns the library name (for libraries with a #library tag) or the script
   * file name (for scripts without a #library tag). The latter case is used to
   * provide a 'library name' for scripts, to use for instance in dartdoc.
   */
  String get simpleName {
    if (_library.libraryTag !== null) {
      return _library.libraryTag.argument.dartString.slowToString();
    } else {
      // Use the file name as script name.
      String path = _library.uri.path;
      return path.substring(path.lastIndexOf('/') + 1);
    }
  }

  String get qualifiedName => simpleName;

  void _ensureTypes() {
    if (_types == null) {
      _types = <String, InterfaceMirror>{};
      _library.forEachExport((Element e) {
        if (e.getLibrary() == _library) {
          if (e.isClass()) {
            e.ensureResolved(system.compiler);
            var type = new Dart2JsInterfaceMirror.fromLibrary(this, e);
            _types[type.canonicalName] = type;
          } else if (e.isTypedef()) {
            var type = new Dart2JsTypedefMirror.fromLibrary(this,
                e.computeType(system.compiler));
            _types[type.canonicalName] = type;
          }
        }
      });
    }
  }

  void _ensureMembers() {
    if (_members == null) {
      _members = <String, MemberMirror>{};
      _library.forEachExport((Element e) {
        if (!e.isClass() && !e.isTypedef()) {
          for (var member in _convertElementMemberToMemberMirrors(this, e)) {
            _members[member.canonicalName] = member;
          }
        }
      });
    }
  }

  Map<Object, MemberMirror> get declaredMembers {
    _ensureMembers();
    return new ImmutableMapWrapper<Object, MemberMirror>(_members);
  }

  Map<Object, InterfaceMirror> get types {
    _ensureTypes();
    return new ImmutableMapWrapper<Object, InterfaceMirror>(_types);
  }

  Location get location {
    var script = _library.getCompilationUnit().script;
    return new Dart2JsLocation(
        script,
        new SourceSpan(script.uri, 0, script.text.length));
  }
}

class Dart2JsLocation implements Location {
  Script _script;
  SourceSpan _span;

  Dart2JsLocation(this._script, this._span);

  int get start => _span.begin;

  int get end => _span.end;

  Source get source => new Dart2JsSource(_script);

  String get text => _script.text.substring(start, end);
}

class Dart2JsSource implements Source {
  Script _script;

  Dart2JsSource(this._script);

  Uri get uri => _script.uri;

  String get text => _script.text;
}

class Dart2JsParameterMirror extends Dart2JsElementMirror
    implements ParameterMirror {
  final MethodMirror _method;
  final bool isOptional;

  factory Dart2JsParameterMirror(Dart2JsMirrorSystem system,
                                 MethodMirror method,
                                 VariableElement element,
                                 bool isOptional) {
    if (element is FieldParameterElement) {
      return new Dart2JsFieldParameterMirror(system,
                                             method, element, isOptional);
    }
    return new Dart2JsParameterMirror._normal(system,
                                              method, element, isOptional);
  }

  Dart2JsParameterMirror._normal(Dart2JsMirrorSystem system,
                         this._method,
                         VariableElement element,
                         this.isOptional)
    : super(system, element);

  VariableElement get _variableElement => _element;

  String get canonicalName => simpleName;

  String get qualifiedName => '${_method.qualifiedName}#${simpleName}';

  TypeMirror get type => _convertTypeToTypeMirror(system,
      _variableElement.computeType(system.compiler),
      system.compiler.types.dynamicType,
      _variableElement.variables.functionSignature);

  String get defaultValue {
    if (hasDefaultValue) {
      SendSet expression = _variableElement.cachedNode.asSendSet();
      return unparse(expression.arguments.head);
    }
    return null;
  }
  bool get hasDefaultValue {
    return _variableElement.cachedNode !== null &&
        _variableElement.cachedNode is SendSet;
  }

  bool get isInitializingFormal => false;

  FieldMirror get initializedField => null;
}

class Dart2JsFieldParameterMirror extends Dart2JsParameterMirror {

  Dart2JsFieldParameterMirror(Dart2JsMirrorSystem system,
                              MethodMirror method,
                              FieldParameterElement element,
                              bool isOptional)
      : super._normal(system, method, element, isOptional);

  FieldParameterElement get _fieldParameterElement => _element;

  TypeMirror get type {
    if (_fieldParameterElement.variables.cachedNode.type !== null) {
      return super.type;
    }
    return _convertTypeToTypeMirror(system,
      _fieldParameterElement.fieldElement.computeType(system.compiler),
      system.compiler.types.dynamicType,
      _variableElement.variables.functionSignature);
  }

  bool get isInitializingFormal => true;

  FieldMirror get initializedField => new Dart2JsFieldMirror(
      _method.surroundingDeclaration, _fieldParameterElement.fieldElement);
}

//------------------------------------------------------------------------------
// Declarations
//------------------------------------------------------------------------------
class Dart2JsInterfaceMirror extends Dart2JsObjectMirror
    implements Dart2JsTypeMirror, InterfaceMirror {
  final Dart2JsLibraryMirror library;
  Map<String, Dart2JsMemberMirror> _members;
  List<TypeVariableMirror> _typeVariables;

  Dart2JsInterfaceMirror(Dart2JsMirrorSystem system, ClassElement _class)
      : this.library = system.getLibrary(_class.getLibrary()),
        super(system, _class);

  ClassElement get _class => _element;


  Dart2JsInterfaceMirror.fromLibrary(Dart2JsLibraryMirror library,
                                 ClassElement _class)
      : this.library = library,
        super(library.system, _class);

  String get canonicalName => simpleName;

  String get qualifiedName => '${library.qualifiedName}.${simpleName}';

  Location get location {
    if (_class is PartialClassElement) {
      var node = _class.parseNode(_diagnosticListener);
      if (node !== null) {
        var script = _class.getCompilationUnit().script;
        var span = system.compiler.spanFromNode(node, script.uri);
        return new Dart2JsLocation(script, span);
      }
    }
    return super.location;
  }

  void _ensureMembers() {
    if (_members == null) {
      _members = <String, Dart2JsMemberMirror>{};
      _class.localMembers.forEach((e) {
        for (var member in _convertElementMemberToMemberMirrors(this, e)) {
          _members[member.canonicalName] = member;
        }
      });
    }
  }

  Map<Object, MemberMirror> get declaredMembers {
    _ensureMembers();
    return new ImmutableMapWrapper<Object, MemberMirror>(_members);
  }

  bool get isObject => _class == system.compiler.objectClass;

  bool get isDynamic => _class == system.compiler.dynamicClass;

  bool get isVoid => false;

  bool get isTypeVariable => false;

  bool get isTypedef => false;

  bool get isFunction => false;

  InterfaceMirror get declaration => this;

  InterfaceMirror get superclass {
    if (_class.supertype != null) {
      return new Dart2JsInterfaceTypeMirror(system, _class.supertype);
    }
    return null;
  }

  Map<Object, InterfaceMirror> get interfaces {
    var map = new Map<String, InterfaceMirror>();
    Link<DartType> link = _class.interfaces;
    while (!link.isEmpty()) {
      var type = _convertTypeToTypeMirror(system, link.head,
                                          system.compiler.types.dynamicType);
      map[type.canonicalName] = type;
      link = link.tail;
    }
    return new ImmutableMapWrapper<Object, InterfaceMirror>(map);
  }

  bool get isClass => !_class.isInterface();

  bool get isInterface => _class.isInterface();

  bool get isPrivate => _isPrivate(simpleName);

  bool get isDeclaration => true;

  List<TypeMirror> get typeArguments {
    throw new UnsupportedOperationException(
        'Declarations do not have type arguments');
  }

  List<TypeVariableMirror> get typeVariables {
    if (_typeVariables == null) {
      _typeVariables = <TypeVariableMirror>[];
      _class.ensureResolved(system.compiler);
      for (TypeVariableType typeVariable in _class.typeVariables) {
        _typeVariables.add(
            new Dart2JsTypeVariableMirror(system, typeVariable));
      }
    }
    return _typeVariables;
  }

  Map<Object, MethodMirror> get constructors {
    _ensureMembers();
    return new AsFilteredImmutableMap<Object, MemberMirror, MethodMirror>(
        _members, (m) => m.isConstructor ? m : null);
  }

  /**
   * Returns the default type for this interface.
   */
  InterfaceMirror get defaultType {
    if (_class.defaultClass != null) {
      return new Dart2JsInterfaceTypeMirror(system, _class.defaultClass);
    }
    return null;
  }

  bool operator ==(Object other) {
    if (this === other) {
      return true;
    }
    if (other is! InterfaceMirror) {
      return false;
    }
    if (library != other.library) {
      return false;
    }
    if (isDeclaration !== other.isDeclaration) {
      return false;
    }
    return qualifiedName == other.qualifiedName;
  }
}

class Dart2JsTypedefMirror extends Dart2JsTypeElementMirror
    implements Dart2JsTypeMirror, TypedefMirror {
  final Dart2JsLibraryMirror _library;
  List<TypeVariableMirror> _typeVariables;
  TypeMirror _definition;

  Dart2JsTypedefMirror(Dart2JsMirrorSystem system, TypedefType _typedef)
      : this._library = system.getLibrary(_typedef.element.getLibrary()),
        super(system, _typedef);

  Dart2JsTypedefMirror.fromLibrary(Dart2JsLibraryMirror library,
                                   TypedefType _typedef)
      : this._library = library,
        super(library.system, _typedef);

  TypedefType get _typedef => _type;

  String get canonicalName => simpleName;

  String get qualifiedName => '${library.qualifiedName}.${simpleName}';

  Location get location {
    var node = _typedef.element.parseNode(_diagnosticListener);
    if (node !== null) {
      var script = _typedef.element.getCompilationUnit().script;
      var span = system.compiler.spanFromNode(node, script.uri);
      return new Dart2JsLocation(script, span);
    }
    return super.location;
  }

  LibraryMirror get library => _library;

  bool get isObject => false;

  bool get isDynamic => false;

  bool get isVoid => false;

  bool get isTypeVariable => false;

  bool get isTypedef => true;

  bool get isFunction => false;

  List<TypeMirror> get typeArguments {
    throw new UnsupportedOperationException(
        'Declarations do not have type arguments');
  }

  List<TypeVariableMirror> get typeVariables {
    if (_typeVariables == null) {
      _typeVariables = <TypeVariableMirror>[];
      for (TypeVariableType typeVariable in _typedef.typeArguments) {
        _typeVariables.add(
            new Dart2JsTypeVariableMirror(system, typeVariable));
      }
    }
    return _typeVariables;
  }

  TypeMirror get definition {
    if (_definition === null) {
      // TODO(johnniwinther): Should be [ensureResolved].
      system.compiler.resolveTypedef(_typedef.element);
      _definition = _convertTypeToTypeMirror(
          system,
          _typedef.element.alias,
          system.compiler.types.dynamicType,
          _typedef.element.functionSignature);
    }
    return _definition;
  }

  Map<Object, MemberMirror> get declaredMembers =>
      const <String, MemberMirror>{};

  InterfaceMirror get declaration => this;

  // TODO(johnniwinther): How should a typedef respond to these?
  InterfaceMirror get superclass => null;

  Map<Object, InterfaceMirror> get interfaces =>
      const <String, InterfaceMirror>{};

  bool get isClass => false;

  bool get isInterface => false;

  bool get isPrivate => _isPrivate(simpleName);

  bool get isDeclaration => true;

  Map<Object, MethodMirror> get constructors =>
      const <String, MethodMirror>{};

  InterfaceMirror get defaultType => null;
}

class Dart2JsTypeVariableMirror extends Dart2JsTypeElementMirror
    implements TypeVariableMirror {
  final TypeVariableType _typeVariableType;
  InterfaceMirror _declarer;

  Dart2JsTypeVariableMirror(Dart2JsMirrorSystem system,
                            TypeVariableType typeVariableType)
    : this._typeVariableType = typeVariableType,
      super(system, typeVariableType) {
      assert(_typeVariableType !== null);
  }


  String get qualifiedName => '${declarer.qualifiedName}.${simpleName}';

  InterfaceMirror get declarer {
    if (_declarer === null) {
      if (_typeVariableType.element.enclosingElement.isClass()) {
        _declarer = new Dart2JsInterfaceMirror(system,
            _typeVariableType.element.enclosingElement);
      } else if (_typeVariableType.element.enclosingElement.isTypedef()) {
        _declarer = new Dart2JsTypedefMirror(system,
            _typeVariableType.element.enclosingElement.computeType(
                system.compiler));
      }
    }
    return _declarer;
  }

  LibraryMirror get library => declarer.library;

  bool get isObject => false;

  bool get isDynamic => false;

  bool get isVoid => false;

  bool get isTypeVariable => true;

  bool get isTypedef => false;

  bool get isFunction => false;

  TypeMirror get bound => _convertTypeToTypeMirror(
      system,
      _typeVariableType.element.bound,
      system.compiler.objectClass.computeType(system.compiler));

  bool operator ==(Object other) {
    if (this === other) {
      return true;
    }
    if (other is! TypeVariableMirror) {
      return false;
    }
    if (declarer != other.declarer) {
      return false;
    }
    return qualifiedName == other.qualifiedName;
  }
}


//------------------------------------------------------------------------------
// Types
//------------------------------------------------------------------------------

abstract class Dart2JsTypeElementMirror extends Dart2JsProxyMirror
    implements Dart2JsTypeMirror {
  final DartType _type;

  Dart2JsTypeElementMirror(Dart2JsMirrorSystem system, this._type)
    : super(system);

  String get simpleName => _type.name.slowToString();

  String get canonicalName => simpleName;

  Location get location {
    var script = _type.element.getCompilationUnit().script;
    return new Dart2JsLocation(script,
                               system.compiler.spanFromElement(_type.element));
  }

  LibraryMirror get library {
    return system.getLibrary(_type.element.getLibrary());
  }

  String toString() => _type.element.toString();
}

class Dart2JsInterfaceTypeMirror extends Dart2JsTypeElementMirror
    implements InterfaceMirror {
  List<TypeMirror> _typeArguments;

  Dart2JsInterfaceTypeMirror(Dart2JsMirrorSystem system,
                             InterfaceType interfaceType)
      : super(system, interfaceType);

  InterfaceType get _interfaceType => _type;

  String get qualifiedName => declaration.qualifiedName;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<Object, MemberMirror> get declaredMembers => declaration.declaredMembers;

  bool get isObject => system.compiler.objectClass == _type.element;

  bool get isDynamic => system.compiler.dynamicClass == _type.element;

  bool get isTypeVariable => false;

  bool get isVoid => false;

  bool get isTypedef => false;

  bool get isFunction => false;

  InterfaceMirror get declaration
      => new Dart2JsInterfaceMirror(system, _type.element);

  // TODO(johnniwinther): Substitute type arguments for type variables.
  InterfaceMirror get superclass => declaration.superclass;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<Object, InterfaceMirror> get interfaces => declaration.interfaces;

  bool get isClass => declaration.isClass;

  bool get isInterface => declaration.isInterface;

  bool get isPrivate => declaration.isPrivate;

  bool get isDeclaration => false;

  List<TypeMirror> get typeArguments {
    if (_typeArguments == null) {
      _typeArguments = <TypeMirror>[];
      Link<DartType> type = _interfaceType.arguments;
      while (type != null && type.head != null) {
        _typeArguments.add(_convertTypeToTypeMirror(system, type.head,
            system.compiler.types.dynamicType));
        type = type.tail;
      }
    }
    return _typeArguments;
  }

  List<TypeVariableMirror> get typeVariables => declaration.typeVariables;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<Object, MethodMirror> get constructors => declaration.constructors;

  // TODO(johnniwinther): Substitute type arguments for type variables?
  InterfaceMirror get defaultType => declaration.defaultType;

  bool operator ==(Object other) {
    if (this === other) {
      return true;
    }
    if (other is! InterfaceMirror) {
      return false;
    }
    if (other.isDeclaration) {
      return false;
    }
    if (declaration != other.declaration) {
      return false;
    }
    var thisTypeArguments = typeArguments.iterator();
    var otherTypeArguments = other.typeArguments.iterator();
    while (thisTypeArguments.hasNext() && otherTypeArguments.hasNext()) {
      if (thisTypeArguments.next() != otherTypeArguments.next()) {
        return false;
      }
    }
    return !thisTypeArguments.hasNext() && !otherTypeArguments.hasNext();
  }
}


class Dart2JsFunctionTypeMirror extends Dart2JsTypeElementMirror
    implements FunctionTypeMirror {
  final FunctionSignature _functionSignature;
  List<ParameterMirror> _parameters;

  Dart2JsFunctionTypeMirror(Dart2JsMirrorSystem system,
                             FunctionType functionType, this._functionSignature)
      : super(system, functionType) {
    assert (_functionSignature !== null);
  }

  FunctionType get _functionType => _type;

  // TODO(johnniwinther): Is this the qualified name of a function type?
  String get qualifiedName => declaration.qualifiedName;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<Object, MemberMirror> get declaredMembers {
    var method = callMethod;
    if (method !== null) {
      var map = new Map<String, MemberMirror>.from(
          declaration.declaredMembers);
      var name = method.qualifiedName;
      map[name] = method;
      Function func = null;
      return new ImmutableMapWrapper<Object, MemberMirror>(map);
    }
    return declaration.declaredMembers;
  }

  bool get isObject => system.compiler.objectClass == _type.element;

  bool get isDynamic => system.compiler.dynamicClass == _type.element;

  bool get isVoid => false;

  bool get isTypeVariable => false;

  bool get isTypedef => false;

  bool get isFunction => true;

  MethodMirror get callMethod => _convertElementMethodToMethodMirror(
      system.getLibrary(_functionType.element.getLibrary()),
      _functionType.element);

  InterfaceMirror get declaration
      => new Dart2JsInterfaceMirror(system, system.compiler.functionClass);

  // TODO(johnniwinther): Substitute type arguments for type variables.
  InterfaceMirror get superclass => declaration.superclass;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<Object, InterfaceMirror> get interfaces => declaration.interfaces;

  bool get isClass => declaration.isClass;

  bool get isInterface => declaration.isInterface;

  bool get isPrivate => declaration.isPrivate;

  bool get isDeclaration => false;

  List<TypeMirror> get typeArguments => const <TypeMirror>[];

  List<TypeVariableMirror> get typeVariables => declaration.typeVariables;

  Map<Object, MethodMirror> get constructors =>
      <String, MethodMirror>{};

  InterfaceMirror get defaultType => null;

  TypeMirror get returnType {
    return _convertTypeToTypeMirror(system, _functionType.returnType,
                                    system.compiler.types.dynamicType);
  }

  List<ParameterMirror> get parameters {
    if (_parameters === null) {
      _parameters = _parametersFromFunctionSignature(system, callMethod,
                                                     _functionSignature);
    }
    return _parameters;
  }
}

class Dart2JsVoidMirror extends Dart2JsTypeElementMirror {

  Dart2JsVoidMirror(Dart2JsMirrorSystem system, VoidType voidType)
      : super(system, voidType);

  VoidType get _voidType => _type;

  String get qualifiedName => simpleName;

  /**
   * The void type has no location.
   */
  Location get location => null;

  /**
   * The void type has no library.
   */
  LibraryMirror get library => null;

  bool get isObject => false;

  bool get isVoid => true;

  bool get isDynamic => false;

  bool get isTypeVariable => false;

  bool get isTypedef => false;

  bool get isFunction => false;

  bool operator ==(Object other) {
    if (this === other) {
      return true;
    }
    if (other is! TypeMirror) {
      return false;
    }
    return other.isVoid;
  }
}

//------------------------------------------------------------------------------
// Member mirrors implementation.
//------------------------------------------------------------------------------

class Dart2JsMethodMirror extends Dart2JsElementMirror
    implements Dart2JsMemberMirror, MethodMirror {
  final Dart2JsObjectMirror _objectMirror;
  String _name;
  String _constructorName;
  String _operatorName;
  Dart2JsMethodKind _kind;
  String _canonicalName;

  Dart2JsMethodMirror(Dart2JsObjectMirror objectMirror,
                      FunctionElement function)
      : this._objectMirror = objectMirror,
        super(objectMirror.system, function) {
    _name = _element.name.slowToString();
    if (_function.kind == ElementKind.GETTER) {
      _kind = Dart2JsMethodKind.GETTER;
      _canonicalName = _name;
    } else if (_function.kind == ElementKind.SETTER) {
      _kind = Dart2JsMethodKind.SETTER;
      _canonicalName = '$_name=';
    } else if (_function.kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
      _constructorName = '';
      int dollarPos = _name.indexOf('\$');
      if (dollarPos != -1) {
        _constructorName = _name.substring(dollarPos + 1);
        _name = _name.substring(0, dollarPos);
        // canonical name is TypeName.constructorName
        _canonicalName = '$_name.$_constructorName';
      } else {
        // canonical name is TypeName
        _canonicalName = _name;
      }
      if (_function.modifiers !== null && _function.modifiers.isConst()) {
        _kind = Dart2JsMethodKind.CONST;
      } else {
        _kind = Dart2JsMethodKind.CONSTRUCTOR;
      }
    } else if (_function.modifiers !== null &&
               _function.modifiers.isFactory()) {
      _kind = Dart2JsMethodKind.FACTORY;
      _constructorName = '';
      int dollarPos = _name.indexOf('\$');
      if (dollarPos != -1) {
        _constructorName = _name.substring(dollarPos+1);
        _name = _name.substring(0, dollarPos);
      }
      // canonical name is TypeName.constructorName
      _canonicalName = '$_name.$_constructorName';
    } else if (_name == 'negate') {
      _operatorName = _name;
      _name = 'operator';
      _kind = Dart2JsMethodKind.OPERATOR;
      // canonical name is 'operator operatorName'
      _canonicalName = 'operator $_operatorName';
    } else if (_name.startsWith('operator\$')) {
      String str = _name.substring(9);
      _name = 'operator';
      _kind = Dart2JsMethodKind.OPERATOR;
      _operatorName = _getOperatorFromOperatorName(str);
      // canonical name is 'operator operatorName'
      _canonicalName = 'operator $_operatorName';
    } else {
      _kind = Dart2JsMethodKind.NORMAL;
      _canonicalName = _name;
    }
  }

  FunctionElement get _function => _element;

  String get simpleName => _name;

  String get qualifiedName
      => '${surroundingDeclaration.qualifiedName}.$canonicalName';

  String get canonicalName => _canonicalName;

  ObjectMirror get surroundingDeclaration => _objectMirror;

  bool get isTopLevel => _objectMirror is LibraryMirror;

  bool get isConstructor
      => _kind == Dart2JsMethodKind.CONSTRUCTOR || isConst || isFactory;

  bool get isField => false;

  bool get isMethod => !isConstructor;

  bool get isPrivate => _isPrivate(simpleName);

  bool get isStatic =>
      _function.modifiers !== null && _function.modifiers.isStatic();

  List<ParameterMirror> get parameters {
    return _parametersFromFunctionSignature(system, this,
        _function.computeSignature(system.compiler));
  }

  TypeMirror get returnType => _convertTypeToTypeMirror(
      system, _function.computeSignature(system.compiler).returnType,
      system.compiler.types.dynamicType);

  bool get isConst => _kind == Dart2JsMethodKind.CONST;

  bool get isFactory => _kind == Dart2JsMethodKind.FACTORY;

  String get constructorName => _constructorName;

  bool get isGetter => _kind == Dart2JsMethodKind.GETTER;

  bool get isSetter => _kind == Dart2JsMethodKind.SETTER;

  bool get isOperator => _kind == Dart2JsMethodKind.OPERATOR;

  String get operatorName => _operatorName;

  Location get location {
    var node = _function.parseNode(_diagnosticListener);
    if (node !== null) {
      var script = _function.getCompilationUnit().script;
      if (_function.isPatched) {
        // TODO(ager): This should not be necessary when patch
        // support has been reworked.
        script = _function.patch.getCompilationUnit().script;
      }
      var span = system.compiler.spanFromNode(node, script.uri);
      return new Dart2JsLocation(script, span);
    }
    return super.location;
  }

}

class Dart2JsFieldMirror extends Dart2JsElementMirror
    implements Dart2JsMemberMirror, FieldMirror {
  Dart2JsObjectMirror _objectMirror;
  VariableElement _variable;

  Dart2JsFieldMirror(Dart2JsObjectMirror objectMirror,
                     VariableElement variable)
      : this._objectMirror = objectMirror,
        this._variable = variable,
        super(objectMirror.system, variable);

  String get qualifiedName
      => '${surroundingDeclaration.qualifiedName}.$canonicalName';

  String get canonicalName => simpleName;

  ObjectMirror get surroundingDeclaration => _objectMirror;

  bool get isTopLevel => _objectMirror is LibraryMirror;

  bool get isConstructor => false;

  bool get isField => true;

  bool get isMethod => false;

  bool get isPrivate => _isPrivate(simpleName);

  bool get isStatic => _variable.modifiers.isStatic();

  // TODO(johnniwinther): Should this return true on const as well?
  bool get isFinal => _variable.modifiers.isFinal();

  TypeMirror get type => _convertTypeToTypeMirror(system,
      _variable.computeType(system.compiler),
      system.compiler.types.dynamicType);

  Location get location {
    var script = _variable.getCompilationUnit().script;
    var node = _variable.variables.parseNode(_diagnosticListener);
    if (node !== null) {
      var span = system.compiler.spanFromNode(node, script.uri);
      return new Dart2JsLocation(script, span);
    } else {
      var span = system.compiler.spanFromElement(_variable);
      return new Dart2JsLocation(script, span);
    }
  }
}

