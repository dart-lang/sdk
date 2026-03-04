// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

/// Outputs the contents of [nodes] to [sink], prepending [prefix] to every
/// line.
void printNodes<SortKey extends Comparable<SortKey>>(
  StringSink sink,
  List<(SortKey, Node)> nodes, {
  String prefix = '',
}) {
  for (var entry in nodes.sortedBy((n) => n.$1)) {
    var node = entry.$2;
    sink.writeln('$prefix${node.text.join()}');
    node.printChildren(sink, prefix: '$prefix  ');
  }
}

/// A node to be printed to the output.
class Node<ChildSortKey extends Comparable<ChildSortKey>> {
  /// A list of objects which, when their string representations are
  /// concatenated, is the text that should be displayed on the first line of
  /// the node.
  ///
  /// The reason this is a list rather than a single string is to allow elements
  /// of the list to be [UniqueName] objects, which may acquire a disambiguation
  /// suffix at a later time.
  final text = <Object?>[];

  /// A list of child nodes, paired with a sort key indicating the order in
  /// which they should be output.
  final childNodes = <(ChildSortKey, Node)>[];

  /// Outputs [childNodes], prepending [prefix] to every line.
  void printChildren(StringSink sink, {required String prefix}) {
    printNodes(sink, childNodes, prefix: prefix);
  }
}
