// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler;

import com.google.dart.compiler.ast.DartUnit;

/**
 * Interface that {@link DartCompiler} consumers can use to monitor compilation progress and report
 * various problems that occur during compilation.
 */
public interface DartCompilerListener {
  /**
   * Called by the compiler when a compilation error has occurred in a Dart file.
   * 
   * @param event the event information (not <code>null</code>)
   */
  void onError(DartCompilationError event);

  /**
   * Called by the compiler before parsing given {@link DartSource}.
   */
  void unitAboutToCompile(DartSource source, boolean diet);

  /**
   * Called by the compiler after the resolution and type analyzer phase for each unit.
   * 
   * @param unit the {@link DartUnit} having just been compiled (not <code>null</code>)
   */
  void unitCompiled(DartUnit unit);

  /**
   * Implementation of {@link DartCompilerListener} which does nothing.
   */
  public static class Empty implements DartCompilerListener {
    @Override
    public void onError(DartCompilationError event) {
    }

    @Override
    public void unitAboutToCompile(DartSource source, boolean diet) {
    }

    @Override
    public void unitCompiled(DartUnit unit) {
    }
  }
  
  /**
   * Instance of {@link DartCompilerListener} which does nothing.
   */
  public static final DartCompilerListener EMPTY = new Empty();
}
