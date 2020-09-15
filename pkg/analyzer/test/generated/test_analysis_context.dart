// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/test_utilities/mock_sdk_elements.dart';

class TestAnalysisContext implements AnalysisContext {
  @override
  final SourceFactory sourceFactory = _MockSourceFactory();

  final _MockAnalysisSession _analysisSession = _MockAnalysisSession();
  AnalysisOptionsImpl _analysisOptions;

  TypeProvider _typeProviderLegacy;
  TypeProvider _typeProviderNonNullableByDefault;

  TypeSystemImpl _typeSystemLegacy;
  TypeSystemImpl _typeSystemNonNullableByDefault;

  TestAnalysisContext({FeatureSet featureSet}) {
    _analysisOptions = AnalysisOptionsImpl()
      ..contextFeatures = featureSet ?? FeatureSet.forTesting();

    var sdkElements = MockSdkElements(this, _analysisSession);

    _typeProviderLegacy = TypeProviderImpl(
      coreLibrary: sdkElements.coreLibrary,
      asyncLibrary: sdkElements.asyncLibrary,
      isNonNullableByDefault: false,
    );

    _typeProviderNonNullableByDefault = TypeProviderImpl(
      coreLibrary: sdkElements.coreLibrary,
      asyncLibrary: sdkElements.asyncLibrary,
      isNonNullableByDefault: true,
    );

    _typeSystemLegacy = TypeSystemImpl(
      implicitCasts: _analysisOptions.implicitCasts,
      isNonNullableByDefault: false,
      strictInference: _analysisOptions.strictInference,
      typeProvider: _typeProviderLegacy,
    );

    _typeSystemNonNullableByDefault = TypeSystemImpl(
      implicitCasts: _analysisOptions.implicitCasts,
      isNonNullableByDefault: true,
      strictInference: _analysisOptions.strictInference,
      typeProvider: _typeProviderNonNullableByDefault,
    );

    _setLibraryTypeSystem(sdkElements.coreLibrary);
    _setLibraryTypeSystem(sdkElements.asyncLibrary);
  }

  @override
  AnalysisOptions get analysisOptions => _analysisOptions;

  AnalysisSessionImpl get analysisSession => _analysisSession;

  TypeProvider get typeProviderLegacy {
    return _typeProviderLegacy;
  }

  TypeProvider get typeProviderNonNullableByDefault {
    return _typeProviderNonNullableByDefault;
  }

  TypeSystemImpl get typeSystemLegacy {
    return _typeSystemLegacy;
  }

  TypeSystemImpl get typeSystemNonNullableByDefault {
    return _typeSystemNonNullableByDefault;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void _setLibraryTypeSystem(LibraryElementImpl libraryElement) {
    libraryElement.typeProvider = _typeProviderNonNullableByDefault;
    libraryElement.typeSystem = _typeSystemNonNullableByDefault;
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
  String get encoding => '$uri';

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
