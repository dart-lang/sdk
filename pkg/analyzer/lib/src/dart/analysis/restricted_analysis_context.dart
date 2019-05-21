// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/type_system.dart';

/// This class is a temporary step toward migrating Analyzer clients to the
/// new API.  It guards against attempts to use any [AnalysisContext]
/// functionality (which is task based), except what we intend to expose
/// through the new API.
class RestrictedAnalysisContext implements AnalysisContextImpl {
  final SynchronousSession synchronousSession;

  @override
  final SourceFactory sourceFactory;

  RestrictedAnalysisContext(this.synchronousSession, this.sourceFactory);

  @override
  AnalysisOptionsImpl get analysisOptions => synchronousSession.analysisOptions;

  @override
  DeclaredVariables get declaredVariables =>
      synchronousSession.declaredVariables;

  @override
  TypeProvider get typeProvider => synchronousSession.typeProvider;

  @override
  set typeProvider(TypeProvider typeProvider) {
    synchronousSession.typeProvider = typeProvider;
  }

  @override
  TypeSystem get typeSystem => synchronousSession.typeSystem;

  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  void clearTypeProvider() {
    synchronousSession.clearTypeProvider();
  }
}
