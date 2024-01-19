// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/// An [AnalysisContext] in which analysis can be performed.
class AnalysisContextImpl implements AnalysisContext {
  AnalysisOptionsImpl _analysisOptions;

  @override
  final DeclaredVariables declaredVariables;

  @override
  final SourceFactory sourceFactory;

  TypeProviderImpl? _typeProviderLegacy;
  TypeProviderImpl? _typeProviderNonNullableByDefault;

  TypeSystemImpl? _typeSystemLegacy;
  TypeSystemImpl? _typeSystemNonNullableByDefault;

  AnalysisContextImpl({
    required AnalysisOptionsImpl analysisOptions,
    required this.declaredVariables,
    required this.sourceFactory,
  }) : _analysisOptions = analysisOptions;

  @Deprecated("Use 'getAnalysisOptionsForFile(file)' instead")
  @override
  AnalysisOptionsImpl get analysisOptions {
    return _analysisOptions;
  }

  // TODO(scheglov): Remove it, exists only for Cider.
  set analysisOptions(AnalysisOptionsImpl analysisOptions) {
    _analysisOptions = analysisOptions;
  }

  bool get hasTypeProvider {
    return _typeProviderNonNullableByDefault != null;
  }

  TypeProviderImpl get typeProviderLegacy {
    return _typeProviderLegacy!;
  }

  TypeProviderImpl get typeProviderNonNullableByDefault {
    return _typeProviderNonNullableByDefault!;
  }

  TypeSystemImpl get typeSystemLegacy {
    return _typeSystemLegacy!;
  }

  TypeSystemImpl get typeSystemNonNullableByDefault {
    return _typeSystemNonNullableByDefault!;
  }

  void clearTypeProvider() {
    _typeProviderLegacy = null;
    _typeProviderNonNullableByDefault = null;

    _typeSystemLegacy = null;
    _typeSystemNonNullableByDefault = null;
  }

  @override
  AnalysisOptionsImpl getAnalysisOptionsForFile(File file) => _analysisOptions;

  void setTypeProviders({
    required TypeProviderImpl legacy,
    required TypeProviderImpl nonNullableByDefault,
  }) {
    if (_typeProviderLegacy != null ||
        _typeProviderNonNullableByDefault != null) {
      throw StateError('TypeProvider(s) can be set only once.');
    }

    _typeSystemLegacy = TypeSystemImpl(
      isNonNullableByDefault: false,
      typeProvider: legacy,
    );

    _typeSystemNonNullableByDefault = TypeSystemImpl(
      isNonNullableByDefault: true,
      typeProvider: nonNullableByDefault,
    );

    _typeProviderLegacy = legacy;
    _typeProviderNonNullableByDefault = nonNullableByDefault;
  }
}
