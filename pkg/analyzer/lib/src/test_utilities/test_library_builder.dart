// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart' show Variance;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/reference.dart';

/// Creates a set of mock libraries from the given specifications.
Map<String, LibraryElementImpl> buildLibrariesFromSpec({
  required engine.AnalysisContext analysisContext,
  required RootReference rootReference,
  required AnalysisSessionImpl analysisSession,
  required Map<String, LibrarySpec> specs,
  Map<String, LibraryElementImpl> externalLibraries = const {},
}) {
  var builder = _LibraryBuilder(
    rootReference,
    analysisContext,
    analysisSession,
    specs,
    externalLibraries,
  );
  return builder.build();
}

List<InterfaceTypeImpl> _materializeInterfaceTypes(
  Iterable<_ParsedType> types,
  _Scope scope,
) {
  return [for (var type in types) type.materialize(scope) as InterfaceTypeImpl];
}

class ClassSpec {
  final String header;

  final List<ConstructorSpec> constructors;
  final List<MethodSpec> methods;

  const ClassSpec(
    this.header, {
    this.constructors = const [],
    this.methods = const [],
  });
}

class ConstructorSpec {
  final String header;

  const ConstructorSpec(this.header);
}

class EnumSpec {
  final String header;
  final List<String> constants;

  const EnumSpec(this.header, {this.constants = const []});
}

class ExtensionTypeSpec {
  final String header;

  const ExtensionTypeSpec(this.header);
}

class LibrarySpec {
  final String uri;
  final List<String> imports;
  final List<ClassSpec> classes;
  final List<EnumSpec> enums;
  final List<ExtensionTypeSpec> extensionTypes;
  final List<TopLevelFunctionSpec> functions;
  final List<MixinSpec> mixins;
  final List<TypeAliasSpec> typeAliases;

  const LibrarySpec({
    required this.uri,
    this.imports = const [],
    this.classes = const [],
    this.enums = const [],
    this.extensionTypes = const [],
    this.functions = const [],
    this.mixins = const [],
    this.typeAliases = const [],
  });
}

class MethodSpec {
  final String header;

  const MethodSpec(this.header);
}

class MixinSpec {
  final String header;

  const MixinSpec(this.header);
}

class TopLevelFunctionSpec {
  final String header;

  const TopLevelFunctionSpec(this.header);
}

class TypeAliasSpec {
  final String header;

  const TypeAliasSpec(this.header);
}

final class TypeSpecParser {
  final _Scope _scope;

  TypeSpecParser({
    required List<LibraryElementImpl> libraries,
    required List<TypeParameterElementImpl> typeParameters,
  }) : _scope = _Scope.forLibraries(
         libraries: libraries,
         typeParameters: typeParameters,
       );

  TypeImpl parse(String input) {
    return _SpecParser.parseType(input).materialize(_scope);
  }

  List<TypeParameterElementImpl> parseTypeParameters(String input) {
    var declarations = _TypeParameterDeclarations(
      _SpecParser.parseTypeParameters(input),
    );
    return declarations.materializeStandalone(_Scope.child(_scope));
  }
}

class _ClassDeclaration {
  final ClassSpec spec;

  final _ParsedClassHeader header;
  final _TypeParameterDeclarations typeParameters;

  final List<_ConstructorDeclaration> constructors;
  final List<_MethodDeclaration> methods;

  late final ClassFragmentImpl fragment;
  late final ClassElementImpl element;

  factory _ClassDeclaration.fromSpec(ClassSpec spec) {
    var header = _SpecParser.parseClassHeader(spec.header);
    return _ClassDeclaration._(spec, header);
  }

  _ClassDeclaration._(this.spec, this.header)
    : typeParameters = _TypeParameterDeclarations(header.typeParameters),
      constructors = [
        for (var constructorSpec in spec.constructors)
          _ConstructorDeclaration.fromSpec(constructorSpec),
      ],
      methods = [
        for (var methodSpec in spec.methods)
          _MethodDeclaration.fromSpec(methodSpec),
      ];

  void createElement({required LibraryReference libraryReference}) {
    fragment = ClassFragmentImpl(name: header.name)
      ..typeParameters = typeParameters.createFragments()
      ..isAbstract = header.isAbstract
      ..isSealed = header.isSealed;

    element = ClassElementImpl(
      libraryReference.declareClass(header.name),
      fragment,
    );

    for (var constructorDeclaration in constructors) {
      constructorDeclaration.createElement(classElement: element);
      fragment.addConstructor(constructorDeclaration.fragment);
      element.addConstructor(constructorDeclaration.element);
    }

    for (var methodDeclaration in methods) {
      methodDeclaration.createElement(classElement: element);
      fragment.addMethod(methodDeclaration.fragment);
      element.addMethod(methodDeclaration.element);
    }
  }

  void resolve(_Scope libraryScope) {
    var scope = _Scope.child(libraryScope);
    typeParameters.resolve(scope);

    element.supertype =
        header.supertype.materialize(scope) as InterfaceTypeImpl;
    element.mixins = _materializeInterfaceTypes(header.mixins, scope);
    element.interfaces = _materializeInterfaceTypes(header.interfaces, scope);

    for (var constructorDeclaration in constructors) {
      constructorDeclaration.resolve(scope);
    }

    for (var methodDeclaration in methods) {
      methodDeclaration.resolve(scope);
    }
  }
}

class _ConstructorDeclaration {
  final ConstructorSpec spec;
  final _ParsedConstructorHeader header;
  final _FormalParameterDeclarations formalParameters;

  late final ConstructorFragmentImpl fragment;
  late final ConstructorElementImpl element;

  factory _ConstructorDeclaration.fromSpec(ConstructorSpec spec) {
    var header = _SpecParser.parseConstructorHeader(spec.header);
    return _ConstructorDeclaration._(spec, header);
  }

  _ConstructorDeclaration._(this.spec, this.header)
    : formalParameters = _FormalParameterDeclarations(header.formalParameters);

  void createElement({required ClassElementImpl classElement}) {
    fragment = ConstructorFragmentImpl(name: header.name)
      ..formalParameters = formalParameters.createFragments()
      ..isOriginDeclaration = true
      ..isConst = header.isConst
      ..isFactory = header.isFactory;

    element = ConstructorElementImpl(
      name: header.name,
      reference: classElement.reference.declareConstructor(header.name),
      firstFragment: fragment,
    );
  }

