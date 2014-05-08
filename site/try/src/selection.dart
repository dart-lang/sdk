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
  Node anchorNode;
  int anchorOffset;

  String text;
  int globalOffset = -1;

  TrySelection(this.root, Selection selection)
      : anchorNode = isCollapsed(selection) ? selection.anchorNode : null,
        anchorOffset = isCollapsed(selection) ? selection.anchorOffset : -1;

  TrySelection.empty(this.root)
      : anchorNode = null,
        anchorOffset = -1;

  Text addNodeFromSubstring(int start,
                            int end,
                            List<Node> nodes,
                            [Decoration decoration]) {
    if (start == end) return null;

    Text textNode = new Text(text.substring(start, end));

    if (start <= globalOffset && globalOffset <= end) {
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

  void updateText(String newText) {
    text = newText;
    globalOffset = computeGlobalOffset(root, anchorNode, anchorOffset);
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

bool isCollapsed(Selection selection) {
  // Firefox and Chrome don't agree on if the selection is collapsed if there
  // is no node selected.
  return selection.isCollapsed && selection.anchorNode != null;
}
