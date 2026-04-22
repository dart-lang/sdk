// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';

import 'elements_types_mixin.dart';
import 'test_analysis_context.dart';

abstract class AbstractTypeSystemTest with ElementsTypesMixin {
  static const _testLibraryUri = 'package:test/test.dart';

  late TestAnalysisContext analysisContext;

  @override
  late LibraryElementImpl testLibrary;

  @override
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

  void setUp() {
    analysisContext = TestAnalysisContext();
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
}
