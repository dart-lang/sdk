// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/reference.dart';

/// Creates a set of mock libraries from the given specifications.
Map<String, LibraryElementImpl> buildLibrariesFromSpec(
  engine.AnalysisContext analysisContext,
  Reference rootReference,
  AnalysisSessionImpl analysisSession,
  Map<String, LibrarySpec> specs,
) {
  var builder = _LibraryBuilder(
    rootReference,
    analysisContext,
    analysisSession,
    specs,
  );
  return builder.build();
}

class ClassSpec {
  final String name;
  final List<String> typeParameters;
  final String? supertype;
  final List<String> interfaces;
  final List<ConstructorSpec> constructors;
  final List<MethodSpec> methods;
  final bool isAbstract;

  const ClassSpec({
    required this.name,
    this.typeParameters = const [],
    this.supertype,
    this.interfaces = const [],
    this.constructors = const [],
    this.methods = const [],
    this.isAbstract = false,
  });
}

class ConstructorSpec {
  final String name;
  final String formalParameters;
  final bool isConst;
  final bool isFactory;

  const ConstructorSpec({
    this.name = '',
    this.formalParameters = '',
    this.isConst = false,
    this.isFactory = false,
  });
}

class FunctionSpec {
  final String name;
  final List<String> typeParameters;
  final String formalParameters;
  final String returnType;

  const FunctionSpec({
    required this.name,
    this.typeParameters = const [],
    this.formalParameters = '',
    required this.returnType,
  });
}

class LibrarySpec {
  final String uri;
  final List<ClassSpec> classes;
  final List<FunctionSpec> functions;

  const LibrarySpec({
    required this.uri,
    this.classes = const [],
    this.functions = const [],
  });
}

class MethodSpec {
  final String name;
  final List<String> typeParameters;
  final String formalParameters;
  final String returnType;

  const MethodSpec({
    required this.name,
    this.typeParameters = const [],
    this.formalParameters = '',
    required this.returnType,
  });
}

/// Builds a set of libraries from a collection of [LibrarySpec]s.
///
/// The builder uses a two-pass process:
///
/// 1. **Shell Creation**: Create all `LibraryElementImpl`, `ClassElementImpl`,
///    etc "shells". This populates the namespace so that type lookups can
///    succeed across library boundaries in the next step.
///
/// 2. **Element Population**: Fill in the details of each element, such as
///    supertypes, interfaces, methods, and parameters. This step resolves
///    all type strings using the shells created in the first pass.
///
/// This two-pass approach allows for resolving inter-library dependencies and
/// cycles (e.g., `dart:core` and `dart:async` referencing each other).
class _LibraryBuilder {
  final Reference rootReference;
  final engine.AnalysisContext analysisContext;
  final AnalysisSessionImpl analysisSession;
  final Map<String, LibrarySpec> specs;

  final Map<String, LibraryElementImpl> _libraryElements = {};
  final Map<String, LibraryFragmentImpl> _libraryFragments = {};
  final Map<String, ClassElementImpl> _classElements = {};

  late final _Scope _rootScope;
  final _TypeParser _typeParser = _TypeParser();

  _LibraryBuilder(
    this.rootReference,
    this.analysisContext,
    this.analysisSession,
    this.specs,
  ) {
    _rootScope = _Scope.root(_classElements);
  }

  /// Builds all libraries specified in [specs] and returns them in a map.
  Map<String, LibraryElementImpl> build() {
    _buildElementShells();
    _populateElements();
    return _libraryElements;
  }

