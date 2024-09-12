// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'arguments.dart';
import 'constant.dart';
import 'instance_constant.dart';
import 'location.dart';

sealed class Reference {
  final String? loadingUnit;

  /// Represents the "@" field in the JSON
  final Location location;

  const Reference({this.loadingUnit, required this.location});

  Map<String, dynamic> toJson(
    Map<String, int> uris,
    Map<Constant, int> constants,
  ) =>
      {
        'loadingUnit': loadingUnit,
        '@': location.toJson(uris: uris),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Reference &&
        other.loadingUnit == loadingUnit &&
        other.location == location;
  }

  @override
  int get hashCode => Object.hash(loadingUnit, location);
}

final class CallReference extends Reference {
  final Arguments? arguments;

  const CallReference({
    required this.arguments,
    super.loadingUnit,
    required super.location,
  });

  factory CallReference.fromJson(
    Map<String, dynamic> json,
    List<String> uris,
    List<Constant> constants,
  ) {
    return CallReference(
      arguments: json['arguments'] != null
          ? Arguments.fromJson(
              json['arguments'] as Map<String, dynamic>, constants)
          : null,
      loadingUnit: json['loadingUnit'] as String?,
      location:
          Location.fromJson(json['@'] as Map<String, dynamic>, null, uris),
    );
  }

  @override
  Map<String, dynamic> toJson(
    Map<String, int> uris,
    Map<Constant, int> constants,
  ) {
    final argumentJson = arguments?.toJson(constants) ?? {};
    return {
      if (argumentJson.isNotEmpty) 'arguments': argumentJson,
      ...super.toJson(uris, constants),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (!(super == other)) return false;

    return other is CallReference && other.arguments == arguments;
  }

  @override
  int get hashCode => Object.hash(arguments, super.hashCode);
}

final class InstanceReference extends Reference {
  final InstanceConstant instanceConstant;

  const InstanceReference({
    super.loadingUnit,
    required super.location,
    required this.instanceConstant,
  });

  factory InstanceReference.fromJson(
    Map<String, dynamic> json,
    List<String> uris,
    List<Constant> constants,
  ) {
    return InstanceReference(
      instanceConstant: InstanceConstant.fromJson(
        json['instanceConstant'] as Map<String, dynamic>,
        constants,
      ),
      loadingUnit: json['loadingUnit'] as String?,
      location: Location.fromJson(
        json['@'] as Map<String, dynamic>,
        null,
        uris,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson(
    Map<String, int> uris,
    Map<Constant, int> constants,
  ) =>
      {
        'instanceConstant': instanceConstant.toJson(constants),
        ...super.toJson(uris, constants),
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
