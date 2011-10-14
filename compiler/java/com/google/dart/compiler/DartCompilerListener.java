// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.DartUnit;

/**
 * Abstract class that {@link DartCompiler} consumers can use to monitor
 * compilation progress and report various problems that occur during
 * compilation.
 */
public abstract class DartCompilerListener {

  /**
   * Called by the compiler when a compilation error has occurred in a Dart
   * file.
   *
   * @param event the event information (not <code>null</code>)
   */
  public abstract void compilationError(DartCompilationError event);

  public abstract void compilationWarning(DartCompilationError event);

  public abstract void typeError(DartCompilationError event);

  /**
   * Called by the compiler after the resolution and type analyzer phase for each unit.
   *
   * @param unit the DartUnit having just been compiled. (not <code>null</code>)
   */
  public abstract void unitCompiled(DartUnit unit);
}