  void resolve(_Scope scope) {
    formalParameters.resolve(scope);
  }
}

class _EnumDeclaration {
  final EnumSpec spec;

  final _ParsedEnumHeader header;

  late final EnumFragmentImpl fragment;
  late final EnumElementImpl element;

  factory _EnumDeclaration.fromSpec(EnumSpec spec) {
    var header = _SpecParser.parseEnumHeader(spec.header);
    return _EnumDeclaration._(spec, header);
  }

  _EnumDeclaration._(this.spec, this.header);

  void createElement({required LibraryReference libraryReference}) {
    fragment = EnumFragmentImpl(name: header.name);

    fragment.fields = [
      for (var name in spec.constants)
        FieldFragmentImpl(name: name)
          ..isEnumConstant = true
          ..isOriginDeclaration = true,
    ];

    element = EnumElementImpl(
      libraryReference.declareEnum(header.name),
      fragment,
    );
  }

  void resolve(_Scope libraryScope) {
    element.mixins = _materializeInterfaceTypes(header.mixins, libraryScope);
    element.interfaces = _materializeInterfaceTypes(
      header.interfaces,
      libraryScope,
    );
  }
}

enum _ExecutableHeaderContext {
  method(
    typeParameterContext: _TypeParameterContext.methodDeclaration,
    allowsOperators: true,
  ),
  topLevelFunction(
    typeParameterContext: _TypeParameterContext.topLevelFunctionDeclaration,
    allowsOperators: false,
  );

  final _TypeParameterContext typeParameterContext;
  final bool allowsOperators;

  const _ExecutableHeaderContext({
    required this.typeParameterContext,
    required this.allowsOperators,
  });
}

class _ExtensionTypeDeclaration {
  final ExtensionTypeSpec spec;

  final _ParsedExtensionTypeHeader header;
  final _TypeParameterDeclarations typeParameters;

  late final ExtensionTypeFragmentImpl fragment;
  late final ExtensionTypeElementImpl element;

  factory _ExtensionTypeDeclaration.fromSpec(ExtensionTypeSpec spec) {
    var header = _SpecParser.parseExtensionTypeHeader(spec.header);
    return _ExtensionTypeDeclaration._(spec, header);
  }

  _ExtensionTypeDeclaration._(this.spec, this.header)
    : typeParameters = _TypeParameterDeclarations(header.typeParameters);

  void createElement({required LibraryReference libraryReference}) {
    var fieldFragment = FieldFragmentImpl(name: header.representationName)
      ..isOriginDeclaringFormalParameter = true;

    fragment = ExtensionTypeFragmentImpl(name: header.name)
      ..typeParameters = typeParameters.createFragments()
      ..fields = [fieldFragment];

    element = ExtensionTypeElementImpl(
      libraryReference.declareExtensionType(header.name),
      fragment,
    );

    var fieldElement = FieldElementImpl(
      reference: element.reference.declareField(header.representationName),
      firstFragment: fieldFragment,
    );

    element.fields = [fieldElement];
  }

  void resolve(_Scope libraryScope) {
    var scope = _Scope.child(libraryScope);
    typeParameters.resolve(scope);

    var representationType = header.representationType.materialize(scope);
    element.typeErasure = representationType;
    element.fields.single.type = representationType;
    element.interfaces = _materializeInterfaceTypes(header.interfaces, scope);
  }
}

class _FormalParameterDeclaration {
  final _ParsedFormalParameter parsed;

  late final FormalParameterFragmentImpl fragment;

  _FormalParameterDeclaration(this.parsed);

  FormalParameterElementImpl get element => fragment.element;

  FormalParameterFragmentImpl createFragment() {
    return fragment = FormalParameterFragmentImpl(
      name: parsed.name,
      nameOffset: 0,
      parameterKind: parsed.kind,
    )..isExplicitlyCovariant = parsed.isCovariant;
  }

  void resolve(_Scope scope) {
    fragment.element.type = parsed.type.materialize(scope);
  }
}

class _FormalParameterDeclarations {
  final List<_FormalParameterDeclaration> _declarations;

  _FormalParameterDeclarations(
    Iterable<_ParsedFormalParameter> formalParameters,
  ) : _declarations = [
        for (var parsed in formalParameters)
          _FormalParameterDeclaration(parsed),
      ];

  List<FormalParameterElementImpl> get elements => [
    for (var declaration in _declarations) declaration.element,
  ];

  List<FormalParameterFragmentImpl> createFragments() {
    return [
      for (var declaration in _declarations) declaration.createFragment(),
    ];
  }

  void resolve(_Scope scope) {
    for (var declaration in _declarations) {
      declaration.resolve(scope);
    }
  }
}

/// Builds a set of libraries from a collection of [LibrarySpec]s.
///
/// The builder uses a two-pass process:
///
/// 1. Create fragments and elements for every declaration. This populates the
///    namespaces needed to resolve cross-library references.
/// 2. Resolve the parsed type representations in scope and write them into the
///    created fragments and elements.
///
/// This allows inter-library dependencies and cycles (e.g., `dart:core` and
/// `dart:async` referencing each other).
class _LibraryBuilder {
  final RootReference rootReference;
  final engine.AnalysisContext analysisContext;
  final AnalysisSessionImpl analysisSession;
  final Map<String, LibraryElementImpl> externalLibraries;

  final Map<String, LibraryElementImpl> _libraryElements = {};

  late final List<_LibraryDeclaration> _libraries;

  _LibraryBuilder(
    this.rootReference,
    this.analysisContext,
    this.analysisSession,
    Map<String, LibrarySpec> specs,
    this.externalLibraries,
  ) {
    _libraries = [
      for (var spec in specs.values) _LibraryDeclaration.fromSpec(spec),
    ];
  }

  Map<String, LibraryElementImpl> build() {
    _createElements();
    _resolveTypes();
    return _libraryElements;
  }

  void _createElements() {
    for (var library in _libraries) {
      library.createElement(this);
      _libraryElements[library.spec.uri] = library.element;
    }
  }

