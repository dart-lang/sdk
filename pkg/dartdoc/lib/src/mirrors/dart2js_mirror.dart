// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mirrors_dart2js;

import 'dart:io';
import 'dart:uri';

import '../../../../../lib/compiler/compiler.dart' as diagnostics;
import '../../../../../lib/compiler/implementation/elements/elements.dart';
import '../../../../../lib/compiler/implementation/resolution/resolution.dart'
    show ResolverTask, ResolverVisitor;
import '../../../../../lib/compiler/implementation/apiimpl.dart' as api;
import '../../../../../lib/compiler/implementation/scanner/scannerlib.dart';
import '../../../../../lib/compiler/implementation/ssa/ssa.dart';
import '../../../../../lib/compiler/implementation/dart2jslib.dart';
import '../../../../../lib/compiler/implementation/filenames.dart';
import '../../../../../lib/compiler/implementation/source_file.dart';
import '../../../../../lib/compiler/implementation/tree/tree.dart';
import '../../../../../lib/compiler/implementation/util/util.dart';
import '../../../../../lib/compiler/implementation/util/uri_extras.dart';
import '../../../../../lib/compiler/implementation/dart2js.dart';

// TODO(rnystrom): Use "package:" URL (#4968).
import '../../mirrors.dart';
import 'util.dart';

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
  while (!link.isEmpty) {
    parameters.add(new Dart2JsParameterMirror(
        system, method, link.head, false, false));
    link = link.tail;
  }
  link = signature.optionalParameters;
  bool isNamed = signature.optionalParametersAreNamed;
  while (!link.isEmpty) {
    parameters.add(new Dart2JsParameterMirror(
        system, method, link.head, true, isNamed));
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
    if (type === system.compiler.types.dynamicType) {
      return new Dart2JsDynamicMirror(system, type);
    } else {
      return new Dart2JsInterfaceTypeMirror(system, type);
    }
  } else if (type is TypeVariableType) {
    return new Dart2JsTypeVariableMirror(system, type);
  } else if (type is FunctionType) {
    return new Dart2JsFunctionTypeMirror(system, type, functionSignature);
  } else if (type is VoidType) {
    return new Dart2JsVoidMirror(system, type);
  } else if (type is TypedefType) {
    return new Dart2JsTypedefMirror(system, type);
  }
  throw new ArgumentError("Unexpected interface type $type");
}

Collection<Dart2JsMemberMirror> _convertElementMemberToMemberMirrors(
    Dart2JsContainerMirror library, Element element) {
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
  throw new ArgumentError(
      "Unexpected member type $element ${element.kind}");
}

