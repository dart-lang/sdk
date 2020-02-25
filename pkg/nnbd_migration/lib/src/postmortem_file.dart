// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' as convert;

import 'package:analyzer/file_system/file_system.dart';
import 'package:nnbd_migration/nullability_state.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/variables.dart';

/// Representation of a single step in the downstream propagation algorithm.
class DownstreamPropagationStep extends PropagationStep<Nullability> {
  DownstreamPropagationStep(NullabilityNode node, Nullability newState,
      {NullabilityNode causeNode, NullabilityEdge causeEdge})
      : super(node, newState, causeNode: causeNode, causeEdge: causeEdge);

  DownstreamPropagationStep.fromJson(
      dynamic json, NullabilityGraphDeserializer deserializer)
      : super.fromJson(
            json, deserializer, (json) => Nullability.fromJson(json));

  Map<String, Object> toJson(NullabilityGraphSerializer serializer) =>
      toJsonInternal(serializer, (state) => state.toJson());
}

/// Helper class for reading a postmortem file.
class PostmortemFileReader {
  final NullabilityGraphDeserializer deserializer;

  final NullabilityGraph graph;

  final List<UpstreamPropagationStep> upstreamPropagationSteps;

  final List<DownstreamPropagationStep> downstreamPropagationSteps;

  final Map<String, Map<int, Map<String, NullabilityNode>>> fileDecorations;

  factory PostmortemFileReader.read(File file) {
    var json = convert.json.decode(file.readAsStringSync());
    var deserializer = NullabilityGraphDeserializer(
        json['graph']['nodes'] as List<dynamic>,
        json['graph']['edges'] as List<dynamic>);
    return PostmortemFileReader._(json, deserializer);
  }

  PostmortemFileReader._(dynamic json, this.deserializer)
      : graph = NullabilityGraph.fromJson(json['graph'], deserializer),
        upstreamPropagationSteps = [
          for (var step in json['upstreamPropagationSteps'])
            UpstreamPropagationStep.fromJson(step, deserializer)
        ],
        downstreamPropagationSteps = [
          for (var step in json['downstreamPropagationSteps'])
            DownstreamPropagationStep.fromJson(step, deserializer)
        ],
        fileDecorations = {
          for (var fileEntry
              in (json['fileDecorations'] as Map<String, dynamic>).entries)
            fileEntry.key: {
              for (var decorationEntry
                  in (fileEntry.value as Map<String, dynamic>).entries)
                int.parse(decorationEntry.key): {
                  for (var roleEntry
                      in (decorationEntry.value as Map<String, dynamic>)
                          .entries)
                    roleEntry.key:
                        deserializer.nodeForId(roleEntry.value as int)
                }
            }
        };

  NodeToIdMapper get idMapper => deserializer;

  void findDecorationsByNode(NullabilityNode node,
      void Function(String path, OffsetEndPair span, String role) callback) {
    for (var fileEntry in fileDecorations.entries) {
      for (var decorationEntry in fileEntry.value.entries) {
        for (var roleEntry in decorationEntry.value.entries) {
          if (identical(roleEntry.value, node)) {
            callback(
                fileEntry.key,
                Variables.spanForUniqueIdentifier(decorationEntry.key),
                roleEntry.key);
          }
        }
      }
    }
  }
}

/// Helper class for writing to a postmortem file.
class PostmortemFileWriter {
  final File file;

  NullabilityGraph graph;

  final List<DownstreamPropagationStep> downstreamPropagationSteps = [];

  final List<UpstreamPropagationStep> upstreamPropagationSteps = [];

  final Map<String, Map<int, Map<String, NullabilityNode>>> _fileDecorations =
      {};

  PostmortemFileWriter(this.file);

  void storeFileDecorations(
      String path, int location, DecoratedType decoratedType) {
    var roles = <String, NullabilityNode>{};
    decoratedType.recordRoles(roles);
    (_fileDecorations[path] ??= {})[location] = roles;
  }

  void write() {
    var json = <String, Object>{};
    var serializer = NullabilityGraphSerializer();
    json['graph'] = graph.toJson(serializer);
    json['upstreamPropagationSteps'] = [
      for (var step in upstreamPropagationSteps) step.toJson(serializer)
    ];
    json['downstreamPropagationSteps'] = [
      for (var step in downstreamPropagationSteps) step.toJson(serializer)
    ];
    json['fileDecorations'] = {
      for (var fileEntry in _fileDecorations.entries)
        fileEntry.key: {
          for (var decorationEntry in (fileEntry.value).entries)
            decorationEntry.key.toString(): {
              for (var roleEntry in (decorationEntry.value).entries)
                roleEntry.key: serializer.idForNode(roleEntry.value)
            }
        }
    };
    file.writeAsStringSync(convert.json.encode(json));
  }
}

class PropagationStep<State> {
  /// The node whose state was changed.
  final NullabilityNode node;

  /// The new state.
  final State newState;

  /// The cause of the state change (if the cause was a node), otherwise `null`.
  final NullabilityNode causeNode;

  /// The cause of the state change (if the cause was an edge), otherwise
  /// `null`.
  final NullabilityEdge causeEdge;

  PropagationStep(this.node, this.newState, {this.causeNode, this.causeEdge});

  PropagationStep.fromJson(
      dynamic json,
      NullabilityGraphDeserializer deserializer,
      State Function(dynamic) deserializeState)
      : node = deserializer.nodeForId(json['node'] as int),
        newState = deserializeState(json['newState']),
        causeNode = json['causeNode'] == null
            ? null
            : deserializer.nodeForId(json['causeNode'] as int),
        causeEdge = json['causeEdge'] == null
            ? null
            : deserializer.edgeForId(json['causeEdge'] as int);

  Map<String, Object> toJsonInternal(NullabilityGraphSerializer serializer,
      String Function(State) serializeState) {
    var json = <String, Object>{};
    json['node'] = serializer.idForNode(node);
    json['newState'] = serializeState(newState);
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

/// Representation of a single step in the upstream propagation algorithm.
class UpstreamPropagationStep extends PropagationStep<NonNullIntent> {
  UpstreamPropagationStep(NullabilityNode node, NonNullIntent newState,
      {NullabilityNode causeNode, NullabilityEdge causeEdge})
      : super(node, newState, causeNode: causeNode, causeEdge: causeEdge);

  UpstreamPropagationStep.fromJson(
      dynamic json, NullabilityGraphDeserializer deserializer)
      : super.fromJson(
            json, deserializer, (json) => NonNullIntent.fromJson(json));

  Map<String, Object> toJson(NullabilityGraphSerializer serializer) =>
      toJsonInternal(serializer, (state) => state.toJson());
}
