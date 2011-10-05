// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.dart.compiler.backend.js.ast.JsStatement;
import com.google.dart.compiler.backend.js.ast.JsVisitable;
import com.google.dart.compiler.backend.js.ast.JsVisitor;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

class FlatteningVisitor extends JsVisitor {

  public static TreeNode exec(List<JsStatement> statements) {
    FlatteningVisitor visitor = new FlatteningVisitor();
    visitor.acceptList(statements);
    return visitor.root;
  }

  public static class TreeNode {
    public final JsVisitable node;
    public final List<TreeNode> children = new ArrayList<TreeNode>();

    public TreeNode(JsVisitable node) {
      this.node = node;
    }
  }

  private TreeNode root;

  private FlatteningVisitor() {
    root = new TreeNode(null);
  }

  protected <T extends JsVisitable> T doAccept(T node) {
    TreeNode oldRoot = root;
    root = new TreeNode(node);
    oldRoot.children.add(root);
    super.doAccept(node);
    root = oldRoot;
    return node;
  }

  // @Override
  protected <T extends JsVisitable> void doAcceptList(List<T> collection) {
    for (Iterator<T> it = collection.iterator(); it.hasNext();) {
      doAccept(it.next());
    }
  }
}