MethodMirror _convertElementMethodToMethodMirror(Dart2JsContainerMirror library,
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

  void cancel(String reason, {node, token, instruction, element}) {
    print(reason);
  }

  void log(message) {
    print(message);
  }

  void internalError(String message,
                     {Node node, Token token, HInstruction instruction,
                      Element element}) {
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
      elementList.add(libraryLoader.loadLibrary(uri, null, uri));
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
    backend.processNativeClasses(world, libraries.values);
    for (var library in elements) {
      library.forEachLocalMember((element) {
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
      throw new ArgumentError(uri);
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

  MirrorSystem get mirrors => new Dart2JsMirrorSystem(_compiler);

  Future<String> compileToJavaScript() =>
      new Future<String>.immediate(_compiler.assembledCode);
}


//------------------------------------------------------------------------------
// Dart2Js specific extensions of mirror interfaces
//------------------------------------------------------------------------------

abstract class Dart2JsMirror implements Mirror {
  Dart2JsMirrorSystem get system;
}

abstract class Dart2JsDeclarationMirror
    implements Dart2JsMirror, DeclarationMirror {

  bool get isTopLevel => owner != null && owner is LibraryMirror;

  bool get isPrivate => _isPrivate(simpleName);
}

abstract class Dart2JsMemberMirror extends Dart2JsElementMirror
    implements MemberMirror {

  Dart2JsMemberMirror(Dart2JsMirrorSystem system, Element element)
      : super(system, element);

  bool get isConstructor => false;

  bool get isField => false;

  bool get isMethod => false;

  bool get isStatic => false;
}

abstract class Dart2JsTypeMirror extends Dart2JsDeclarationMirror
    implements TypeMirror {

}

abstract class Dart2JsElementMirror extends Dart2JsDeclarationMirror {
  final Dart2JsMirrorSystem system;
  final Element _element;

  Dart2JsElementMirror(this.system, this._element) {
    assert (system !== null);
    assert (_element !== null);
  }

  String get simpleName => _element.name.slowToString();

  String get displayName => simpleName;

  SourceLocation get location => new Dart2JsLocation(
      _element.getCompilationUnit().script,
      system.compiler.spanFromElement(_element));

  String toString() => _element.toString();

  int get hashCode => qualifiedName.hashCode;
}

abstract class Dart2JsProxyMirror extends Dart2JsDeclarationMirror {
  final Dart2JsMirrorSystem system;

  Dart2JsProxyMirror(this.system);

  String get displayName => simpleName;

  int get hashCode => qualifiedName.hashCode;
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
        _libraries[mirror.simpleName] = mirror;
        _libraryMap[v] = mirror;
      });
    }
  }

  Map<String, LibraryMirror> get libraries {
    _ensureLibraries();
    return new ImmutableMapWrapper<String, LibraryMirror>(_libraries);
  }

  Dart2JsLibraryMirror getLibrary(LibraryElement element) {
    return _libraryMap[element];
  }

  Dart2JsMirrorSystem get system => this;

  String get simpleName => "mirror";
  String get displayName => simpleName;
  String get qualifiedName => simpleName;

  // TODO(johnniwinther): Hack! Dart2JsMirrorSystem need not be a Mirror.
  int get hashCode => qualifiedName.hashCode;
}

abstract class Dart2JsContainerMirror extends Dart2JsElementMirror
    implements ContainerMirror {
  Map<String, MemberMirror> _members;

  Dart2JsContainerMirror(Dart2JsMirrorSystem system, Element element)
      : super(system, element);

  abstract void _ensureMembers();

  Map<String, MemberMirror> get members {
    _ensureMembers();
    return new ImmutableMapWrapper<String, MemberMirror>(_members);
  }

  Map<String, MethodMirror> get functions {
    _ensureMembers();
    return new AsFilteredImmutableMap<String, MemberMirror, MethodMirror>(
        _members,
        (MemberMirror member) => member is MethodMirror);
  }

  Map<String, MethodMirror> get getters {
    _ensureMembers();
    return new AsFilteredImmutableMap<String, MemberMirror, MethodMirror>(
        _members,
        (MemberMirror member) =>
            member is MethodMirror && (member as MethodMirror).isGetter);
  }

  Map<String, MethodMirror> get setters {
    _ensureMembers();
    return new AsFilteredImmutableMap<String, MemberMirror, MethodMirror>(
        _members,
        (MemberMirror member) =>
            member is MethodMirror && (member as MethodMirror).isSetter);
  }

  Map<String, VariableMirror> get variables {
    _ensureMembers();
    return new AsFilteredImmutableMap<String, MemberMirror, VariableMirror>(
        _members,
        (MemberMirror member) => member is VariableMirror);
  }
}

