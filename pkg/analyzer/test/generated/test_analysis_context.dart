// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart' show SourceFactory;
import 'package:analyzer/src/test_utilities/mock_sdk_elements.dart';

class TestAnalysisContext implements AnalysisContext {
  @override
  final SourceFactory sourceFactory = _MockSourceFactory();

  final _MockAnalysisSession _analysisSession = _MockAnalysisSession();
  final AnalysisOptionsImpl _analysisOptions = AnalysisOptionsImpl();

  late TypeProviderImpl _typeProvider;
  late TypeSystemImpl _typeSystem;

  TestAnalysisContext() {
    var sdkElements = MockSdkElements(this, _analysisSession);

    _typeProvider = TypeProviderImpl(
      coreLibrary: sdkElements.coreLibrary,
      asyncLibrary: sdkElements.asyncLibrary,
    );

    _typeSystem = TypeSystemImpl(
      typeProvider: _typeProvider,
    );

    _setLibraryTypeSystem(sdkElements.coreLibrary);
    _setLibraryTypeSystem(sdkElements.asyncLibrary);
  }

  @override
  AnalysisOptionsImpl get analysisOptions => _analysisOptions;

  AnalysisSessionImpl get analysisSession => _analysisSession;

  TypeProviderImpl get typeProvider {
    return _typeProvider;
  }

  TypeSystemImpl get typeSystem {
    return _typeSystem;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void _setLibraryTypeSystem(LibraryElementImpl libraryElement) {
    libraryElement.typeProvider = _typeProvider;
    libraryElement.typeSystem = _typeSystem;
  }
}

class _MockAnalysisSession implements AnalysisSessionImpl {
  @override
  final ClassHierarchy classHierarchy = ClassHierarchy();

  @override
  final InheritanceManager3 inheritanceManager = InheritanceManager3();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSource implements Source {
  @override
  final Uri uri;

  _MockSource(this.uri);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSourceFactory implements SourceFactory {
  @override
  Source forUri(String uriStr) {
    var uri = Uri.parse(uriStr);
    return _MockSource(uri);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
