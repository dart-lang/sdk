// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.mirrors;

import 'dart:collection' show UnmodifiableListView, UnmodifiableMapView;

import '../cps_ir/const_expression.dart';
import '../elements/elements.dart';
import '../scanner/scannerlib.dart';
import '../resolution/resolution.dart' show Scope;
import '../dart2jslib.dart';
import '../dart_types.dart';
import '../tree/tree.dart';
import '../util/util.dart'
    show Link,
         LinkBuilder;
import '../util/characters.dart' show $CR, $LF;

import 'source_mirrors.dart';
import 'mirrors_util.dart';

part 'dart2js_library_mirror.dart';
part 'dart2js_type_mirrors.dart';
part 'dart2js_member_mirrors.dart';
part 'dart2js_instance_mirrors.dart';

//------------------------------------------------------------------------------
// Utility types and functions for the dart2js mirror system
//------------------------------------------------------------------------------

bool _includeLibrary(Dart2JsLibraryMirror mirror) {
  return const bool.fromEnvironment("list_all_libraries") ||
      !mirror._element.isInternalLibrary;
}

bool _isPrivate(String name) {
  return name.startsWith('_');
}

List<ParameterMirror> _parametersFromFunctionSignature(
    Dart2JsDeclarationMirror owner,
    FunctionSignature signature) {
  var parameters = <ParameterMirror>[];
  Link<Element> link = signature.requiredParameters;
  while (!link.isEmpty) {
    parameters.add(new Dart2JsParameterMirror(
        owner, link.head, isOptional: false, isNamed: false));
    link = link.tail;
  }
  link = signature.optionalParameters;
  bool isNamed = signature.optionalParametersAreNamed;
  while (!link.isEmpty) {
    parameters.add(new Dart2JsParameterMirror(
        owner, link.head, isOptional: true, isNamed: isNamed));
    link = link.tail;
  }
  return parameters;
}

MethodMirror _convertElementMethodToMethodMirror(
    Dart2JsDeclarationMirror library, Element element) {
  if (element is FunctionElement) {
    return new Dart2JsMethodMirror(library, element);
  } else {
    return null;
  }
}

//------------------------------------------------------------------------------
// Dart2Js specific extensions of mirror interfaces
//------------------------------------------------------------------------------

abstract class Dart2JsMirror implements Mirror {
  Dart2JsMirrorSystem get mirrorSystem;
}

abstract class Dart2JsDeclarationMirror extends Dart2JsMirror
    implements DeclarationSourceMirror {

  bool get isTopLevel => owner != null && owner is LibraryMirror;

  bool get isPrivate => _isPrivate(_simpleNameString);

  String get _simpleNameString;

  String get _qualifiedNameString {
    var parent = owner;
    if (parent is Dart2JsDeclarationMirror) {
      return '${parent._qualifiedNameString}.${_simpleNameString}';
    }
    assert(parent == null);
    return _simpleNameString;
  }

  Symbol get simpleName => symbolOf(_simpleNameString, getLibrary(this));

  Symbol get qualifiedName => symbolOf(_qualifiedNameString, getLibrary(this));

  DeclarationMirror lookupInScope(String name) => null;

  bool get isNameSynthetic => false;

  /// Returns the type mirror for [type] in the context of this declaration.
  TypeMirror _getTypeMirror(DartType type) {
    return mirrorSystem._convertTypeToTypeMirror(type);
  }

  /// Returns a list of the declaration mirrorSystem for [element].
  Iterable<Dart2JsMemberMirror> _getDeclarationMirrors(Element element) {
    if (element.isSynthesized) {
      return const <Dart2JsMemberMirror>[];
    } else if (element is VariableElement) {
      return <Dart2JsMemberMirror>[new Dart2JsFieldMirror(this, element)];
    } else if (element is FunctionElement) {
      return <Dart2JsMemberMirror>[new Dart2JsMethodMirror(this, element)];
    } else if (element is AbstractFieldElement) {
      var members = <Dart2JsMemberMirror>[];
      AbstractFieldElement field = element;
      if (field.getter != null) {
        members.add(new Dart2JsMethodMirror(this, field.getter));
      }
      if (field.setter != null) {
        members.add(new Dart2JsMethodMirror(this, field.setter));
      }
      return members;
    }
    mirrorSystem.compiler.internalError(element,
        "Unexpected member type $element ${element.kind}.");
    return null;
  }
}

abstract class Dart2JsElementMirror extends Dart2JsDeclarationMirror {
  final Dart2JsMirrorSystem mirrorSystem;
  final Element _element;
  List<InstanceMirror> _metadata;

  Dart2JsElementMirror(this.mirrorSystem, this._element) {
    assert (mirrorSystem != null);
    assert (_element != null);
  }

  String get _simpleNameString => _element.name;

  /**
   * Computes the first token for this declaration using the begin token of the
   * element node or element position as indicator.
   */
  Token getBeginToken() {
    Element element = _element;
    if (element is AstElement) {
      Node node = element.node;
      if (node != null) {
        return node.getBeginToken();
      }
    }
    return element.position;
  }

