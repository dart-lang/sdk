// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.resolver.CoreTypeProvider;

/**
 * A compiler phase that processes a unit and possibly transforms it or reports
 * compilation errors.
 */
public interface DartCompilationPhase {

  /**
   * Execute this phase on a unit.
   *
   * @param unit the program to process
   * @param context context where to report error messages
   */
  DartUnit exec(DartUnit unit, DartCompilerContext context, CoreTypeProvider typeProvider);
}