  /// Create empty shells for all libraries and elements.
  void _buildElementShells() {
    for (var libSpec in specs.values) {
      var libraryUriStr = libSpec.uri;
      var librarySource = analysisContext.sourceFactory.forUri(libraryUriStr)!;
      var libraryElement = LibraryElementImpl(
        analysisContext,
        analysisSession,
        libraryUriStr.replaceAll(':', '.'),
        0,
        0,
        FeatureSet.latestLanguageVersion(),
      );
      var libraryFragment = LibraryFragmentImpl(
        library: libraryElement,
        source: librarySource,
        lineInfo: LineInfo([0]),
      );
      libraryElement.firstFragment = libraryFragment;
      _libraryElements[libraryUriStr] = libraryElement;
      _libraryFragments[libraryUriStr] = libraryFragment;

      for (var classSpec in libSpec.classes) {
        var fragment = ClassFragmentImpl(name: classSpec.name);
        var element = ClassElementImpl(
          rootReference.getChild('@class').getChild(classSpec.name),
          fragment,
        );

        libraryFragment.encloseElement(fragment);
        libraryElement.addClass(element);
        _classElements[classSpec.name] = element;
      }
    }
  }

  ConstructorFragmentImpl _createConstructorFragment(
    ConstructorSpec spec, {
    required ClassElementImpl classElement,
    required _Scope classScope,
  }) {
    var fragment = ConstructorFragmentImpl(name: spec.name);
    fragment.isConst = spec.isConst;
    fragment.isFactory = spec.isFactory;

    var element = ConstructorElementImpl(
      name: spec.name,
      reference: classElement.reference
          .getChild('@constructor')
          .getChild(spec.name),
      firstFragment: fragment,
    );
    classElement.addConstructor(element);

    var formalParameters = _typeParser.parseFormalParameters(
      classScope,
      spec.formalParameters,
    );
    fragment.formalParameters = formalParameters.map((formalParameterElement) {
      return formalParameterElement.firstFragment;
    }).toList();

    return fragment;
  }

  TopLevelFunctionFragmentImpl _createFunctionFragment(
    LibraryElementImpl library,
    FunctionSpec spec,
  ) {
    var fragment = TopLevelFunctionFragmentImpl(name: spec.name);
    var scope = _Scope.child(_rootScope);

    var element = TopLevelFunctionElementImpl(
      rootReference.getChild('@function').getChild(spec.name),
      fragment,
    );
    library.addTopLevelFunction(element);

    for (var name in spec.typeParameters) {
      var tpElement = _createTypeParameterElement(name);
      scope.addTypeParameter(tpElement);
      fragment.typeParameters.add(tpElement.firstFragment);
    }

    var formalParameterElements = _typeParser.parseFormalParameters(
      scope,
      spec.formalParameters,
    );
    fragment.formalParameters = formalParameterElements.map((
      formalParameterElement,
    ) {
      return formalParameterElement.firstFragment;
    }).toList();

    element.returnType = _typeParser.parse(spec.returnType, scope);
    return fragment;
  }

  MethodFragmentImpl _createMethodFragment(
    ClassElementImpl classElement,
    MethodSpec spec,
    _Scope parentScope,
  ) {
    var fragment = MethodFragmentImpl(name: spec.name);
    var scope = _Scope.child(parentScope);

    var element = MethodElementImpl(
      name: spec.name,
      reference: classElement.reference.getChild('@method').getChild(spec.name),
      firstFragment: fragment,
    );

    fragment.typeParameters = spec.typeParameters.map((name) {
      var tpElement = _createTypeParameterElement(name);
      scope.addTypeParameter(tpElement);
      return tpElement.firstFragment;
    }).toList();

    var formalParameterElements = _typeParser.parseFormalParameters(
      scope,
      spec.formalParameters,
    );
    fragment.formalParameters = formalParameterElements.map((
      formalParameterElement,
    ) {
      return formalParameterElement.firstFragment;
    }).toList();

    element.returnType = _typeParser.parse(spec.returnType, scope);
    return fragment;
  }

  TypeParameterElementImpl _createTypeParameterElement(String name) {
    var fragment = TypeParameterFragmentImpl(name: name);
    return TypeParameterElementImpl(firstFragment: fragment);
  }