  /**
   * Computes the last token for this declaration using the end token of the
   * element node or element position as indicator.
   */
  Token getEndToken() {
    Element element = _element;
    if (element is AstElement) {
      Node node = element.node;
      if (node != null) {
        return node.getEndToken();
      }
    }
    return element.position;
  }

  /**
   * Returns the first token for the source of this declaration, including
   * metadata annotations.
   */
  Token getFirstToken() {
    if (!_element.metadata.isEmpty) {
      for (MetadataAnnotation metadata in _element.metadata) {
        if (metadata.beginToken != null) {
          return metadata.beginToken;
        }
      }
    }
    return getBeginToken();
  }

  Script getScript() => _element.compilationUnit.script;

  SourceLocation get location {
    Token beginToken = getFirstToken();
    Script script = getScript();
    SourceSpan span;
    if (beginToken == null) {
      span = new SourceSpan(script.readableUri, 0, 0);
    } else {
      Token endToken = getEndToken();
      span = mirrorSystem.compiler.spanFromTokens(
          beginToken, endToken, script.readableUri);
    }
    return new Dart2JsSourceLocation(script, span);
  }

  String toString() => _element.toString();

  void _appendCommentTokens(Token commentToken) {
    while (commentToken != null && commentToken.kind == COMMENT_TOKEN) {
      _metadata.add(new Dart2JsCommentInstanceMirror(
          mirrorSystem, commentToken.value));
      commentToken = commentToken.next;
    }
  }

