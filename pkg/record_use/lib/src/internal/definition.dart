// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../public/identifier.dart';
import '../public/location.dart';

class Definition {
  final Identifier identifier;

  /// Represents the '@' field in the JSON
  final Location location;
  final String? loadingUnit;

  const Definition({
    required this.identifier,
    required this.location,
    this.loadingUnit,
  });

  factory Definition.fromJson(
    Map<String, dynamic> json,
    List<Identifier> identifiers,
    List<String> uris,
  ) {
    final identifier = identifiers[json['id'] as int];
    return Definition(
      identifier: identifier,
      location: Location.fromJson(json['@'] as Map<String, dynamic>, uris),
      loadingUnit: json['loadingUnit'] as String?,
    );
  }

  Map<String, dynamic> toJson(
    Map<Identifier, int> identifiers,
    Map<String, int> uris,
  ) =>
      {
        'id': identifiers[identifier]!,
        '@': location.toJson(uris),
        'loadingUnit': loadingUnit,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Definition &&
        other.identifier == identifier &&
        other.location == location &&
        other.loadingUnit == loadingUnit;
  }

  @override
  int get hashCode => Object.hash(identifier, location, loadingUnit);
}