  void _populateClasses(LibrarySpec libSpec) {
    for (var classSpec in libSpec.classes) {
      var element = _classElements[classSpec.name]!;
      var fragment = element.firstFragment;
      var scope = _Scope.child(_rootScope);

      fragment.typeParameters = classSpec.typeParameters.map((name) {
        var tpElement = _createTypeParameterElement(name);
        scope.addTypeParameter(tpElement);
        return tpElement.firstFragment;
      }).toList();

      if (classSpec.supertype case var supertypeStr?) {
        var supertype = _typeParser.parse(supertypeStr, scope);
        element.supertype = supertype as InterfaceTypeImpl;
      }

      element.interfaces = classSpec.interfaces.map((interfaceStr) {
        var interface = _typeParser.parse(interfaceStr, scope);
        return interface as InterfaceTypeImpl;
      }).toList();

      for (var constructorSpec in classSpec.constructors) {
        var constructorFragment = _createConstructorFragment(
          classElement: element,
          classScope: scope,
          constructorSpec,
        );
        fragment.addConstructor(constructorFragment);
      }

      for (var methodSpec in classSpec.methods) {
        var methodFragment = _createMethodFragment(element, methodSpec, scope);
        fragment.addMethod(methodFragment);
      }

      element.methods = fragment.methods.map((f) => f.element).toList();
      element.constructors = fragment.constructors
          .map((f) => f.element)
          .toList();
    }
  }

  /// Populate the shells with types, methods, and other details.
  void _populateElements() {
    for (var libSpec in specs.values) {
      _populateClasses(libSpec);
      _populateTopLevelFunctions(libSpec);
    }
  }

  void _populateTopLevelFunctions(LibrarySpec libSpec) {
    var libraryElement = _libraryElements[libSpec.uri]!;
    var libraryFragment = _libraryFragments[libSpec.uri]!;

    for (var functionSpec in libSpec.functions) {
      var functionFragment = _createFunctionFragment(
        libraryElement,
        functionSpec,
      );
      libraryFragment.addFunction(functionFragment);
    }
    libraryElement.topLevelFunctions = libraryFragment.functions.map((element) {
      return element.element;
    }).toList();
  }
}

/// Representation of direct type like `void` or `dynamic`.
class _PreExplicitType implements _PreType {
  final TypeImpl type;

  _PreExplicitType({required this.type});

  @override
  TypeImpl materialize(_Scope scope) => type;
}

class _PreFormalParameter {
  final _PreType type;
  final String? name;
  final ParameterKind kind;

  _PreFormalParameter({
    required this.type,
    required this.name,
    required this.kind,
  });

  FormalParameterElementImpl materialize(_Scope scope) {
    var fragment = FormalParameterFragmentImpl(
      name: name,
      nameOffset: 0,
      parameterKind: kind,
    );

    var element = FormalParameterElementImpl(fragment);
    element.type = type.materialize(scope);
    return element;
  }
}

class _PreFunctionType implements _PreType {
  final List<_PreTypeParameter> typeParameters;
  final List<_PreFormalParameter> formalParameters;
  final _PreType returnType;

  _PreFunctionType({
    required this.typeParameters,
    required this.formalParameters,
    required this.returnType,
  });

