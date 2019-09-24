// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/test_utilities/mock_sdk_elements.dart';

class TestAnalysisContext implements AnalysisContext {
  @override
  final SourceFactory sourceFactory = _MockSourceFactory();

  AnalysisOptions _analysisOptions;
  TypeProviderImpl _typeProvider;
  TypeSystem _typeSystem;

  TestAnalysisContext({FeatureSet featureSet}) {
    _analysisOptions = AnalysisOptionsImpl()
      ..contextFeatures = featureSet ?? FeatureSet.forTesting();

    var sdkElements = MockSdkElements(
      this,
      analysisOptions.contextFeatures.isEnabled(Feature.non_nullable)
          ? NullabilitySuffix.none
          : NullabilitySuffix.star,
    );

    _typeProvider = TypeProviderImpl(
      sdkElements.coreLibrary,
      sdkElements.asyncLibrary,
    );

    if (_analysisOptions.contextFeatures.isEnabled(Feature.non_nullable)) {
      _typeProvider = _typeProvider.withNullability(NullabilitySuffix.none);
    }

    _typeSystem = Dart2TypeSystem(typeProvider);
  }

  @override
  AnalysisOptions get analysisOptions => _analysisOptions;

  @override
  TypeProvider get typeProvider => _typeProvider;

  @override
  TypeSystem get typeSystem => _typeSystem;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSource implements Source {
  @override
  final Uri uri;

  _MockSource(this.uri);

  @override
  String get encoding => '$uri';

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSourceFactory implements SourceFactory {
  @override
  Source forUri(String uriStr) {
    var uri = Uri.parse(uriStr);
    return _MockSource(uri);
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
