// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.selection;

import 'dart:html' show
    CharacterData,
    Node,
    NodeFilter,
    Selection,
    Text,
    TreeWalker;

import 'decoration.dart';

class TrySelection {
  final Node root;
  final String text;
  final int globalOffset;

  Node anchorNode;
  int anchorOffset;

  TrySelection.internal(
      this.root, this.text, this.globalOffset,
      this.anchorNode, this.anchorOffset);

  factory TrySelection(Node root, Selection selection, String text) {
    if (selection.isCollapsed) {
      Node anchorNode = selection.anchorNode;
      int anchorOffset = selection.anchorOffset;
      return new TrySelection.internal(
          root, text, computeGlobalOffset(root, anchorNode, anchorOffset),
          anchorNode, anchorOffset);
    } else {
      return new TrySelection.internal(root, text, -1, null, -1);
    }
  }

  Text addNodeFromSubstring(int start,
                            int end,
                            List<Node> nodes,
                            [Decoration decoration]) {
    if (start == end) return null;

    Text textNode = new Text(text.substring(start, end));

    if (start <= globalOffset && globalOffset < end) {
      anchorNode = textNode;
      anchorOffset = globalOffset - start;
    }

    nodes.add(decoration == null ? textNode : decoration.applyTo(textNode));

    return textNode;
  }

  void adjust(Selection selection) {
    if (anchorOffset >= 0) {
      selection.collapse(anchorNode, anchorOffset);
    }
  }

  /// Computes the global offset, that is, the offset from [root].
  static int computeGlobalOffset(Node root, Node anchorNode, int anchorOffset) {
    if (anchorOffset == -1) return -1;

    int offset = 0;
    TreeWalker walker = new TreeWalker(root, NodeFilter.SHOW_TEXT);
    for (Node node = walker.nextNode();
         node != null;
         node = walker.nextNode()) {
      CharacterData text = node;
      if (anchorNode == text) {
        return anchorOffset + offset;
      }
      offset += text.data.length;
    }

    return -1;
  }
}
