// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'nodes.dart';

/// [Parser] parsers a program split constraints json file and returns a
/// [ConstraintData] object.
class Parser {
  final Map<String, NamedNode> nameMap = {};
  final List<OrderNode> orderedNodes = [];

  void parseReference(Map<String, dynamic> nodeJson) {
    var reference = ReferenceNode.fromJson(nodeJson);
    nameMap[reference.name] = reference;
  }

  void parseCombiner(Map<String, dynamic> nodeJson) {
    var combinerNode = CombinerNode.fromJson(nodeJson, nameMap);
    nameMap[combinerNode.name] = combinerNode;
  }

  void parseRelativeOrder(Map<String, dynamic> nodeJson) {
    orderedNodes.add(RelativeOrderNode.fromJson(nodeJson, nameMap));
  }

  void parseFuse(Map<String, dynamic> nodeJson) {
    orderedNodes.add(FuseNode.fromJson(nodeJson, nameMap));
  }

  /// Reads a program split constraints json file string and returns a [Nodes]
  /// object reflecting the parsed constraints.
  ConstraintData read(String programSplitJson) {
    List<dynamic> doc = json.decode(programSplitJson);
    List<Map<String, dynamic>> referenceConstraints = [];
    List<Map<String, dynamic>> combinerConstraints = [];
    List<Map<String, dynamic>> fuseConstraints = [];
    List<Map<String, dynamic>> relativeOrderConstraints = [];
    for (Map<String, dynamic> constraint in doc) {
      switch (constraint['type']) {
        case 'reference':
          referenceConstraints.add(constraint);
          break;
        case 'and':
        case 'or':
          combinerConstraints.add(constraint);
          break;
        case 'fuse':
          fuseConstraints.add(constraint);
          break;
        case 'relative_order':
          relativeOrderConstraints.add(constraint);
          break;
        default:
          throw 'Unrecognized constraint type in $constraint';
      }
    }

    // Parse references, than combiners, than finally sequences.
    referenceConstraints.forEach(parseReference);
    combinerConstraints.forEach(parseCombiner);
    fuseConstraints.forEach(parseFuse);
    relativeOrderConstraints.forEach(parseRelativeOrder);
    return ConstraintData(nameMap.values.toList(), orderedNodes);
  }
}
