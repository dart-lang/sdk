// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.IOException;

/**
 * Abstract interface to library source.
 *
 * TODO(jgw): Consider requiring implementors to intern LibrarySource instances
 * so that users can depend upon reference equality to avoid cycles (or require
 * them to use .equals()). As it is, there are two pieces of code in
 * DartCompiler and one in JavascriptBackend that do this manually, and it's a
 * little tricky.
 */
public interface LibrarySource extends Source {

  /**
   * Answer the {@link LibrarySource} for the path specified in the receiver's
   * imports declaration
   *
   * @param relPath path to the {@link LibrarySource} relative to the receiver
   * @return the dart source or <code>null</code> if could not be found
   */
  LibrarySource getImportFor(String relPath) throws IOException;

  /**
   * Answer the {@link DartSource} for the path specified in the receiver's
   * sources declaration
   *
   * @param relPath the path to the {@link DartSource} relative to the receiver
   * @return the dart source or <code>null</code> if could not be found
   */
  DartSource getSourceFor(String relPath);
}
