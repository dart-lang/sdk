// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/type_system.dart' show TypeSystemImpl;

/**
 * An [AnalysisContext] in which analysis can be performed.
 */
class AnalysisContextImpl implements InternalAnalysisContext {
  final SynchronousSession _synchronousSession;

  @override
  final SourceFactory sourceFactory;

  AnalysisContextImpl(this._synchronousSession, this.sourceFactory);

  @override
  AnalysisOptionsImpl get analysisOptions {
    return _synchronousSession.analysisOptions;
  }

  @override
  DeclaredVariables get declaredVariables {
    return _synchronousSession.declaredVariables;
  }

  @override
  TypeProvider get typeProvider {
    return _synchronousSession.typeProvider;
  }

  @override
  set typeProvider(TypeProvider typeProvider) {
    _synchronousSession.typeProvider = typeProvider;
  }

  @override
  TypeSystemImpl get typeSystem => _synchronousSession.typeSystem;

  void clearTypeProvider() {
    _synchronousSession.clearTypeProvider();
  }

  @override
  void set analysisOptions(AnalysisOptions options) {
    throw StateError('Cannot be changed.');
  }

  @override
  void set sourceFactory(SourceFactory factory) {
    throw StateError('Cannot be changed.');
  }
}

/**
 * An [AnalysisContext] that only contains sources for a Dart SDK.
 */
class SdkAnalysisContext extends AnalysisContextImpl {
  /**
   * Initialize a newly created SDK analysis context with the given [options].
   * Analysis options cannot be changed afterwards.  If the given [options] are
   * `null`, then default options are used.
   */
  SdkAnalysisContext(AnalysisOptions options, SourceFactory sourceFactory)
      : super(SynchronousSession(options, DeclaredVariables()), sourceFactory);
}