  List<InstanceMirror> get metadata {
    if (_metadata == null) {
      _metadata = <InstanceMirror>[];
      for (MetadataAnnotation metadata in _element.metadata) {
        _appendCommentTokens(
            mirrorSystem.compiler.commentMap[metadata.beginToken]);
        metadata.ensureResolved(mirrorSystem.compiler);
        _metadata.add(_convertConstantToInstanceMirror(
            mirrorSystem, metadata.constant, metadata.constant.value));
      }
      _appendCommentTokens(mirrorSystem.compiler.commentMap[getBeginToken()]);
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
      if (result != null && result.isPrefix) {
        PrefixElement prefix = result;
        result = prefix.lookupLocalMember(id);
      } else {
        result = null;
      }
    } else {
      // Lookup [: id :].
      result = scope.lookup(name);
    }
    if (result == null || result.isPrefix) return null;
    return _convertElementToDeclarationMirror(mirrorSystem, result);
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

//------------------------------------------------------------------------------
// Mirror system implementation.
//------------------------------------------------------------------------------

class Dart2JsMirrorSystem extends MirrorSystem {
  final Compiler compiler;
  Map<LibraryElement, Dart2JsLibraryMirror> _libraryMap;
  UnmodifiableMapView<Uri, LibraryMirror> _filteredLibraries;

  Dart2JsMirrorSystem(this.compiler);

  IsolateMirror get isolate => null;

  void _ensureLibraries() {
    if (_filteredLibraries == null) {
      var filteredLibs = new Map<Uri, LibraryMirror>();
      _libraryMap = new Map<LibraryElement, Dart2JsLibraryMirror>();
      compiler.libraryLoader.libraries.forEach((LibraryElement v) {
        var mirror = new Dart2JsLibraryMirror(mirrorSystem, v);
        if (_includeLibrary(mirror)) {
          filteredLibs[mirror.uri] = mirror;
        }
        _libraryMap[v] = mirror;
      });

      _filteredLibraries =
          new UnmodifiableMapView<Uri, LibraryMirror>(filteredLibs);
    }
  }

  Map<Uri, LibraryMirror> get libraries {
    _ensureLibraries();
    return _filteredLibraries;
  }

  Dart2JsLibraryMirror _getLibrary(LibraryElement element) =>
      _libraryMap[element];

  Dart2JsMirrorSystem get mirrorSystem => this;

  TypeMirror get dynamicType =>
      _convertTypeToTypeMirror(const DynamicType());

  TypeMirror get voidType =>
      _convertTypeToTypeMirror(const VoidType());

  TypeMirror _convertTypeToTypeMirror(DartType type) {
    assert(type != null);
    if (type.treatAsDynamic) {
      return new Dart2JsDynamicMirror(this, type);
    } else if (type is InterfaceType) {
      if (type.typeArguments.isEmpty) {
        return _getTypeDeclarationMirror(type.element);
      } else {
        return new Dart2JsInterfaceTypeMirror(this, type);
      }
    } else if (type is TypeVariableType) {
      return new Dart2JsTypeVariableMirror(this, type);
    } else if (type is FunctionType) {
      return new Dart2JsFunctionTypeMirror(this, type);
    } else if (type is VoidType) {
      return new Dart2JsVoidMirror(this, type);
    } else if (type is TypedefType) {
      if (type.typeArguments.isEmpty) {
        return _getTypeDeclarationMirror(type.element);
      } else {
        return new Dart2JsTypedefMirror(this, type);
      }
    }
    compiler.internalError(type.element,
        "Unexpected type $type of kind ${type.kind}.");
    return null;
  }

  DeclarationMirror _getTypeDeclarationMirror(TypeDeclarationElement element) {
    if (element.isClass) {
      return new Dart2JsClassDeclarationMirror(this, element.thisType);
    } else if (element.isTypedef) {
      return new Dart2JsTypedefDeclarationMirror(this, element.thisType);
    }
    compiler.internalError(element, "Unexpected element $element.");
    return null;
  }
}

abstract class ContainerMixin {
  UnmodifiableMapView<Symbol, DeclarationMirror> _declarations;

  void _ensureDeclarations() {
    if (_declarations == null) {
      var declarations = <Symbol, DeclarationMirror>{};
      _forEachElement((Element element) {
        for (DeclarationMirror mirror in _getDeclarationMirrors(element)) {
          assert(invariant(_element,
              !declarations.containsKey(mirror.simpleName),
              message: "Declaration name '${nameOf(mirror)}' "
                       "is not unique in $_element."));
          declarations[mirror.simpleName] = mirror;
        }
      });
      _declarations =
          new UnmodifiableMapView<Symbol, DeclarationMirror>(declarations);
    }
  }

  Element get _element;

  void _forEachElement(f(Element element));

  Iterable<Dart2JsMemberMirror> _getDeclarationMirrors(Element element);

  Map<Symbol, DeclarationMirror> get declarations {
    _ensureDeclarations();
    return _declarations;
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
  if (element.isTypeVariable) {
    TypeVariableElement typeVariable = element;
    return new Dart2JsTypeVariableMirror(system, typeVariable.type);
  }

  Dart2JsLibraryMirror library = system._libraryMap[element.library];
  if (element.isLibrary) return library;
  if (element.isTypedef) {
    TypedefElement typedefElement = element;
    return new Dart2JsTypedefMirror.fromLibrary(
        library, typedefElement.thisType);
  }

  Dart2JsDeclarationMirror container = library;
  if (element.enclosingClass != null) {
    container = system._getTypeDeclarationMirror(element.enclosingClass);
  }
  if (element.isClass) return container;
  if (element.isParameter) {
    Dart2JsMethodMirror method = _convertElementMethodToMethodMirror(
        container, element.outermostEnclosingMemberOrTopLevel);
    // TODO(johnniwinther): Find the right info for [isOptional] and [isNamed].
    return new Dart2JsParameterMirror(
        method, element, isOptional: false, isNamed: false);
  }
  Iterable<DeclarationMirror> members =
      container._getDeclarationMirrors(element);
  if (members.isEmpty) return null;
  return members.first;
}

/**
 * Experimental API for accessing compilation units defined in a
 * library.
 */
// TODO(ahe): Superclasses? Is this really a mirror?
class Dart2JsCompilationUnitMirror extends Dart2JsMirror with ContainerMixin {
  final Dart2JsLibraryMirror _library;
  final CompilationUnitElement _element;

  Dart2JsCompilationUnitMirror(this._element, this._library);

  Dart2JsMirrorSystem get mirrorSystem => _library.mirrorSystem;

  // TODO(johnniwinther): make sure that these are returned in declaration
  // order.
  void _forEachElement(f(Element element)) => _element.forEachLocalMember(f);

  Iterable<DeclarationMirror> _getDeclarationMirrors(Element element) =>
      _library._getDeclarationMirrors(element);

  Uri get uri => _element.script.resourceUri;
}

class ResolvedNode {
  final node;
  final _elements;
  final _mirrorSystem;
  ResolvedNode(this.node, this._elements, this._mirrorSystem);

  Mirror resolvedMirror(node) {
    var element = _elements[node];
    if (element == null) return null;
    return _convertElementToDeclarationMirror(_mirrorSystem, element);
  }
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
    return library._element.compilationUnits.mapToList(
        (cu) => new Dart2JsCompilationUnitMirror(cu, library));
  }

  static Iterable metadataSyntaxOf(Dart2JsElementMirror declaration) {
    Compiler compiler = declaration.mirrorSystem.compiler;
    return declaration._element.metadata.map((metadata) {
      var node = metadata.parseNode(compiler);
      var treeElements = metadata.annotatedElement.treeElements;
      return new ResolvedNode(
          node, treeElements, declaration.mirrorSystem);
    });
  }

  static ResolvedNode initializerSyntaxOf(Dart2JsFieldMirror variable) {
    var node = variable._variable.initializer;
    if (node == null) return null;
    return new ResolvedNode(
        node, variable._variable.treeElements, variable.mirrorSystem);
  }

  static ResolvedNode defaultValueSyntaxOf(Dart2JsParameterMirror parameter) {
    if (!parameter.hasDefaultValue) return null;
    ParameterElement parameterElement = parameter._element;
    var node = parameterElement.initializer;
    var treeElements = parameterElement.treeElements;
    return new ResolvedNode(node, treeElements, parameter.mirrorSystem);
  }
}
