// Copyright (c) 2011, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast.viz;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.util.HashMap;
import java.util.Map;

import com.google.common.io.Closeables;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartUnit;

/**
 * Write the AST in to System out.
 */
public class ConsoleWriter extends BaseASTWriter {
  Map<DartNode, Integer> indentMap;
  OutputStreamWriter out;

  public ConsoleWriter(String outputDir) {
    super(outputDir);
    this.indentMap = new HashMap<DartNode, Integer>();
    out = new OutputStreamWriter(System.out);
  }

  @Override
  protected void startHook(DartUnit unit) {
    // Do nothing  
  }

  @Override
  protected void endHook(DartUnit unit) {
    try {
      Closeables.close(out, true);
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  protected void write(String nodeType, DartNode node, String data) {
    StringBuffer sb = new StringBuffer();
    int indent = 0;
    DartNode parent = node.getParent();
    if (parent != null) {
      indent = this.indentMap.get(parent) + 1;
    }
    for (int i = 0; i < indent; i++) {
      sb.append('\t');
    }
    try {
      out.write(sb.toString());
      out.write(nodeType);
      if (!data.equals("")) {
        out.write(" (" + data + ")");
      }
      out.write('\n');
    } catch (IOException e) {

    }
  }

  @Override
  protected void visitChildren(DartNode node) {
    // Setup Indentation
    DartNode parent = node.getParent();
    if (parent == null) { // DartUnit's parent is null
      this.indentMap.put(node, 0);
    } else {
      int parentIndent = this.indentMap.get(parent);
      this.indentMap.put(node, parentIndent + 1);
    }
    super.visitChildren(node);
  }

}
