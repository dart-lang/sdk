// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../helper.dart';
import '../public/arguments.dart';
import '../public/constant.dart';
import '../public/identifier.dart';
import '../public/metadata.dart';
import '../public/reference.dart';
import 'usage.dart';

class UsageRecord {
  final Metadata metadata;
  final List<Usage<CallReference>> calls;
  final List<Usage<InstanceReference>> instances;

  const UsageRecord({
    required this.metadata,
    required this.calls,
    required this.instances,
  });

  factory UsageRecord.fromJson(Map<String, dynamic> json) {
    final uris = json['uris'] as List<String>;

    final identifiers = (json['ids'] as List)
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => Identifier.fromJson(e, uris),
        )
        .toList();

    final constants = <Constant>[];
    for (var constantJsonObj in json['constants'] as List) {
      var constantJson = constantJsonObj as Map<String, dynamic>;
      constants.add(Constant.fromJson(constantJson, constants));
    }

    return UsageRecord(
      metadata: Metadata.fromJson(json['metadata'] as Map<String, dynamic>),
      calls: (json['calls'] as List?)
              ?.map((x) => Usage.fromJson(
                    x as Map<String, dynamic>,
                    identifiers,
                    uris,
                    constants,
                    CallReference.fromJson,
                  ))
              .toList() ??
          [],
      instances: (json['instances'] as List?)
              ?.map((x) => Usage.fromJson(
                    x as Map<String, dynamic>,
                    identifiers,
                    uris,
                    constants,
                    InstanceReference.fromJson,
                  ))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    final identifiers = <Identifier>{
      ...calls.map((call) => call.definition.identifier),
      ...instances.map((instance) => instance.definition.identifier),
    }.toList();
    final uris = <String>{
      ...identifiers.map((e) => e.uri),
      ...calls.expand((call) => [
            call.definition.location.uri,
            ...call.references.map((reference) => reference.location.uri),
          ]),
      ...instances.expand((instance) => [
            instance.definition.location.uri,
            ...instance.references.map((reference) => reference.location.uri),
          ]),
    }.toList();

    final constants = {
      ...calls.expand((e) => e.references
          .map((e) => e.arguments?.constArguments)
          .whereType<ConstArguments>()
          .expand((e) => {...e.named.values, ...e.positional.values})),
      ...instances
          .expand((element) => element.references)
          .expand((e) => e.instanceConstant.fields.values)
    }.flatten().toList();
    return {
      'metadata': metadata.toJson(),
      'uris': uris,
      'ids': identifiers.map((identifier) => identifier.toJson(uris)).toList(),
      'constants': constants.map((e) => e.toJson(constants)).toList(),
      if (calls.isNotEmpty)
        'calls': calls
            .map((reference) => reference.toJson(identifiers, uris, constants))
            .toList(),
      if (instances.isNotEmpty)
        'instances': instances
            .map((reference) => reference.toJson(identifiers, uris, constants))
            .toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UsageRecord &&
        other.metadata == metadata &&
        deepEquals(other.calls, calls) &&
        deepEquals(other.instances, instances);
  }

  @override
  int get hashCode =>
      Object.hash(metadata, deepHash(calls), deepHash(instances));
}

extension on Iterable<Constant> {
  Set<Constant> flatten() {
    final constants = <Constant>{};
    for (var constant in this) {
      constants.addAll(switch (constant) {
        ListConstant<Constant> list => [...list.value.flatten(), list],
        MapConstant<Constant> map => [...map.value.values.flatten(), map],
        Constant() => {constant},
      });
    }
    return constants;
  }
}
