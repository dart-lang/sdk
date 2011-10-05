// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.backend.js.ast.HasName;
import com.google.debugging.sourcemap.FilePosition;
import com.google.debugging.sourcemap.SourceMapFormat;
import com.google.debugging.sourcemap.SourceMapGenerator;
import com.google.debugging.sourcemap.SourceMapGeneratorFactory;
import com.google.debugging.sourcemap.SourceMapSection;

import java.io.IOException;
import java.util.List;

/**
 * Collects information mapping the generated (compiled) source back to
 * its original source for debugging purposes.
 *
 * @author johnlenz@google.com (John Lenz)
 */
public class GenerateSourceMap {

  private final SourceMapGenerator generator;

  public GenerateSourceMap() {
    // Get the source map in the default format.
    this.generator = SourceMapGeneratorFactory.getInstance(SourceMapFormat.V3);
  }

  /**
   * Adds a mapping for the given node.  Mappings must be added in order.
   *
   * @param node The node that the new mapping represents.
   * @param startPosition The position on the starting line
   * @param endPosition The position on the ending line.
   */
  public void addMapping(
      HasSourceInfo node, FilePosition startPosition, FilePosition endPosition) {
    SourceInfo sourceInfo = node.getSourceInfo();

    // If the node does not have an associated source file or
    // its line number is -1, then the node does not have sufficient
    // information for a mapping to be useful.
    if (sourceInfo.getSource() == null || sourceInfo.getSourceLine() < 0) {
      return;
    }

    String sourceFile = sourceInfo.getSource().getName();

    String originalName = null;
    if (node instanceof HasName) {
      Symbol symbol = ((HasName)node).getSymbol();
      if (symbol != null) {
        originalName = symbol.getOriginalSymbolName();
      }
    } else if (node instanceof DartIdentifier) {
      // We need a better abstraction, see bug 4188120.
      originalName = ((DartIdentifier) node).getTargetName();
    } else if (node instanceof DartPropertyAccess) {
      // We need a better abstraction, see bug 4188120.
      originalName = ((DartPropertyAccess) node).getPropertyName();
    }
    generator.addMapping(sourceFile, originalName, new FilePosition(
      sourceInfo.getSourceLine(), sourceInfo.getSourceColumn()), startPosition, endPosition);
  }

  public void appendTo(Appendable out, String name) throws IOException {
    generator.appendTo(out, name);
  }

  /**
   * To facilitate incremental compiles, create source map that is built
   * piecemeal from other source maps.
   * @throws IOException
   */
  public void appendIndexMapTo(
      Appendable out, String name, List<SourceMapSection> appSections)
      throws IOException {
    generator.appendIndexMapTo(out, name, appSections);
  }
}
