// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.AbstractNode;

/**
 * An element in a library or application manifest
 *
 * TODO(jgw): This class works with both JSON and the new library syntax. It can be greatly
 * simplified once support for the JSON syntax is removed.
 */
public class LibraryNode extends AbstractNode {

  private final String text;
  private final String prefix;

  /**
   * Construct a new library node instance
   *
   * @param manifest the library manifest declaration (not <code>null</code>)
   * @param text the text comprising the node (not <code>null</code>)
   */
  public LibraryNode(String text) {
    this(text, null);
  }

  public LibraryNode(String text, String prefix) {
    this.text = text;
    this.prefix = prefix;
  }

  public String getText() {
    return text;
  }

  public String getPrefix() {
    return prefix;
  }
}
