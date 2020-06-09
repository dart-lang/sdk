// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' as convert;

import 'package:analyzer/file_system/file_system.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/variables.dart';

/// Helper class for reading a postmortem file.
class PostmortemFileReader {
  final NullabilityGraphDeserializer deserializer;

  final NullabilityGraph graph;

  final List<PropagationStep> propagationSteps;

  final Map<String, Map<int, Map<String, NullabilityNode>>> fileDecorations;

  factory PostmortemFileReader.read(File file) {
    var json = convert.json.decode(file.readAsStringSync());
    List<PropagationStep> deserializedSteps = [];
    var deserializer = NullabilityGraphDeserializer(
        json['graph']['nodes'] as List<dynamic>,
        json['graph']['edges'] as List<dynamic>,
        deserializedSteps);
    return PostmortemFileReader._(json, deserializer, deserializedSteps);
  }

  PostmortemFileReader._(dynamic json, this.deserializer, this.propagationSteps)
      : graph = NullabilityGraph.fromJson(json['graph'], deserializer),
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
        } {
    _decodePropagationSteps(json['propagationSteps']);
  }

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

  void _decodePropagationSteps(dynamic json) {
    for (var serializedStep in json) {
      var step = PropagationStep.fromJson(serializedStep, deserializer);
      deserializer.recordStepId(step, propagationSteps.length);
      propagationSteps.add(step);
    }
  }
}

/// Helper class for writing to a postmortem file.
class PostmortemFileWriter {
  final File file;

  NullabilityGraph graph;

  final List<PropagationStep> _propagationSteps = [];

  final Map<String, Map<int, Map<String, NullabilityNode>>> _fileDecorations =
      {};

  PostmortemFileWriter(this.file);

  void addPropagationStep(PropagationStep step) {
    _propagationSteps.add(step);
  }

  void clearPropagationSteps() {
    _propagationSteps.clear();
  }

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
    List<Object> serializedPropagationSteps = [];
    for (var step in _propagationSteps) {
      serializer.recordStepId(step, serializedPropagationSteps.length);
      serializedPropagationSteps.add(step.toJson(serializer));
    }
    json['propagationSteps'] = serializedPropagationSteps;
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