class Dart2JsLibraryMirror extends Dart2JsContainerMirror
    implements LibraryMirror {
  Map<String, ClassMirror> _classes;

  Dart2JsLibraryMirror(Dart2JsMirrorSystem system, LibraryElement library)
      : super(system, library);

  LibraryElement get _library => _element;

  Uri get uri => _library.uri;

  DeclarationMirror get owner => null;

  bool get isPrivate => false;

  LibraryMirror library() => this;

  /**
   * Returns the library name (for libraries with a #library tag) or the script
   * file name (for scripts without a #library tag). The latter case is used to
   * provide a 'library name' for scripts, to use for instance in dartdoc.
   */
  String get simpleName {
    if (_library.libraryTag !== null) {
      // TODO(ahe): Remove StringNode check when old syntax is removed.
      StringNode name = _library.libraryTag.name.asStringNode();
      if (name !== null) {
        return name.dartString.slowToString();
      } else {
        return _library.libraryTag.name.toString();
      }
    } else {
      // Use the file name as script name.
      String path = _library.uri.path;
      return path.substring(path.lastIndexOf('/') + 1);
    }
  }

  String get qualifiedName => simpleName;

  void _ensureClasses() {
    if (_classes == null) {
      _classes = <String, ClassMirror>{};
      _library.forEachLocalMember((Element e) {
        if (e.isClass()) {
          ClassElement classElement = e;
          classElement.ensureResolved(system.compiler);
          var type = new Dart2JsClassMirror.fromLibrary(this, classElement);
          assert(invariant(_library, !_classes.containsKey(type.simpleName),
              message: "Type name '${type.simpleName}' "
                       "is not unique in $_library."));
          _classes[type.simpleName] = type;
        } else if (e.isTypedef()) {
          var type = new Dart2JsTypedefMirror.fromLibrary(this,
              e.computeType(system.compiler));
          assert(invariant(_library, !_classes.containsKey(type.simpleName),
              message: "Type name '${type.simpleName}' "
                       "is not unique in $_library."));
          _classes[type.simpleName] = type;
        }
      });
    }
  }

  void _ensureMembers() {
    if (_members == null) {
      _members = <String, MemberMirror>{};
      _library.forEachLocalMember((Element e) {
        if (!e.isClass() && !e.isTypedef()) {
          for (var member in _convertElementMemberToMemberMirrors(this, e)) {
            assert(!_members.containsKey(member.simpleName));
            _members[member.simpleName] = member;
          }
        }
      });
    }
  }

  Map<String, ClassMirror> get classes {
    _ensureClasses();
    return new ImmutableMapWrapper<String, ClassMirror>(_classes);
  }

  SourceLocation get location {
    var script = _library.getCompilationUnit().script;
    return new Dart2JsLocation(
        script,
        new SourceSpan(script.uri, 0, script.text.length));
  }
}

class Dart2JsLocation implements SourceLocation {
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

class Dart2JsParameterMirror extends Dart2JsMemberMirror
    implements ParameterMirror {
  final MethodMirror _method;
  final bool isOptional;
  final bool isNamed;

  factory Dart2JsParameterMirror(Dart2JsMirrorSystem system,
                                 MethodMirror method,
                                 VariableElement element,
                                 bool isOptional,
                                 bool isNamed) {
    if (element is FieldParameterElement) {
      return new Dart2JsFieldParameterMirror(system,
          method, element, isOptional, isNamed);
    }
    return new Dart2JsParameterMirror._normal(system,
        method, element, isOptional, isNamed);
  }

  Dart2JsParameterMirror._normal(Dart2JsMirrorSystem system,
                         this._method,
                         VariableElement element,
                         this.isOptional,
                         this.isNamed)
    : super(system, element);

  DeclarationMirror get owner => _method;

  VariableElement get _variableElement => _element;

  String get qualifiedName => '${_method.qualifiedName}#${simpleName}';

  TypeMirror get type => _convertTypeToTypeMirror(system,
      _variableElement.computeType(system.compiler),
      system.compiler.types.dynamicType,
      _variableElement.variables.functionSignature);


  bool get isFinal => false;

  bool get isConst => false;

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

  VariableMirror get initializedField => null;
}

class Dart2JsFieldParameterMirror extends Dart2JsParameterMirror {

  Dart2JsFieldParameterMirror(Dart2JsMirrorSystem system,
                              MethodMirror method,
                              FieldParameterElement element,
                              bool isOptional,
                              bool isNamed)
      : super._normal(system, method, element, isOptional, isNamed);

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