  void _resolveTypes() {
    for (var library in _libraries) {
      library.resolveTypes(this);
    }
  }

  _Scope _scopeFor(LibrarySpec spec) {
    var libraries = <LibraryElementImpl>[];

    for (var importUri in spec.imports) {
      if (externalLibraries[importUri] case var externalLibrary?) {
        libraries.add(externalLibrary);
      }
      if (_libraryElements[importUri] case var builtLibrary?) {
        libraries.add(builtLibrary);
      }
    }

    libraries.add(_libraryElements[spec.uri]!);
    return _Scope.forLibraries(libraries: libraries);
  }
}

class _LibraryDeclaration {
  final LibrarySpec spec;

  final List<_ClassDeclaration> classes;
  final List<_EnumDeclaration> enums;
  final List<_ExtensionTypeDeclaration> extensionTypes;
  final List<_TopLevelFunctionDeclaration> functions;
  final List<_MixinDeclaration> mixins;
  final List<_TypeAliasDeclaration> typeAliases;

  late final LibraryFragmentImpl fragment;
  late final LibraryElementImpl element;
  late final LibraryReference reference;

  _LibraryDeclaration.fromSpec(this.spec)
    : classes = [
        for (var classSpec in spec.classes)
          _ClassDeclaration.fromSpec(classSpec),
      ],
      enums = [
        for (var enumSpec in spec.enums) _EnumDeclaration.fromSpec(enumSpec),
      ],
      extensionTypes = [
        for (var extensionTypeSpec in spec.extensionTypes)
          _ExtensionTypeDeclaration.fromSpec(extensionTypeSpec),
      ],
      functions = [
        for (var functionSpec in spec.functions)
          _TopLevelFunctionDeclaration.fromSpec(functionSpec),
      ],
      mixins = [
        for (var mixinSpec in spec.mixins)
          _MixinDeclaration.fromSpec(mixinSpec),
      ],
      typeAliases = [
        for (var typeAliasSpec in spec.typeAliases)
          _TypeAliasDeclaration.fromSpec(typeAliasSpec),
      ];

  void createElement(_LibraryBuilder builder) {
    var libraryUriStr = spec.uri;
    var librarySource = builder.analysisContext.sourceFactory.forUri(
      libraryUriStr,
    )!;
    reference = builder.rootReference.getOrCreateLibrary(Uri.parse(spec.uri));

    element = LibraryElementImpl(
      builder.analysisContext,
      builder.analysisSession,
      libraryUriStr.replaceAll(':', '.'),
      0,
      0,
      FeatureSet.latestLanguageVersion(),
    );
    element.reference = reference;
    reference.element = element;

    fragment = LibraryFragmentImpl(
      library: element,
      source: librarySource,
      lineInfo: LineInfo([0]),
    );

    element.firstFragment = fragment;

    for (var classDeclaration in classes) {
      classDeclaration.createElement(libraryReference: reference);
      fragment.addClass(classDeclaration.fragment);
      element.addClass(classDeclaration.element);
    }

    for (var mixinDeclaration in mixins) {
      mixinDeclaration.createElement(libraryReference: reference);
      fragment.addMixin(mixinDeclaration.fragment);
      element.addMixin(mixinDeclaration.element);
    }

    for (var enumDeclaration in enums) {
      enumDeclaration.createElement(libraryReference: reference);
      fragment.addEnum(enumDeclaration.fragment);
      element.addEnum(enumDeclaration.element);
    }

    for (var extensionTypeDeclaration in extensionTypes) {
      extensionTypeDeclaration.createElement(libraryReference: reference);
      fragment.addExtensionType(extensionTypeDeclaration.fragment);
      element.addExtensionType(extensionTypeDeclaration.element);
    }

    for (var typeAliasDeclaration in typeAliases) {
      typeAliasDeclaration.createElement(libraryReference: reference);
      fragment.addTypeAlias(typeAliasDeclaration.fragment);
      element.addTypeAlias(typeAliasDeclaration.element);
    }

    for (var functionDeclaration in functions) {
      functionDeclaration.createElement(libraryReference: reference);
      fragment.addFunction(functionDeclaration.fragment);
      element.addTopLevelFunction(functionDeclaration.element);
    }
  }

  void resolveTypes(_LibraryBuilder builder) {
    var libraryScope = builder._scopeFor(spec);

    for (var typeAliasDeclaration in typeAliases) {
      typeAliasDeclaration.resolve(libraryScope);
    }
    for (var extensionTypeDeclaration in extensionTypes) {
      extensionTypeDeclaration.resolve(libraryScope);
    }
    for (var mixinDeclaration in mixins) {
      mixinDeclaration.resolve(libraryScope);
    }
    for (var enumDeclaration in enums) {
      enumDeclaration.resolve(libraryScope);
    }
    for (var classDeclaration in classes) {
      classDeclaration.resolve(libraryScope);
    }
    for (var functionDeclaration in functions) {
      functionDeclaration.resolve(libraryScope);
    }
  }
}

class _MethodDeclaration {
  final MethodSpec spec;

  final _ParsedExecutableHeader header;
  final _FormalParameterDeclarations formalParameters;
  final _TypeParameterDeclarations typeParameters;

  late final MethodFragmentImpl fragment;
  late final MethodElementImpl element;

  factory _MethodDeclaration.fromSpec(MethodSpec spec) {
    var header = _SpecParser.parseMethodHeader(spec.header);
    return _MethodDeclaration._(spec, header);
  }

  _MethodDeclaration._(this.spec, this.header)
    : formalParameters = _FormalParameterDeclarations(header.formalParameters),
      typeParameters = _TypeParameterDeclarations(header.typeParameters);

  void createElement({required ClassElementImpl classElement}) {
    fragment = MethodFragmentImpl(name: header.name)
      ..typeParameters = typeParameters.createFragments()
      ..formalParameters = formalParameters.createFragments();

    element = MethodElementImpl(
      name: header.name,
      reference: classElement.reference.declareMethod(header.name),
      firstFragment: fragment,
    );
  }

