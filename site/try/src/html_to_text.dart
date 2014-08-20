// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.htmlToText;

import 'dart:math' show
    max;

import 'dart:html' show
    CharacterData,
    Element,
    Node,
    NodeFilter,
    ShadowRoot,
    TreeWalker;

import 'selection.dart' show
    TrySelection;

import 'shadow_root.dart' show
    WALKER_NEXT,
    WALKER_SKIP_NODE,
    walkNodes;

/// Returns true if [node] is a block element, that is, not inline.
bool isBlockElement(Node node) {
  if (node is! Element) return false;
  Element element = node;

  // TODO(ahe): Remove this line by changing code completion to avoid using a
  // div element.
  if (element.classes.contains('dart-code-completion')) return false;

  var display = element.getComputedStyle().display;
  return display != 'inline' && display != 'none';
}

/// Writes the text of [root] to [buffer]. Keeps track of [selection] and
/// returns the new anchorOffset from beginning of [buffer] or -1 if the
/// selection isn't in [root].
int htmlToText(Node root,
               StringBuffer buffer,
               TrySelection selection,
               {bool treatRootAsInline: false}) {
  int selectionOffset = -1;
  walkNodes(root, (Node node) {
    if (selection.anchorNode == node) {
      selectionOffset = selection.anchorOffset + buffer.length;
    }
    switch (node.nodeType) {
      case Node.CDATA_SECTION_NODE:
      case Node.TEXT_NODE:
        CharacterData text = node;
        buffer.write(text.data.replaceAll('\xA0', ' '));
        break;

      default:
        if (node.nodeName == 'BR') {
          buffer.write('\n');
        } else if (node != root && isBlockElement(node)) {
          selectionOffset =
              max(selectionOffset, htmlToText(node, buffer, selection));
          return WALKER_SKIP_NODE;
        }
        break;
    }

    return WALKER_NEXT;
  });

  if (!treatRootAsInline && isBlockElement(root)) {
    buffer.write('\n');
  }

  return selectionOffset;
}
