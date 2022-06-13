// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

import "reference_name_test.dart" show createComponent;

void main() {
  testQualifiedCanonicalNameToString();
}

void testQualifiedCanonicalNameToString() {
  Component component = createComponent();
  component.computeCanonicalNames();
  NamedNodeCollector namedNodeCollector = new NamedNodeCollector();
  component.accept(namedNodeCollector);

  bool foundMismatch = false;

  for (NamedNode namedNode in namedNodeCollector.namedNodes) {
    for (AstTextStrategy strategy in [
      const AstTextStrategy(
          includeLibraryNamesInMembers: false,
          includeLibraryNamesInTypes: false),
      const AstTextStrategy(includeLibraryNamesInMembers: true),
      const AstTextStrategy(includeLibraryNamesInTypes: true),
      const AstTextStrategy(
          includeLibraryNamesInMembers: true, includeLibraryNamesInTypes: true),
    ]) {
      String throughNode = namedNode.toText(strategy);
      String throughReference = namedNode.reference.toText(strategy);
      String throughCanonicalName =
          namedNode.reference.canonicalName!.toText(strategy);
      if (throughNode == throughReference &&
          throughReference == throughCanonicalName) continue;
      print("${namedNode.runtimeType} "
          "(${strategy.includeLibraryNamesInMembers},"
          "${strategy.includeLibraryNamesInTypes}): "
          "$throughNode <--> $throughReference <--> $throughCanonicalName");
      foundMismatch = true;
    }
  }

  if (foundMismatch) throw "Found mismatch.";
}

class NamedNodeCollector extends RecursiveVisitor {
  List<NamedNode> namedNodes = [];
  @override
  void defaultNode(Node node) {
    if (node is NamedNode) {
      namedNodes.add(node);
    }
    if (node is Extension) return;
    if (node is Typedef) return;
    if (node is Member) return;

    super.defaultNode(node);
  }
}
