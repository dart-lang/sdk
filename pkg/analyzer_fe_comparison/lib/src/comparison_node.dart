// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

/// [ComparisonNode] defines a simple tree structure that can be used to compare
/// two representations of Dart code.
///
/// Each node contains a textual string and a list of child nodes.
class ComparisonNode {
  final String text;
  final List<ComparisonNode> children;

  ComparisonNode(this.text, [List<ComparisonNode> children])
      : children = children ?? <ComparisonNode>[];

  factory ComparisonNode.sorted(
          String text, Iterable<ComparisonNode> children) =>
      ComparisonNode(text, sortList(children));

  @override
  bool operator ==(Object other) {
    if (other is ComparisonNode) {
      if (text != other.text) return false;
      if (children.length != other.children.length) return false;
      for (int i = 0; i < children.length; i++) {
        if (children[i] != other.children[i]) return false;
      }
      return true;
    }
    return false;
  }

  String toString({String newline: '\n'}) {
    var lines = ['$text'];
    var indentedNewline = '$newline  ';
    for (var child in children) {
      lines.add(child.toString(newline: indentedNewline));
    }
    return lines.join(indentedNewline);
  }

  static ComparisonNode diff(
      ComparisonNode a, ComparisonNode b, String aName, String bName) {
    if (a.text == b.text) {
      return ComparisonNode(
          a.text, diffLists(a.children, b.children, aName, bName));
    } else {
      return ComparisonNode('Root nodes differ',
          [_prefix('In $aName: ', a), _prefix('In $bName: ', b)]);
    }
  }

  static List<ComparisonNode> diffLists(List<ComparisonNode> a,
      List<ComparisonNode> b, String aName, String bName) {
    // Note: this is an O(n) "poor man's" diff algorithm; it produces optimal
    // results if the incoming results are sorted by text or if there is just
    // one contiguous hunk of differences.  Otherwise it may not find the
    // shortest diff.  This should be sufficient for our purposes, since we are
    // not expecting many diffs.

    // We'll exclude common nodes at the beginning of both lists
    var shorterLength = min(a.length, b.length);
    var commonInitialNodes = 0;
    while (commonInitialNodes < shorterLength &&
        a[commonInitialNodes] == b[commonInitialNodes]) {
      commonInitialNodes++;
    }

    // Fast exit if a == b
    if (commonInitialNodes == a.length && a.length == b.length) {
      return [];
    }

    // We'll exclude common nodes at the end of both lists (note: we don't want
    // to overcount by re-testing the common nodes identified above)
    var commonFinalNodes = 0;
    while (commonInitialNodes + commonFinalNodes < shorterLength &&
        a[a.length - commonFinalNodes - 1] ==
            b[b.length - commonFinalNodes - 1]) {
      commonFinalNodes++;
    }

    // Walk the remaining nodes starting at the first node that's different,
    // matching up nodes by their text.
    var aIndex = commonInitialNodes;
    var bIndex = commonInitialNodes;
    var aEnd = a.length - commonFinalNodes;
    var bEnd = b.length - commonFinalNodes;
    var result = <ComparisonNode>[];
    while (aIndex < aEnd && bIndex < bEnd) {
      var comparisonResult = a[aIndex].text.compareTo(b[bIndex].text);
      if (comparisonResult < 0) {
        // a[aIndex].text sorts before b[bIndex].text.  Assume that this means
        // a[aIndex] was removed.
        result.add(_prefix('Only in $aName: ', a[aIndex++]));
      } else if (comparisonResult > 0) {
        // b[bIndex].text sorts before a[aIndex].text.  Assume that this means
        // b[bIndex] was added.
        result.add(_prefix('Only in $bName: ', b[bIndex++]));
      } else {
        // a[aIndex].text matches b[bIndex].text, so diff the nodes if
        // necessary.
        var aNode = a[aIndex++];
        var bNode = b[bIndex++];
        if (aNode != bNode) {
          result.add(diff(aNode, bNode, aName, bName));
        }
      }
    }

    // Deal with any nodes left over.
    while (aIndex < aEnd) {
      result.add(_prefix('Only in $aName: ', a[aIndex++]));
    }
    while (bIndex < bEnd) {
      result.add(_prefix('Only in $bName: ', b[bIndex++]));
    }

    // If we get here and we haven't added any nodes, something has gone wrong.
    if (result.isEmpty) {
      throw StateError('Diff produced empty diff for non-matching lists');
    }

    return result;
  }

  static List<ComparisonNode> sortList(Iterable<ComparisonNode> nodes) {
    var result = nodes.toList();
    result.sort((a, b) => a.text.compareTo(b.text));
    return result;
  }

  static ComparisonNode _prefix(String prefixString, ComparisonNode node) {
    return ComparisonNode(prefixString + node.text, node.children);
  }
}
