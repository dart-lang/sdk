// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'constant.dart';
import 'helper.dart';
import 'identifier.dart';
import 'location.dart' show Location;

const _loadingUnitKey = 'loading_unit';

/// A reference to *something*.
///
/// The something might be a call or an instance, matching a [CallReference] or
/// an [InstanceReference].
/// All references have in common that they occur in a [loadingUnit], which we
/// record to be able to piece together which loading units are "related", for
/// example all needing the same asset.
sealed class Reference {
  final String? loadingUnit;
  final Location location;

  const Reference({required this.loadingUnit, required this.location});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Reference &&
        other.loadingUnit == loadingUnit &&
        other.location == location;
  }

  @override
  int get hashCode => Object.hash(loadingUnit, location);

  Map<String, Object?> toJson(
    Map<Constant, int> constants,
    Map<Location, int> locations,
  ) => {_loadingUnitKey: loadingUnit, _locationKey: locations[location]};
}

const _locationKey = '@';
const _positionalKey = 'positional';
const _namedKey = 'named';
const _typeKey = 'type';

/// A reference to a call to some [Identifier].
///
/// This might be an actual call, in which case we record the arguments, or a
/// tear-off, in which case we can't record the arguments.
sealed class CallReference extends Reference {
  const CallReference({required super.loadingUnit, required super.location});

  static CallReference fromJson(
    Map<String, Object?> json,
    List<Constant> constants,
    List<Location> locations,
  ) {
    final loadingUnit = json[_loadingUnitKey] as String?;
    final location = locations[json[_locationKey] as int];
    return json[_typeKey] == 'tearoff'
        ? CallTearOff(loadingUnit: loadingUnit, location: location)
        : CallWithArguments(
          positionalArguments:
              (json[_positionalKey] as List<dynamic>? ?? [])
                  .whereType<int?>()
                  .map((index) {
                    return index != null ? constants[index] : null;
                  })
                  .toList(),
          namedArguments: (json[_namedKey] as Map<String, Object?>? ?? {}).map(
            (key, value) =>
                MapEntry(key, value != null ? constants[value as int] : null),
          ),
          loadingUnit: loadingUnit,
          location: location,
        );
  }
}

/// A reference to a call to some [Identifier] with [positionalArguments] and
/// [namedArguments].
final class CallWithArguments extends CallReference {
  final List<Constant?> positionalArguments;
  final Map<String, Constant?> namedArguments;

  const CallWithArguments({
    required this.positionalArguments,
    required this.namedArguments,
    required super.loadingUnit,
    required super.location,
  });

  @override
  Map<String, Object?> toJson(
    Map<Constant, int> constants,
    Map<Location, int> locations,
  ) {
    final positionalJson =
        positionalArguments.map((constant) => constants[constant]).toList();
    final namedJson = namedArguments.map(
      (name, constant) => MapEntry(name, constants[constant]),
    );
    return {
      _typeKey: 'with_arguments',
      if (positionalJson.isNotEmpty) _positionalKey: positionalJson,
      if (namedJson.isNotEmpty) _namedKey: namedJson,
      ...super.toJson(constants, locations),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (!(super == other)) return false;

    return other is CallWithArguments &&
        deepEquals(other.positionalArguments, positionalArguments) &&
        deepEquals(other.namedArguments, namedArguments);
  }

  @override
  int get hashCode => Object.hash(
    deepHash(positionalArguments),
    deepHash(namedArguments),
    super.hashCode,
  );
}

/// A reference to a tear-off use of the [Identifier]. This means that we can't
/// record the arguments possibly passed to the method somewhere else.
final class CallTearOff extends CallReference {
  const CallTearOff({required super.loadingUnit, required super.location});

  @override
  Map<String, Object?> toJson(
    Map<Constant, int> constants,
    Map<Location, int> locations,
  ) {
    return {_typeKey: 'tearoff', ...super.toJson(constants, locations)};
  }
}

final class InstanceReference extends Reference {
  final InstanceConstant instanceConstant;

  const InstanceReference({
    required this.instanceConstant,
    required super.loadingUnit,
    required super.location,
  });

  static const _constantKey = 'constant_index';

  factory InstanceReference.fromJson(
    Map<String, Object?> json,
    List<Constant> constants,
    List<Location> locations,
  ) {
    return InstanceReference(
      instanceConstant:
          constants[json[_constantKey] as int] as InstanceConstant,
      loadingUnit: json[_loadingUnitKey] as String?,
      location: locations[json[_locationKey] as int],
    );
  }

  @override
  Map<String, Object?> toJson(
    Map<Constant, int> constants,
    Map<Location, int> locations,
  ) => {
    _constantKey: constants[instanceConstant]!,
    ...super.toJson(constants, locations),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (!(super == other)) return false;

    return other is InstanceReference &&
        other.instanceConstant == instanceConstant;
  }

  @override
  int get hashCode => Object.hash(instanceConstant, super.hashCode);
}
