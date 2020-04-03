// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeSystemImpl;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/test_utilities/mock_sdk_elements.dart';

class TestAnalysisContext implements AnalysisContext {
  @override
  final SourceFactory sourceFactory = _MockSourceFactory();

  AnalysisOptionsImpl _analysisOptions;

  TypeProvider _typeProviderLegacy;
  TypeProvider _typeProviderNonNullableByDefault;

  TypeSystemImpl _typeSystemLegacy;
  TypeSystemImpl _typeSystemNonNullableByDefault;

  TestAnalysisContext({FeatureSet featureSet}) {
    _analysisOptions = AnalysisOptionsImpl()
      ..contextFeatures = featureSet ?? FeatureSet.forTesting();

    var sdkElements = MockSdkElements(
      this,
      analysisOptions.contextFeatures.isEnabled(Feature.non_nullable)
          ? NullabilitySuffix.none
          : NullabilitySuffix.star,
    );

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

  @Deprecated('Use LibraryElement.typeProvider')
  @override
  TypeProvider get typeProvider => typeProviderLegacy;

  TypeProvider get typeProviderLegacy {
    return _typeProviderLegacy;
  }

  TypeProvider get typeProviderNonNullableByDefault {
    return _typeProviderNonNullableByDefault;
  }

  @Deprecated('Use LibraryElement.typeSystem')
  @override
  TypeSystemImpl get typeSystem => typeSystemLegacy;

  TypeSystemImpl get typeSystemLegacy {
    return _typeSystemLegacy;
  }

  TypeSystemImpl get typeSystemNonNullableByDefault {
    return _typeSystemNonNullableByDefault;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void _setLibraryTypeSystem(LibraryElementImpl libraryElement) {
    libraryElement.typeProvider = _typeProviderLegacy;
    libraryElement.typeSystem = _typeSystemLegacy;
  }
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
