// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('mirrors.dart2js');

#import('../../compiler/compiler.dart', prefix: 'diagnostics');
#import('../../compiler/implementation/elements/elements.dart');
#import('../../compiler/implementation/apiimpl.dart', prefix: 'api');
#import('../../compiler/implementation/scanner/scannerlib.dart');
#import('../../compiler/implementation/leg.dart');
#import('../../compiler/implementation/filenames.dart');
#import('../../compiler/implementation/source_file.dart');
#import('../../compiler/implementation/tree/tree.dart');
#import('../../compiler/implementation/util/util.dart');
#import('../../compiler/implementation/util/uri_extras.dart');
#import('../../compiler/implementation/dart2js.dart');
#import('mirrors.dart');
#import('util.dart');
#import('dart:io');
#import('dart:uri');


//------------------------------------------------------------------------------
// Utility types and functions for the dart2js mirror system
//------------------------------------------------------------------------------

bool _isPrivate(String name) {
  return name.startsWith('_');
}

List<ParameterMirror> _parametersFromFunctionSignature(
    Dart2jsMirrorSystem system,
    Dart2jsMethodMirror method,
    FunctionSignature signature) {
  var parameters = <ParameterMirror>[];
  Link<Element> link = signature.requiredParameters;
  while (!link.isEmpty()) {
    parameters.add(new Dart2jsParameterMirror(system, method,
                                              link.head, false));
    link = link.tail;
  }
  link = signature.optionalParameters;
  while (!link.isEmpty()) {
    parameters.add(new Dart2jsParameterMirror(system, method,
                                              link.head, true));
    link = link.tail;
  }
  return parameters;
}

Dart2jsTypeMirror _convertTypeToTypeMirror(
    Dart2jsMirrorSystem system,
    Type type,
    InterfaceType defaultType,
    [FunctionSignature functionSignature]) {
  if (type === null) {
    return new Dart2jsInterfaceTypeMirror(system, defaultType);
  } else if (type is InterfaceType) {
    return new Dart2jsInterfaceTypeMirror(system, type);
  } else if (type is TypeVariableType) {
    return new Dart2jsTypeVariableMirror(system, type);
  } else if (type is FunctionType) {
    if (type.element is TypedefElement) {
      return new Dart2jsTypedefMirror(system, type.element);
    } else {
      return new Dart2jsFunctionTypeMirror(system, type, functionSignature);
    }
  } else if (type is VoidType) {
    return new Dart2jsVoidMirror(system, type);
  }
  throw new IllegalArgumentException("Unexpected interface type $type");
}

Collection<Dart2jsMemberMirror> _convertElementMemberToMemberMirrors(
    Dart2jsObjectMirror library, Element element) {
  if (element is SynthesizedConstructorElement) {
    return const <Dart2jsMemberMirror>[];
  } else if (element is VariableElement) {
    return <Dart2jsMemberMirror>[new Dart2jsFieldMirror(library, element)];
  } else if (element is FunctionElement) {
    return <Dart2jsMemberMirror>[new Dart2jsMethodMirror(library, element)];
  } else if (element is AbstractFieldElement) {
    var members = <Dart2jsMemberMirror>[];
    if (element.getter !== null) {
      members.add(new Dart2jsMethodMirror(library, element.getter,
                                          Dart2jsMethodKind.GETTER));
    }
    if (element.setter !== null) {
      members.add(new Dart2jsMethodMirror(library, element.setter,
                                          Dart2jsMethodKind.SETTER));
    }
    return members;
  }
  throw new IllegalArgumentException(
      "Unexpected member type $element ${element.kind}");
}

MethodMirror _convertElementMethodToMethodMirror(Dart2jsObjectMirror library,
                                                 Element element) {
  if (element is FunctionElement) {
    return new Dart2jsMethodMirror(library, element);
  } else {
    return null;
  }
}

class Dart2jsMethodKind {
  static final Dart2jsMethodKind NORMAL = const Dart2jsMethodKind("normal");
  static final Dart2jsMethodKind CONSTRUCTOR
      = const Dart2jsMethodKind("constructor");
  static final Dart2jsMethodKind CONST = const Dart2jsMethodKind("const");
  static final Dart2jsMethodKind FACTORY = const Dart2jsMethodKind("factory");
  static final Dart2jsMethodKind GETTER = const Dart2jsMethodKind("getter");
  static final Dart2jsMethodKind SETTER = const Dart2jsMethodKind("setter");
  static final Dart2jsMethodKind OPERATOR = const Dart2jsMethodKind("operator");

