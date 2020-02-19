// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' as convert;

import 'package:analyzer/file_system/file_system.dart';
import 'package:nnbd_migration/nullability_state.dart';
import 'package:nnbd_migration/src/nullability_node.dart';

/// Representation of a single step in the downstream propagation algorithm.
class DownstreamPropagationStep {
  /// The node whose state was changed.
  final NullabilityNode node;

  /// The new state.
  final Nullability newState;

  /// The cause of the state change (if the cause was a node), otherwise `null`.
  final NullabilityNode causeNode;

  /// The cause of the state change (if the cause was an edge), otherwise
  /// `null`.
  final NullabilityEdge causeEdge;

  DownstreamPropagationStep(this.node, this.newState,
      {this.causeNode, this.causeEdge});

  DownstreamPropagationStep.fromJson(
      dynamic json, NullabilityGraphDeserializer deserializer)
      : node = deserializer.nodeForId(json['node'] as int),
        newState = Nullability.fromJson(json['newState']),
        causeNode = json['causeNode'] == null
            ? null
            : deserializer.nodeForId(json['causeNode'] as int),
        causeEdge = json['causeEdge'] == null
            ? null
            : deserializer.edgeForId(json['causeEdge'] as int);

  Map<String, Object> toJson(NullabilityGraphSerializer serializer) {
    var json = <String, Object>{};
    json['node'] = serializer.idForNode(node);
    json['newState'] = newState.toJson();
    if (causeNode != null) {
      json['causeNode'] = serializer.idForNode(causeNode);
    }
    if (causeEdge != null) {
      json['causeEdge'] = serializer.idForEdge(causeEdge);
    }
    return json;
  }

  @override
  String toString({NodeToIdMapper idMapper}) =>
      '${node.toString(idMapper: idMapper)} becomes $newState due to '
      '${_computeCause(idMapper: idMapper)}';

  String _computeCause({NodeToIdMapper idMapper}) {
    var causes = <String>[
      if (causeNode != null) causeNode.toString(idMapper: idMapper),
      if (causeEdge != null) causeEdge.toString(idMapper: idMapper)
    ];
    if (causes.isEmpty) {
      return 'NO CAUSE';
    } else {
      return causes.join(', ');
    }
  }
}

/// Helper class for reading a postmortem file.
class PostmortemFileReader {
  final NullabilityGraphDeserializer deserializer;

  final NullabilityGraph graph;

  final List<DownstreamPropagationStep> downstreamPropagationSteps;

  factory PostmortemFileReader.read(File file) {
    var json = convert.json.decode(file.readAsStringSync());
    var deserializer = NullabilityGraphDeserializer(
        json['graph']['nodes'] as List<dynamic>,
        json['graph']['edges'] as List<dynamic>);
    return PostmortemFileReader._(json, deserializer);
  }

  PostmortemFileReader._(dynamic json, this.deserializer)
      : graph = NullabilityGraph.fromJson(json['graph'], deserializer),
        downstreamPropagationSteps = [
          for (var step in json['downstreamPropagationSteps'])
            DownstreamPropagationStep.fromJson(step, deserializer)
        ];

  NodeToIdMapper get idMapper => deserializer;
}

/// Helper class for writing to a postmortem file.
class PostmortemFileWriter {
  final File file;

  NullabilityGraph graph;

  final List<DownstreamPropagationStep> downstreamPropagationSteps = [];

  PostmortemFileWriter(this.file);

  void write() {
    var json = <String, Object>{};
    var serializer = NullabilityGraphSerializer();
    json['graph'] = graph.toJson(serializer);
    json['downstreamPropagationSteps'] = [
      for (var step in downstreamPropagationSteps) step.toJson(serializer)
    ];
    file.writeAsStringSync(convert.json.encode(json));
  }
}
