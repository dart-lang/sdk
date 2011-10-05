// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.resolver.CoreTypeProvider;

import java.io.IOException;
import java.util.Collection;

/**
 * Interface for compiler backends.
 */
public interface Backend {

  /**
   * Determines whether compilation artifacts are out of date with respect to
   * this source.
   */
  boolean isOutOfDate(DartSource src, DartCompilerContext context);

  /**
   * Compile the given compilation unit.
   * @param context The listener through which compilation errors are reported
   *          (not <code>null</code>)
   */
  void compileUnit(DartUnit unit, DartSource src,
                   DartCompilerContext context,
                   CoreTypeProvider typeProvider)
      throws IOException;

  /**
   * Package the given application.
   *
   * @param app The application library whose entry-point should be called
   * @param libraries The transitive set of libraries contained in this
   *          application
   * @param context The listener through which compilation errors are reported
   *          (not <code>null</code>)
   */
  void packageApp(LibrarySource app,
                  Collection<LibraryUnit> libraries,
                  DartCompilerContext context,
                  CoreTypeProvider typeProvider)
      throws IOException;

  /**
   * The application extension for the backend.
   */
  String getAppExtension();

  /**
   * The source map extension for the backend.
   */
  String getSourceMapExtension();
}
