// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'nodes.dart';

import '../../../compiler_new.dart' as api;
import '../../kernel/front_end_adapter.dart' show CompilerFileSystem;

/// [Parser] parsers a program split constraints json file and returns a
/// [ConstraintData] object.
class Parser {
  final Map<String, NamedNode> nameMap = {};
  final List<RelativeOrderNode> orderedNodes = [];

  T _lookup<T>(Map<String, dynamic> nodeJson, String key) {
    var value = nodeJson[key];
    if (value == null) {
      throw 'Missing "$key" key in $nodeJson';
    }
    return value;
  }

  void parseReference(Map<String, dynamic> nodeJson) {
    String name = _lookup(nodeJson, 'name');
    String uriAndPrefixString = _lookup(nodeJson, 'import');
    var uriAndPrefix = uriAndPrefixString.split('#');
    if (uriAndPrefix.length != 2) {
      throw 'Invalid "import" "uri#prefix" value in $nodeJson';
    }
    var uri = Uri.parse(uriAndPrefix[0]);
    var prefix = uriAndPrefix[1];
    var referenceNode = ReferenceNode(name, uri, prefix);
    nameMap[name] = referenceNode;
  }

  CombinerType parseCombinerType(Map<String, dynamic> nodeJson) {
    String type = nodeJson['type'];
    switch (type) {
      case 'fuse':
        return CombinerType.fuse;
      case 'and':
        return CombinerType.and;
      default:
        throw 'Unrecognized Combiner $nodeJson';
    }
  }

  void parseCombiner(Map<String, dynamic> nodeJson) {
    String name = _lookup(nodeJson, 'name');
    List<dynamic> referencesJson = _lookup(nodeJson, 'nodes');
    Set<ReferenceNode> references = {};
    for (String reference in referencesJson) {
      references.add(nameMap[reference]);
    }
    var combinerNode =
        CombinerNode(name, parseCombinerType(nodeJson), references);
    nameMap[name] = combinerNode;
  }

  NamedNode _lookupNode(Map<String, dynamic> nodeJson, String key) {
    var node = nameMap[_lookup(nodeJson, key)];
    if (node == null) {
      throw 'Invalid "$key" name in $nodeJson';
    }
    return node;
  }

  void parseOrder(Map<String, dynamic> nodeJson) {
    var predecessor = _lookupNode(nodeJson, 'predecessor');
    var successor = _lookupNode(nodeJson, 'successor');
    var orderNode =
        RelativeOrderNode(predecessor: predecessor, successor: successor);
    orderedNodes.add(orderNode);
  }

  /// Reads a program split constraints json file and returns a [Nodes] object
  /// reflecting the parsed constraints.
  Future<ConstraintData> read(api.CompilerInput provider, Uri path) async {
    String programSplitJson =
        await CompilerFileSystem(provider).entityForUri(path).readAsString();
    List<dynamic> doc = json.decode(programSplitJson);
    List<Map<String, dynamic>> referenceConstraints = [];
    List<Map<String, dynamic>> combinerConstraints = [];
    List<Map<String, dynamic>> orderConstraints = [];
    for (Map<String, dynamic> constraint in doc) {
      switch (constraint['type']) {
        case 'reference':
          referenceConstraints.add(constraint);
          break;
        case 'and':
        case 'fuse':
          combinerConstraints.add(constraint);
          break;
        case 'order':
          orderConstraints.add(constraint);
          break;
        default:
          throw 'Unrecognized constraint type in $constraint';
      }
    }

    // Parse references, than combiners, than finally sequences.
    referenceConstraints.forEach(parseReference);
    combinerConstraints.forEach(parseCombiner);
    orderConstraints.forEach(parseOrder);
    return ConstraintData(nameMap.values.toList(), orderedNodes);
  }
}