  void resolve(_Scope classScope) {
    var methodScope = _Scope.child(classScope);
    typeParameters.resolve(methodScope);
    formalParameters.resolve(methodScope);
    element.returnType = header.returnType.materialize(methodScope);
  }
}

class _MixinDeclaration {
  final MixinSpec spec;

  final _ParsedMixinHeader header;
  final _TypeParameterDeclarations typeParameters;

  late final MixinFragmentImpl fragment;
  late final MixinElementImpl element;

  factory _MixinDeclaration.fromSpec(MixinSpec spec) {
    var header = _SpecParser.parseMixinHeader(spec.header);
    return _MixinDeclaration._(spec, header);
  }

  _MixinDeclaration._(this.spec, this.header)
    : typeParameters = _TypeParameterDeclarations(header.typeParameters);

  void createElement({required LibraryReference libraryReference}) {
    fragment = MixinFragmentImpl(name: header.name)
      ..typeParameters = typeParameters.createFragments();

    element = MixinElementImpl(
      libraryReference.declareMixin(header.name),
      fragment,
    );
  }

  void resolve(_Scope libraryScope) {
    var scope = _Scope.child(libraryScope);
    typeParameters.resolve(scope);

    element.superclassConstraints = _materializeInterfaceTypes(
      header.constraints,
      scope,
    );
    element.interfaces = _materializeInterfaceTypes(header.interfaces, scope);
  }
}

class _ParsedClassHeader {
  final String name;
  final bool isAbstract;
  final bool isSealed;

  final List<_ParsedTypeParameter> typeParameters;
  final _ParsedType supertype;
  final List<_ParsedType> mixins;
  final List<_ParsedType> interfaces;

  _ParsedClassHeader({
    required this.name,
    required this.isAbstract,
    required this.isSealed,
    required this.typeParameters,
    required this.supertype,
    required this.mixins,
    required this.interfaces,
  });
}

class _ParsedConstructorHeader {
  final String name;
  final bool isConst;
  final bool isFactory;
  final List<_ParsedFormalParameter> formalParameters;

  _ParsedConstructorHeader({
    required this.name,
    required this.isConst,
    required this.isFactory,
    required this.formalParameters,
  });
}

class _ParsedEnumHeader {
  final String name;
  final List<_ParsedType> mixins;
  final List<_ParsedType> interfaces;

  _ParsedEnumHeader({
    required this.name,
    required this.mixins,
    required this.interfaces,
  });
}

class _ParsedExecutableHeader {
  final String name;
  final List<_ParsedTypeParameter> typeParameters;
  final List<_ParsedFormalParameter> formalParameters;
  final _ParsedType returnType;

  _ParsedExecutableHeader({
    required this.name,
    required this.typeParameters,
    required this.formalParameters,
    required this.returnType,
  });
}

class _ParsedExplicitType implements _ParsedType {
  final TypeImpl type;

  _ParsedExplicitType({required this.type});

  @override
  TypeImpl materialize(_Scope scope) => type;
}

class _ParsedExtensionTypeHeader {
  final String name;
  final List<_ParsedTypeParameter> typeParameters;
  final _ParsedType representationType;
  final String representationName;
  final List<_ParsedType> interfaces;

  _ParsedExtensionTypeHeader({
    required this.name,
    required this.typeParameters,
    required this.representationType,
    required this.representationName,
    required this.interfaces,
  });
}

class _ParsedFormalParameter {
  final bool isCovariant;
  final ParameterKind kind;
  final String? name;
  final _ParsedType type;

  _ParsedFormalParameter({
    required this.isCovariant,
    required this.kind,
    required this.name,
    required this.type,
  });
}

class _ParsedFunctionType implements _ParsedType {
  final List<_ParsedFormalParameter> formalParameters;
  final _ParsedType returnType;
  final List<_ParsedTypeParameter> typeParameters;

  _ParsedFunctionType({
    required this.typeParameters,
    required this.formalParameters,
    required this.returnType,
  });

