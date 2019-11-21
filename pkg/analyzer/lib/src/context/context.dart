// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/type_system.dart' show TypeSystemImpl;

/**
 * An [AnalysisContext] in which analysis can be performed.
 */
class AnalysisContextImpl implements InternalAnalysisContext {
  /**
   * The set of analysis options controlling the behavior of this context.
   */
  AnalysisOptionsImpl _options = new AnalysisOptionsImpl();

  /**
   * The source factory used to create the sources that can be analyzed in this
   * context.
   */
  SourceFactory _sourceFactory;

  /**
   * The set of declared variables used when computing constant values.
   */
  DeclaredVariables _declaredVariables = new DeclaredVariables();

  /**
   * The [TypeProvider] for this context, `null` if not yet created.
   */
  TypeProvider _typeProvider;

  /**
   * The [TypeSystem] for this context, `null` if not yet created.
   */
  TypeSystemImpl _typeSystem;

  /**
   * Initialize a newly created analysis context.
   */
  AnalysisContextImpl();

  @override
  AnalysisOptions get analysisOptions => _options;

  @override
  void set analysisOptions(AnalysisOptions options) {
    this._options = options;
  }

  @override
  DeclaredVariables get declaredVariables => _declaredVariables;

  /**
   * Set the declared variables to the give collection of declared [variables].
   */
  void set declaredVariables(DeclaredVariables variables) {
    _declaredVariables = variables;
  }

  @override
  SourceFactory get sourceFactory => _sourceFactory;

  @override
  void set sourceFactory(SourceFactory factory) {
    _sourceFactory = factory;
  }

  @override
  TypeProvider get typeProvider {
    return _typeProvider;
  }

  /**
   * Sets the [TypeProvider] for this context.
   */
  @override
  void set typeProvider(TypeProvider typeProvider) {
    _typeProvider = typeProvider;
  }

  @override
  TypeSystemImpl get typeSystem {
    return _typeSystem ??= TypeSystemImpl(
      implicitCasts: true,
      isNonNullableByDefault: false,
      strictInference: false,
      typeProvider: typeProvider,
    );
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
  SdkAnalysisContext(AnalysisOptions options) {
    if (options != null) {
      super.analysisOptions = options;
    }
  }

  @override
  void set analysisOptions(AnalysisOptions options) {
    throw new StateError('AnalysisOptions of SDK context cannot be changed.');
  }
}