  @override
  TypeImpl materialize(_Scope scope) {
    // Create a new scope for the function's own type parameters.
    var functionScope = _Scope.child(scope);

    // Create elements for the function's own type parameters and add to scope.
    var typeParameters = this.typeParameters.map((pre) {
      var fragment = TypeParameterFragmentImpl(name: pre.name);
      var element = TypeParameterElementImpl(firstFragment: fragment);
      functionScope.addTypeParameter(element);
      return element;
    }).toList();

    // Now that the type parameters are in scope, materialize their bounds.
    for (var i = 0; i < typeParameters.length; i++) {
      var pre = this.typeParameters[i];
      if (pre.bound case var bound?) {
        typeParameters[i].bound = bound.materialize(functionScope);
      }
    }

    var returnType = this.returnType.materialize(functionScope);
    var formalParameters = this.formalParameters
        .map((p) => p.materialize(functionScope))
        .toList();

    return FunctionTypeImpl.v2(
      returnType: returnType,
      typeParameters: typeParameters,
      formalParameters: formalParameters,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}

class _PreNamedType implements _PreType {
  final String name;
  final List<_PreType> args;

  _PreNamedType({required this.name, required this.args});

  @override
  TypeImpl materialize(_Scope scope) {
    if (scope.lookupTypeParameter(name) case var element?) {
      assert(args.isEmpty);
      return TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    var element = scope.lookupInterface(name);
    if (element == null) throw StateError('Unknown type: $name');

    return InterfaceTypeImpl(
      element: element,
      typeArguments: args.map((arg) => arg.materialize(scope)).toList(),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}

/// Makes [inner] type nullable.
class _PreNullableType implements _PreType {
  final _PreType inner;

  _PreNullableType({required this.inner});

  @override
  TypeImpl materialize(_Scope scope) {
    return inner.materialize(scope).withNullability(NullabilitySuffix.question);
  }
}

/// Representation of a [TypeImpl] that has been parsed but hasn't had meaning
/// assigned to its identifiers yet.
abstract class _PreType {
  /// Translates `this` into a [TypeImpl].
  ///
  /// The meaning of identifiers in `this` is determined by looking them up
  /// in the provided [scope].
  TypeImpl materialize(_Scope scope);
}

class _PreTypeParameter {
  final String name;
  final _PreType? bound;

  _PreTypeParameter({required this.name, required this.bound})
    : assert(name.isNotEmpty);
}

/// A unified scope for looking up named elements.
///
/// It can look up type parameters from the current (and parent) scopes,
/// as well as named types (like classes and mixins) from the global scope.
class _Scope {
  final _Scope? parent;
  final Map<String, TypeParameterElementImpl> _typeParameters = {};
  final Map<String, InterfaceElementImpl> _interfaces;

  /// Creates a nested scope that inherits its parent's context.
  ///
  /// This is used to add type parameters of a class, method, etc.
  _Scope.child(_Scope this.parent) : _interfaces = parent._interfaces;

  /// Creates a root scope containing all known interfaces.
  _Scope.root(this._interfaces) : parent = null;

  /// Adds a type parameter to the current scope.
  void addTypeParameter(TypeParameterElementImpl element) {
    _typeParameters[element.name!] = element;
  }

  /// Looks up an interface by name.
  InterfaceElementImpl? lookupInterface(String name) {
    return _interfaces[name];
  }

  /// Looks up a type parameter by name, walking up the scope chain.
  TypeParameterElementImpl? lookupTypeParameter(String name) {
    return _typeParameters[name] ?? parent?.lookupTypeParameter(name);
  }
}

class _TokenStream {
  static final RegExp _tokenizer = RegExp(
    r'[a-zA-Z_]\w*|<|>|,|\?|\(|\)|\{|\}|\[|\]|extends',
  );

  final List<String> _tokens;
  int _index = 0;

  factory _TokenStream.fromString(String input) {
    var tokens = _tokenizer.allMatches(input).map((m) => m.group(0)!).toList();
    return _TokenStream._(tokens);
  }

  _TokenStream._(this._tokens);

  bool get isAtEnd => _index >= _tokens.length;

  String consume() {
    if (isAtEnd) throw StateError('Unexpected end of token stream.');
    return _tokens[_index++];
  }

  void expect(String expected) {
    if (isAtEnd) {
      throw StateError('Expected "$expected" but found end of stream.');
    }
    var token = consume();
    if (token != expected) {
      throw StateError('Expected "$expected" but found "$token".');
    }
  }

  bool match(String expected) {
    if (peekIs(expected)) {
      _index++;
      return true;
    }
    return false;
  }

  String peek() {
    if (isAtEnd) throw StateError('Unexpected end of token stream.');
    return _tokens[_index];
  }

  bool peekIs(String token) {
    return !isAtEnd && peek() == token;
  }

  bool peekIsAnyOf(Set<String> tokens) {
    return !isAtEnd && tokens.contains(peek());
  }
}

class _TypeParser {
  TypeImpl parse(String input, _Scope scope) {
    var stream = _TokenStream.fromString(input);
    var preType = _parseType(stream);
    if (!stream.isAtEnd) {
      throw StateError('Unexpected trailing tokens');
    }
    return preType.materialize(scope);
  }

  /// Parse formal parameters, without enclosing `()`.
  List<FormalParameterElementImpl> parseFormalParameters(
    _Scope scope,
    String input,
  ) {
    var stream = _TokenStream.fromString(input);
    var preList = _parseFormalParameters(stream);
    return preList.map((pre) => pre.materialize(scope)).toList();
  }

  _PreFormalParameter _parseFormalParameter(
    _TokenStream stream,
    ParameterKind kind,
  ) {
    if (kind == ParameterKind.NAMED) {
      kind = ParameterKind.NAMED_REQUIRED;
    }

    var type = _parseType(stream);

    String? name;
    if (!stream.isAtEnd && !stream.peekIsAnyOf(const {',', ')', ']', '}'})) {
      name = stream.consume();
    }

    return _PreFormalParameter(type: type, name: name, kind: kind);
  }

  /// Parse formal parameters, without enclosing `()`.
  List<_PreFormalParameter> _parseFormalParameters(_TokenStream stream) {
    var formalParameters = <_PreFormalParameter>[];
    if (stream.isAtEnd || stream.peekIs(')')) {
      return formalParameters;
    }

    // Parse required positional formal parameters.
    while (!stream.isAtEnd && !stream.peekIsAnyOf(const {')', '[', '{'})) {
      formalParameters.add(
        _parseFormalParameter(stream, ParameterKind.REQUIRED),
      );
      stream.match(',');
    }

    // Parse optional positional formal parameters.
    if (stream.match('[')) {
      while (!stream.isAtEnd && !stream.peekIs(']')) {
        formalParameters.add(
          _parseFormalParameter(stream, ParameterKind.POSITIONAL),
        );
        stream.match(',');
      }
      stream.expect(']');
    }

    // Parse named formal parameters.
    if (stream.match('{')) {
      while (!stream.isAtEnd && !stream.peekIs('}')) {
        formalParameters.add(
          _parseFormalParameter(stream, ParameterKind.NAMED),
        );
        stream.match(',');
      }
      stream.expect('}');
    }

    return formalParameters;
  }

  _PreType _parsePrimaryType(_TokenStream stream) {
    var name = stream.consume();
    switch (name) {
      case 'dynamic':
        return _PreExplicitType(type: DynamicTypeImpl.instance);
      case 'void':
        return _PreExplicitType(type: VoidTypeImpl.instance);
    }

    var args = <_PreType>[];
    if (stream.match('<')) {
      while (!stream.isAtEnd && !stream.peekIs('>')) {
        args.add(_parseType(stream));
        stream.match(',');
      }
      stream.expect('>');
    }
    return _PreNamedType(name: name, args: args);
  }

  _PreType _parseType(_TokenStream stream) {
    var type = _parsePrimaryType(stream);

    // Check for function type.
    if (stream.match('Function')) {
      var typeParameters = _parseTypeParameters(stream);

      stream.expect('(');
      var formalParameters = _parseFormalParameters(stream);
      stream.expect(')');
      type = _PreFunctionType(
        returnType: type,
        formalParameters: formalParameters,
        typeParameters: typeParameters,
      );
    }

    if (stream.match('?')) {
      return _PreNullableType(inner: type);
    }
    return type;
  }

  List<_PreTypeParameter> _parseTypeParameters(_TokenStream stream) {
    var typeParameters = <_PreTypeParameter>[];
    if (stream.isAtEnd || !stream.match('<')) {
      return typeParameters;
    }

    while (!stream.isAtEnd && !stream.peekIs('>')) {
      var name = stream.consume();
      _PreType? bound;
      if (stream.match('extends')) {
        bound = _parseType(stream);
      }
      typeParameters.add(_PreTypeParameter(name: name, bound: bound));

      stream.match(',');
    }

    stream.expect('>');
    return typeParameters;
  }
}
