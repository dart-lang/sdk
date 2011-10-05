// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

import com.google.debugging.sourcemap.FilePosition;


/**
 * Maintains a mapping from a given node to the position
 * in the source code at which its generated form was
 * placed. This position is relative only to the current
 * run.
 *
 * @see GenerateSourceMap
 */
public class SourceMapping {
  final HasSourceInfo node;
  final FilePosition start;
  FilePosition end;

  public SourceMapping(HasSourceInfo node, FilePosition start) {
    this.node = node;
    this.start = start;
  }

  /**
   * @return the end
   */
  public FilePosition getEnd() {
    return end;
  }
  /**
   * @param end the end to set
   */
  public void setEnd(FilePosition end) {
    this.end = end;
  }
  /**
   * @return the node
   */
  public HasSourceInfo getNode() {
    return node;
  }
  /**
   * @return the start
   */
  public FilePosition getStart() {
    return start;
  }
}
