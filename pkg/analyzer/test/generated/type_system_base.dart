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
  late TestAnalysisContext analysisContext;

  @override
  late LibraryElementImpl testLibrary;

  @override
  late TypeProviderImpl typeProvider;

  late TypeSystemImpl typeSystem;

  late TypeSystemOperations typeSystemOperations;

  ExtensionTypeElementImpl buildExtensionType(
    ExtensionTypeSpec spec, {
    List<String> imports = const ['dart:core', 'dart:async'],
    Map<String, LibraryElementImpl>? externalLibraries,
  }) {
    testLibrary = buildTestLibrary(
      LibrarySpec(
        uri: 'package:test/test.dart',
        imports: imports,
        extensionTypes: [spec],
      ),
      externalLibraries: externalLibraries,
    );
    return testLibrary.getExtensionType(spec.name)!;
  }

  Map<String, LibraryElementImpl> buildTestLibrariesFromSpec(
    Map<String, LibrarySpec> specs, {
    Map<String, LibraryElementImpl>? externalLibraries,
  }) {
    var libraries = buildLibrariesFromSpec(
      analysisContext,
      analysisContext.rootReference,
      analysisContext.analysisSession,
      specs,
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

  LibraryElementImpl buildTestLibrary(
    LibrarySpec spec, {
    Map<String, LibraryElementImpl>? externalLibraries,
  }) {
    return buildTestLibrariesFromSpec({
      spec.uri: spec,
    }, externalLibraries: externalLibraries)[spec.uri]!;
  }

  void setUp() {
    analysisContext = TestAnalysisContext();
    typeProvider = analysisContext.typeProvider;
    typeSystem = analysisContext.typeSystem;
    typeSystemOperations = TypeSystemOperations(
      typeSystem,
      strictCasts: analysisContext.analysisOptions.strictCasts,
    );

    testLibrary = library_(
      uriStr: 'package:test/test.dart',
      analysisContext: analysisContext,
      analysisSession: analysisContext.analysisSession,
      typeSystem: typeSystem,
    );
  }
}
