// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';

import 'test_analysis_context.dart';

abstract class AbstractTypeSystemTest {
  static const _testLibraryUri = 'package:test/test.dart';

  bool _hasTestLibrary = false;

  late TestAnalysisContext analysisContext;

  late LibraryElementImpl testLibrary;

  late TypeProviderImpl typeProvider;

  late TypeSystemImpl typeSystem;

  late TypeSystemOperations typeSystemOperations;

  Map<String, LibraryElementImpl> buildLibraries(
    Map<String, LibrarySpec> specs, {
    Map<String, LibraryElementImpl>? externalLibraries,
  }) {
    var libraries = buildLibrariesFromSpec(
      analysisContext: analysisContext,
      rootReference: analysisContext.rootReference,
      analysisSession: analysisContext.analysisSession,
      specs: specs,
      externalLibraries:
          externalLibraries ??
          {
            'dart:core': analysisContext.coreLibrary,
            'dart:async': analysisContext.asyncLibrary,
          },
    );

    for (var library in libraries.values) {
      library.typeProvider = typeProvider;
      library.typeSystem = typeSystem;
    }

    return libraries;
  }

  LibraryElementImpl buildTestLibrary({
    List<String> imports = const ['dart:core'],
    List<ClassSpec> classes = const [],
    List<EnumSpec> enums = const [],
    List<ExtensionTypeSpec> extensionTypes = const [],
    List<TopLevelFunctionSpec> functions = const [],
    List<MixinSpec> mixins = const [],
    List<TypeAliasSpec> typeAliases = const [],
    Map<String, LibraryElementImpl>? externalLibraries,
  }) {
    testLibrary = buildLibraries({
      _testLibraryUri: LibrarySpec(
        uri: _testLibraryUri,
        imports: imports,
        classes: classes,
        enums: enums,
        extensionTypes: extensionTypes,
        functions: functions,
        mixins: mixins,
        typeAliases: typeAliases,
      ),
    }, externalLibraries: externalLibraries)[_testLibraryUri]!;
    _hasTestLibrary = true;
    return testLibrary;
  }

  ClassElementImpl classElement(String name) {
    return testLibrary.getClass(name)!;
  }

  EnumElementImpl enumElement(String name) {
    return testLibrary.getEnum(name)!;
  }

  ExtensionTypeElementImpl extensionTypeElement(String name) {
    return testLibrary.getExtensionType(name)!;
  }

  MixinElementImpl mixinElement(String name) {
    return testLibrary.getMixin(name)!;
  }

  FunctionTypeImpl parseFunctionType(
    String input, {
    List<LibraryElementImpl>? libraries,
  }) {
    return _typeParsingScope(libraries: libraries).parseFunctionType(input);
  }

  InterfaceTypeImpl parseInterfaceType(
    String input, {
    List<LibraryElementImpl>? libraries,
  }) {
    return _typeParsingScope(libraries: libraries).parseInterfaceType(input);
  }

  RecordTypeImpl parseRecordType(
    String input, {
    List<LibraryElementImpl>? libraries,
  }) {
    return _typeParsingScope(libraries: libraries).parseRecordType(input);
  }

  TypeImpl parseType(String input, {List<LibraryElementImpl>? libraries}) {
    return _typeParsingScope(libraries: libraries).parseType(input);
  }

  TypeParameterTypeImpl parseTypeParameterType(
    String input, {
    List<LibraryElementImpl>? libraries,
  }) {
    return _typeParsingScope(
      libraries: libraries,
    ).parseTypeParameterType(input);
  }

  void setUp() {
    analysisContext = TestAnalysisContext();
    _hasTestLibrary = false;
    typeProvider = analysisContext.typeProvider;
    typeSystem = analysisContext.typeSystem;
    typeSystemOperations = TypeSystemOperations(
      typeSystem,
      strictCasts: analysisContext.analysisOptions.strictCasts,
    );
  }

  TypeAliasElementImpl typeAliasElement(String name) {
    return testLibrary.getTypeAlias(name)! as TypeAliasElementImpl;
  }

  R withTypeParameterScope<R>(
    String spec,
    R Function(TypeParsingScope scope) operation, {
    List<LibraryElementImpl>? libraries,
    List<TypeParameterElementImpl> typeParameters = const [],
  }) {
    return _typeParsingScope(
      libraries: libraries,
      typeParameters: typeParameters,
    ).withTypeParameterScope(spec, operation);
  }

  TypeParsingScope _typeParsingScope({
    List<LibraryElementImpl>? libraries,
    List<TypeParameterElementImpl> typeParameters = const [],
  }) {
    return TypeParsingScope(
      libraries:
          libraries ??
          [
            analysisContext.coreLibrary,
            analysisContext.asyncLibrary,
            if (_hasTestLibrary) testLibrary,
          ],
      typeParameters: typeParameters,
    );
  }
}

/// Parses test type specs against a fixed library and type-parameter scope.
class TypeParsingScope {
  final List<LibraryElementImpl> _libraries;
  final List<TypeParameterElementImpl> _typeParameters;

  TypeParsingScope({
    required List<LibraryElementImpl> libraries,
    required List<TypeParameterElementImpl> typeParameters,
  }) : _libraries = List.unmodifiable(libraries),
       _typeParameters = List.unmodifiable(typeParameters);

  FunctionTypeImpl parseFunctionType(String input) {
    return parseType(input);
  }

  InterfaceTypeImpl parseInterfaceType(String input) {
    return parseType(input);
  }

  RecordTypeImpl parseRecordType(String input) {
    return parseType(input);
  }

  T parseType<T extends TypeImpl>(String input) {
    var type = TypeSpecParser(
      libraries: _libraries,
      typeParameters: _typeParameters,
    ).parse(input);

    if (type is T) {
      return type;
    }
    throw StateError('Expected $T for "$input", got: $type');
  }

  TypeParameterTypeImpl parseTypeParameterType(String input) {
    return parseType(input);
  }

  TypeParameterElementImpl typeParameter(String name) {
    for (var i = _typeParameters.length - 1; i >= 0; i--) {
      var element = _typeParameters[i];
      if (element.name == name) {
        return element;
      }
    }
    throw StateError('Unknown type parameter: $name');
  }

  R withTypeParameterScope<R>(
    String spec,
    R Function(TypeParsingScope scope) operation,
  ) {
    var newTypeParameters = TypeSpecParser(
      libraries: _libraries,
      typeParameters: _typeParameters,
    ).parseTypeParameters(spec);

    return operation(
      TypeParsingScope(
        libraries: _libraries,
        typeParameters: [..._typeParameters, ...newTypeParameters],
      ),
    );
  }
}
