// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mirrors_dart2js;

import 'dart:async';

import '../../compiler.dart' as api;
import '../elements/elements.dart';
import '../apiimpl.dart' as apiimpl;
import '../scanner/scannerlib.dart';
import '../resolution/resolution.dart' show Scope;
import '../dart2jslib.dart';
import '../dart_types.dart';
import '../tree/tree.dart';
import '../util/util.dart' show Spannable, Link;
import '../util/characters.dart' show $CR, $LF;

import 'mirrors.dart';
import 'mirrors_util.dart';
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
        system, method, link.head, isOptional: false, isNamed: false));
    link = link.tail;
  }
  link = signature.optionalParameters;
  bool isNamed = signature.optionalParametersAreNamed;
  while (!link.isEmpty) {
    parameters.add(new Dart2JsParameterMirror(
        system, method, link.head, isOptional: true, isNamed: isNamed));
    link = link.tail;
  }
  return parameters;
}

Dart2JsTypeMirror _convertTypeToTypeMirror(
    Dart2JsMirrorSystem system,
    DartType type,
    InterfaceType defaultType,
    [FunctionSignature functionSignature]) {
  if (type == null) {
    return new Dart2JsInterfaceTypeMirror(system, defaultType);
  } else if (type is InterfaceType) {
    if (type == system.compiler.types.dynamicType) {
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
  } else if (type is MalformedType) {
    // TODO(johnniwinther): We need a mirror on malformed types.
    return system.dynamicType;
  }
  system.compiler.internalError("Unexpected type $type of kind ${type.kind}");
}

Iterable<Dart2JsMemberMirror> _convertElementMemberToMemberMirrors(
    Dart2JsContainerMirror library, Element element) {
  if (element.isSynthesized) {
    return const <Dart2JsMemberMirror>[];
  } else if (element is VariableElement) {
    return <Dart2JsMemberMirror>[new Dart2JsFieldMirror(library, element)];
  } else if (element is FunctionElement) {
    return <Dart2JsMemberMirror>[new Dart2JsMethodMirror(library, element)];
  } else if (element is AbstractFieldElement) {
    var members = <Dart2JsMemberMirror>[];
    AbstractFieldElement field = element;
    if (field.getter != null) {
      members.add(new Dart2JsMethodMirror(library, field.getter));
    }
    if (field.setter != null) {
      members.add(new Dart2JsMethodMirror(library, field.setter));
    }
    return members;
  }
  library.mirrors.compiler.internalError(
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

InstanceMirror _convertConstantToInstanceMirror(Dart2JsMirrorSystem mirrors,
                                                Constant constant) {
  if (constant is BoolConstant) {
    return new Dart2JsBoolConstantMirror(mirrors, constant);
  } else if (constant is NumConstant) {
    return new Dart2JsNumConstantMirror(mirrors, constant);
  } else if (constant is StringConstant) {
    return new Dart2JsStringConstantMirror(mirrors, constant);
  } else if (constant is ListConstant) {
    return new Dart2JsListConstantMirror(mirrors, constant);
  } else if (constant is MapConstant) {
    return new Dart2JsMapConstantMirror(mirrors, constant);
  } else if (constant is TypeConstant) {
    return new Dart2JsTypeConstantMirror(mirrors, constant);
  } else if (constant is FunctionConstant) {
    return new Dart2JsConstantMirror(mirrors, constant);
  } else if (constant is NullConstant) {
    return new Dart2JsNullConstantMirror(mirrors, constant);
  } else if (constant is ConstructedConstant) {
    return new Dart2JsConstructedConstantMirror(mirrors, constant);
  }
  mirrors.compiler.internalError("Unexpected constant $constant");
}

class Dart2JsMethodKind {
  static const Dart2JsMethodKind REGULAR = const Dart2JsMethodKind("regular");
  static const Dart2JsMethodKind GENERATIVE =
      const Dart2JsMethodKind("generative");
  static const Dart2JsMethodKind REDIRECTING =
      const Dart2JsMethodKind("redirecting");
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
  if (newName == null) {
    throw new Exception('Unhandled operator name: $name');
  }
  return newName;
}

//------------------------------------------------------------------------------
// Analysis entry point.
//------------------------------------------------------------------------------

/**
 * Analyzes set of libraries and provides a mirror system which can be used for
 * static inspection of the source code.
 */
// TODO(johnniwinther): Move this to [compiler/compiler.dart].
Future<MirrorSystem> analyze(List<Uri> libraries,
                             Uri libraryRoot,
                             Uri packageRoot,
                             api.CompilerInputProvider inputProvider,
                             api.DiagnosticHandler diagnosticHandler,
                             [List<String> options = const <String>[]]) {
  if (!libraryRoot.path.endsWith("/")) {
    throw new ArgumentError("libraryRoot must end with a /");
  }
  if (packageRoot != null && !packageRoot.path.endsWith("/")) {
    throw new ArgumentError("packageRoot must end with a /");
  }
  options = new List<String>.from(options);
  options.add('--analyze-only');
  options.add('--analyze-signatures-only');
  options.add('--analyze-all');
  options.add('--categories=Client,Server');

  bool compilationFailed = false;
  void internalDiagnosticHandler(Uri uri, int begin, int end,
                                 String message, api.Diagnostic kind) {
    if (kind == api.Diagnostic.ERROR ||
        kind == api.Diagnostic.CRASH) {
      compilationFailed = true;
    }
    diagnosticHandler(uri, begin, end, message, kind);
  }

  Compiler compiler = new apiimpl.Compiler(inputProvider,
                                           null,
                                           internalDiagnosticHandler,
                                           libraryRoot, packageRoot,
                                           options,
                                           const {});
  compiler.librariesToAnalyzeWhenRun = libraries;
  return compiler.run(null).then((bool success) {
    if (success && !compilationFailed) {
      return new Dart2JsMirrorSystem(compiler);
    } else {
      throw new StateError('Failed to create mirror system.');
    }
  });
}

//------------------------------------------------------------------------------
// Dart2Js specific extensions of mirror interfaces
//------------------------------------------------------------------------------

abstract class Dart2JsMirror implements Mirror {
  Dart2JsMirrorSystem get mirrors;
}

abstract class Dart2JsDeclarationMirror extends Dart2JsMirror
    implements DeclarationMirror {

  bool get isTopLevel => owner != null && owner is LibraryMirror;

  bool get isPrivate => _isPrivate(simpleName);

  /**
   * Returns the first token for the source of this declaration, not including
   * metadata annotations.
   */
  Token getBeginToken();

  /**
   * Returns the last token for the source of this declaration.
   */
  Token getEndToken();

  /**
   * Returns the script for the source of this declaration.
   */
  Script getScript();
}

abstract class Dart2JsTypeMirror extends Dart2JsDeclarationMirror
    implements TypeMirror {
}

abstract class Dart2JsElementMirror extends Dart2JsDeclarationMirror {
  final Dart2JsMirrorSystem mirrors;
  final Element _element;
  List<InstanceMirror> _metadata;

  Dart2JsElementMirror(this.mirrors, this._element) {
    assert (mirrors != null);
    assert (_element != null);
  }

  /**
   * Returns the element to be used to determine the begin token of this
   * declaration and the metadata associated with this declaration.
   *
   * This indirection is needed to use the [VariableListElement] as the location
   * for type and metadata information on a [VariableElement].
   */
  Element get _beginElement => _element;

  String get simpleName => _element.name;

  bool get isNameSynthetic => false;

  /**
   * Computes the first token for this declaration using the begin token of the
   * element node or element position as indicator.
   */
  Token getBeginToken() {
    // TODO(johnniwinther): Avoid calling [parseNode].
    Node node = _beginElement.parseNode(mirrors.compiler);
    if (node == null) {
      return _beginElement.position();
    }
    return node.getBeginToken();
  }

  /**
   * Computes the last token for this declaration using the end token of the
   * element node or element position as indicator.
   */
  Token getEndToken() {
    // TODO(johnniwinther): Avoid calling [parseNode].
    Node node = _element.parseNode(mirrors.compiler);
    if (node == null) {
      return _element.position();
    }
    return node.getEndToken();
  }

  /**
   * Returns the first token for the source of this declaration, including
   * metadata annotations.
   */
  Token getFirstToken() {
    if (!_beginElement.metadata.isEmpty) {
      for (MetadataAnnotation metadata in _beginElement.metadata) {
        if (metadata.beginToken != null) {
          return metadata.beginToken;
        }
      }
    }
    return getBeginToken();
  }

  Script getScript() => _element.getCompilationUnit().script;

  SourceLocation get location {
    Token beginToken = getFirstToken();
    Script script = getScript();
    SourceSpan span;
    if (beginToken == null) {
      span = new SourceSpan(script.uri, 0, 0);
    } else {
      Token endToken = getEndToken();
      span = mirrors.compiler.spanFromTokens(beginToken, endToken, script.uri);
    }
    return new Dart2JsSourceLocation(script, span);
  }

  String toString() => _element.toString();

  void _appendCommentTokens(Token commentToken) {
    while (commentToken != null && commentToken.kind == COMMENT_TOKEN) {
      _metadata.add(new Dart2JsCommentInstanceMirror(
          mirrors, commentToken.value));
      commentToken = commentToken.next;
    }
  }

  List<InstanceMirror> get metadata {
    if (_metadata == null) {
      _metadata = <InstanceMirror>[];
      for (MetadataAnnotation metadata in _element.metadata) {
        _appendCommentTokens(mirrors.compiler.commentMap[metadata.beginToken]);
        metadata.ensureResolved(mirrors.compiler);
        _metadata.add(
            _convertConstantToInstanceMirror(mirrors, metadata.value));
      }
      _appendCommentTokens(mirrors.compiler.commentMap[getBeginToken()]);
    }
    // TODO(johnniwinther): Return an unmodifiable list instead.
    return new List<InstanceMirror>.from(_metadata);
  }

  DeclarationMirror lookupInScope(String name) {
    // TODO(11653): Support lookup of constructors.
    Scope scope = _element.buildScope();
    Element result;
    int index = name.indexOf('.');
    if (index != -1) {
      // Lookup [: prefix.id :].
      String prefix = name.substring(0, index);
      String id = name.substring(index+1);
      result = scope.lookup(prefix);
      if (result != null && result.isPrefix()) {
        PrefixElement prefix = result;
        result = prefix.lookupLocalMember(id);
      } else {
        result = null;
      }
    } else {
      // Lookup [: id :].
      result = scope.lookup(name);
    }
    if (result == null || result.isPrefix()) return null;
    return _convertElementToDeclarationMirror(mirrors, result);
  }

  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other == null) return false;
    if (other is! Dart2JsElementMirror) return false;
    return _element == other._element &&
           owner == other.owner;
  }

  int get hashCode {
    return 13 * _element.hashCode + 17 * owner.hashCode;
  }
}

abstract class Dart2JsMemberMirror extends Dart2JsElementMirror
    implements MemberMirror {

  Dart2JsMemberMirror(Dart2JsMirrorSystem system, Element element)
      : super(system, element);

  bool get isConstructor => false;

  bool get isVariable => false;

  bool get isMethod => false;

  bool get isStatic => false;

  bool get isParameter => false;
}

//------------------------------------------------------------------------------
// Mirror system implementation.
//------------------------------------------------------------------------------

class Dart2JsMirrorSystem extends MirrorSystem {
  final Compiler compiler;
  Map<Uri, Dart2JsLibraryMirror> _libraries;
  Map<LibraryElement, Dart2JsLibraryMirror> _libraryMap;

  Dart2JsMirrorSystem(this.compiler)
    : _libraryMap = new Map<LibraryElement, Dart2JsLibraryMirror>();

  void _ensureLibraries() {
    if (_libraries == null) {
      _libraries = new Map<Uri, Dart2JsLibraryMirror>();
      compiler.libraries.forEach((_, LibraryElement v) {
        var mirror = new Dart2JsLibraryMirror(mirrors, v);
        _libraries[mirror.uri] = mirror;
        _libraryMap[v] = mirror;
      });
    }
  }

  Map<Uri, LibraryMirror> get libraries {
    _ensureLibraries();
    return new ImmutableMapWrapper<Uri, LibraryMirror>(_libraries);
  }

  Dart2JsLibraryMirror _getLibrary(LibraryElement element) =>
      _libraryMap[element];

  Dart2JsMirrorSystem get mirrors => this;

  TypeMirror get dynamicType =>
      _convertTypeToTypeMirror(this, compiler.types.dynamicType, null);

  TypeMirror get voidType =>
      _convertTypeToTypeMirror(this, compiler.types.voidType, null);
}

abstract class Dart2JsContainerMirror extends Dart2JsElementMirror
    implements ContainerMirror {
  Map<String, MemberMirror> _members;

  Dart2JsContainerMirror(Dart2JsMirrorSystem system, Element element)
      : super(system, element);

  void _ensureMembers();

  Map<String, MemberMirror> get members {
    _ensureMembers();
    return new ImmutableMapWrapper<String, MemberMirror>(_members);
  }

  Map<String, MethodMirror> get functions {
    _ensureMembers();
    return new AsFilteredImmutableMap<String, MemberMirror, MethodMirror>(
        _members,
        (MemberMirror member) => member is MethodMirror ? member : null);
  }

  Map<String, MethodMirror> get getters {
    _ensureMembers();
    return new AsFilteredImmutableMap<String, MemberMirror, MethodMirror>(
        _members,
        (MemberMirror member) =>
            member is MethodMirror && member.isGetter ? member : null);
  }

  Map<String, MethodMirror> get setters {
    _ensureMembers();
    return new AsFilteredImmutableMap<String, MemberMirror, MethodMirror>(
        _members,
        (MemberMirror member) =>
            member is MethodMirror && member.isSetter ? member : null);
  }

  Map<String, VariableMirror> get variables {
    _ensureMembers();
    return new AsFilteredImmutableMap<String, MemberMirror, VariableMirror>(
        _members,
        (MemberMirror member) => member is VariableMirror ? member : null);
  }
}

class Dart2JsLibraryMirror extends Dart2JsContainerMirror
    implements LibraryMirror {
  Map<String, ClassMirror> _classes;

  Dart2JsLibraryMirror(Dart2JsMirrorSystem system, LibraryElement library)
      : super(system, library);

  LibraryElement get _library => _element;

  Uri get uri => _library.canonicalUri;

  DeclarationMirror get owner => null;

  bool get isPrivate => false;

  LibraryMirror library() => this;

  /**
   * Returns the library name (for libraries with a library tag) or the script
   * file name (for scripts without a library tag). The latter case is used to
   * provide a 'library name' for scripts, to use for instance in dartdoc.
   */
  String get simpleName {
    if (_library.libraryTag != null) {
      return _library.libraryTag.name.toString();
    } else {
      // Use the file name as script name.
      String path = _library.canonicalUri.path;
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
          classElement.ensureResolved(mirrors.compiler);
          var type = new Dart2JsClassMirror.fromLibrary(this, classElement);
          assert(invariant(_library, !_classes.containsKey(type.simpleName),
              message: "Type name '${type.simpleName}' "
                       "is not unique in $_library."));
          _classes[type.simpleName] = type;
        } else if (e.isTypedef()) {
          var type = new Dart2JsTypedefMirror.fromLibrary(this,
              e.computeType(mirrors.compiler));
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
          // TODO(ahe): I think it is incorrect to filter out classes
          // and typedefs.  See http://dartbug.com/10371.
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

  /**
   * Computes the first token of this library using the first library tag as
   * indicator.
   */
  Token getBeginToken() {
    if (_library.libraryTag != null) {
      return _library.libraryTag.getBeginToken();
    } else if (!_library.tags.isEmpty) {
      return _library.tags.reverse().head.getBeginToken();
    }
    return null;
  }

  /**
   * Computes the first token of this library using the last library tag as
   * indicator.
   */
  Token getEndToken() {
    if (!_library.tags.isEmpty) {
      return _library.tags.head.getEndToken();
    }
    return null;
  }
}

class Dart2JsSourceLocation implements SourceLocation {
  final Script _script;
  final SourceSpan _span;
  int _line;
  int _column;

  Dart2JsSourceLocation(this._script, this._span);

  int _computeLine() {
    var sourceFile = _script.file;
    if (sourceFile != null) {
      return sourceFile.getLine(offset) + 1;
    }
    var index = 0;
    var lineNumber = 0;
    while (index <= offset && index < sourceText.length) {
      index = sourceText.indexOf('\n', index) + 1;
      if (index <= 0) break;
      lineNumber++;
    }
    return lineNumber;
  }

  int get line {
    if (_line == null) {
      _line = _computeLine();
    }
    return _line;
  }

  int _computeColumn() {
    if (length == 0) return 0;

    var sourceFile = _script.file;
    if (sourceFile != null) {
      return sourceFile.getColumn(sourceFile.getLine(offset), offset) + 1;
    }
    int index = offset - 1;
    var columnNumber = 0;
    while (0 <= index && index < sourceText.length) {
      columnNumber++;
      var codeUnit = sourceText.codeUnitAt(index);
      if (codeUnit == $CR || codeUnit == $LF) {
        break;
      }
      index--;
    }
    return columnNumber;
  }

  int get column {
    if (_column == null) {
      _column = _computeColumn();
    }
    return _column;
  }

  int get offset => _span.begin;

  int get length => _span.end - _span.begin;

  String get text => _script.text.substring(_span.begin, _span.end);

  Uri get sourceUri => _script.uri;

  String get sourceText => _script.text;
}

class Dart2JsParameterMirror extends Dart2JsMemberMirror
    implements ParameterMirror {
  final MethodMirror _method;
  final bool isOptional;
  final bool isNamed;

  factory Dart2JsParameterMirror(Dart2JsMirrorSystem system,
                                 MethodMirror method,
                                 VariableElement element,
                                 {bool isOptional: false,
                                  bool isNamed: false}) {
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

  Element get _beginElement => _variableElement.variables;

  DeclarationMirror get owner => _method;

  VariableElement get _variableElement => _element;

  String get qualifiedName => '${_method.qualifiedName}#${simpleName}';

  TypeMirror get type => _convertTypeToTypeMirror(mirrors,
      _variableElement.computeType(mirrors.compiler),
      mirrors.compiler.types.dynamicType,
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
    return _variableElement.cachedNode != null &&
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
    VariableListElement variables = _fieldParameterElement.variables;
    VariableDefinitions node = variables.parseNode(mirrors.compiler);
    if (node.type != null) {
      return super.type;
    }
    // Use the field type for initializing formals with no type annotation.
    return _convertTypeToTypeMirror(mirrors,
      _fieldParameterElement.fieldElement.computeType(mirrors.compiler),
      mirrors.compiler.types.dynamicType,
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
      : this.library = system._getLibrary(_class.getLibrary()),
        super(system, _class);

  ClassElement get _class => _element;

  Dart2JsClassMirror.fromLibrary(Dart2JsLibraryMirror library,
                                 ClassElement _class)
      : this.library = library,
        super(library.mirrors, _class);

  DeclarationMirror get owner => library;

  String get qualifiedName => '${library.qualifiedName}.${simpleName}';

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

  bool get isObject => _class == mirrors.compiler.objectClass;

  bool get isDynamic => false;

  bool get isVoid => false;

  bool get isTypeVariable => false;

  bool get isTypedef => false;

  bool get isFunction => false;

  ClassMirror get originalDeclaration => this;

  ClassMirror get superclass {
    if (_class.supertype != null) {
      return new Dart2JsInterfaceTypeMirror(mirrors, _class.supertype);
    }
    return null;
  }

  ClassMirror get mixin {
    if (_class.isMixinApplication) {
      MixinApplicationElement mixinApplication = _class;
      return new Dart2JsInterfaceTypeMirror(mirrors,
                                            mixinApplication.mixinType);
    }
    return this;
  }

  bool get isNameSynthetic {
    if (_class.isMixinApplication) {
      MixinApplicationElement mixinApplication = _class;
      return mixinApplication.isUnnamedMixinApplication;
    }
    return false;
  }

  List<ClassMirror> get superinterfaces {
    var list = <ClassMirror>[];
    Link<DartType> link = _class.interfaces;
    while (!link.isEmpty) {
      var type = _convertTypeToTypeMirror(mirrors, link.head,
                                          mirrors.compiler.types.dynamicType);
      list.add(type);
      link = link.tail;
    }
    return list;
  }

  bool get isClass => true;

  bool get isAbstract => _class.modifiers.isAbstract();

  bool get isOriginalDeclaration => true;

  List<TypeMirror> get typeArguments {
    throw new UnsupportedError(
        'Declarations do not have type arguments');
  }

  List<TypeVariableMirror> get typeVariables {
    if (_typeVariables == null) {
      _typeVariables = <TypeVariableMirror>[];
      _class.ensureResolved(mirrors.compiler);
      for (TypeVariableType typeVariable in _class.typeVariables) {
        _typeVariables.add(
            new Dart2JsTypeVariableMirror(mirrors, typeVariable));
      }
    }
    return _typeVariables;
  }

  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ClassMirror) {
      return false;
    }
    if (library != other.library) {
      return false;
    }
    if (!identical(isOriginalDeclaration, other.isOriginalDeclaration)) {
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
      : this._library = system._getLibrary(_typedef.element.getLibrary()),
        super(system, _typedef);

  Dart2JsTypedefMirror.fromLibrary(Dart2JsLibraryMirror library,
                                   TypedefType _typedef)
      : this._library = library,
        super(library.mirrors, _typedef);

  TypedefType get _typedef => _type;

  String get qualifiedName => '${library.qualifiedName}.${simpleName}';

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
            new Dart2JsTypeVariableMirror(mirrors, typeVariable));
      }
    }
    return _typeVariables;
  }

  TypeMirror get value {
    if (_definition == null) {
      // TODO(johnniwinther): Should be [ensureResolved].
      mirrors.compiler.resolveTypedef(_typedef.element);
      _definition = _convertTypeToTypeMirror(
          mirrors,
          _typedef.element.alias,
          mirrors.compiler.types.dynamicType,
          _typedef.element.functionSignature);
    }
    return _definition;
  }

  ClassMirror get originalDeclaration => this;

  // TODO(johnniwinther): How should a typedef respond to these?
  ClassMirror get superclass => null;

  List<ClassMirror> get superinterfaces => const <ClassMirror>[];

  // TODO(johnniwinther): Refactor [TypedefMirror] to not extend [ClassMirror]
  // and remove this.
  ClassMirror get mixin => this;

  bool get isClass => false;

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
      assert(_typeVariableType != null);
  }


  String get qualifiedName => '${declarer.qualifiedName}.${simpleName}';

  ClassMirror get declarer {
    if (_declarer == null) {
      if (_typeVariableType.element.enclosingElement.isClass()) {
        _declarer = new Dart2JsClassMirror(mirrors,
            _typeVariableType.element.enclosingElement);
      } else if (_typeVariableType.element.enclosingElement.isTypedef()) {
        _declarer = new Dart2JsTypedefMirror(mirrors,
            _typeVariableType.element.enclosingElement.computeType(
                mirrors.compiler));
      }
    }
    return _declarer;
  }

  LibraryMirror get library => declarer.library;

  DeclarationMirror get owner => declarer;

  bool get isTypeVariable => true;

  TypeMirror get upperBound => _convertTypeToTypeMirror(
      mirrors,
      _typeVariableType.element.bound,
      mirrors.compiler.objectClass.computeType(mirrors.compiler));

  bool operator ==(var other) {
    if (identical(this, other)) {
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

abstract class Dart2JsTypeElementMirror extends Dart2JsElementMirror
    implements Dart2JsTypeMirror {
  final DartType _type;

  Dart2JsTypeElementMirror(Dart2JsMirrorSystem system, DartType type)
    : super(system, type.element),
      this._type = type;

  String get simpleName => _type.name;

  DeclarationMirror get owner => library;

  LibraryMirror get library {
    return mirrors._getLibrary(_type.element.getLibrary());
  }

  bool get isObject => false;

  bool get isVoid => false;

  bool get isDynamic => false;

  bool get isTypeVariable => false;

  bool get isTypedef => false;

  bool get isFunction => false;

  String toString() => _type.toString();

  Map<String, MemberMirror> get members => const <String, MemberMirror>{};

  Map<String, MethodMirror> get constructors => const <String, MethodMirror>{};

  Map<String, MethodMirror> get methods => const <String, MethodMirror>{};

  Map<String, MethodMirror> get getters => const <String, MethodMirror>{};

  Map<String, MethodMirror> get setters => const <String, MethodMirror>{};

  Map<String, VariableMirror> get variables => const <String, VariableMirror>{};
}

class Dart2JsInterfaceTypeMirror extends Dart2JsTypeElementMirror
    implements ClassMirror {
  List<TypeMirror> _typeArguments;

  Dart2JsInterfaceTypeMirror(Dart2JsMirrorSystem system,
                             InterfaceType interfaceType)
      : super(system, interfaceType);

  InterfaceType get _interfaceType => _type;

  bool get isNameSynthetic => originalDeclaration.isNameSynthetic;

  String get qualifiedName => originalDeclaration.qualifiedName;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<String, MemberMirror> get members => originalDeclaration.members;

  bool get isObject => mirrors.compiler.objectClass == _type.element;

  // TODO(johnniwinther): How to show malformed types?
  bool get isDynamic => _type.isDynamic;

  ClassMirror get originalDeclaration
      => new Dart2JsClassMirror(mirrors, _type.element);

  // TODO(johnniwinther): Substitute type arguments for type variables.
  ClassMirror get superclass => originalDeclaration.superclass;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  List<ClassMirror> get superinterfaces => originalDeclaration.superinterfaces;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  ClassMirror get mixin {
    if (originalDeclaration.mixin == originalDeclaration) {
      return this;
    }
    return originalDeclaration.mixin;
  }

  bool get isClass => originalDeclaration.isClass;

  bool get isAbstract => originalDeclaration.isAbstract;

  bool get isPrivate => originalDeclaration.isPrivate;

  bool get isOriginalDeclaration => false;

  List<TypeMirror> get typeArguments {
    if (_typeArguments == null) {
      _typeArguments = <TypeMirror>[];
      if (!_interfaceType.isRaw) {
        Link<DartType> type = _interfaceType.typeArguments;
        while (type != null && type.head != null) {
          _typeArguments.add(_convertTypeToTypeMirror(mirrors, type.head,
              mirrors.compiler.types.dynamicType));
          type = type.tail;
        }
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

  bool operator ==(other) {
    if (identical(this, other)) {
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
    var thisTypeArguments = typeArguments.iterator;
    var otherTypeArguments = other.typeArguments.iterator;
    while (thisTypeArguments.moveNext()) {
      if (!otherTypeArguments.moveNext()) return false;
      if (thisTypeArguments.current != otherTypeArguments.current) {
        return false;
      }
    }
    return !otherTypeArguments.moveNext();
  }
}


class Dart2JsFunctionTypeMirror extends Dart2JsTypeElementMirror
    implements FunctionTypeMirror {
  final FunctionSignature _functionSignature;
  List<ParameterMirror> _parameters;

  Dart2JsFunctionTypeMirror(Dart2JsMirrorSystem system,
                            FunctionType functionType, this._functionSignature)
      : super(system, functionType) {
    assert (_functionSignature != null);
  }

  FunctionType get _functionType => _type;

  // TODO(johnniwinther): Is this the qualified name of a function type?
  String get qualifiedName => originalDeclaration.qualifiedName;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  Map<String, MemberMirror> get members {
    var method = callMethod;
    if (method != null) {
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
      mirrors._getLibrary(_functionType.element.getLibrary()),
      _functionType.element);

  ClassMirror get originalDeclaration
      => new Dart2JsClassMirror(mirrors, mirrors.compiler.functionClass);

  // TODO(johnniwinther): Substitute type arguments for type variables.
  ClassMirror get superclass => originalDeclaration.superclass;

  // TODO(johnniwinther): Substitute type arguments for type variables.
  List<ClassMirror> get superinterfaces => originalDeclaration.superinterfaces;

  ClassMirror get mixin => this;

  bool get isClass => originalDeclaration.isClass;

  bool get isPrivate => originalDeclaration.isPrivate;

  bool get isOriginalDeclaration => false;

  bool get isAbstract => false;

  List<TypeMirror> get typeArguments => const <TypeMirror>[];

  List<TypeVariableMirror> get typeVariables =>
      originalDeclaration.typeVariables;

  TypeMirror get returnType {
    return _convertTypeToTypeMirror(mirrors, _functionType.returnType,
                                    mirrors.compiler.types.dynamicType);
  }

  List<ParameterMirror> get parameters {
    if (_parameters == null) {
      _parameters = _parametersFromFunctionSignature(mirrors, callMethod,
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

  bool operator ==(other) {
    if (identical(this, other)) {
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

  bool operator ==(other) {
    if (identical(this, other)) {
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
  final String simpleName;
  final Dart2JsMethodKind _kind;

  Dart2JsMethodMirror._internal(Dart2JsContainerMirror objectMirror,
      FunctionElement function,
      String this.simpleName,
      Dart2JsMethodKind this._kind)
      : this._objectMirror = objectMirror,
        super(objectMirror.mirrors, function);

  factory Dart2JsMethodMirror(Dart2JsContainerMirror objectMirror,
                              FunctionElement function) {
    String realName = function.name;
    // TODO(ahe): This method should not be calling
    // Elements.operatorNameToIdentifier.
    String simpleName =
        Elements.operatorNameToIdentifier(function.name);
    Dart2JsMethodKind kind;
    if (function.kind == ElementKind.GETTER) {
      kind = Dart2JsMethodKind.GETTER;
    } else if (function.kind == ElementKind.SETTER) {
      kind = Dart2JsMethodKind.SETTER;
      simpleName = '$simpleName=';
    } else if (function.kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
      // TODO(johnniwinther): Support detection of redirecting constructors.
      if (function.modifiers.isConst()) {
        kind = Dart2JsMethodKind.CONST;
      } else {
        kind = Dart2JsMethodKind.GENERATIVE;
      }
    } else if (function.modifiers.isFactory()) {
      kind = Dart2JsMethodKind.FACTORY;
    } else if (realName == 'unary-') {
      kind = Dart2JsMethodKind.OPERATOR;
      // Simple name is 'unary-'.
      simpleName = Mirror.UNARY_MINUS;
    } else if (simpleName.startsWith('operator\$')) {
      String str = simpleName.substring(9);
      simpleName = 'operator';
      kind = Dart2JsMethodKind.OPERATOR;
      simpleName = _getOperatorFromOperatorName(str);
    } else {
      kind = Dart2JsMethodKind.REGULAR;
    }
    return new Dart2JsMethodMirror._internal(objectMirror, function,
        simpleName, kind);
  }

  FunctionElement get _function => _element;

  String get qualifiedName
      => '${owner.qualifiedName}.$simpleName';

  DeclarationMirror get owner => _objectMirror;

  bool get isTopLevel => _objectMirror is LibraryMirror;

  bool get isConstructor
      => isGenerativeConstructor || isConstConstructor ||
         isFactoryConstructor || isRedirectingConstructor;

  bool get isMethod => !isConstructor;

  bool get isStatic => _function.modifiers.isStatic();

  List<ParameterMirror> get parameters {
    return _parametersFromFunctionSignature(mirrors, this,
        _function.computeSignature(mirrors.compiler));
  }

  TypeMirror get returnType => _convertTypeToTypeMirror(
      mirrors, _function.computeSignature(mirrors.compiler).returnType,
      mirrors.compiler.types.dynamicType);

  bool get isAbstract => _function.isAbstract(mirrors.compiler);

  bool get isRegularMethod => !(isGetter || isSetter || isConstructor);

  bool get isConstConstructor => _kind == Dart2JsMethodKind.CONST;

  bool get isGenerativeConstructor => _kind == Dart2JsMethodKind.GENERATIVE;

  bool get isRedirectingConstructor => _kind == Dart2JsMethodKind.REDIRECTING;

  bool get isFactoryConstructor => _kind == Dart2JsMethodKind.FACTORY;

  bool get isGetter => _kind == Dart2JsMethodKind.GETTER;

  bool get isSetter => _kind == Dart2JsMethodKind.SETTER;

  bool get isOperator => _kind == Dart2JsMethodKind.OPERATOR;

  DeclarationMirror lookupInScope(String name) {
    for (ParameterMirror parameter in parameters) {
      if (parameter.simpleName == name) {
        return parameter;
      }
    }
    return super.lookupInScope(name);
  }
}

class Dart2JsFieldMirror extends Dart2JsMemberMirror implements VariableMirror {
  Dart2JsContainerMirror _objectMirror;
  VariableElement _variable;

  Dart2JsFieldMirror(Dart2JsContainerMirror objectMirror,
                     VariableElement variable)
      : this._objectMirror = objectMirror,
        this._variable = variable,
        super(objectMirror.mirrors, variable);

  Element get _beginElement => _variable.variables;

  String get qualifiedName
      => '${owner.qualifiedName}.$simpleName';

  DeclarationMirror get owner => _objectMirror;

  bool get isTopLevel => _objectMirror is LibraryMirror;

  bool get isVariable => true;

  bool get isStatic => _variable.modifiers.isStatic();

  bool get isFinal => _variable.modifiers.isFinal();

  bool get isConst => _variable.modifiers.isConst();

  TypeMirror get type => _convertTypeToTypeMirror(mirrors,
      _variable.computeType(mirrors.compiler),
      mirrors.compiler.types.dynamicType);
}

////////////////////////////////////////////////////////////////////////////////
// Mirrors on constant values used for metadata.
////////////////////////////////////////////////////////////////////////////////

class Dart2JsConstantMirror extends InstanceMirror {
  final Dart2JsMirrorSystem mirrors;
  final Constant _constant;

  Dart2JsConstantMirror(this.mirrors, this._constant);

  ClassMirror get type {
    return new Dart2JsClassMirror(mirrors,
        _constant.computeType(mirrors.compiler).element);
  }

  bool get hasReflectee => false;

  get reflectee {
    // TODO(johnniwinther): Which exception/error should be thrown here?
    throw new UnsupportedError('InstanceMirror does not have a reflectee');
  }

  InstanceMirror getField(String fieldName) {
    // TODO(johnniwinther): Which exception/error should be thrown here?
    throw new UnsupportedError('InstanceMirror does not have a reflectee');
  }
}

class Dart2JsNullConstantMirror extends Dart2JsConstantMirror {
  Dart2JsNullConstantMirror(Dart2JsMirrorSystem mirrors, NullConstant constant)
      : super(mirrors, constant);

  NullConstant get _constant => super._constant;

  bool get hasReflectee => true;

  get reflectee => null;
}

class Dart2JsBoolConstantMirror extends Dart2JsConstantMirror {
  Dart2JsBoolConstantMirror(Dart2JsMirrorSystem mirrors, BoolConstant constant)
      : super(mirrors, constant);

  Dart2JsBoolConstantMirror.fromBool(Dart2JsMirrorSystem mirrors, bool value)
      : super(mirrors, value ? new TrueConstant() : new FalseConstant());

  BoolConstant get _constant => super._constant;

  bool get hasReflectee => true;

  get reflectee => _constant is TrueConstant;
}

class Dart2JsStringConstantMirror extends Dart2JsConstantMirror {
  Dart2JsStringConstantMirror(Dart2JsMirrorSystem mirrors,
                              StringConstant constant)
      : super(mirrors, constant);

  Dart2JsStringConstantMirror.fromString(Dart2JsMirrorSystem mirrors,
                                         String text)
      : super(mirrors,
              new StringConstant(new DartString.literal(text), null));

  StringConstant get _constant => super._constant;

  bool get hasReflectee => true;

  get reflectee => _constant.value.slowToString();
}

class Dart2JsNumConstantMirror extends Dart2JsConstantMirror {
  Dart2JsNumConstantMirror(Dart2JsMirrorSystem mirrors,
                           NumConstant constant)
      : super(mirrors, constant);

  NumConstant get _constant => super._constant;

  bool get hasReflectee => true;

  get reflectee => _constant.value;
}

class Dart2JsListConstantMirror extends Dart2JsConstantMirror
    implements ListInstanceMirror {
  Dart2JsListConstantMirror(Dart2JsMirrorSystem mirrors,
                            ListConstant constant)
      : super(mirrors, constant);

  ListConstant get _constant => super._constant;

  int get length => _constant.length;

  InstanceMirror operator[](int index) {
    if (index < 0) throw new RangeError('Negative index');
    if (index >= _constant.length) throw new RangeError('Index out of bounds');
    return _convertConstantToInstanceMirror(mirrors, _constant.entries[index]);
  }
}

class Dart2JsMapConstantMirror extends Dart2JsConstantMirror
    implements MapInstanceMirror {
  List<String> _listCache;

  Dart2JsMapConstantMirror(Dart2JsMirrorSystem mirrors,
                           MapConstant constant)
      : super(mirrors, constant);

  MapConstant get _constant => super._constant;

  List<String> get _list {
    if (_listCache == null) {
      _listCache = new List<String>(_constant.keys.entries.length);
      int index = 0;
      for (StringConstant keyConstant in _constant.keys.entries) {
        _listCache[index] = keyConstant.value.slowToString();
        index++;
      }
    }
    return _listCache;
  }

  int get length => _constant.length;

  Iterable<String> get keys {
    // TODO(johnniwinther): Return an unmodifiable list instead.
    return new List<String>.from(_list);
  }

  InstanceMirror operator[](String key) {
    int index = _list.indexOf(key);
    if (index == -1) return null;
    return _convertConstantToInstanceMirror(mirrors, _constant.values[index]);
  }
}

class Dart2JsTypeConstantMirror extends Dart2JsConstantMirror
    implements TypeInstanceMirror {

  Dart2JsTypeConstantMirror(Dart2JsMirrorSystem mirrors,
                            TypeConstant constant)
      : super(mirrors, constant);

  TypeConstant get _constant => super._constant;

  TypeMirror get representedType => _convertTypeToTypeMirror(
      mirrors, _constant.representedType, mirrors.compiler.types.dynamicType);
}

class Dart2JsConstructedConstantMirror extends Dart2JsConstantMirror {
  Map<String,Constant> _fieldMapCache;

  Dart2JsConstructedConstantMirror(Dart2JsMirrorSystem mirrors,
                                   ConstructedConstant constant)
      : super(mirrors, constant);

  ConstructedConstant get _constant => super._constant;

  Map<String,Constant> get _fieldMap {
    if (_fieldMapCache == null) {
      _fieldMapCache = new Map<String,Constant>();
      if (identical(_constant.type.element.kind, ElementKind.CLASS)) {
        var index = 0;
        ClassElement element = _constant.type.element;
        element.forEachInstanceField((_, Element field) {
          String fieldName = field.name;
          _fieldMapCache.putIfAbsent(fieldName, () => _constant.fields[index]);
          index++;
        }, includeSuperAndInjectedMembers: true);
      }
    }
    return _fieldMapCache;
  }

  InstanceMirror getField(String fieldName) {
    Constant fieldConstant = _fieldMap[fieldName];
    if (fieldConstant != null) {
      return _convertConstantToInstanceMirror(mirrors, fieldConstant);
    }
    return super.getField(fieldName);
  }
}

class Dart2JsCommentInstanceMirror implements CommentInstanceMirror {
  final Dart2JsMirrorSystem mirrors;
  final String text;
  String _trimmedText;

  Dart2JsCommentInstanceMirror(this.mirrors, this.text);

  ClassMirror get type {
    return new Dart2JsClassMirror(mirrors, mirrors.compiler.documentClass);
  }

  bool get isDocComment => text.startsWith('/**') || text.startsWith('///');

  String get trimmedText {
    if (_trimmedText == null) {
      _trimmedText = stripComment(text);
    }
    return _trimmedText;
  }

  bool get hasReflectee => false;

  get reflectee {
    // TODO(johnniwinther): Which exception/error should be thrown here?
    throw new UnsupportedError('InstanceMirror does not have a reflectee');
  }

  InstanceMirror getField(String fieldName) {
    if (fieldName == 'isDocComment') {
      return new Dart2JsBoolConstantMirror.fromBool(mirrors, isDocComment);
    } else if (fieldName == 'text') {
      return new Dart2JsStringConstantMirror.fromString(mirrors, text);
    } else if (fieldName == 'trimmedText') {
      return new Dart2JsStringConstantMirror.fromString(mirrors, trimmedText);
    }
    // TODO(johnniwinther): Which exception/error should be thrown here?
    throw new UnsupportedError('InstanceMirror does not have a reflectee');
  }
}

_convertElementToMembers(Dart2JsLibraryMirror library, Element e) {
  // TODO(ahe): This method creates new mirror objects which is not correct.
  if (e.isClass()) {
    ClassElement classElement = e;
    classElement.ensureResolved(library.mirrors.compiler);
    return [new Dart2JsClassMirror.fromLibrary(library, classElement)];
  } else if (e.isTypedef()) {
    return [new Dart2JsTypedefMirror.fromLibrary(
          library, e.computeType(library.mirrors.compiler))];
  } else {
    return _convertElementMemberToMemberMirrors(library, e);
  }
}

/**
 * Converts [element] into its corresponding [DeclarationMirror], if any.
 *
 * If [element] is an [AbstractFieldElement] the mirror for its getter is
 * returned or, if not present, the mirror for its setter.
 */
DeclarationMirror _convertElementToDeclarationMirror(Dart2JsMirrorSystem system,
                                                     Element element) {
  if (element.isTypeVariable()) {
    return new Dart2JsTypeVariableMirror(
        system, element.computeType(system.compiler));
  }

  Dart2JsLibraryMirror library = system._libraryMap[element.getLibrary()];
  if (element.isLibrary()) return library;
  if (element.isTypedef()) {
    return new Dart2JsTypedefMirror.fromLibrary(
        library, element.computeType(system.compiler));
  }

  Dart2JsContainerMirror container = library;
  if (element.getEnclosingClass() != null) {
    container = new Dart2JsClassMirror.fromLibrary(
        library, element.getEnclosingClass());
  }
  if (element.isClass()) return container;
  if (element.isParameter()) {
    MethodMirror method = _convertElementMethodToMethodMirror(
        container, element.getOutermostEnclosingMemberOrTopLevel());
    // TODO(johnniwinther): Find the right info for [isOptional] and [isNamed].
    return new Dart2JsParameterMirror(
        system, method, element, isOptional: false, isNamed: false);
  }
  Iterable<MemberMirror> members =
      _convertElementMemberToMemberMirrors(container, element);
  if (members.isEmpty) return null;
  return members.first;
}

/**
 * Experimental API for accessing compilation units defined in a
 * library.
 */
// TODO(ahe): Superclasses? Is this really a mirror?
class Dart2JsCompilationUnitMirror extends Dart2JsMirror {
  final Dart2JsLibraryMirror _library;
  final CompilationUnitElement _element;

  Dart2JsCompilationUnitMirror(this._element, this._library);

  Dart2JsMirrorSystem get mirrors => _library.mirrors;

  List<DeclarationMirror> get members {
    // TODO(ahe): Should return an immutable List.
    // TODO(johnniwinther): make sure that these are returned in declaration
    // order.
    List<DeclarationMirror> members= <DeclarationMirror>[];
    _element.forEachLocalMember((m) {
      members.addAll(_convertElementToMembers(_library, m));
    });
    return members;
  }

  Uri get uri => _element.script.uri;
}

/**
 * Transitional class that allows access to features that have not yet
 * made it to the mirror API.
 *
 * All API in this class is experimental.
 */
class BackDoor {
  /// Return the compilation units comprising [library].
  static List<Mirror> compilationUnitsOf(Dart2JsLibraryMirror library) {
    return library._library.compilationUnits.toList().map(
        (cu) => new Dart2JsCompilationUnitMirror(cu, library)).toList();
  }
}