  final String text;

  const Dart2jsMethodKind(this.text);

  String toString() => text;
}


String _getOperatorFromOperatorName(String name) {
  Map<String, String> mapping = const {
    'eq': '==',
    'not': '~',
    'negate': 'negate', // Will change.
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

DiagnosticListener get _diagnosticListener() {
  return const Dart2jsDiagnosticListener();
}

class Dart2jsDiagnosticListener implements DiagnosticListener {
  const Dart2jsDiagnosticListener();

  void cancel([String reason, node, token, instruction, element]) {
    print(reason);
  }

  void log(message) {
    print(message);
  }
}

//------------------------------------------------------------------------------
// Compilation implementation
//------------------------------------------------------------------------------

class Dart2jsCompilation implements Compilation {
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
    } catch (FileIOException ex) {
      throw 'Error: Cannot read "${relativize(cwd, uri)}" (${ex.osError}).';
    }
    sourceFiles[uri.toString()] =
      new SourceFile(relativize(cwd, uri), source);
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

  Dart2jsCompilation(String script, String libraryRoot,
                     [String packageRoot, List<String> opts = const <String>[]])
      : cwd = getCurrentDirectory(), sourceFiles = <SourceFile>{} {
    var libraryUri = cwd.resolve(nativeToUriPath(libraryRoot));
    var packageUri;
    if (packageRoot !== null) {
      packageUri = cwd.resolve(nativeToUriPath(packageRoot));
    } else {
      packageUri = libraryUri;
    }
    _compiler = new api.Compiler(provider, handler,
        libraryUri, packageUri, <String>[]);
    var scriptUri = cwd.resolve(nativeToUriPath(script));
    // TODO(johnniwinther): Detect file not found
    _compiler.run(scriptUri);
  }

  void addLibrary(String path) {
    var uri = cwd.resolve(nativeToUriPath(path));
    _compiler.scanner.loadLibrary(uri, null);
  }

  MirrorSystem mirrors() => new Dart2jsMirrorSystem(_compiler);
}


//------------------------------------------------------------------------------
// Dart2js specific extensions of mirror interfaces
//------------------------------------------------------------------------------

interface Dart2jsMirror extends Mirror {
  /**
   * A unique name used as the key in maps.
   */
  final String canonicalName;
  final Dart2jsMirrorSystem system;
}

interface Dart2jsMemberMirror extends Dart2jsMirror, MemberMirror {

}

interface Dart2jsTypeMirror extends Dart2jsMirror, TypeMirror {

}

abstract class Dart2jsElementMirror implements Dart2jsMirror {
  final Dart2jsMirrorSystem system;
  final Element _element;

  Dart2jsElementMirror(this.system, this._element) {
    assert (system !== null);
    assert (_element !== null);
  }

  String simpleName() => _element.name.slowToString();

  Location location() => new Dart2jsLocation(
      _element.getCompilationUnit().script,
      system.compiler.spanFromElement(_element));

  String toString() => _element.toString();
}

abstract class Dart2jsProxyMirror implements Dart2jsMirror {
  final Dart2jsMirrorSystem system;

  Dart2jsProxyMirror(this.system);
}

///////////////////////////////////////////////////////
// implementation
///////////////////////////////////////////////////////

class Dart2jsMirrorSystem implements MirrorSystem, Dart2jsMirror {
  final api.Compiler compiler;
  Map<String, Dart2jsLibraryMirror> _libraries;
  Map<LibraryElement, Dart2jsLibraryMirror> _libraryMap;

  Dart2jsMirrorSystem(this.compiler)
    : _libraryMap = new Map<LibraryElement, Dart2jsLibraryMirror>();

  void _ensureLibraries() {
    if (_libraries == null) {
      _libraries = <Dart2jsLibraryMirror>{};
      compiler.libraries.forEach((_, LibraryElement v) {
        var mirror = new Dart2jsLibraryMirror(system, v);
        _libraries[mirror.canonicalName] = mirror;
        _libraryMap[v] = mirror;
      });
    }
  }

  Map<Object, LibraryMirror> libraries() {
    _ensureLibraries();
    return new ImmutableMapWrapper<Object, LibraryMirror>(_libraries);
  }

  Dart2jsLibraryMirror getLibrary(LibraryElement element) {
    return _libraryMap[element];
  }

  Dart2jsMirrorSystem get system() => this;

  String simpleName() => "mirror";
  String qualifiedName() => simpleName();

  String get canonicalName() => simpleName();
}

abstract class Dart2jsObjectMirror extends Dart2jsElementMirror
    implements ObjectMirror {
  Dart2jsObjectMirror(Dart2jsMirrorSystem system, Element element)
      : super(system, element);
}

class Dart2jsLibraryMirror extends Dart2jsObjectMirror
    implements LibraryMirror {
  Map<String, InterfaceMirror> _types;
  Map<String, MemberMirror> _members;

  Dart2jsLibraryMirror(Dart2jsMirrorSystem system, LibraryElement library)
      : super(system, library);

  LibraryElement get _library() => _element;

  String get canonicalName() => simpleName();

  /**
   * Returns the library name (for libraries with a #library tag) or the script
   * file name (for scripts without a #library tag). The latter case is used to
   * provide a 'library name' for scripts, to use for instance in dartdoc.
   */
  String simpleName() {
    if (_library.libraryTag !== null) {
      return _library.libraryTag.argument.dartString.slowToString();
    } else {
      // Use the file name as script name.
      String path = _library.script.uri.path;
      return path.substring(path.lastIndexOf('/') + 1);
    }
  }

  String qualifiedName() => simpleName();

  void _ensureTypes() {
    if (_types == null) {
      _types = <InterfaceMirror>{};
      _library.forEachExport((Element e) {
        if (e.getLibrary() == _library) {
          if (e.isClass()) {
            var type = new Dart2jsInterfaceMirror.fromLibrary(this, e);
            _types[type.canonicalName] = type;
          } else if (e.isTypedef()) {
            var type = new Dart2jsTypedefMirror.fromLibrary(this, e);
            _types[type.canonicalName] = type;
          }
        }
      });
    }
  }

  void _ensureMembers() {
    if (_members == null) {
      _members = <MemberMirror>{};
      _library.forEachExport((Element e) {
        if (!e.isClass() && !e.isTypedef()) {
          for (var member in _convertElementMemberToMemberMirrors(this, e)) {
            _members[member.canonicalName] = member;
          }
        }
      });
    }
  }

  Map<Object, MemberMirror> declaredMembers() {
    _ensureMembers();
    return new ImmutableMapWrapper<Object, MemberMirror>(_members);
  }

  Map<Object, InterfaceMirror> types() {
    _ensureTypes();
    return new ImmutableMapWrapper<Object, InterfaceMirror>(_types);
  }

  Location location() {
    var script = _library.getCompilationUnit().script;
    return new Dart2jsLocation(
        script,
        new SourceSpan(script.uri, 0, script.text.length));
  }
}

class Dart2jsLocation implements Location {
  Script _script;
  SourceSpan _span;

  Dart2jsLocation(this._script, this._span);

  int start() => _span.begin;
  int end() => _span.end;
  Source source() => new Dart2jsSource(_script);

  String text() => _script.text.substring(start(), end());
}

class Dart2jsSource implements Source {
  Script _script;

  Dart2jsSource(this._script);

  Uri uri() => _script.uri;
  String text() => _script.text;
}

class Dart2jsParameterMirror extends Dart2jsElementMirror
    implements ParameterMirror {
  final MethodMirror _method;
  final bool _isOptional;

  Dart2jsParameterMirror(Dart2jsMirrorSystem system,
                         this._method,
                         VariableElement element,
                         this._isOptional)
    : super(system, element);

  VariableElement get _variableElement() => _element;

  String get canonicalName() => simpleName();

  String qualifiedName() => '${_method.qualifiedName()}#${simpleName()}';

  // TODO(johnniwinther): Provide
  // [:_variableElement.variables.functionSignature:] instead of [:null:].
  TypeMirror type() => _convertTypeToTypeMirror(system,
      _variableElement.computeType(system.compiler),
      system.compiler.dynamicClass.computeType(system.compiler),
      null);

  String defaultValue() => null; // TODO(johnniwinther): How to compute this?

  bool hasDefaultValue() => false; // TODO(johnniwinther): How to compute this?

  bool isOptional() => _isOptional;
}

//------------------------------------------------------------------------------
// Declarations
//------------------------------------------------------------------------------
class Dart2jsInterfaceMirror extends Dart2jsObjectMirror
    implements Dart2jsTypeMirror, InterfaceMirror {
  final Dart2jsLibraryMirror _library;
  Map<String, Dart2jsMemberMirror> _members;
  List<TypeVariableMirror> _typeVariables;

  Dart2jsInterfaceMirror(Dart2jsMirrorSystem system, ClassElement _class)
      : this._library = system.getLibrary(_class.getLibrary()),
        super(system, _class);

  ClassElement get _class() => _element;


  Dart2jsInterfaceMirror.fromLibrary(Dart2jsLibraryMirror library,
                                 ClassElement _class)
      : this._library = library,
        super(library.system, _class);

  String get canonicalName() => simpleName();

  String qualifiedName() => '${library().qualifiedName()}.${simpleName()}';

  Location location() {
    if (_class is PartialClassElement) {
      var node = _class.parseNode(_diagnosticListener);
      if (node !== null) {
        var script = _class.getCompilationUnit().script;
        var span = system.compiler.spanFromNode(node, script.uri);
        return new Dart2jsLocation(script, span);
      }
    }
    return super.location();
  }

  void _ensureMembers() {
    if (_members == null) {
      _members = <Dart2jsMemberMirror>{};
      _class.constructors.forEach((_, e) {
        for (var member in _convertElementMemberToMemberMirrors(this, e)) {
          _members[member.canonicalName] = member;
        }
      });
      _class.localMembers.forEach((_, e) {
        for (var member in _convertElementMemberToMemberMirrors(this, e)) {
          _members[member.canonicalName] = member;
        }
      });
    }
  }

  Map<Object, MemberMirror> declaredMembers() {
    _ensureMembers();
    return new ImmutableMapWrapper<Object, MemberMirror>(_members);
  }

  LibraryMirror library() {
    return _library;
  }

  bool get isObject() => _class == system.compiler.objectClass;

  bool get isDynamic() => _class == system.compiler.dynamicClass;

  bool get isVoid() => false;

  bool get isTypeVariable() => false;

  bool get isTypedef() => false;

  bool get isFunction() => false;

  InterfaceMirror get declaration() => this;

  InterfaceMirror superclass() {
    if (_class.supertype != null) {
      return new Dart2jsInterfaceTypeMirror(system, _class.supertype);
    }
    return null;
  }

  Map<Object, InterfaceMirror> interfaces() {
    var map = new Map<String, InterfaceMirror>();
    Link<Type> link = _class.interfaces;
    while (!link.isEmpty()) {
      var type = _convertTypeToTypeMirror(system, link.head,
          system.compiler.dynamicClass.computeType(system.compiler));
      map[type.canonicalName] = type;
      link = link.tail;
    }
    return new ImmutableMapWrapper<Object, InterfaceMirror>(map);
  }

  bool get isClass() => !_class.isInterface();

  bool get isInterface() => _class.isInterface();

  bool get isPrivate() => _isPrivate(simpleName());

  bool get isDeclaration() => true;

  List<TypeMirror> typeArguments() {
    throw new UnsupportedOperationException(
        'Declarations do not have type arguments');
  }

  List<TypeVariableMirror> typeVariables() {
    if (_typeVariables == null) {
      _typeVariables = <TypeVariableMirror>[];
      _class.typeParameters.forEach((_,parameter) {
        _typeVariables.add(
            new Dart2jsTypeVariableMirror(system,
                parameter.computeType(system.compiler)));
      });
    }
    return _typeVariables;
  }

  Map<Object, MethodMirror> constructors() {
    _ensureMembers();
    return new AsFilteredImmutableMap<Object, MemberMirror, MethodMirror>(
        _members, (m) => m.isConstructor ? m : null);
  }

  /**
   * Returns the default type for this interface.
   */
  InterfaceMirror defaultType() {
    if (_class.defaultClass != null) {
      return new Dart2jsInterfaceTypeMirror(system, _class.defaultClass);
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
    if (library() != other.library()) {
      return false;
    }
    if (isDeclaration !== other.isDeclaration) {
      return false;
    }
    return qualifiedName() == other.qualifiedName();
  }
}

class Dart2jsTypedefMirror extends Dart2jsElementMirror
    implements Dart2jsTypeMirror, TypedefMirror {
  final Dart2jsLibraryMirror _library;
  List<TypeVariableMirror> _typeVariables;
  TypeMirror _definition;

  Dart2jsTypedefMirror(Dart2jsMirrorSystem system, TypedefElement _typedef)
      : this._library = system.getLibrary(_typedef.getLibrary()),
        super(system, _typedef);

  Dart2jsTypedefMirror.fromLibrary(Dart2jsLibraryMirror library,
                                   TypedefElement _typedef)
      : this._library = library,
        super(library.system, _typedef);

  TypedefElement get _typedef() => _element;

  String get canonicalName() => simpleName();

  String qualifiedName() => '${library().qualifiedName()}.${simpleName()}';

  Location location() {
    var node = _typedef.parseNode(_diagnosticListener);
    if (node !== null) {
      var script = _typedef.getCompilationUnit().script;
      var span = system.compiler.spanFromNode(node, script.uri);
      return new Dart2jsLocation(script, span);
    }
    return super.location();
  }

  LibraryMirror library() => _library;

  bool get isObject() => false;

  bool get isDynamic() => false;

  bool get isVoid() => false;

  bool get isTypeVariable() => false;

  bool get isTypedef() => true;

  bool get isFunction() => false;

  List<TypeMirror> typeArguments() {
    throw new UnsupportedOperationException(
        'Declarations do not have type arguments');
  }

  List<TypeVariableMirror> typeVariables() {
    if (_typeVariables == null) {
      _typeVariables = <TypeVariableMirror>[];
      // TODO(johnniwinther): Equip [Typedef] with a [typeParameters] map, just
      // like [ClassElement].
    }
    return _typeVariables;
  }

  TypeMirror definition() {
    if (_definition === null) {
      // TODO(johnniwinther): Provide access to the functionSignature of the
      // aliased function definition.
    }
    return _definition;
  }

  Map<Object, MemberMirror> declaredMembers() => const <MemberMirror>{};

  InterfaceMirror get declaration() => this;

  // TODO(johnniwinther): How should a typedef respond to these?
  InterfaceMirror superclass() => null;

  Map<Object, InterfaceMirror> interfaces() => const <InterfaceMirror>{};

  bool get isClass() => false;

  bool get isInterface() => false;

  bool get isPrivate() => _isPrivate(simpleName());

  bool get isDeclaration() => true;

  Map<Object, MethodMirror> constructors() => const <MethodMirror>{};

  InterfaceMirror defaultType() => null;
}

class Dart2jsTypeVariableMirror extends Dart2jsTypeElementMirror
    implements TypeVariableMirror {
  final TypeVariableType _typeVariableType;
  InterfaceMirror _declarer;

  Dart2jsTypeVariableMirror(Dart2jsMirrorSystem system,
                            TypeVariableType typeVariableType)
    : this._typeVariableType = typeVariableType,
      super(system, typeVariableType) {
      assert(_typeVariableType !== null);
  }


  String qualifiedName() => '${declarer().qualifiedName()}.${simpleName()}';

  InterfaceMirror declarer() {
    if (_declarer === null) {
      if (_typeVariableType.element.enclosingElement.isClass()) {
        _declarer = new Dart2jsInterfaceMirror(system,
            _typeVariableType.element.enclosingElement);
      } else if (_typeVariableType.element.enclosingElement.isTypedef()) {
        _declarer = new Dart2jsTypedefMirror(system,
            _typeVariableType.element.enclosingElement);
      }
    }
    return _declarer;
  }

  LibraryMirror library() => declarer().library();

  bool get isObject() => false;

  bool get isDynamic() => false;

  bool get isVoid() => false;

  bool get isTypeVariable() => true;

  bool get isTypedef() => false;

  bool get isFunction() => false;

  TypeMirror bound() => _convertTypeToTypeMirror(
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
    if (declarer() != other.declarer()) {
      return false;
    }
    return qualifiedName() == other.qualifiedName();
  }
}


//------------------------------------------------------------------------------
// Types
//------------------------------------------------------------------------------

abstract class Dart2jsTypeElementMirror extends Dart2jsProxyMirror
    implements Dart2jsTypeMirror {
  final Type _type;

  Dart2jsTypeElementMirror(Dart2jsMirrorSystem system, this._type)
    : super(system);

  String simpleName() => _type.name.slowToString();

  String get canonicalName() => simpleName();

  Location location() {
    var script = _type.element.getCompilationUnit().script;
    return new Dart2jsLocation(script,
                               system.compiler.spanFromElement(_type.element));
  }

  LibraryMirror library() {
    return system.getLibrary(_type.element.getLibrary());
  }

  String toString() => _type.element.toString();
}

class Dart2jsInterfaceTypeMirror extends Dart2jsTypeElementMirror
    implements InterfaceMirror {
  List<TypeMirror> _typeArguments;

  Dart2jsInterfaceTypeMirror(Dart2jsMirrorSystem system,
                             InterfaceType interfaceType)
      : super(system, interfaceType);

  InterfaceType get _interfaceType() => _type;

  String qualifiedName() => declaration.qualifiedName();

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<Object, MemberMirror> declaredMembers() => declaration.declaredMembers();

  bool get isObject() => system.compiler.objectClass == _type.element;

  bool get isDynamic() => system.compiler.dynamicClass == _type.element;

  bool get isTypeVariable() => false;

  bool get isVoid() => false;

  bool get isTypedef() => false;

  bool get isFunction() => false;

  InterfaceMirror get declaration()
      => new Dart2jsInterfaceMirror(system, _type.element);

  // TODO(johnniwinther): Substitute type arguments for type variables.
  InterfaceMirror superclass() => declaration.superclass();

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<Object, InterfaceMirror> interfaces() => declaration.interfaces();

  bool get isClass() => declaration.isClass;

  bool get isInterface() => declaration.isInterface;

  bool get isPrivate() => declaration.isPrivate;

  bool get isDeclaration() => false;

  List<TypeMirror> typeArguments() {
    if (_typeArguments == null) {
      _typeArguments = <TypeMirror>[];
      Link<Type> type = _interfaceType.arguments;
      while (type != null && type.head != null) {
        _typeArguments.add(_convertTypeToTypeMirror(system, type.head,
            system.compiler.dynamicClass.computeType(system.compiler)));
        type = type.tail;
      }
    }
    return _typeArguments;
  }

  List<TypeVariableMirror> typeVariables() => declaration.typeVariables();

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<Object, MethodMirror> constructors() => declaration.constructors();

  // TODO(johnniwinther): Substitute type arguments for type variables?
  InterfaceMirror defaultType() => declaration.defaultType();

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
    var thisTypeArguments = typeArguments().iterator();
    var otherTypeArguments = other.typeArguments().iterator();
    while (thisTypeArguments.hasNext() && otherTypeArguments.hasNext()) {
      if (thisTypeArguments.next() != otherTypeArguments.next()) {
        return false;
      }
    }
    return !thisTypeArguments.hasNext() && !otherTypeArguments.hasNext();
  }
}


class Dart2jsFunctionTypeMirror extends Dart2jsTypeElementMirror
    implements FunctionTypeMirror {
  final FunctionSignature _functionSignature;
  List<ParameterMirror> _parameters;

  Dart2jsFunctionTypeMirror(Dart2jsMirrorSystem system,
                             FunctionType functionType, this._functionSignature)
      : super(system, functionType) {
    assert (_functionSignature !== null);
  }

  FunctionType get _functionType() => _type;

  // TODO(johnniwinther): Is this the qualified name of a function type?
  String qualifiedName() => declaration.qualifiedName();

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<Object, MemberMirror> declaredMembers() {
    var method = callMethod();
    if (method !== null) {
      var map = new Map<String, MemberMirror>.from(
          declaration.declaredMembers());
      var name = method.qualifiedName();
      map[name] = method;
      Function func = null;
      return new ImmutableMapWrapper<Object, MemberMirror>(map);
    }
    return declaration.declaredMembers();
  }

  bool get isObject() => system.compiler.objectClass == _type.element;

  bool get isDynamic() => system.compiler.dynamicClass == _type.element;

  bool get isVoid() => false;

  bool get isTypeVariable() => false;

  bool get isTypedef() => false;

  bool get isFunction() => true;

  MethodMirror callMethod() => _convertElementMethodToMethodMirror(
      system.getLibrary(_functionType.element.getLibrary()),
      _functionType.element);

  InterfaceMirror get declaration()
      => new Dart2jsInterfaceMirror(system, system.compiler.functionClass);

  // TODO(johnniwinther): Substitute type arguments for type variables.
  InterfaceMirror superclass() => declaration.superclass();

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<Object, InterfaceMirror> interfaces() => declaration.interfaces();

  bool get isClass() => declaration.isClass;

  bool get isInterface() => declaration.isInterface;

  bool get isPrivate() => declaration.isPrivate;

  bool get isDeclaration() => false;

  List<TypeMirror> typeArguments() => const <TypeMirror>[];

  List<TypeVariableMirror> typeVariables() => declaration.typeVariables();

  Map<Object, MethodMirror> constructors() => <MethodMirror>{};

  InterfaceMirror defaultType() => null;

  TypeMirror returnType() {
    return _convertTypeToTypeMirror(system, _functionType.returnType,
        system.compiler.dynamicClass.computeType(system.compiler));
  }

  List<ParameterMirror> parameters() {
    if (_parameters === null) {
      _parameters = _parametersFromFunctionSignature(system, callMethod(),
                                                     _functionSignature);
    }
    return _parameters;
  }
}

class Dart2jsVoidMirror extends Dart2jsTypeElementMirror {

  Dart2jsVoidMirror(Dart2jsMirrorSystem system, VoidType voidType)
      : super(system, voidType);

  VoidType get _voidType() => _type;

  String qualifiedName() => simpleName();

  /**
   * The void type has no location.
   */
  Location location() => null;

  /**
   * The void type has no library.
   */
  LibraryMirror getLibrary() => null;

  bool get isObject() => false;

  bool get isVoid() => true;

  bool get isDynamic() => false;

  bool get isTypeVariable() => false;

  bool get isTypedef() => false;

  bool get isFunction() => false;

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

///////////////////////////////////////////////////////
// members
///////////////////////////////////////////////////////

class Dart2jsMethodMirror extends Dart2jsElementMirror
    implements Dart2jsMemberMirror, MethodMirror {
  final Dart2jsObjectMirror _objectMirror;
  String _name;
  String _constructorName;
  String _operatorName;
  Dart2jsMethodKind _kind;
  String _canonicalName;

  Dart2jsMethodMirror(Dart2jsObjectMirror objectMirror,
                      FunctionElement function,
                      [Dart2jsMethodKind kind = null])
      : this._objectMirror = objectMirror,
        this._kind = kind,
        super(objectMirror.system, function) {
    _name = _element.name.slowToString();
    if (kind == null) {
      if (_function.kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
        _constructorName = '';
        int dollarPos = _name.indexOf('\$');
        if (dollarPos != -1) {
          _constructorName = _name.substring(dollarPos+1);
          _name = _name.substring(0, dollarPos);
          // canonical name is TypeName.constructorName
          _canonicalName = '$_name.$_constructorName';
        } else {
          // canonical name is TypeName
          _canonicalName = _name;
        }
        if (_function.modifiers !== null && _function.modifiers.isConst()) {
          _kind = Dart2jsMethodKind.CONST;
        } else {
          _kind = Dart2jsMethodKind.CONSTRUCTOR;
        }
      } else if (_function.modifiers !== null
                 && _function.modifiers.isFactory()) {
        _constructorName = '';
        int dollarPos = _name.indexOf('\$');
        if (dollarPos != -1) {
          _constructorName = _name.substring(dollarPos+1);
          _name = _name.substring(0, dollarPos);
        }
        _kind = Dart2jsMethodKind.FACTORY;
        // canonical name is TypeName.constructorName
        _canonicalName = '$_name.$_constructorName';
      } else if (_name.startsWith('operator\$')) {
        String str = _name.substring(9);
        _name = 'operator';
        _kind = Dart2jsMethodKind.OPERATOR;
        _operatorName = _getOperatorFromOperatorName(str);
        // canonical name is 'operator operatorName'
        _canonicalName = 'operator $_operatorName';
      } else {
        _kind = Dart2jsMethodKind.NORMAL;
        _canonicalName = _name;
      }
    } else if (kind == Dart2jsMethodKind.GETTER) {
      _canonicalName = _name;
    } else if (kind == Dart2jsMethodKind.SETTER) {
      _canonicalName = '$_name=';
    } else {
      assert(false);
    }
  }

  FunctionElement get _function() => _element;

  String simpleName() => _name;

  String qualifiedName()
      => '${surroundingDeclaration().qualifiedName()}.$canonicalName';

  String get canonicalName() => _canonicalName;

  ObjectMirror surroundingDeclaration() => _objectMirror;

  bool get isTopLevel() => _objectMirror is LibraryMirror;

  bool get isConstructor()
      => _kind == Dart2jsMethodKind.CONSTRUCTOR || isConst || isFactory;

  bool get isField() => false;

  bool get isMethod() => !isConstructor;

  bool get isPrivate() => _isPrivate(simpleName());

  bool get isStatic() =>
      _function.modifiers !== null && _function.modifiers.isStatic();

  List<ParameterMirror> parameters() {
    return _parametersFromFunctionSignature(system, this,
        _function.computeSignature(system.compiler));
  }

  TypeMirror returnType() => _convertTypeToTypeMirror(
      system, _function.computeSignature(system.compiler).returnType,
      system.compiler.dynamicClass.computeType(system.compiler));

  bool get isConst() => _kind == Dart2jsMethodKind.CONST;

  bool get isFactory() => _kind == Dart2jsMethodKind.FACTORY;

  String get constructorName() => _constructorName;

  bool get isGetter() => _kind == Dart2jsMethodKind.GETTER;

  bool get isSetter() => _kind == Dart2jsMethodKind.SETTER;

  bool get isOperator() => _kind == Dart2jsMethodKind.OPERATOR;

  String get operatorName() => _operatorName;

  Location location() {
    var node = _function.parseNode(_diagnosticListener);
    if (node !== null) {
      var script = _function.getCompilationUnit().script;
      var span = system.compiler.spanFromNode(node, script.uri);
      return new Dart2jsLocation(script, span);
    }
    return super.location();
  }

}

class Dart2jsFieldMirror extends Dart2jsElementMirror
    implements Dart2jsMemberMirror, FieldMirror {
  Dart2jsObjectMirror _objectMirror;
  VariableElement _variable;

  Dart2jsFieldMirror(Dart2jsObjectMirror objectMirror,
                     VariableElement variable)
      : this._objectMirror = objectMirror,
        this._variable = variable,
        super(objectMirror.system, variable);

  String qualifiedName()
      => '${surroundingDeclaration().qualifiedName()}.$canonicalName';

  String get canonicalName() => simpleName();

  ObjectMirror surroundingDeclaration() => _objectMirror;

  bool get isTopLevel() => _objectMirror is LibraryMirror;

  bool get isConstructor() => false;

  bool get isField() => true;

  bool get isMethod() => false;

  bool get isPrivate() => _isPrivate(simpleName());

  bool get isStatic() => _variable.modifiers.isStatic();

  bool get isFinal() => _variable.modifiers.isFinal();

  TypeMirror type() => _convertTypeToTypeMirror(system,
      _variable.computeType(system.compiler),
      system.compiler.dynamicClass.computeType(system.compiler));

  Location location() {
    var script = _variable.getCompilationUnit().script;
    var node = _variable.variables.parseNode(_diagnosticListener);
    if (node !== null) {
      var span = system.compiler.spanFromNode(node, script.uri);
      return new Dart2jsLocation(script, span);
    } else {
      var span = system.compiler.spanFromElement(_variable);
      return new Dart2jsLocation(script, span);
    }
  }
}

