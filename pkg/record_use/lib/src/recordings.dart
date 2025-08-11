// ignore_for_file: public_member_api_docs, sort_constructors_first
// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'constant.dart';
import 'definition.dart';
import 'helper.dart';
import 'identifier.dart';
import 'location.dart' show Location;
import 'metadata.dart';
import 'reference.dart';

/// [Recordings] combines recordings of calls and instances with metadata.
///
/// This class acts as the top-level container for recorded usage information.
/// The metadata provides context for the recording, such as version and
/// commentary. The [callsForDefinition] and [instancesForDefinition] store the
/// core data, associating each [Definition] with its corresponding [Reference]
/// details.
///
/// The class uses a normalized JSON format, allowing the reuse of locations and
/// constants across multiple recordings to optimize storage.
class Recordings {
  /// [Metadata] such as the recording protocol version.
  final Metadata metadata;

  /// The collected [CallReference]s for each [Definition].
  final Map<Definition, List<CallReference>> callsForDefinition;

  late final Map<Identifier, List<CallReference>> calls = callsForDefinition
      .map((definition, calls) => MapEntry(definition.identifier, calls));

  /// The collected [InstanceReference]s for each [Definition].
  final Map<Definition, List<InstanceReference>> instancesForDefinition;

  late final Map<Identifier, List<InstanceReference>> instances =
      instancesForDefinition.map(
        (definition, instances) => MapEntry(definition.identifier, instances),
      );

  static const _metadataKey = 'metadata';
  static const _constantsKey = 'constants';
  static const _locationsKey = 'locations';
  static const _recordingsKey = 'recordings';
  static const _callsKey = 'calls';
  static const _instancesKey = 'instances';
  static const _definitionKey = 'definition';

  Recordings({
    required this.metadata,
    required this.callsForDefinition,
    required this.instancesForDefinition,
  });

  /// Decodes a JSON representation into a [Recordings] object.
  ///
  /// The format is specifically designed to reduce redundancy and improve
  /// efficiency. Identifiers and constants are stored in separate tables,
  /// allowing them to be referenced by index in the `recordings` map.
  factory Recordings.fromJson(Map<String, Object?> json) {
    final constants = <Constant>[];
    for (final constantJsonObj in json[_constantsKey] as List? ?? []) {
      final constantJson = constantJsonObj as Map<String, Object?>;
      constants.add(Constant.fromJson(constantJson, constants));
    }
    final locations = <Location>[];
    for (final locationJsonObj in json[_locationsKey] as List? ?? []) {
      final locationJson = locationJsonObj as Map<String, Object?>;
      locations.add(Location.fromJson(locationJson));
    }

    final recordings =
        (json[_recordingsKey] as List?)?.whereType<Map<String, Object?>>() ??
        [];
    final recordedCalls = recordings.where(
      (recording) => recording[_callsKey] != null,
    );
    final recordedInstances = recordings.where(
      (recording) => recording[_instancesKey] != null,
    );
    return Recordings(
      metadata: Metadata.fromJson(json[_metadataKey] as Map<String, Object?>),
      callsForDefinition: {
        for (final recording in recordedCalls)
          Definition.fromJson(
                recording[_definitionKey] as Map<String, Object?>,
              ):
              (recording[_callsKey] as List)
                  .map(
                    (json) => CallReference.fromJson(
                      json as Map<String, Object?>,
                      constants,
                      locations,
                    ),
                  )
                  .toList(),
      },
      instancesForDefinition: {
        for (final recording in recordedInstances)
          Definition.fromJson(
                recording[_definitionKey] as Map<String, Object?>,
              ):
              (recording[_instancesKey] as List)
                  .map(
                    (json) => InstanceReference.fromJson(
                      json as Map<String, Object?>,
                      constants,
                      locations,
                    ),
                  )
                  .toList(),
      },
    );
  }

  /// Encodes this object into a JSON representation.
  ///
  /// This method normalizes identifiers and constants for storage efficiency.
  Map<String, Object?> toJson() {
    final constants =
        {
          ...callsForDefinition.values
              .expand((element) => element)
              .whereType<CallWithArguments>()
              .expand(
                (call) => [
                  ...call.positionalArguments,
                  ...call.namedArguments.values,
                ],
              )
              .nonNulls,
          ...instancesForDefinition.values
              .expand((element) => element)
              .expand(
                (instance) => {
                  ...instance.instanceConstant.fields.values,
                  instance.instanceConstant,
                },
              ),
        }.flatten().asMapToIndices;
    final locations =
        {
          ...callsForDefinition.values
              .expand((calls) => calls)
              .map((call) => call.location),
          ...instancesForDefinition.values
              .expand((instances) => instances)
              .map((instance) => instance.location),
        }.asMapToIndices;
    return {
      _metadataKey: metadata.json,
      if (constants.isNotEmpty)
        _constantsKey:
            constants.keys
                .map((constant) => constant.toJson(constants))
                .toList(),
      if (locations.isNotEmpty)
        _locationsKey:
            locations.keys.map((location) => location.toJson()).toList(),
      if (callsForDefinition.isNotEmpty || instancesForDefinition.isNotEmpty)
        _recordingsKey: [
          if (callsForDefinition.isNotEmpty)
            ...callsForDefinition.entries.map(
              (entry) => {
                _definitionKey: entry.key.toJson(),
                _callsKey:
                    entry.value
                        .map((call) => call.toJson(constants, locations))
                        .toList(),
              },
            ),
          if (instancesForDefinition.isNotEmpty)
            ...instancesForDefinition.entries.map(
              (entry) => {
                _definitionKey: entry.key.toJson(),
                _instancesKey:
                    entry.value
                        .map(
                          (instance) => instance.toJson(constants, locations),
                        )
                        .toList(),
              },
            ),
        ],
    };
  }

  @override
  bool operator ==(covariant Recordings other) {
    if (identical(this, other)) return true;

    return other.metadata == metadata &&
        deepEquals(other.callsForDefinition, callsForDefinition) &&
        deepEquals(other.instancesForDefinition, instancesForDefinition);
  }

  @override
  int get hashCode => Object.hash(
    metadata.hashCode,
    deepHash(callsForDefinition),
    deepHash(instancesForDefinition),
  );
}

extension on Iterable<Constant> {
  Set<Constant> flatten() {
    final constants = <Constant>{};
    for (final constant in this) {
      depthFirstSearch(constant, constants);
    }
    return constants;
  }

  void depthFirstSearch(Constant constant, Set<Constant> collected) {
    final children = switch (constant) {
      ListConstant<Constant>() => constant.value,
      MapConstant<Constant>() => constant.value.values,
      InstanceConstant() => constant.fields.values,
      _ => <Constant>[],
    };
    for (final child in children) {
      if (!collected.contains(child)) {
        depthFirstSearch(child, collected);
      }
    }
    collected.add(constant);
  }
}

extension _PrivateIterableExtension<T> on Iterable<T> {
  /// Transform list to map, faster than using list.indexOf
  Map<T, int> get asMapToIndices {
    var i = 0;
    return {for (final element in this) element: i++};
  }
}