  VariableMirror get initializedField => new Dart2JsFieldMirror(
      _method.owner, _fieldParameterElement.fieldElement);
}

//------------------------------------------------------------------------------
// Declarations
//------------------------------------------------------------------------------
class Dart2JsClassMirror extends Dart2JsContainerMirror
    implements Dart2JsTypeMirror, ClassMirror {
  final Dart2JsLibraryMirror library;
  List<TypeVariableMirror> _typeVariables;

  Dart2JsClassMirror(Dart2JsMirrorSystem system, ClassElement _class)
      : this.library = system.getLibrary(_class.getLibrary()),
        super(system, _class);

  ClassElement get _class => _element;

  Dart2JsClassMirror.fromLibrary(Dart2JsLibraryMirror library,
                                 ClassElement _class)
      : this.library = library,
        super(library.system, _class);

  DeclarationMirror get owner => library;

  String get qualifiedName => '${library.qualifiedName}.${simpleName}';

  SourceLocation get location {
    if (_class is PartialClassElement) {
      var node = _class.parseNode(system.compiler);
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
      _class.forEachMember((_, e) {
        for (var member in _convertElementMemberToMemberMirrors(this, e)) {
          assert(!_members.containsKey(member.simpleName));
          _members[member.simpleName] = member;
        }
      });
    }
  }

  Map<String, MethodMirror> get methods => functions;

  Map<String, MethodMirror> get constructors {
    _ensureMembers();
    return new AsFilteredImmutableMap<String, MemberMirror, MethodMirror>(
        _members, (m) => m.isConstructor ? m : null);
  }

  bool get isObject => _class == system.compiler.objectClass;

  bool get isDynamic => false;

  bool get isVoid => false;

  bool get isTypeVariable => false;

  bool get isTypedef => false;

  bool get isFunction => false;

  ClassMirror get originalDeclaration => this;

  ClassMirror get superclass {
    if (_class.supertype != null) {
      return new Dart2JsInterfaceTypeMirror(system, _class.supertype);
    }
    return null;
  }

  List<ClassMirror> get superinterfaces {
    var list = <ClassMirror>[];
    Link<DartType> link = _class.interfaces;
    while (!link.isEmpty) {
      var type = _convertTypeToTypeMirror(system, link.head,
                                          system.compiler.types.dynamicType);
      list.add(type);
      link = link.tail;
    }
    return list;
  }

  bool get isClass => !_class.isInterface();

  bool get isInterface => _class.isInterface();

  bool get isAbstract => _class.modifiers.isAbstract();

  bool get isOriginalDeclaration => true;

  List<TypeMirror> get typeArguments {
    throw new UnsupportedError(
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

  /**
   * Returns the default type for this interface.
   */
  ClassMirror get defaultFactory {
    if (_class.defaultClass != null) {
      return new Dart2JsInterfaceTypeMirror(system, _class.defaultClass);
    }
    return null;
  }

  bool operator ==(Object other) {
    if (this === other) {
      return true;
    }
    if (other is! ClassMirror) {
      return false;
    }
    if (library != other.library) {
      return false;
    }
    if (isOriginalDeclaration !== other.isOriginalDeclaration) {
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

  String get qualifiedName => '${library.qualifiedName}.${simpleName}';

  SourceLocation get location {
    var node = _typedef.element.parseNode(_diagnosticListener);
    if (node !== null) {
      var script = _typedef.element.getCompilationUnit().script;
      var span = system.compiler.spanFromNode(node, script.uri);
      return new Dart2JsLocation(script, span);
    }
    return super.location;
  }

  LibraryMirror get library => _library;

  bool get isTypedef => true;

  List<TypeMirror> get typeArguments {
    throw new UnsupportedError(
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

  TypeMirror get value {
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

  ClassMirror get originalDeclaration => this;

  // TODO(johnniwinther): How should a typedef respond to these?
  ClassMirror get superclass => null;

  List<ClassMirror> get superinterfaces => const <ClassMirror>[];

  bool get isClass => false;

  bool get isInterface => false;

  bool get isOriginalDeclaration => true;

  bool get isAbstract => false;
}

class Dart2JsTypeVariableMirror extends Dart2JsTypeElementMirror
    implements TypeVariableMirror {
  final TypeVariableType _typeVariableType;
  ClassMirror _declarer;

  Dart2JsTypeVariableMirror(Dart2JsMirrorSystem system,
                            TypeVariableType typeVariableType)
    : this._typeVariableType = typeVariableType,
      super(system, typeVariableType) {
      assert(_typeVariableType !== null);
  }


  String get qualifiedName => '${declarer.qualifiedName}.${simpleName}';

  ClassMirror get declarer {
    if (_declarer === null) {
      if (_typeVariableType.element.enclosingElement.isClass()) {
        _declarer = new Dart2JsClassMirror(system,
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

  DeclarationMirror get owner => declarer;

  bool get isTypeVariable => true;

  TypeMirror get upperBound => _convertTypeToTypeMirror(
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

  SourceLocation get location {
    var script = _type.element.getCompilationUnit().script;
    return new Dart2JsLocation(script,
                               system.compiler.spanFromElement(_type.element));
  }

  DeclarationMirror get owner => library;

  LibraryMirror get library {
    return system.getLibrary(_type.element.getLibrary());
  }

  bool get isObject => false;

  bool get isVoid => false;

  bool get isDynamic => false;

  bool get isTypeVariable => false;

  bool get isTypedef => false;

  bool get isFunction => false;

  String toString() => _type.element.toString();

  Map<String, MemberMirror> get members => const <String, MemberMirror>{};

  Map<String, MethodMirror> get constructors => const <String, MethodMirror>{};

  Map<String, MethodMirror> get methods => const <String, MethodMirror>{};

  Map<String, MethodMirror> get getters => const <String, MethodMirror>{};

  Map<String, MethodMirror> get setters => const <String, MethodMirror>{};

  Map<String, VariableMirror> get variables => const <String, VariableMirror>{};

  ClassMirror get defaultFactory => null;
}

class Dart2JsInterfaceTypeMirror extends Dart2JsTypeElementMirror
    implements ClassMirror {
  List<TypeMirror> _typeArguments;

  Dart2JsInterfaceTypeMirror(Dart2JsMirrorSystem system,
                             InterfaceType interfaceType)
      : super(system, interfaceType);

  InterfaceType get _interfaceType => _type;

  String get qualifiedName => originalDeclaration.qualifiedName;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<String, MemberMirror> get members => originalDeclaration.members;

  bool get isObject => system.compiler.objectClass == _type.element;

  bool get isDynamic => system.compiler.dynamicClass == _type.element;

  ClassMirror get originalDeclaration
      => new Dart2JsClassMirror(system, _type.element);

  // TODO(johnniwinther): Substitute type arguments for type variables.
  ClassMirror get superclass => originalDeclaration.superclass;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  List<ClassMirror> get superinterfaces => originalDeclaration.superinterfaces;

  bool get isClass => originalDeclaration.isClass;

  bool get isInterface => originalDeclaration.isInterface;

  bool get isAbstract => originalDeclaration.isAbstract;

  bool get isPrivate => originalDeclaration.isPrivate;

  bool get isOriginalDeclaration => false;

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

  List<TypeVariableMirror> get typeVariables =>
      originalDeclaration.typeVariables;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<String, MethodMirror> get constructors =>
      originalDeclaration.constructors;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<String, MethodMirror> get methods => originalDeclaration.methods;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<String, MethodMirror> get setters => originalDeclaration.setters;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<String, MethodMirror> get getters => originalDeclaration.getters;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<String, VariableMirror> get variables => originalDeclaration.variables;

  // TODO(johnniwinther): Substitute type arguments for type variables?
  ClassMirror get defaultFactory => originalDeclaration.defaultFactory;

  bool operator ==(Object other) {
    if (this === other) {
      return true;
    }
    if (other is! ClassMirror) {
      return false;
    }
    if (other.isOriginalDeclaration) {
      return false;
    }
    if (originalDeclaration != other.originalDeclaration) {
      return false;
    }
    var thisTypeArguments = typeArguments.iterator();
    var otherTypeArguments = other.typeArguments.iterator();
    while (thisTypeArguments.hasNext && otherTypeArguments.hasNext) {
      if (thisTypeArguments.next() != otherTypeArguments.next()) {
        return false;
      }
    }
    return !thisTypeArguments.hasNext && !otherTypeArguments.hasNext;
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
  String get qualifiedName => originalDeclaration.qualifiedName;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<String, MemberMirror> get members {
    var method = callMethod;
    if (method !== null) {
      var map = new Map<String, MemberMirror>.from(
          originalDeclaration.members);
      var name = method.qualifiedName;
      assert(!map.containsKey(name));
      map[name] = method;
      return new ImmutableMapWrapper<String, MemberMirror>(map);
    }
    return originalDeclaration.members;
  }

  bool get isFunction => true;

  MethodMirror get callMethod => _convertElementMethodToMethodMirror(
      system.getLibrary(_functionType.element.getLibrary()),
      _functionType.element);

  ClassMirror get originalDeclaration
      => new Dart2JsClassMirror(system, system.compiler.functionClass);

  // TODO(johnniwinther): Substitute type arguments for type variables.
  ClassMirror get superclass => originalDeclaration.superclass;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  List<ClassMirror> get superinterfaces => originalDeclaration.superinterfaces;

  bool get isClass => originalDeclaration.isClass;

  bool get isInterface => originalDeclaration.isInterface;

  bool get isPrivate => originalDeclaration.isPrivate;

  bool get isOriginalDeclaration => false;

  bool get isAbstract => false;

  List<TypeMirror> get typeArguments => const <TypeMirror>[];

  List<TypeVariableMirror> get typeVariables =>
      originalDeclaration.typeVariables;

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
  SourceLocation get location => null;

  /**
   * The void type has no library.
   */
  LibraryMirror get library => null;

  bool get isVoid => true;

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


class Dart2JsDynamicMirror extends Dart2JsTypeElementMirror {
  Dart2JsDynamicMirror(Dart2JsMirrorSystem system, InterfaceType voidType)
      : super(system, voidType);

  InterfaceType get _dynamicType => _type;

  String get qualifiedName => simpleName;

  /**
   * The dynamic type has no location.
   */
  SourceLocation get location => null;

  /**
   * The dynamic type has no library.
   */
  LibraryMirror get library => null;

  bool get isDynamic => true;

  bool operator ==(Object other) {
    if (this === other) {
      return true;
    }
    if (other is! TypeMirror) {
      return false;
    }
    return other.isDynamic;
  }
}

//------------------------------------------------------------------------------
// Member mirrors implementation.
//------------------------------------------------------------------------------

class Dart2JsMethodMirror extends Dart2JsMemberMirror
    implements MethodMirror {
  final Dart2JsContainerMirror _objectMirror;
  String _simpleName;
  String _displayName;
  String _constructorName;
  String _operatorName;
  Dart2JsMethodKind _kind;

  Dart2JsMethodMirror(Dart2JsContainerMirror objectMirror,
                      FunctionElement function)
      : this._objectMirror = objectMirror,
        super(objectMirror.system, function) {
    _simpleName = _element.name.slowToString();
    if (_function.kind == ElementKind.GETTER) {
      _kind = Dart2JsMethodKind.GETTER;
      _displayName = _simpleName;
    } else if (_function.kind == ElementKind.SETTER) {
      _kind = Dart2JsMethodKind.SETTER;
      _displayName = _simpleName;
      _simpleName = '$_simpleName=';
    } else if (_function.kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
      _constructorName = '';
      int dollarPos = _simpleName.indexOf('\$');
      if (dollarPos != -1) {
        _constructorName = _simpleName.substring(dollarPos + 1);
        _simpleName = _simpleName.substring(0, dollarPos);
        // Simple name is TypeName.constructorName.
        _simpleName = '$_simpleName.$_constructorName';
      } else {
        // Simple name is TypeName.
      }
      if (_function.modifiers.isConst()) {
        _kind = Dart2JsMethodKind.CONST;
      } else {
        _kind = Dart2JsMethodKind.CONSTRUCTOR;
      }
      _displayName = _simpleName;
    } else if (_function.modifiers.isFactory()) {
      _kind = Dart2JsMethodKind.FACTORY;
      _constructorName = '';
      int dollarPos = _simpleName.indexOf('\$');
      if (dollarPos != -1) {
        _constructorName = _simpleName.substring(dollarPos+1);
        _simpleName = _simpleName.substring(0, dollarPos);
        _simpleName = '$_simpleName.$_constructorName';
      }
      // Simple name is TypeName.constructorName.
      _displayName = _simpleName;
    } else if (_simpleName == 'negate') {
      _kind = Dart2JsMethodKind.OPERATOR;
      _operatorName = '-';
      // Simple name is 'unary-'.
      _simpleName = Mirror.UNARY_MINUS;
      // Display name is 'operator operatorName'.
      _displayName = 'operator -';
    } else if (_simpleName.startsWith('operator\$')) {
      String str = _simpleName.substring(9);
      _simpleName = 'operator';
      _kind = Dart2JsMethodKind.OPERATOR;
      _operatorName = _getOperatorFromOperatorName(str);
      // Simple name is 'operator operatorName'.
      _simpleName = _operatorName;
      // Display name is 'operator operatorName'.
      _displayName = 'operator $_operatorName';
    } else {
      _kind = Dart2JsMethodKind.NORMAL;
      _displayName = _simpleName;
    }
  }

  FunctionElement get _function => _element;

  String get simpleName => _simpleName;

  String get displayName => _displayName;

  String get qualifiedName
      => '${owner.qualifiedName}.$simpleName';

  DeclarationMirror get owner => _objectMirror;

  bool get isTopLevel => _objectMirror is LibraryMirror;

  bool get isConstructor
      => _kind == Dart2JsMethodKind.CONSTRUCTOR || isConst || isFactory;

  bool get isMethod => !isConstructor;

  bool get isPrivate =>
      isConstructor ? _isPrivate(constructorName) : _isPrivate(simpleName);

  bool get isStatic => _function.modifiers.isStatic();

  List<ParameterMirror> get parameters {
    return _parametersFromFunctionSignature(system, this,
        _function.computeSignature(system.compiler));
  }

  TypeMirror get returnType => _convertTypeToTypeMirror(
      system, _function.computeSignature(system.compiler).returnType,
      system.compiler.types.dynamicType);

  bool get isAbstract => _function.modifiers.isAbstract();

  bool get isConst => _kind == Dart2JsMethodKind.CONST;

  bool get isFactory => _kind == Dart2JsMethodKind.FACTORY;

  String get constructorName => _constructorName;

  bool get isGetter => _kind == Dart2JsMethodKind.GETTER;

  bool get isSetter => _kind == Dart2JsMethodKind.SETTER;

  bool get isOperator => _kind == Dart2JsMethodKind.OPERATOR;

  String get operatorName => _operatorName;

  SourceLocation get location {
    var node = _function.parseNode(_diagnosticListener);
    if (node !== null) {
      var script = _function.getCompilationUnit().script;
      var span = system.compiler.spanFromNode(node, script.uri);
      return new Dart2JsLocation(script, span);
    }
    return super.location;
  }

}

class Dart2JsFieldMirror extends Dart2JsMemberMirror implements VariableMirror {
  Dart2JsContainerMirror _objectMirror;
  VariableElement _variable;

  Dart2JsFieldMirror(Dart2JsContainerMirror objectMirror,
                     VariableElement variable)
      : this._objectMirror = objectMirror,
        this._variable = variable,
        super(objectMirror.system, variable);

  String get qualifiedName
      => '${owner.qualifiedName}.$simpleName';

  DeclarationMirror get owner => _objectMirror;

  bool get isTopLevel => _objectMirror is LibraryMirror;

  bool get isField => true;

  bool get isStatic => _variable.modifiers.isStatic();

  bool get isFinal => _variable.modifiers.isFinal();

  bool get isConst => _variable.modifiers.isConst();

  TypeMirror get type => _convertTypeToTypeMirror(system,
      _variable.computeType(system.compiler),
      system.compiler.types.dynamicType);

  SourceLocation get location {
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

