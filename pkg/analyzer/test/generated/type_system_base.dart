// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';

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

  void setUp() {
    analysisContext = TestAnalysisContext();
    typeProvider = analysisContext.typeProvider;
    typeSystem = analysisContext.typeSystem;
    typeSystemOperations = TypeSystemOperations(typeSystem,
        strictCasts: analysisContext.analysisOptions.strictCasts);

    testLibrary = library_(
      uriStr: 'package:test/test.dart',
      analysisContext: analysisContext,
      analysisSession: analysisContext.analysisSession,
      typeSystem: typeSystem,
    );
  }
}
