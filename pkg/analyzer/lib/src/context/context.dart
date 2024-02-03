// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/// An [AnalysisContext] in which analysis can be performed.
class AnalysisContextImpl implements AnalysisContext {
  AnalysisOptionsMap _analysisOptionsMap;

  @override
  final DeclaredVariables declaredVariables;

  @override
  final SourceFactory sourceFactory;

  TypeProviderImpl? _typeProvider;
  TypeSystemImpl? _typeSystem;

  AnalysisContextImpl({
    required AnalysisOptionsMap analysisOptionsMap,
    required this.declaredVariables,
    required this.sourceFactory,
  }) : _analysisOptionsMap = analysisOptionsMap;

  @Deprecated("Use 'getAnalysisOptionsForFile(file)' instead")
  @override
  AnalysisOptionsImpl get analysisOptions {
    return _analysisOptionsMap.firstOrDefault;
  }

  // TODO(scheglov): Remove it, exists only for Cider.
  set analysisOptions(AnalysisOptionsImpl analysisOptions) {
    _analysisOptionsMap = AnalysisOptionsMap.forSharedOptions(analysisOptions);
  }

  bool get hasTypeProvider {
    return _typeProvider != null;
  }

  TypeProviderImpl get typeProvider {
    return _typeProvider!;
  }

  TypeSystemImpl get typeSystem {
    return _typeSystem!;
  }

  void clearTypeProvider() {
    _typeProvider = null;
    _typeSystem = null;
  }

  @override
  AnalysisOptionsImpl getAnalysisOptionsForFile(File file) =>
      _analysisOptionsMap.getOptions(file);

  void setTypeProviders({
    required TypeProviderImpl typeProvider,
  }) {
    if (_typeProvider != null) {
      throw StateError('TypeProvider can be set only once.');
    }

    _typeProvider = typeProvider;

    _typeSystem = TypeSystemImpl(
      typeProvider: typeProvider,
    );
  }
}