  @override
  TypeImpl materialize(_Scope scope) {
    var functionScope = _Scope.child(scope);

    var typeParameters = _TypeParameterDeclarations(this.typeParameters);
    typeParameters.materializeStandalone(functionScope);

    var formalParameters = _FormalParameterDeclarations(this.formalParameters);
    formalParameters.createFragments();
    formalParameters.resolve(functionScope);

    return FunctionTypeImpl.v2(
      returnType: returnType.materialize(functionScope),
      typeParameters: typeParameters.elements,
      formalParameters: formalParameters.elements,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}

class _ParsedMixinHeader {
  final String name;
  final List<_ParsedTypeParameter> typeParameters;
  final List<_ParsedType> constraints;
  final List<_ParsedType> interfaces;

  _ParsedMixinHeader({
    required this.name,
    required this.typeParameters,
    required this.constraints,
    required this.interfaces,
  });
}

class _ParsedNamedType implements _ParsedType {
  final List<_ParsedType> args;
  final String name;

  _ParsedNamedType({required this.name, required this.args});

  @override
  TypeImpl materialize(_Scope scope) {
    if (scope.lookupTypeParameter(name) case var element?) {
      assert(args.isEmpty);
      return TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    if (scope.lookupTypeAlias(name) case var element?) {
      return element.instantiateImpl(
        typeArguments: args.map((arg) => arg.materialize(scope)).toList(),
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

class _ParsedNullableType implements _ParsedType {
  final _ParsedType inner;

  _ParsedNullableType({required this.inner});

  @override
  TypeImpl materialize(_Scope scope) {
    return inner.materialize(scope).withNullability(NullabilitySuffix.question);
  }
}

class _ParsedPromotedType implements _ParsedType {
  final _ParsedType base;
  final _ParsedType promotedBound;

  _ParsedPromotedType({required this.base, required this.promotedBound});

  @override
  TypeImpl materialize(_Scope scope) {
    var baseType = base.materialize(scope);
    if (baseType is! TypeParameterTypeImpl) {
      throw StateError('Cannot promote a non-type-parameter type: $baseType');
    }
    return TypeParameterTypeImpl(
      element: baseType.element,
      nullabilitySuffix: baseType.nullabilitySuffix,
      promotedBound: promotedBound.materialize(scope),
    );
  }
}

class _ParsedRecordType implements _ParsedType {
  final List<({String name, _ParsedType type})> namedFields;
  final List<_ParsedType> positionalFields;

  _ParsedRecordType({
    required this.positionalFields,
    required this.namedFields,
  });

  @override
  TypeImpl materialize(_Scope scope) {
    return RecordTypeImpl(
      positionalFields: [
        for (var type in positionalFields)
          RecordTypePositionalFieldImpl(type: type.materialize(scope)),
      ],
      namedFields: [
        for (var field in namedFields)
          RecordTypeNamedFieldImpl(
            name: field.name,
            type: field.type.materialize(scope),
          ),
      ],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}

/// Representation of a [TypeImpl] that has been parsed but hasn't had meaning
/// assigned to its identifiers yet.
abstract class _ParsedType {
  /// Translates `this` into a [TypeImpl].
  ///
  /// The meaning of identifiers in `this` is determined by looking them up
  /// in the provided [scope].
  TypeImpl materialize(_Scope scope);
}

class _ParsedTypeAliasHeader {
  final String name;
  final List<_ParsedTypeParameter> typeParameters;
  final _ParsedType aliasedType;

  _ParsedTypeAliasHeader({
    required this.name,
    required this.typeParameters,
    required this.aliasedType,
  });
}

class _ParsedTypeParameter {
  final _ParsedType? bound;
  final String name;
  final Variance? variance;

  _ParsedTypeParameter({
    required this.name,
    required this.bound,
    required this.variance,
  }) : assert(name.isNotEmpty);
}

/// A unified scope for looking up named elements.
///
/// It can look up type parameters from the current (and parent) scopes,
/// as well as named types (like classes and mixins) from the global scope.
class _Scope {
  final _Scope? parent;
  final Map<String, TypeParameterElementImpl> _typeParameters = {};
  final Map<String, InterfaceElementImpl> _interfaces;
  final Map<String, TypeAliasElementImpl> _typeAliases;

  /// Creates a nested scope that inherits its parent's context.
  ///
  /// This is used to add type parameters of a class, method, etc.
  _Scope.child(_Scope this.parent)
    : _interfaces = parent._interfaces,
      _typeAliases = parent._typeAliases;

  factory _Scope.forLibraries({
    required List<LibraryElementImpl> libraries,
    List<TypeParameterElementImpl> typeParameters = const [],
  }) {
    var interfaces = <String, InterfaceElementImpl>{};
    var typeAliases = <String, TypeAliasElementImpl>{};

    for (var library in libraries) {
      for (var element in library.classes) {
        if (element.name case var name?) {
          interfaces[name] = element;
        }
      }
      for (var element in library.enums) {
        if (element.name case var name?) {
          interfaces[name] = element;
        }
      }
      for (var element in library.extensionTypes) {
        if (element.name case var name?) {
          interfaces[name] = element;
        }
      }
      for (var element in library.mixins) {
        if (element.name case var name?) {
          interfaces[name] = element;
        }
      }
      for (var element in library.typeAliases) {
        if (element.name case var name?) {
          typeAliases[name] = element;
        }
      }
    }

    var scope = _Scope.root(interfaces: interfaces, typeAliases: typeAliases);
    for (var typeParameter in typeParameters) {
      scope.addTypeParameter(typeParameter);
    }
    return scope;
  }

  /// Creates a root scope containing all known interfaces.
  _Scope.root({
    required Map<String, InterfaceElementImpl> interfaces,
    required Map<String, TypeAliasElementImpl> typeAliases,
  }) : parent = null,
       _interfaces = interfaces,
       _typeAliases = typeAliases;

  /// Adds a type parameter to the current scope.
  void addTypeParameter(TypeParameterElementImpl element) {
    _typeParameters[element.name!] = element;
  }

  /// Looks up an interface by name.
  InterfaceElementImpl? lookupInterface(String name) {
    return _interfaces[name];
  }

  TypeAliasElementImpl? lookupTypeAlias(String name) {
    return _typeAliases[name];
  }

  /// Looks up a type parameter by name, walking up the scope chain.
  TypeParameterElementImpl? lookupTypeParameter(String name) {
    return _typeParameters[name] ?? parent?.lookupTypeParameter(name);
  }
}

class _SpecParser {
  final _TokenStream _stream;

  _SpecParser._(String input) : _stream = _TokenStream.fromString(input);

  void _expectEnd(String message) {
    if (!_stream.isAtEnd) {
      throw StateError(message);
    }
  }

  _ParsedClassHeader _parseClassHeader() {
    var isAbstract = false;
    var isSealed = false;
    while (!_stream.isAtEnd && !_stream.peekIs('class')) {
      switch (_stream.consume()) {
        case 'abstract':
          isAbstract = true;
        case 'sealed':
          isSealed = true;
        case var modifier:
          throw StateError('Unsupported class modifier: $modifier');
      }
    }

    _stream.expect('class');
    var name = _stream.consume();

    var typeParameters = _parseOptionalTypeParameters(
      context: _TypeParameterContext.classDeclaration,
    );

    _ParsedType supertype;
    if (_stream.match('extends')) {
      supertype = _parseType();
    } else {
      supertype = _ParsedNamedType(name: 'Object', args: <_ParsedType>[]);
    }

    var mixins = <_ParsedType>[];
    if (_stream.match('with')) {
      mixins = _parseTypes(stopTokens: const {'implements'});
    }

    var interfaces = <_ParsedType>[];
    if (_stream.match('implements')) {
      interfaces = _parseTypes();
    }

    _expectEnd('Unexpected trailing tokens in class header.');
    return _ParsedClassHeader(
      name: name,
      isAbstract: isAbstract,
      isSealed: isSealed,
      typeParameters: typeParameters,
      supertype: supertype,
      mixins: mixins,
      interfaces: interfaces,
    );
  }

  _ParsedConstructorHeader _parseConstructorHeader() {
    var isConst = _stream.match('const');
    var isFactory = _stream.match('factory');
    var name = _stream.consume();

    _stream.expect('(');
    var formalParameters = _parseFormalParameters();
    _stream.expect(')');

    _expectEnd('Unexpected trailing tokens in constructor header.');
    return _ParsedConstructorHeader(
      name: name,
      isConst: isConst,
      isFactory: isFactory,
      formalParameters: formalParameters,
    );
  }

  _ParsedEnumHeader _parseEnumHeader() {
    _stream.expect('enum');
    var name = _stream.consume();

    var mixins = <_ParsedType>[];
    if (_stream.match('with')) {
      mixins = _parseTypes(stopTokens: const {'implements'});
    }

    var interfaces = <_ParsedType>[];
    if (_stream.match('implements')) {
      interfaces = _parseTypes();
    }

    _stream.match(';');
    _expectEnd('Unexpected trailing tokens in enum header.');
    return _ParsedEnumHeader(
      name: name,
      mixins: mixins,
      interfaces: interfaces,
    );
  }

  _ParsedExecutableHeader _parseExecutableHeader(
    _ExecutableHeaderContext context,
  ) {
    var returnType = _parseType();
    var name = _parseExecutableName(context);
    var typeParameters = _parseOptionalTypeParameters(
      context: context.typeParameterContext,
    );

    _stream.expect('(');
    var formalParameters = _parseFormalParameters();
    _stream.expect(')');
    _stream.match(';');

    _expectEnd('Unexpected trailing tokens in ${context.name} header.');
    return _ParsedExecutableHeader(
      name: name,
      typeParameters: typeParameters,
      formalParameters: formalParameters,
      returnType: returnType,
    );
  }

  String _parseExecutableName(_ExecutableHeaderContext context) {
    if (context.allowsOperators && _stream.match('operator')) {
      return _parseOperatorName();
    }
    return _stream.consume();
  }

  _ParsedExtensionTypeHeader _parseExtensionTypeHeader() {
    _stream.expect('extension');
    _stream.expect('type');
    var name = _stream.consume();

    var typeParameters = _parseOptionalTypeParameters(
      context: _TypeParameterContext.extensionTypeDeclaration,
    );

    _stream.expect('(');
    var representationType = _parseType();
    var representationName = _stream.consume();
    _stream.expect(')');

    var interfaces = <_ParsedType>[];
    if (_stream.match('implements')) {
      interfaces = _parseTypes();
    }

    _expectEnd('Unexpected trailing tokens in extension type header.');
    return _ParsedExtensionTypeHeader(
      name: name,
      typeParameters: typeParameters,
      representationType: representationType,
      representationName: representationName,
      interfaces: interfaces,
    );
  }

  _ParsedFormalParameter _parseFormalParameter(ParameterKind kind) {
    if (kind == ParameterKind.NAMED && _stream.match('required')) {
      kind = ParameterKind.NAMED_REQUIRED;
    }

    var isCovariant = _stream.match('covariant');
    var type = _parseType();

    String? name;
    if (!_stream.isAtEnd && !_stream.peekIsAnyOf(const {',', ')', ']', '}'})) {
      name = _stream.consume();
    }

    return _ParsedFormalParameter(
      isCovariant: isCovariant,
      type: type,
      name: name,
      kind: kind,
    );
  }

  List<_ParsedFormalParameter> _parseFormalParameters() {
    var formalParameters = <_ParsedFormalParameter>[];
    if (_stream.isAtEnd || _stream.peekIs(')')) {
      return formalParameters;
    }

    while (!_stream.isAtEnd && !_stream.peekIsAnyOf(const {')', '[', '{'})) {
      formalParameters.add(_parseFormalParameter(ParameterKind.REQUIRED));
      _stream.match(',');
    }

    if (_stream.match('[')) {
      while (!_stream.isAtEnd && !_stream.peekIs(']')) {
        formalParameters.add(_parseFormalParameter(ParameterKind.POSITIONAL));
        _stream.match(',');
      }
      _stream.expect(']');
    }

    if (_stream.match('{')) {
      while (!_stream.isAtEnd && !_stream.peekIs('}')) {
        formalParameters.add(_parseFormalParameter(ParameterKind.NAMED));
        _stream.match(',');
      }
      _stream.expect('}');
    }

    return formalParameters;
  }

  _ParsedMixinHeader _parseMixinHeader() {
    _stream.expect('mixin');
    var name = _stream.consume();

    var typeParameters = _parseOptionalTypeParameters(
      context: _TypeParameterContext.mixinDeclaration,
    );

    var constraints = <_ParsedType>[
      _ParsedNamedType(name: 'Object', args: <_ParsedType>[]),
    ];
    if (_stream.match('on')) {
      constraints = _parseTypes(stopTokens: const {'implements'});
    }

    var interfaces = <_ParsedType>[];
    if (_stream.match('implements')) {
      interfaces = _parseTypes();
    }

    _expectEnd('Unexpected trailing tokens in mixin header.');
    return _ParsedMixinHeader(
      name: name,
      typeParameters: typeParameters,
      constraints: constraints,
      interfaces: interfaces,
    );
  }

  String _parseOperatorName() {
    if (_stream.match('[')) {
      _stream.expect(']');
      if (_stream.match('=')) {
        return '[]=';
      }
      return '[]';
    }

    if (_stream.peekIsAnyOf(const {
      '+',
      '-',
      '*',
      '/',
      '%',
      '~',
      '&',
      '|',
      '^',
    })) {
      return _stream.consume();
    }

    if (_stream.match('=')) {
      _stream.expect('=');
      return '==';
    }

    if (_stream.match('<')) {
      if (_stream.match('=')) {
        return '<=';
      }
      if (_stream.match('<')) {
        return '<<';
      }
      return '<';
    }

    if (_stream.match('>')) {
      if (_stream.match('=')) {
        return '>=';
      }
      if (_stream.match('>')) {
        if (_stream.match('>')) {
          return '>>>';
        }
        return '>>';
      }
      return '>';
    }

    throw StateError('Unsupported operator token in executable header.');
  }

  List<_ParsedTypeParameter> _parseOptionalTypeParameters({
    required _TypeParameterContext context,
  }) {
    if (_stream.isAtEnd || !_stream.match('<')) {
      return const [];
    }

    return _parseTypeParametersRest(context: context);
  }

  _ParsedType _parseParenthesizedOrRecordType() {
    _stream.expect('(');

    var positionalFields = <_ParsedType>[];
    var namedFields = <({String name, _ParsedType type})>[];
    var hasComma = false;

    while (!_stream.isAtEnd && !_stream.peekIsAnyOf(const {')', '{'})) {
      positionalFields.add(_parseType());
      hasComma = _stream.match(',');
      if (!hasComma) {
        break;
      }
    }

    if (_stream.match('{')) {
      while (!_stream.isAtEnd && !_stream.peekIs('}')) {
        var type = _parseType();
        var name = _stream.consume();
        namedFields.add((name: name, type: type));
        _stream.match(',');
      }
      _stream.expect('}');
    }

    _stream.expect(')');

    // If there is exactly one positional field, no trailing comma, and no
    // named fields, it is a parenthesized type, not a record type.
    // Example: `(int)` is parenthesized, but `(int,)` is a record.
    if (positionalFields.length == 1 && !hasComma && namedFields.isEmpty) {
      return positionalFields[0];
    }

    return _ParsedRecordType(
      positionalFields: positionalFields,
      namedFields: namedFields,
    );
  }

  _ParsedType _parsePrimaryType() {
    if (_stream.peekIs('(')) {
      return _parseParenthesizedOrRecordType();
    }

    var name = _stream.consume();
    switch (name) {
      case 'dynamic':
        return _ParsedExplicitType(type: DynamicTypeImpl.instance);
      case 'InvalidType':
        return _ParsedExplicitType(type: InvalidTypeImpl.instance);
      case 'Never':
        return _ParsedExplicitType(type: NeverTypeImpl.instance);
      case 'UnknownInferredType':
        return _ParsedExplicitType(type: UnknownInferredType.instance);
      case 'void':
        return _ParsedExplicitType(type: VoidTypeImpl.instance);
    }

    var args = <_ParsedType>[];
    if (_stream.match('<')) {
      while (!_stream.isAtEnd && !_stream.peekIs('>')) {
        args.add(_parseType());
        _stream.match(',');
      }
      _stream.expect('>');
    }
    return _ParsedNamedType(name: name, args: args);
  }

  _ParsedType _parseType() {
    var type = _parsePrimaryType();

    while (true) {
      if (_stream.match('?')) {
        type = _ParsedNullableType(inner: type);
        continue;
      }

      if (_stream.match('Function')) {
        var typeParameters = _parseOptionalTypeParameters(
          context: _TypeParameterContext.genericFunctionType,
        );

        _stream.expect('(');
        var formalParameters = _parseFormalParameters();
        _stream.expect(')');
        type = _ParsedFunctionType(
          returnType: type,
          formalParameters: formalParameters,
          typeParameters: typeParameters,
        );
        continue;
      }

      if (_stream.match('&')) {
        type = _ParsedPromotedType(base: type, promotedBound: _parseType());
        continue;
      }

      return type;
    }
  }

  _ParsedTypeAliasHeader _parseTypeAliasHeader() {
    _stream.expect('typedef');
    var name = _stream.consume();

    var typeParameters = _parseOptionalTypeParameters(
      context: _TypeParameterContext.typeAliasDeclaration,
    );

    _stream.expect('=');
    var aliasedType = _parseType();
    _stream.match(';');

    _expectEnd('Unexpected trailing tokens in type alias header.');
    return _ParsedTypeAliasHeader(
      name: name,
      typeParameters: typeParameters,
      aliasedType: aliasedType,
    );
  }

  List<_ParsedTypeParameter> _parseTypeParametersRest({
    required _TypeParameterContext context,
  }) {
    if (_stream.peekIs('>')) {
      throw StateError('Type parameter clause cannot be empty.');
    }

    var typeParameters = <_ParsedTypeParameter>[];

    while (!_stream.isAtEnd && !_stream.peekIs('>')) {
      Variance? variance;
      if (_varianceForKeyword(_stream.peek()) case var keywordVariance?) {
        _stream.consume();
        if (!context.allowsVariance) {
          throw StateError(
            'Variance modifiers are not allowed in ${context.name}.',
          );
        }
        variance = keywordVariance;
      }

      var name = _stream.consume();
      _ParsedType? bound;
      if (_stream.match('extends')) {
        bound = _parseType();
      }
      typeParameters.add(
        _ParsedTypeParameter(name: name, bound: bound, variance: variance),
      );

      _stream.match(',');
    }

    _stream.expect('>');
    return typeParameters;
  }

  List<_ParsedType> _parseTypes({Set<String> stopTokens = const {}}) {
    if (_stream.isAtEnd || _stream.peekIsAnyOf(stopTokens)) {
      throw StateError('Expected a type.');
    }

    var types = <_ParsedType>[];
    while (!_stream.isAtEnd && !_stream.peekIsAnyOf(stopTokens)) {
      types.add(_parseType());
      if (!_stream.match(',')) {
        break;
      }
      if (_stream.isAtEnd || _stream.peekIsAnyOf(stopTokens)) {
        throw StateError('Expected a type after ",".');
      }
    }
    return types;
  }

  static _ParsedClassHeader parseClassHeader(String input) {
    return _SpecParser._(input)._parseClassHeader();
  }

  static _ParsedConstructorHeader parseConstructorHeader(String input) {
    return _SpecParser._(input)._parseConstructorHeader();
  }

  static _ParsedEnumHeader parseEnumHeader(String input) {
    return _SpecParser._(input)._parseEnumHeader();
  }

  static _ParsedExtensionTypeHeader parseExtensionTypeHeader(String input) {
    return _SpecParser._(input)._parseExtensionTypeHeader();
  }

  static _ParsedExecutableHeader parseMethodHeader(String input) {
    return _SpecParser._(
      input,
    )._parseExecutableHeader(_ExecutableHeaderContext.method);
  }

  static _ParsedMixinHeader parseMixinHeader(String input) {
    return _SpecParser._(input)._parseMixinHeader();
  }

  static _ParsedExecutableHeader parseTopLevelFunctionHeader(String input) {
    return _SpecParser._(
      input,
    )._parseExecutableHeader(_ExecutableHeaderContext.topLevelFunction);
  }

  static _ParsedType parseType(String input) {
    var parser = _SpecParser._(input);
    var type = parser._parseType();
    parser._expectEnd('Unexpected trailing tokens in type.');
    return type;
  }

  static _ParsedTypeAliasHeader parseTypeAliasHeader(String input) {
    return _SpecParser._(input)._parseTypeAliasHeader();
  }

  static List<_ParsedTypeParameter> parseTypeParameters(String input) {
    input = input.trim();
    if (!input.startsWith('<')) {
      input = '<$input>';
    }

    var parser = _SpecParser._(input);
    parser._stream.expect('<');
    var typeParameters = parser._parseTypeParametersRest(
      context: _TypeParameterContext.classDeclaration,
    );
    parser._expectEnd('Unexpected trailing tokens in type parameters.');
    return typeParameters;
  }

  static Variance? _varianceForKeyword(String keyword) {
    switch (keyword) {
      case 'out':
        return Variance.covariant;
      case 'in':
        return Variance.contravariant;
      case 'inout':
        return Variance.invariant;
    }
    return null;
  }
}

class _TokenStream {
  static final RegExp _tokenizer = RegExp(
    r'[$a-zA-Z_][$\w]*|<|>|\+|-|\*|/|%|~|&|\||\^|,|\?|\(|\)|\{|\}|\[|\]|=|;',
  );

  final List<String> _tokens;
  int _index = 0;

  factory _TokenStream.fromString(String input) {
    var tokens = _tokenizer.allMatches(input).map((m) => m[0]!).toList();
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

class _TopLevelFunctionDeclaration {
  final TopLevelFunctionSpec spec;

  final _ParsedExecutableHeader header;
  final _FormalParameterDeclarations formalParameters;
  final _TypeParameterDeclarations typeParameters;

  late final TopLevelFunctionFragmentImpl fragment;
  late final TopLevelFunctionElementImpl element;

  factory _TopLevelFunctionDeclaration.fromSpec(TopLevelFunctionSpec spec) {
    var header = _SpecParser.parseTopLevelFunctionHeader(spec.header);
    return _TopLevelFunctionDeclaration._(spec, header);
  }

  _TopLevelFunctionDeclaration._(this.spec, this.header)
    : formalParameters = _FormalParameterDeclarations(header.formalParameters),
      typeParameters = _TypeParameterDeclarations(header.typeParameters);

  void createElement({required LibraryReference libraryReference}) {
    fragment = TopLevelFunctionFragmentImpl(name: header.name)
      ..typeParameters = typeParameters.createFragments()
      ..formalParameters = formalParameters.createFragments();

    element = TopLevelFunctionElementImpl(
      libraryReference.declareTopLevelFunction(header.name),
      fragment,
    );
  }

  void resolve(_Scope libraryScope) {
    var functionScope = _Scope.child(libraryScope);
    typeParameters.resolve(functionScope);
    formalParameters.resolve(functionScope);
    element.returnType = header.returnType.materialize(functionScope);
  }
}

class _TypeAliasDeclaration {
  final TypeAliasSpec spec;

  final _ParsedTypeAliasHeader header;
  final _TypeParameterDeclarations typeParameters;

  late final TypeAliasFragmentImpl fragment;
  late final TypeAliasElementImpl element;

  factory _TypeAliasDeclaration.fromSpec(TypeAliasSpec spec) {
    var header = _SpecParser.parseTypeAliasHeader(spec.header);
    return _TypeAliasDeclaration._(spec, header);
  }

  _TypeAliasDeclaration._(this.spec, this.header)
    : typeParameters = _TypeParameterDeclarations(header.typeParameters);

  void createElement({required LibraryReference libraryReference}) {
    fragment = TypeAliasFragmentImpl(name: header.name, firstTokenOffset: null)
      ..typeParameters = typeParameters.createFragments();

    element = TypeAliasElementImpl(
      libraryReference.declareTypeAlias(header.name),
      fragment,
    );
  }

  void resolve(_Scope libraryScope) {
    var scope = _Scope.child(libraryScope);
    typeParameters.resolve(scope);
    element.aliasedType = header.aliasedType.materialize(scope);
  }
}

enum _TypeParameterContext {
  classDeclaration(allowsVariance: true),
  extensionTypeDeclaration(allowsVariance: true),
  genericFunctionType(allowsVariance: true),
  methodDeclaration(allowsVariance: false),
  mixinDeclaration(allowsVariance: true),
  topLevelFunctionDeclaration(allowsVariance: false),
  typeAliasDeclaration(allowsVariance: true);

  final bool allowsVariance;

  const _TypeParameterContext({required this.allowsVariance});
}

class _TypeParameterDeclaration {
  final _ParsedTypeParameter parsed;
  late final TypeParameterFragmentImpl fragment;

  _TypeParameterDeclaration(this.parsed);

  TypeParameterElementImpl get element => fragment.element;

  void createElement() {
    TypeParameterElementImpl(firstFragment: fragment);
  }

  TypeParameterFragmentImpl createFragment() {
    return fragment = TypeParameterFragmentImpl(name: parsed.name);
  }

  void resolve(_Scope scope) {
    if (parsed.bound case var bound?) {
      element.bound = bound.materialize(scope);
    }
    if (parsed.variance case var variance?) {
      element.variance = variance;
    }
  }
}

class _TypeParameterDeclarations {
  final List<_TypeParameterDeclaration> _declarations;

  _TypeParameterDeclarations(Iterable<_ParsedTypeParameter> parameters)
    : _declarations = [
        for (var parameter in parameters) _TypeParameterDeclaration(parameter),
      ];

  List<TypeParameterElementImpl> get elements => [
    for (var declaration in _declarations) declaration.element,
  ];

  void createElements() {
    for (var declaration in _declarations) {
      declaration.createElement();
    }
  }

  List<TypeParameterFragmentImpl> createFragments() {
    return [
      for (var declaration in _declarations) declaration.createFragment(),
    ];
  }

  List<TypeParameterElementImpl> materializeStandalone(_Scope scope) {
    createFragments();
    createElements();
    resolve(scope);
    return elements;
  }

  void resolve(_Scope scope) {
    for (var declaration in _declarations) {
      scope.addTypeParameter(declaration.element);
    }

    for (var declaration in _declarations) {
      declaration.resolve(scope);
    }
  }
}
